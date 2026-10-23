#!/usr/bin/env python3
"""Restartable MASS retrieval and MARINE_VAL preprocessing. Python 3.8+."""
import argparse, contextlib, fcntl, glob, hashlib, json, os, pathlib, shutil
import subprocess, sys, tempfile, time
P = pathlib.Path
VERSION = 'marineval-pipeline-1'

def load(p):
    return json.loads(P(p).read_text())

def atomic_json(path, value):
    path=P(path); path.parent.mkdir(parents=True, exist_ok=True)
    tmp=path.with_name(path.name+'.tmp')
    tmp.write_text(json.dumps(value, indent=2)+'\n'); os.replace(tmp,path)

def run(args):
    print('+', ' '.join(map(str,args)), flush=True)
    subprocess.run(list(map(str,args)),check=True)

def signature(c):
    h=hashlib.sha256()
    h.update(VERSION.encode()); h.update(P(__file__).read_bytes())
    for k in ('run_id','time_mode','expected_time_units','target_time_units'):
        h.update(str(c[k]).encode())
    p=P(c['converter'])
    if p.is_file(): h.update(p.read_bytes())
    return h.hexdigest()

def validate(path, full=False):
    import netCDF4
    with netCDF4.Dataset(path) as ds:
        if not ds.variables: raise ValueError('No variables: '+str(path))
        # Full validation reads every variable in bounded first-dimension slabs.
        # One horizontal/depth slab can still be large; memory must allow it.
        if full:
            for v in ds.variables.values():
                if v.ndim == 0: v[...]
                else:
                    for i in range(v.shape[0]): v[i:i+1,...]

def valid_output(path, sig):
    import netCDF4
    try:
        with netCDF4.Dataset(path) as ds:
            return ds.getncattr('marineval_pipeline_signature') == sig
    except (OSError, AttributeError, RuntimeError): return False

@contextlib.contextmanager
def lock(path):
    P(path).parent.mkdir(parents=True,exist_ok=True)
    with open(path,'a') as f:
        try: fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB)
        except BlockingIOError: raise RuntimeError('Chunk already running: '+str(path))
        yield

def groups(c,year):
    rid=c['run_id']; y=f'{year:04d}'; root=f'moo:/crum/u-{rid}'
    # Explicit grid letters avoid matching unrelated annual products.
    for grid in 'UVT':
        yield f'{y}_annual_{grid}', f'{root}/ony.nc.file/nemo_{rid}o_1y_{y}*grid[-_]{grid}.nc'
    yield f'{y}_seasonal_T',f'{root}/ons.nc.file/nemo_{rid}o_1s_{y}1201*grid[-_]T.nc'
    for month in ('03','09'):
        yield f'{y}_monthly_T_{month}',f'{root}/onm.nc.file/nemo_{rid}o_1m_{y}{month}01*grid[-_]T.nc'
    for month in ('09','03','02'):
        yield f'{y}_ice_{month}',f'{root}/inm.nc.file/si3_{rid}i_1m_{y}{month}01*_icemod.nc'

def chunk_paths(c,chunk):
    root=P(c['work_root']); tag=f'{chunk[0]:04d}-{chunk[1]:04d}'
    state=root/'state'/tag; raw=root/'raw'/tag; out=root/'processed'/tag
    for p in (state,raw,out): p.mkdir(parents=True,exist_ok=True)
    return state,raw,out

def chunk_complete(state,out,sig):
    p=state/'processed.json'
    if not p.exists(): return False
    m=load(p)
    return m.get('signature')==sig and bool(m.get('files')) and all(valid_output(out/f,sig) for f in m['files'])

