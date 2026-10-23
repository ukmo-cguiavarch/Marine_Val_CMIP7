#!/bin/bash
#SBATCH --mem=10G
#SBATCH --time=20
#SBATCH --ntasks=1

if [[ $# -ne 3 ]]; then echo 'mk_stc_glo_700m.bash [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi 

RUNID=$1
TAG=$2
FREQ=$3

PROC='runSTC700m' 
GENERATED_TMASKS=($(jq -r ".${PROC}[]" "${SCRPATH}/tmasks_generated.json"))

### Models ### 
RUN_NAME=${RUNID#*-}

# check presence of input file
FILET=`ls [nu]*${RUN_NAME}o_${FREQ}_${TAG}*_grid[-_]T.nc`
if [ ! -f $FILET ] ; then echo "$FILET is missing; exit"; echo "E R R O R in : ./mk_stc_glo_700m.bash $@ (see ${JOBOUT_PATH}/mk_stc_glo_700m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# Calculate salt content in Joules --> area of salt content for each layer
FILEOUT=SALTC_GLO_700m_${RUN_NAME}o_${FREQ}_${TAG}_saltc.nc

# Extract tmask filename
PATTERN="GLO"
for GEN_TMASK in "${GENERATED_TMASKS[@]}"; do
   if [[ "$GEN_TMASK" == *"$PATTERN"* ]]; then
      PARAMS=$(jq -c --arg tmask "$GEN_TMASK" '.[$tmask]' ${SCRPATH}/tmasks_all_params.json)
      TMASK=$(echo "$PARAMS" | jq -r '.o')
   fi
done
echo TMASK: $TMASK

# assumes 75 levels in ocean:
$CDFPATH/cdfsaltc -f $FILET -M $TMASK tmask -o tmp_$FILEOUT #

#Computes the salt content in the specified area (Joules). Using all depth.
#cdfsaltc  -f T-file [-mxloption option] [-mxlf MXL-file] ...'
#             [-zoom imin imax jmin jmax kmin kmax] [-full] [-o OUT-file]'
#             [-M MSK-file VAR-mask ] [-vvl ]

#outputs: saltc3d (Joules)

# mv output file
#if the previous command =! 0, save it otherwise return an error
if [[ $? -eq 0 ]]; then
   mv tmp_$FILEOUT $FILEOUT
else
   echo "error when running cdfsaltc; exit"; echo "E R R O R in : ./mk_stc_glo_700m.bash $@ (see ${JOBOUT_PATH}/mk_stc_glo_700m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi 

#needed due to problem reading masked saltc3d variable:
ncatted -a valid_min,saltc3d,d,, -a valid_max,saltc3d,d,, $FILEOUT

#SOUTHERN OCEAN
# Calculate salt content in Joules --> area of salt content for each layer
FILEOUT=SALTC_SO_700m_${RUN_NAME}o_${FREQ}_${TAG}_saltc.nc

# Extract tmask filename
PATTERN="SO_HEAT"
for GEN_TMASK in "${GENERATED_TMASKS[@]}"; do
   if [[ "$GEN_TMASK" == *"$PATTERN"* ]]; then
      PARAMS=$(jq -c --arg tmask "$GEN_TMASK" '.[$tmask]' ${SCRPATH}/tmasks_all_params.json)
      TMASK=$(echo "$PARAMS" | jq -r '.o')
   fi
done
echo TMASK: $TMASK

# assumes 75 levels in ocean:
$CDFPATH/cdfsaltc -f $FILET -M $TMASK tmask -o tmp_$FILEOUT #

#Computes the salt content in the specified area (Joules). Using all depth.
#cdfsaltc  -f T-file [-mxloption option] [-mxlf MXL-file] ...'
#             [-zoom imin imax jmin jmax kmin kmax] [-full] [-o OUT-file]'
#             [-M MSK-file VAR-mask ] [-vvl ]

#outputs: saltc3d (Joules)

# mv output file
#if the previous command =! 0, save it otherwise return an error
if [[ $? -eq 0 ]]; then
   mv tmp_$FILEOUT $FILEOUT
else
   echo "error when running cdfsaltc; exit"; echo "E R R O R in : ./mk_stc_glo_700m.bash $@ (see ${JOBOUT_PATH}/mk_stc_glo_700m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi 

#needed due to problem reading masked saltc3d variable:
ncatted -a valid_min,saltc3d,d,, -a valid_max,saltc3d,d,, $FILEOUT


#NORTH ATLANTIC
# Calculate salt content in Joules --> area of salt content for each layer
FILEOUT=SALTC_NA_ARC_700m_${RUN_NAME}o_${FREQ}_${TAG}_saltc.nc

# Extract tmask filename
PATTERN="NA_HEAT"
for GEN_TMASK in "${GENERATED_TMASKS[@]}"; do
   if [[ "$GEN_TMASK" == *"$PATTERN"* ]]; then
      PARAMS=$(jq -c --arg tmask "$GEN_TMASK" '.[$tmask]' ${SCRPATH}/tmasks_all_params.json)
      TMASK=$(echo "$PARAMS" | jq -r '.o')
   fi
done
echo TMASK: $TMASK

# assumes 75 levels in ocean:
$CDFPATH/cdfsaltc -f $FILET -M $TMASK tmask -o tmp_$FILEOUT #

#Computes the salt content in the specified area (Joules). Using all depth.
#cdfsaltc  -f T-file [-mxloption option] [-mxlf MXL-file] ...'
#             [-zoom imin imax jmin jmax kmin kmax] [-full] [-o OUT-file]'
#             [-M MSK-file VAR-mask ] [-vvl ]

#outputs: saltc3d (Joules)

# mv output file
#if the previous command =! 0, save it otherwise return an error
if [[ $? -eq 0 ]]; then
   mv tmp_$FILEOUT $FILEOUT
else
   echo "error when running cdfsaltc; exit"; echo "E R R O R in : ./mk_stc_glo_700m.bash $@ (see ${JOBOUT_PATH}/mk_stc_glo_700m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi 

#needed due to problem reading masked saltc3d variable:
ncatted -a valid_min,saltc3d,d,, -a valid_max,saltc3d,d,, $FILEOUT
