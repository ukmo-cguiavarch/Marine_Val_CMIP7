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
# NA subpolar gyre max strength
echo 'plot NA subpolar gyre strength time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f *BSF_NA*${FREQ}*psi_NA.nc -var '(min_sobarstf|sobarstf)' -title "SPG max strength (Sv)" -dir ${DATPATH} -o ${KEY}_BSF -sf -0.000001 #-obs OBS/SUBP_PSI_obs.txt
#-sf is scale factor i.e. m3/s to Sv
#using min and negative scale factor because streamf is negative in subpolar gyre
if [[ $? -ne 0 ]]; then exit 42; fi

read -r -a RUNID_LIST <<< "$RUNIDS"

HEATC_FILES=()
SALTC_FILES=()
for RUNID in "${RUNID_LIST[@]}"; do
	RUN_NAME=${RUNID#*-}
	HEATC_FILES+=("HEATC_NA_${RUN_NAME}o_*${FREQ}*heatc.nc")
	SALTC_FILES+=("SALTC_NA_${RUN_NAME}o_*${FREQ}*saltc.nc")
done

echo '  '

# Heat content of subpolar gyre
echo 'plot heat content of subpolar gyre time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid "${RUNID_LIST[@]}" -f "${HEATC_FILES[@]}" -var heatc3d -title "Heat content in SPG (*10^23 J)" -dir ${DATPATH} -o ${KEY}_HTC #-obs OBS/HTC_subp_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# Salt content of subpolar gyre
echo 'plot salt content of subpolar gyre time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid "${RUNID_LIST[@]}" -f "${SALTC_FILES[@]}" -var saltc3d -title "Salt content in SPG" -dir ${DATPATH} -o ${KEY}_STC #-obs OBS/STC_subp_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# AMOC at 26.5N (maximum in z)
echo 'plot AMOC time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f *AMOC*${FREQ}*moc.nc -var Total_max_amoc_rapid -title "AMOC @26.5N (Sv)" -dir ${DATPATH} -o ${KEY}_AMOC -obs OBS/AMOC_max_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean MXL depth in Lab Sea in March (averaged in small region)
echo 'plot mean MXL depth in Lab Sea time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f *LAB_MXL*1m*0301*T*003*.nc -var '(mean_somxl030|somxl030)' -title "Mean MXL in Lab Sea in March (m)" -dir ${DATPATH} -o ${KEY}_MXL_LAB_MEAN -sf -1 -obs OBS/MXL_lab_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean MXL depth in GIN Sea in March (averaged in small region)
echo 'plot mean MXL depth in GIN Sea time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f *GIN_MXL*1m*0301*T*003*.nc -var '(mean_somxl030|somxl030)' -title "Mean MXL in GIN Sea in March (m)" -dir ${DATPATH} -o ${KEY}_MXL_GIN_MEAN -sf -1 #-obs OBS/MXL_GIN_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean SSS in Labrador Sea
echo 'plot mean SSS in Labrador Sea time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f SSSav_LabSea_*${FREQ}*T.nc -var '(mean_so_pra|so_pra)' -title "Mean SSS in Labrador Sea (PSU)" -dir ${DATPATH} -o ${KEY}_SSS_LabSea -obs OBS/SSS_LabSea_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean SSS in GIN Sea
echo 'plot mean SSS in GIN Sea time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f SSSav_GINSea_*${FREQ}*T.nc -var '(mean_so_pra|so_pra)' -title "Mean SSS in GIN (PSU)" -dir ${DATPATH} -o ${KEY}_SSS_GIN #-obs OBS/SSS_GINSea_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean SST Labrador Sea
echo 'plot mean SST in Labrador Sea sea time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f SSTav_LabSea_*${FREQ}*T.nc -var '(mean_thetao_pot|thetao_pot)' -title "Mean SST in Labrador Sea (degC)" -dir ${DATPATH} -o ${KEY}_SST_LabSea #-obs OBS/SST_LabSea_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# mean SST GIN Seas
echo 'plot mean SST in GIN sea time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f SSTav_GINSea_*${FREQ}*T.nc -var '(mean_thetao_pot|thetao_pot)' -title "Mean SST in GIN (degC)" -dir ${DATPATH} -o ${KEY}_SST_GIN #-obs OBS/SST_GINSea_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# ARC SIE
echo 'plot SIE time series - March'
python ${SCRPATH}/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f SIE*si3*0301.nc -var NExnsidc -sf 0.001 -title "SIE Arctic m03 [1e6 km2]" -dir ${DATPATH} -o ${KEY}_SIE_03 -obs OBS/ARC_sie03_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
/data/users/catherine.guiavarch/MARINE_VAL//u-dv341_NExnsidc.nc

echo 'plot SIE time series - September'
python ${SCRPATH}/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f SIE*si3*0901.nc -var NExnsidc -sf 0.001 -title "SIE Arctic m09 [1e6 km2]" -dir ${DATPATH} -o ${KEY}_SIE_09 -obs OBS/ARC_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi


# ARC SIE
echo 'plot SIE time series'
python ${SCRPATH}/plot_time_series.py -noshow -runid $RUNIDS -varf 'SIE*si3**0301.nc' 'SIE*si3*0901.nc' -var NExnsidc NExnsidc -sf 0.001 -title "SIE Arctic m03 [1e6 km2] : ${KEY}" "SIE Arctic m09 [1e6 km2] : ${KEY}" -dir ${DATPATH} -o ${KEY}_SIE -obs OBS/ARC_sie03_obs.txt OBS/ARC_sie09_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_SIE.png -crop 1240x1040+0+0 tmp08.png


# mean SST off Newfoundland
echo 'plot mean SST off Newfoundland time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f SSTav_Newfound_*${FREQ}*T.nc -var '(mean_thetao_pot|thetao_pot)' -title "Mean SST off Newfoundland (degC)" -dir ${DATPATH} -o ${KEY}_SST_newf -obs OBS/SST_newf_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# GS separation latitude
echo 'plot GS separation latitude time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f *${FREQ}*NA_crop_T.nc -var GS_sep_lat -title "GS separation latitude @72degW" -dir ${DATPATH} -o ${KEY}_GSL -obs OBS/GS_sep_lat_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# NAC latitude
echo 'plot NAC latitude time series'
python SCRIPT/plot_time_series_1850_30y.py -noshow -runid $RUNIDS -f *${FREQ}*NA_crop_T.nc -var NAC_lat -title "NAC latitude @41degW" -dir ${DATPATH} -o ${KEY}_NAC -obs OBS/NAC_lat_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi

# crop figure (rm legend)

#VALNA
convert ${KEY}_BSF.png                     -crop 1240x1040+0+0 ${KEY}_BSF.png
convert ${KEY}_HTC.png                     -crop 1240x1040+0+0 ${KEY}_HTC.png
convert ${KEY}_STC.png                     -crop 1240x1040+0+0 ${KEY}_STC.png
convert ${KEY}_AMOC.png                    -crop 1240x1040+0+0 ${KEY}_AMOC.png
convert ${KEY}_MXL_LAB_MEAN.png            -crop 1240x1040+0+0 ${KEY}_MXL_LAB_MEAN.png
convert ${KEY}_MXL_GIN_MEAN.png            -crop 1240x1040+0+0 ${KEY}_MXL_GIN_MEAN.png
convert ${KEY}_SSS_LabSea.png              -crop 1240x1040+0+0 ${KEY}_SSS_LabSea.png
convert ${KEY}_SSS_GIN.png                 -crop 1240x1040+0+0 ${KEY}_SSS_GIN.png
convert ${KEY}_SST_LabSea.png              -crop 1240x1040+0+0 ${KEY}_SST_LabSea.png
convert ${KEY}_SST_GIN.png                 -crop 1240x1040+0+0 ${KEY}_SST_GIN.png
convert ${KEY}_SST_newf.png                -crop 1240x1040+0+0 ${KEY}_SST_newf.png
convert ${KEY}_GSL.png                     -crop 1240x1040+0+0 ${KEY}_GSL.png 
convert ${KEY}_NAC.png                     -crop 1240x1040+0+0 ${KEY}_NAC.png 
convert ${KEY}_SIE_03.png                  -crop 1240x1040+0+0 ${KEY}_SIE_03.png
convert ${KEY}_SIE_09.png                  -crop 1240x1040+0+0 ${KEY}_SIE_09.png

convert FIGURES/box_NA.png  -trim -bordercolor White -border 2 tmp00.png
# trim figure (remove white area)
convert legend.png      -trim    -bordercolor White -border 20 tmp-2.png
convert runidname.png   -trim    -bordercolor White -border 20 tmp-1.png

convert \( ${KEY}_AMOC.png  ${KEY}_MXL_LAB_MEAN.png ${KEY}_MXL_GIN_MEAN.png +append \) \
        \( ${KEY}_SST_newf.png ${KEY}_SST_LabSea.png ${KEY}_SST_GIN.png +append \) \
        \( ${KEY}_SIE_03.png ${KEY}_SSS_LabSea.png ${KEY}_SSS_GIN.png +append \) \
        tmp-2.png tmp-1.png -append -trim -bordercolor White -border 50 ${KEY}_1.png        

convert \( ${KEY}_SIE_09.png ${KEY}_GSL.png  ${KEY}_NAC.png +append \) \
        \( ${KEY}_BSF.png ${KEY}_HTC.png ${KEY}_STC.png +append \) \
           tmp-2.png tmp-1.png -append -trim -bordercolor White -border 50 ${KEY}_2.png

# save figure
#mv ${KEY}_*.png FIGURES/.
#mv ${KEY}_*.txt FIGURES/.
#mv tmp-2.png FIGURES/${KEY}_legend.png
#mv tmp-1.png FIGURES/${KEY}_runidname.png

# clean
#rm tmp??.png
#rm tmp??b.png
#rm runidname.png
#rm legend.png

#display
#display -resize 30% $KEY_1.png
#display -resize 30% $KEY_2.png