def retrieve(c,chunk):
    state,raw,out=chunk_paths(c,chunk); sig=signature(c)
    with lock(state/'retrieve.lock'):
        if chunk_complete(state,out,sig):
            print('Chunk already processed; retrieval skipped.'); return
        all_files=[]
        for year in range(chunk[0],chunk[1]+1):
            for key,uri in groups(c,year):
                marker=state/(key+'.json')
                if marker.exists():
                    m=load(marker)
                    if m.get('uri')==uri and all((raw/f).is_file() and (raw/f).stat().st_size==n for f,n in m['files'].items()):
                        for f in m['files']: validate(raw/f)
                        all_files.extend(m['files']); continue
                # Fresh isolated download: a failed moo get never publishes partial files.
                # Old interrupted .get-* directories are removed under the retrieval lock.
                for old in raw.glob('.get-*'): shutil.rmtree(old)
                with tempfile.TemporaryDirectory(prefix='.get-',dir=raw) as d:
                    run(['moo','get',uri,d])
                    files=list(P(d).glob('*.nc'))
                    if len(files)!=1:
                        raise RuntimeError(f'{uri}: expected exactly one file, found {len(files)}. Check naming/stream layout.')
                    f=files[0]; validate(f,full=True)
                    dest=raw/f.name
                    os.replace(f,dest)
                    atomic_json(marker,{'uri':uri,'files':{dest.name:dest.stat().st_size}})
                    all_files.append(dest.name)
        if len(set(all_files))!=len(all_files): raise RuntimeError('Duplicate filenames in retrieval manifest')
        atomic_json(state/'retrieved.json',{'files':all_files})

def rename(ds_path,kind,old,new):
    import netCDF4
    with netCDF4.Dataset(ds_path) as ds:
        names=ds.variables if kind=='v' else ds.dimensions
        has_old=old in names; has_new=new in names
    if has_old and has_new: raise RuntimeError(f'Both {old} and {new} exist in {ds_path}')
    if has_old: run(['ncrename','-O','-'+kind,old+','+new,ds_path])
    elif not has_new: raise RuntimeError(f'Neither {old} nor {new} exists in {ds_path}')

def correct_time(path, c=None):
    import re
    from pathlib import Path
    import netCDF4
    import cftime

    match = re.search(
        r"_(\d{8})-(\d{8})_", Path(path).name
    )
    if not match:
        raise ValueError(f"No date range found in filename: {path}")

    units = "seconds since 1850-01-01 00:00:00"

    with netCDF4.Dataset(path, "r+") as ds:
        names = [
            name for name in ("time_counter", "time_centered")
            if name in ds.variables
        ]
        if not names:
            raise ValueError(f"No recognised time variable: {path}")

        for name in names:
            var = ds.variables[name]
            if var.size != 1:
                raise ValueError(
                    f"{name}: expected one time record, found {var.size}"
                )

            calendar = getattr(var, "calendar", "standard")

            def to_seconds(tag):
                date = cftime.datetime(
                    int(tag[:4]),
                    int(tag[4:6]),
                    int(tag[6:8]),
                    calendar=calendar,
                )
                return float(
                    cftime.date2num(date, units, calendar=calendar)
                )

            start = to_seconds(match.group(1))
            end = to_seconds(match.group(2))

            if end <= start:
                raise ValueError(f"Invalid filename date range: {path}")

            midpoint = (start + end) / 2

            # Avoid silently truncating fractional seconds.
            if var.dtype.kind in "iu" and not midpoint.is_integer():
                raise ValueError(
                    f"{name}: integer variable cannot store {midpoint}"
                )

            var[...] = midpoint
            var.units = units
            var.time_origin = "1850-01-01 00:00:00"

def transform(path,c):
    import netCDF4
    name=path.name
    if name.startswith('si3_'):
        rename(path,'d','x_grid_T','x')
    elif 'grid-T' in name or 'grid_T' in name:
        run(['ncatted','-O','-a','standard_name,deptht,o,c,depth',path])
        rename(path,'v','bigthetao','thetao_con'); rename(path,'v','so','so_abs')
        run([sys.executable,c['converter'],path])
        rename(path,'v','thkcello','cell_thickness'); rename(path,'v','mlotst','somxzint1')
    elif 'grid-U' in name or 'grid_U' in name:
        run(['ncatted','-O','-a','standard_name,depthu,o,c,depth',path])
        rename(path,'v','thkcelluo','thkcello')
    elif 'grid-V' in name or 'grid_V' in name:
        run(['ncatted','-O','-a','standard_name,depthv,o,c,depth',path])
        rename(path,'v','thkcellvo','thkcello')
    else: raise RuntimeError('Unrecognised product '+name)
    correct_time(path,c)
    if 'grid-T' in name or 'grid_T' in name:
        candidates=['time_centered_bounds','time_counter_bounds','bounds_nav_lon','bounds_nav_lat','deptht_bounds','t20d','iax_20C']
        with netCDF4.Dataset(path) as ds:
            drop=[v for v in candidates if v in ds.variables]
            attrs=[v for v in ('nav_lon','nav_lat','time_centered','time_counter','deptht') if v in ds.variables and 'bounds' in ds[v].ncattrs()]
        if attrs:
            args=['ncatted','-O']
            for v in attrs: args+=['-a',f'bounds,{v},d,,']
            run(args+[path])
        if drop: run(['ncks','-O','-C','-x','-v',','.join(drop),path,path])

