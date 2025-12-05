#!/bin/bash
#SBATCH --mem=20G
#SBATCH --time=10
#SBATCH --ntasks=1

if [[ $# -ne 3 ]]; then echo 'mk_spatial_avg_lower.bash [RUNID (u-aa000)] [TAG (19991201_20061201_ANN)] [FREQ (1y)]'; exit 1 ; fi

RUNID=$1
TAG=$2
FREQ=$3
GRID='T'
PROC='runSpAvgLower'
GENERATED_TMASKS=($(jq -r ".${PROC}[]" "${SCRPATH}/tmasks_generated.json"))
# name
RUN_NAME=${RUNID#*-}

# download data if needed
#${SCRPATH}/get_data.bash $RUNID $FREQ $TAG grid-${GRID}

# check presence of input file
FILE=`ls [nu]*${RUN_NAME}o_${FREQ}_${TAG}*_grid[-_]${GRID}.nc`
if [ ! -f $FILE ] ; then echo "$FILE is missing; exit"; echo "E R R O R in : ./mk_spatial_avg_lower.bash $@ (see SLURM/${RUNID}/mk_spatial_avg_lower_${FREQ}_${TAG}.out)" >> ${EXEPATH}/ERROR.txt ; exit 1 ; fi

# Extract tmask filename
PATTERN="GLO"
for GEN_TMASK in "${GENERATED_TMASKS[@]}"; do
   if [[ "$GEN_TMASK" == *"$PATTERN"* ]]; then
      PARAMS=$(jq -c --arg tmask "$GEN_TMASK" '.[$tmask]' ${SCRPATH}/tmasks_all_params.json)
      TMASK=$(echo "$PARAMS" | jq -r '.o')
   fi
done
echo TMASK: $TMASK

#Temperature
# calculate globally averaged value
echo "mk_spatial_avg.bash : making global average"
# calculate averaged value 0-1000m
FILEOUT=GlobalMean_lower_thetao_pot_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
$SCRPATH/reduce_fields.py -i $FILE -v thetao_pot -c longitude latitude depth -A mean -G measures self -g cell_area cell_thickness -o $FILEOUT -m $TMASK 

# Gather all the spatial means into one file

ncrename -v thetao_pot,thetao_pot_mean_lower GlobalMean_lower_thetao_pot_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
ncks GlobalMean_lower_thetao_pot_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc -v thetao_pot_mean_lower \
     -A Spatial_Means_lower_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
rm GlobalMean_lower_thetao_pot_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc

#Salinity
# calculate globally averaged value
echo "mk_spatial_avg.bash : making global average"
# calculate averaged value 0-1000m
FILEOUT=GlobalMean_lower_so_pra_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
$SCRPATH/reduce_fields.py -i $FILE -v so_pra -c longitude latitude depth -A mean -G measures self -g cell_area cell_thickness -o $FILEOUT -m $TMASK 

# Gather all the spatial means into one file

ncrename -v so_pra,so_pra_mean_lower GlobalMean_lower_so_pra_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
ncks GlobalMean_lower_so_pra_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc -v so_pra_mean_lower \
     -A Spatial_Means_lower_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc
rm GlobalMean_lower_so_pra_nemo_${RUN_NAME}o_${FREQ}_${TAG}_grid-${GRID}.nc


