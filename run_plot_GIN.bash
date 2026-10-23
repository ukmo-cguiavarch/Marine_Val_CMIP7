#!/bin/bash -l
#
# This script currently only plots the minimal set of VALNA metrics, excluding:
#     1. Meridional heat transport (MHT) which metric only works if relevant diagnostic in model output. 
#     2. Overflow metrics (OVF) for which the calculation needs to be corrected.

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the figure title and output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ./param.bash

KEY=${1}
FREQ=${2}
RUNIDS=${@:3}

echo '  '

# 1) timeseries of AMOC at 26.5N (maximum in z)
echo 'plot max(AMOC_z) at 26.5N time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f rapid_z/*moc_z_RAPID*${FREQ}*.nc -var Total_max_amoc_rapid -title "AMOC @26.5N (Sv)" -dir ${DATPATH} -o ${KEY}_AMOC -obs OBS/AMOC_max_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# 2) AMOC profiles (in z space) at 26.5N
echo 'plot RAPID mocz'
python SCRIPT/plot_rapid_mocz.py -runid $RUNIDS -dir ${DATPATH} -o ${KEY}_rapid_mocz -st ${FREQ} -p moc_z_RAPID -obs ${OBS_RPD_PRF}

# mean MXL depth in Lab Sea in March (averaged in small region)
echo 'plot mean MXL depth in Lab Sea time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *LAB_MXL*1m*0301*T*003*.nc -var '(mean_somxl030|somxl030)' -title "Mean MXL in Lab Sea in March (m)" -dir ${DATPATH} -o ${KEY}_MXL_LAB_MEAN -sf -1 -obs OBS/MXL_lab_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean MXL depth in GIN Sea in March (averaged in small region)
echo 'plot mean MXL depth in GIN Sea time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *GIN_MXL*1m*0301*T*003*.nc -var '(mean_somxl030|somxl030)' -title "Mean MXL in GIN Sea in March (m)" -dir ${DATPATH} -o ${KEY}_MXL_GIN_MEAN -sf -1 #-obs OBS/MXL_GIN_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean SSS in Labrador Sea
echo 'plot mean SSS in Labrador Sea time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f SSSav_LabSea_*${FREQ}*T.nc -var '(mean_so_pra|so_pra)' -title "Mean SSS in Labrador Sea (PSU)" -dir ${DATPATH} -o ${KEY}_SSS_LabSea -obs OBS/SSS_LabSea_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean SSS in GIN Sea
echo 'plot mean SSS in GIN Sea time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f SSSav_GINSea_*${FREQ}*T.nc -var '(mean_so_pra|so_pra)' -title "Mean SSS in GIN (PSU)" -dir ${DATPATH} -o ${KEY}_SSS_GIN #-obs OBS/SSS_GINSea_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean SST GIN Seas
echo 'plot mean SST in GIN sea time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f SSTav_GIN_*${FREQ}*T.nc -var '(mean_thetao_pot|thetao_pot)' -title "Mean SST in GIN (degC)" -dir ${DATPATH} -o ${KEY}_SST_GIN #-obs OBS/SST_newf_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ARC SIE
echo 'plot SIE time series'
python ${SCRPATH}/plot_time_series.py -noshow -runid $RUNIDS -varf '*sie*0301.nc' '*sie*0901.nc' -var NExnsidc NExnsidc -sf 0.001 -title "SIE Arctic m03 [1e6 km2] : ${KEY}" "SIE Arctic m09 [1e6 km2] : ${KEY}" -dir ${DATPATH} -o ${KEY}_SIE -obs OBS/ARC_sie03_obs.txt OBS/ARC_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_SIE.png -crop 1240x1040+0+0 tmp08.png

# Heat content of subpolar gyre
echo 'plot heat content of subpolar gyre time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *HEATC_NA_*${FREQ}*heatc.nc -var heatc3d -title "Heat content in SPG (*10^23 J)" -dir ${DATPATH} -o ${KEY}_HTC -obs OBS/HTC_subp_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi


# Salt content of subpolar gyre
echo 'plot salt content of subpolar gyre time series'
python SCRIPT/plot_time_series.py -noshow -runid $RUNIDS -f *SALTC_NA_*${FREQ}*saltc.nc -var saltc3d -title "Salt content in SPG" -dir ${DATPATH} -o ${KEY}_STC -obs OBS/STC_subp_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi


# crop timeseries plots (rm legend)
convert ${KEY}_AMOC.png            -crop 1240x1040+0+0 tmp04.png
convert ${KEY}_MXL_LAB_MEAN.png    -crop 1240x1040+0+0 tmp05.png 
convert ${KEY}_MXL_GIN_MEAN.png    -crop 1240x1040+0+0 tmp05b.png
convert ${KEY}_SSS_LabSea.png      -crop 1240x1040+0+0 tmp06.png #
convert ${KEY}_SSS_GIN.png         -crop 1240x1040+0+0 tmp06b.png #
convert ${KEY}_SST_GIN.png        -crop 1240x1040+0+0 tmp07.png #
convert ${KEY}_STC.png        -crop 1240x1040+0+0 tmp09.png #
convert ${KEY}_HTC.png        -crop 1240x1040+0+0 tmp10.png #
ln -s ${KEY}_rapid_mocz.png tmp14.png


convert FIGURES/box_NA.png  -trim -bordercolor White -border 2 tmp00.png
# trim figure (remove white area)
convert legend.png      -trim    -bordercolor White -border 20 tmp-2.png
convert runidname.png   -trim    -bordercolor White -border 20 tmp-1.png

#convert \( tmp04.png tmp05.png tmp05b.png +append \) \
#        \( tmp07.png tmp06.png tmp06b.png +append \) \
#        \( tmp08.png tmp10.png tmp09.png +append \) \
#           tmp-2.png tmp-1.png -append -trim -bordercolor White -border 50 ${KEY}.png


convert \( tmp04.png tmp05.png tmp05b.png +append \) \
        \( tmp07.png tmp06.png tmp06b.png +append \) \
        \( tmp08.png tmp10.png tmp09.png +append \) \
           tmp-2.png tmp-1.png -append -trim -bordercolor White -border 50 ${KEY}.png



# save figure
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp-2.png FIGURES/${KEY}_legend.png
mv tmp-1.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png
rm tmp??b.png
rm runidname.png
rm legend.png

#display
display -resize 30% $KEY.png