def process(c,chunk):
    state,raw,out=chunk_paths(c,chunk); sig=signature(c)
    with lock(state/'process.lock'):
        if chunk_complete(state,out,sig):
            print('Chunk already processed; skipping.')
            cleanup(c,state,raw); return
        manifest=state/'retrieved.json'
        if not manifest.exists(): raise RuntimeError('No successful retrieval manifest')
        files=load(manifest)['files']
        for name in files:
            dest=out/name
            if valid_output(dest,sig): print('SKIP',name,flush=True); continue
            source=raw/name
            if not source.is_file(): raise RuntimeError('Missing raw file; rerun retrieval: '+str(source))
            for old in out.glob('.work-*'): shutil.rmtree(old)
            with tempfile.TemporaryDirectory(prefix='.work-',dir=out) as d:
                work=P(d)/name; shutil.copy2(source,work)
                transform(work,c); validate(work,full=True)
                import netCDF4
                with netCDF4.Dataset(work,'r+') as ds:
                    ds.marineval_pipeline_signature=sig
                os.replace(work,dest)
        atomic_json(state/'processed.json',{'signature':sig,'files':files})
        cleanup(c,state,raw)

def cleanup(c,state,raw):
    if c['delete_raw_after_chunk']:
        # Delete only manifest-listed files created by this pipeline.
        for name in load(state/'processed.json')['files']:
            (raw/name).unlink(missing_ok=True)
        print('Validated chunk complete; pipeline raw copies removed.',flush=True)

def preflight(c):
    if c['time_mode'] not in ('none','rebase'):
        raise ValueError('Set time_mode to none or rebase in config.json before submission')
    if not P(c['work_root']).is_absolute(): raise ValueError('work_root must be absolute')
    if not P(c['converter']).is_file(): raise ValueError('Converter not found: '+c['converter'])
    if not isinstance(c['delete_raw_after_chunk'],bool): raise ValueError('delete_raw_after_chunk must be boolean')
    for key in ('retrieve_concurrency','process_concurrency'):
        if not isinstance(c[key],int) or c[key]<1: raise ValueError(key+' must be positive')

