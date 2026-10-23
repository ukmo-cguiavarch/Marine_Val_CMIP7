# MARINE_VAL restartable retrieval and preprocessing

## Files
- pipeline.py: plan generation, Slurm submission, retrieval, processing, status and cancellation.
- worker.sh: batch environment setup. Edit module/conda commands for your cluster.
- config.json: run ID, paths, resource settings and time handling.

This is a proposed implementation based on your supplied script, not a cluster-tested replacement.
Python 3.8+, netCDF4, cftime and numpy are required. Batch workers also need moo, ncks,
ncatted and ncrename, archive credentials, shared filesystem access and your EOS80 converter.
Use a filesystem supporting advisory flock locks and same-filesystem atomic rename.
Run submissions on a host where sbatch is available. Workers must run where MASS is accessible.
No jobs have been submitted by Copilot.

## 1. Install and configure
Unzip the archive into a dedicated directory and cd there.

    module load scitools
    conda activate marval
    chmod +x worker.sh
    python -c "import netCDF4, cftime, numpy"

Edit config.json:
- Check run_id, work_root and converter.
- Check qos/account/partition and memory/time limits for your site.
- Choose time_mode explicitly: "none" or "rebase". The supplied placeholder blocks submission.
- For rebase, expected_time_units must exactly match the source metadata. The example
  1900 epoch is NOT verified against your files. Inspect an original file with ncdump -h.
  target_time_units defaults to seconds since 1850-01-01 00:00:00.
- Rebasing preserves represented dates using each variable's calendar, including 360_day;
  it does NOT repair an incorrectly labelled epoch or shift the represented model dates.
  If your old correction was intended to repair bad metadata, investigate that separately.
- delete_raw_after_chunk is false initially. Set true after the pilot to remove only
  pipeline-downloaded raw copies after successful chunk processing. MASS is never modified.
  With false, raw storage accumulates across waves. With true, raw staging is bounded
  approximately by one wave plus temporary working copies. Processed outputs still accumulate.
- Retrieval defaults to 4G; processing to 120G; both request 4 hours and one CPU/task.
  These are starting settings, not measured requirements or confirmed site limits.

## 2. Pilot on one year

    python pipeline.py plan 1850 1850 --chunk-years 1 --output pilot.json
    python pipeline.py submit --plan pilot.json --wave-chunks 1
    python pipeline.py status --plan pilot.json
    squeue -u "$USER" -r

Inspect logs and output metadata and compare diagnostics against your existing workflow.
The pilot is stored under processed/1850-1850. A later 10-year plan uses different chunk
folders, so it does not reuse this pilot output. Do not merge both sets blindly downstream.

## 3. Run 2,000 years (illustrative inclusive range)
After checking the pilot, set delete_raw_after_chunk to true if staging space is limited.

    python pipeline.py plan 1850 3849 --chunk-years 10
    python pipeline.py submit --wave-chunks 4
    python pipeline.py status

This creates 200 chunks. Each wave contains at most four chunks (40 years).
One retrieval task and two processing tasks run concurrently by default.
Within a wave, each processing task depends on its matching retrieval task (aftercorr).
The next wave's retrieval waits for the entire preceding processing array (afterok).
All waves are submitted immediately, subject to your site's queued-job limits; the script
itself does not stay running. For strict submission limits, submit subsets with --indices.
Failure stops downstream waves from progressing. No automatic retries or resubmissions.

The range 1850-3849 is only an example. Use the actual first and last archive years.
Keep chunk boundaries unchanged when restarting; changing them changes output/state paths.

## 4. Restart after a failure
Every submission prints the path to its jobs.json record.
Cancel the remaining jobs in that submission before restarting, to avoid duplicate workers:

    python pipeline.py cancel /absolute/path/to/submissions/TIMESTAMP/jobs.json

Check squeue until the old workers have stopped, then rerun:

    python pipeline.py submit --wave-chunks 4

Completed chunks and completed files are skipped when the processing signature matches.
Successful retrievals are checkpointed per product/year. An interrupted individual download
is fetched again; byte-range resume is not implemented. An interrupted processing file is
rebuilt from its untouched raw copy. Already published outputs are not modified in place.

To retry only chunk index 7 (zero-based) after cancelling its old jobs:

    python pipeline.py submit --indices 7 --wave-chunks 1

If retrieval succeeded and raw files remain, retry processing alone:

    python pipeline.py submit --indices 7 --only process --wave-chunks 1

Retrying one chunk does NOT release dependencies in an old failed submission. Cancel the
old submission and resubmit the full plan to continue later waves, or submit remaining indices.
If submission itself fails part-way, use the partial jobs.json record to cancel accepted jobs.
Cancellation errors should be checked: the cancel command stops at its first scancel failure.

## Output and restart safety
work_root contains raw/START-END, processed/START-END, state/START-END, logs/ and submissions/.
Each submission snapshots configuration, plan, pipeline, worker and the EOS80 converter.
The converter must be self-contained or import its dependencies from the active environment;
if it relies on sibling files or __file__ paths, adapt snapshotting before using this package.
Output signatures include processing code, converter contents and time configuration.
Changing those invalidates old output completion and may require fresh retrieval.
Full variable reads are performed on newly downloaded and newly processed files. Reuse checks
use saved file sizes/header readability for raw files and signature/header checks for outputs;
there is no cryptographic data-integrity audit on every restart. These checks do not prove
scientific correctness. Keep independent backups and inspect the pilot's scientific results.

## Product selection and preserved transformations
The retrieval code assumes exactly one file per year/product: annual U/V/T, December seasonal
T, March and September monthly T, and February/March/September monthly sea ice: nine files/year.
It accepts grid-T or grid_T naming. It deliberately stops on zero/multiple matches rather than
silently processing incomplete data. Adapt groups() if your archive layout differs.
It issues one moo get per product/year for granular checkpoints. This favours reliable retries,
not optimal tape batching. For a large tape workload, benchmark archive recall overhead; a
site-supported bulk manifest/recall method can replace retrieval without changing processing.
MOO wildcard support, credentials and actual archive filenames must be verified in the pilot.

The T/U/V renames, depth standard_name edits, EOS80 converter invocation, sea-ice x dimension
rename and T-file variable removals follow the supplied script. Only x_grid_T is renamed for
sea ice, as in the original; y_grid_T is unchanged. Missing optional drop variables are tolerated.
Required rename pairs fail if both names or neither name exist. T-file bounds attributes are
removed before deleting their variables. U/V/ice time bounds are retained and rebased when used.
The old repeated ncap2/ncatted time updates are replaced by calendar-aware Python rebasing.
No ncrcat concatenation or MARINE_VAL diagnostic execution is added.

## Operational notes
- Plan chunks small enough that one processing chunk fits wall time. If one file alone exceeds
  wall time, reduce its work or increase the permitted limit; chunking cannot fix that case.
- Disk usage includes all processed outputs, raw wave staging and temporary copies. This script
  does not enforce a byte quota or check free space automatically.
- Avoid overlapping submissions against the same work_root. Per-stage chunk locks protect
  duplicate workers, but do not replace cancelling old jobs before retrying.
- Existing completed output is reused only if its signature matches; manual edits to source
  archives are not detected by output signatures. Use a new work_root for changed input data.

## References checked during preparation
- Slurm job arrays: https://slurm.schedmd.com/job_array.html
- Slurm sbatch: https://slurm.schedmd.com/sbatch.html
- NCO manual: https://nco.sourceforge.net/nco.html
