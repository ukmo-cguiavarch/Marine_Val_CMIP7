#!/bin/bash

if [ $# -eq 0 ] ; then echo 'need a [KEYWORD] (will be inserted inside the figure title and output name) and a list of id [RUNIDS RUNID ...] (definition of line style need to be done in RUNID.db)'; exit; fi

. ./param.bash
module load scitools

DATPATH=${SCRATCH}/MARINE_VAL

KEY=${1}
RUNIDS=${@:2}

# QNET
echo 'plot QNET  time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f GLO_hfds*.nc -var '(sohefldo_mean|hfds_mean)' -title "Net downward heat flux (W/m2) : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig01 
#-obs OBS/QNET_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig01.png -crop 1240x1040+0+0 tmp01.png

# SO SST
echo 'plot SO SST time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f SO_sst*.nc -var '(votemper_mean|thetao_mean|thetao_pot_mean)' -title "SO sst [K] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig02 -obs OBS/SO_sst_mean_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig02.png -crop 1240x1040+0+0 tmp02.png

# ACC
# Drake
echo 'plot ACC time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f *ACC_nemo_*${FREQ}*1.nc -var vtrp -sf -1 -title "ACC transport (Sv)" -dir ${DATPATH} -o "${KEY}_ACC" -obs OBS/ACC_obs.txt
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_ACC.png                   -crop 1240x1040+0+0 tmp02a.png

#GLO SST
echo 'plot GLO SST time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f GLO_sst*.nc -var '(votemper_mean|thetao_mean|thetao_pot_mean)' -title "GLO sst [K] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig03
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig03.png -crop 1240x1040+0+0 tmp03.png

#GLO SSS
echo 'plot GLO SSS time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f GLO_sss*.nc -var '(so_pra_mean)' -title "GLO sss [psu] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig03a
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig03a.png -crop 1240x1040+0+0 tmp03a.png


# Global mean temperature time series
echo 'plot Global mean temperature time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f Spatial_Means_full*.nc -var '(votemper_mean|thetao_mean|thetao_pot_mean)' -title "Temperature [K] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig04
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig04.png -crop 1240x1040+0+0 tmp04.png

# Upper 0-1000m global mean temperature time series
echo 'plot Global upper 0-1000m mean temperature time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f Spatial_Means_upper*.nc -var '(votemper_mean_upper|thetao_mean_upper|thetao_pot_mean_upper)' -title "Temperature (upper 0-1000m) [K] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig05
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig05.png -crop 1240x1040+0+0 tmp05.png

# lower 1000+m global mean temperature time series
echo 'plot Global lower 1000+m mean temperature time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f Spatial_Means_lower*.nc -var '(votemper_mean_lower|thetao_mean_lower|thetao_pot_mean_lower)' -title "Temperature (lower 1000+m) [K] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig06
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig06.png -crop 1240x1040+0+0 tmp06.png

# Global mean salinity time series
echo 'plot Global mean salinity time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f Spatial_Means_full*.nc -var '(so_pra_mean)' -title "Salinity [psu] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig07
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig07.png -crop 1240x1040+0+0 tmp07.png

# Upper 0-1000m global mean salinity time series
echo 'plot Global upper 0-1000m mean salinity time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f Spatial_Means_upper*.nc -var '(so_pra_mean_upper)' -title "Salinity (upper 0-1000m) [psu] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig08
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig08.png -crop 1240x1040+0+0 tmp08.png

# lower 1000+m global mean salinity time series
echo 'plot Global lower 1000+m mean temperature time series'
python ${SCRPATH}/plot_time_series_30y.py -noshow -runid $RUNIDS -f Spatial_Means_lower*.nc -var '(so_pra_mean_lower)' -title "Salinity (lower 1000+m) [psu] : ${KEY}" -dir ${DATPATH} -o ${KEY}_fig09
if [[ $? -ne 0 ]]; then exit 42; fi
convert ${KEY}_fig09.png -crop 1240x1040+0+0 tmp09.png



# trim figure
convert FIGURES/box_VALGLO.png -trim -bordercolor White -border 40 tmp10.png
convert legend.png             -trim -bordercolor White -border 20 tmp11.png
convert runidname.png          -trim -bordercolor White -border 20 tmp12.png

# compose the image
convert \( tmp01.png tmp03.png  tmp03a.png +append \) \
        \( tmp02.png tmp02a.png tmp10.png +append \) \
        \( tmp04.png tmp05.png  tmp06.png +append \) \
	 \( tmp07.png tmp08.png tmp09.png +append \) \
         tmp11.png tmp12.png -append -trim -bordercolor White -border 40 $KEY.png
#        \( tmp07.png tmp08.png tmp09.png +append \) \
# save plot
mv ${KEY}_*.png FIGURES/.
mv ${KEY}_*.txt FIGURES/.
mv tmp10.png FIGURES/${KEY}_legend.png
mv tmp11.png FIGURES/${KEY}_runidname.png

# clean
rm tmp??.png

# display
#display -resize 30% $KEY.png
