#!/bin/bash
#SBATCH --mem=10G
#SBATCH --time=20
#SBATCH --ntasks=1

if [[ $# -ne 3 ]]; then echo 'mk_htc_glo_700_2000m.bash [RUNID (mi-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi 

RUNID=$1
TAG=$2
FREQ=$3

PROC='runHTC700_2000m' 
GENERATED_TMASKS=($(jq -r ".${PROC}[]" "${SCRPATH}/tmasks_generated.json"))

### Models ### 
RUN_NAME=${RUNID#*-}

# check presence of input file
FILET=`ls [nu]*${RUN_NAME}o_${FREQ}_${TAG}*_grid[-_]T.nc`
if [ ! -f $FILET ] ; then echo "$FILET is missing; exit"; echo "E R R O R in : ./mk_htc_glo_700_2000m.bash $@ (see ${JOBOUT_PATH}/mk_htc_glo_700_2000m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# Calculate heat content in Joules --> area of heat content for each layer
FILEOUT=HEATC_GLO_700_2000m_${RUN_NAME}o_${FREQ}_${TAG}_heatc.nc

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
$CDFPATH/cdfheatc -f $FILET -M $TMASK tmask -o tmp_$FILEOUT #

#Computes the heat content in the specified area (Joules). Using all depth.
#cdfheatc  -f T-file [-mxloption option] [-mxlf MXL-file] ...'
#             [-zoom imin imax jmin jmax kmin kmax] [-full] [-o OUT-file]'
#             [-M MSK-file VAR-mask ] [-vvl ]

#outputs: heatc3d (Joules)

# mv output file
#if the previous command =! 0, save it otherwise return an error
if [[ $? -eq 0 ]]; then
   mv tmp_$FILEOUT $FILEOUT
else
   echo "error when running cdfheatc; exit"; echo "E R R O R in : ./mk_htc_glo_700_2000m.bash $@ (see ${JOBOUT_PATH}/mk_htc_glo_700_2000m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi 

#needed due to problem reading masked heatc3d variable:
ncatted -a valid_min,heatc3d,d,, -a valid_max,heatc3d,d,, $FILEOUT

#SOUTHERN OCEAN

# Calculate heat content in Joules --> area of heat content for each layer
FILEOUT=HEATC_SO_700_2000m_${RUN_NAME}o_${FREQ}_${TAG}_heatc.nc

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
$CDFPATH/cdfheatc -f $FILET -M $TMASK tmask -o tmp_$FILEOUT #

#Computes the heat content in the specified area (Joules). Using all depth.
#cdfheatc  -f T-file [-mxloption option] [-mxlf MXL-file] ...'
#             [-zoom imin imax jmin jmax kmin kmax] [-full] [-o OUT-file]'
#             [-M MSK-file VAR-mask ] [-vvl ]

#outputs: heatc3d (Joules)

# mv output file
#if the previous command =! 0, save it otherwise return an error
if [[ $? -eq 0 ]]; then
   mv tmp_$FILEOUT $FILEOUT
else
   echo "error when running cdfheatc; exit"; echo "E R R O R in : ./mk_htc_glo_700_2000m.bash $@ (see ${JOBOUT_PATH}/mk_htc_glo_700_2000m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi 

#needed due to problem reading masked heatc3d variable:
ncatted -a valid_min,heatc3d,d,, -a valid_max,heatc3d,d,, $FILEOUT

#NORTH ATLANTIC
# Calculate heat content in Joules --> area of heat content for each layer
FILEOUT=HEATC_NA_ARC_700_2000m_${RUN_NAME}o_${FREQ}_${TAG}_heatc.nc

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
$CDFPATH/cdfheatc -f $FILET -M $TMASK tmask -o tmp_$FILEOUT #

#Computes the heat content in the specified area (Joules). Using all depth.
#cdfheatc  -f T-file [-mxloption option] [-mxlf MXL-file] ...'
#             [-zoom imin imax jmin jmax kmin kmax] [-full] [-o OUT-file]'
#             [-M MSK-file VAR-mask ] [-vvl ]

#outputs: heatc3d (Joules)

# mv output file
#if the previous command =! 0, save it otherwise return an error
if [[ $? -eq 0 ]]; then
   mv tmp_$FILEOUT $FILEOUT
else
   echo "error when running cdfheatc; exit"; echo "E R R O R in : ./mk_htc_glo_700_2000m.bash $@ (see ${JOBOUT_PATH}/mk_htc_glo_700_2000m_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1
fi 

#needed due to problem reading masked heatc3d variable:
ncatted -a valid_min,heatc3d,d,, -a valid_max,heatc3d,d,, $FILEOUT
