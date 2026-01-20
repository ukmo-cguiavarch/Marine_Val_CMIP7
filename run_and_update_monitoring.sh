#!/bin/bash

## Get data or update data
#runs="u-dv765"
runs="u-dv764 u-dv759 u-dv672 u-dv766 u-dv765"
# u-dv672 u-dv766 u-dv765 (and the orig's: u-du914, u-dv020, u-dv027,
# u-dv028, u-dv346; UKESM1.1 u-by230
DATAPATH=/data/scratch/andrea.rochner/MARINE_VAL

for suiteId in $runs ; do
  echo ${DATAPATH}/${suiteId}

  RUNPATH=${DATAPATH}/${suiteId}

  if [ ! -d ${RUNPATH} ]; then
    echo "Directory for ${suiteId} does not exist. Creating it."
    mkdir ${RUNPATH}
  else
    echo "Directory for ${suiteId} exists."
  fi


  ## Update data
  ./GET_DATA/submit_convert_marineval.batch "${suiteId}" ${RUNPATH}

  ## Run processing data
  # start point: either first file or most recent when updating
  processed=$(ls ${RUNPATH}/ACC_nemo* | wc -l)
  echo ${processed}

  if [ ${processed} == 0 ]; then # No file has been processed yet
    firstfile=$(ls ${RUNPATH}/nemo*1y*grid-T.nc | head -1)
    firstfile=${firstfile##*1y_}
    startyear="${firstfile%1201-*}" # select start
  else # files had been processed, find the latest one
    firstfile=$(ls ${RUNPATH}/ACC_nemo* | tail -1)
    firstfile=${firstfile##*1y_}
    startyear="${firstfile%1201.*}" # select start
  fi


  # Last year added
  lastfile=$(ls ${RUNPATH}/nemo*grid-T.nc | tail -1)
  lastfile=${lastfile##*1y_}
  endyear=${lastfile%1201-*}


  echo "Processing files from ${startyear} to ${endyear}"
  ./run_proc.bash -B UKESM/bathy_remove-000_match_wrap-eORCA1_MARINEVAL.nc UKESM/mesh_mask_remove-000_match_wrap-eORCA1_MARINEVAL.nc ${startyear} ${endyear} 1y ${suiteId}
done

## Plot
timestamp=$(date +%Y-%m-%d)
echo Plot produced on ${timestamp}
./run_plot_VALGLO_30y.bash UKESM_VALGLO_${timestamp} ${runs} u-by230
./run_plot_VALNA_30y.bash UKESM_VALNA_${timestamp} 1y ${runs} u-by230
./run_plot_VALSO_30y.bash UKESM_VALSO_${timestamp} 1y ${runs} u-by230

## Save and move figure to shared folder
mv /home/users/andrea.rochner/public_html/CMIP7_piControl/*.png /home/users/andrea.rochner/PROJECTS/CMIP7/MONITORING/Marine_Val_CMIP7/CMIP_piC_plots/.
cp UKESM_VAL*_${timestamp}.png /home/users/andrea.rochner/public_html/CMIP7_piControl/.