def submit(c,config_path,plan_path,wave_size,indices,only):
    preflight(c)
    chunks=load(plan_path)['chunks']
    chosen=list(range(len(chunks))) if indices is None else [int(i) for i in indices.split(',')]
    if not chosen or len(set(chosen))!=len(chosen) or any(i<0 or i>=len(chunks) for i in chosen):
        raise ValueError('Invalid/duplicate chunk indices')
    root=P(c['work_root']); (root/'logs').mkdir(parents=True,exist_ok=True)
    # Immutable per-submission copies: later config/plan edits do not change queued jobs.
    snap=root/'submissions'/(time.strftime('%Y%m%dT%H%M%S')+'-'+str(time.time_ns()))
    snap.mkdir(parents=True,exist_ok=False)
    atomic_json(snap/'config.json',c); atomic_json(snap/'plan.json',load(plan_path))
    shutil.copy2(__file__,snap/'pipeline.py')
    shutil.copy2(P(__file__).with_name('worker.sh'),snap/'worker.sh')
    shutil.copy2(c['converter'],snap/'convert_nemo_eos80.py')
    c['converter']=str(snap/'convert_nemo_eos80.py'); atomic_json(snap/'config.json',c)
    prev=None; jobs=[]
    for start in range(0,len(chosen),wave_size):
        ids=chosen[start:start+wave_size]; spec=','.join(map(str,ids))
        def sb(stage,dependency=None):
            args=['sbatch','--parsable','--job-name=mv_'+stage,'--ntasks=1','--cpus-per-task=1',
                  '--array='+spec+'%'+str(c[stage+'_concurrency']),
                  '--mem='+c[stage+'_memory'],'--time='+c[stage+'_walltime'],
                  '--output='+str(root/'logs'/(stage+'_%A_%a.out')),
                  '--error='+str(root/'logs'/(stage+'_%A_%a.err'))]
            for key in ('qos','account','partition'):
                if c.get(key): args+=['--'+key+'='+c[key]]
            if dependency: args+=['--dependency='+dependency]
            args += [str(snap/'worker.sh'),str(snap/'pipeline.py'),stage,str(snap/'config.json'),str(snap/'plan.json')]
            print('+',' '.join(args),flush=True)
            result=subprocess.check_output(args,text=True).strip().split(';')[0]
            if not result.isdigit(): raise RuntimeError('Unexpected sbatch output: '+result)
            jobs.append({'stage':stage,'job_id':result,'indices':ids})
            atomic_json(snap/'jobs.json',jobs)
            return result
        if only=='process': p=sb('process','afterok:'+prev if prev else None)
        else:
            r=sb('retrieve','afterok:'+prev if prev else None)
            p=sb('process','aftercorr:'+r)
        prev=p
    print('Submission record:',snap/'jobs.json')
    print('On failure: cancel remaining jobs from this record before resubmitting. Completed files are reused.')

def main():
    a=argparse.ArgumentParser(description=__doc__); sub=a.add_subparsers(dest='cmd',required=True)
    p=sub.add_parser('plan'); p.add_argument('first',type=int); p.add_argument('last',type=int); p.add_argument('--chunk-years',type=int,default=10); p.add_argument('--output',default='chunks.json')
    p=sub.add_parser('submit'); p.add_argument('--config',default='config.json'); p.add_argument('--plan',default='chunks.json'); p.add_argument('--wave-chunks',type=int,default=4); p.add_argument('--indices'); p.add_argument('--only',choices=['both','process'],default='both')
    p=sub.add_parser('status'); p.add_argument('--config',default='config.json'); p.add_argument('--plan',default='chunks.json')
    p=sub.add_parser('worker'); p.add_argument('stage',choices=['retrieve','process']); p.add_argument('config'); p.add_argument('plan'); p.add_argument('index',type=int)
    p=sub.add_parser('cancel'); p.add_argument('record')
    args=a.parse_args()
    if args.cmd=='plan':
        if not (1<=args.first<=args.last<=9999) or args.chunk_years<1: raise ValueError('Require 1 <= first <= last <= 9999 and positive chunk size')
        chunks=[[y,min(y+args.chunk_years-1,args.last)] for y in range(args.first,args.last+1,args.chunk_years)]
        atomic_json(args.output,{'chunks':chunks}); print(f'{len(chunks)} chunks; inclusive years {args.first}-{args.last}')
    elif args.cmd=='cancel':
        for job in load(args.record): run(['scancel',job['job_id']])
    else:
        c=load(args.config)
        if args.cmd=='submit':
            if args.wave_chunks<1: raise ValueError('wave-chunks must be positive')
            submit(c,args.config,args.plan,args.wave_chunks,args.indices,args.only)
        elif args.cmd=='worker':
            preflight(c); chunk=load(args.plan)['chunks'][args.index]
            print(args.stage,chunk,flush=True)
            (retrieve if args.stage=='retrieve' else process)(c,chunk)
        else:
            sig=signature(c)
            for i,chunk in enumerate(load(args.plan)['chunks']):
                state,raw,out=chunk_paths(c,chunk)
                done=chunk_complete(state,out,sig)
                print(i,chunk[0],chunk[1], 'DONE' if done else ('RETRIEVED/INCOMPLETE' if (state/'retrieved.json').exists() else 'NOT READY'))

if __name__=='__main__':
    try: main()
    except Exception as e:
        print('ERROR:',str(e),file=sys.stderr); sys.exit(1)
