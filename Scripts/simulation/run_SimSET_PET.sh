#!/usr/bin/env bash
# SIMSET: Adaptation of Pablo's source to SimSET 2.9 by Berta Marti
#Last Modified by: Jesus Silva 
# 07/11/2012

#unset variables
unset SIM_NUM EMISS_DATA ATTEN_DATA PHOTONS SAMPLING INTERFILE DIR_SIMSET LENGTH SIM_TYPE
unset scatter_param min_s max_s num_z_bins min_z max_z num_aa_bins num_td_bins min_td max_td min_energy_window positron_range no_colinearidad
unset radio_scanner corte_central

if [ -z "$1" ]; 
then
    echo "usage: $0 "
    echo "there is not env_params.sh in command line"
    exit 1
fi

#set variables
source $1

echo $EMISS_HDR
echo $ATTEN_HDR

SIM_NUM=`basename $1 .sh`
######################## Detecting input format ########################### 
HDR=0 # Analyze input
HV=0 # Interfile input

if [ $EMISS_HDR != ${EMISS_HDR/.hdr/.img} -a $ATTEN_HDR != ${ATTEN_HDR/.hdr/.img} ]; then 
    EMISS_DATA="${EMISS_HDR/.hdr/.img}"
    ATTEN_DATA="${ATTEN_HDR/.hdr/.img}"
    HDR=1
fi

if [ $EMISS_HDR != ${EMISS_HDR/.hv/.v} -a $ATTEN_HDR != ${ATTEN_HDR/.hv/.v} ]; then 
    EMISS_DATA="${EMISS_HDR/.hv/.v}"
    ATTEN_DATA="${ATTEN_HDR/.hv/.v}"
    HV=1
fi

if [ $HDR -eq 1 -a $HV -eq 1 ]; then 
        echo " Maybe 'hv' or 'hdr' inside of input header name..."
	   exit 1
fi

if [ $HDR -eq 0 -a $HV -eq 0 ]; then 
        echo " Can't understand input format (only *.hdr or *.hv)"
	   exit 1
fi

########################  Set directories ###################################

cd ..
cd ..
DIR_LOCAL=$PWD
cd $DIR_SCRIPTS
#DIR_SCRIPTS=$DIR_LOCAL/Scripts
DIR_INPUT=$dataPath
echo "dataPath RunSIMSET is $DIR_INPUT"
DIR_OUTPUT=$DIR_PROJECTIONS/$SIM_NUM$N
echo "OUTPUT: "$DIR_OUTPUT

if [ ! -r "${EMISS_HDR}" -o  ! -r "${EMISS_DATA}" -o ! -r "${ATTEN_HDR}" -o ! -r "${ATTEN_DATA}" ]; then
     echo Attenuation or Emission image could not open
	exit 1
fi

echo "dir scripts:"$DIR_SCRIPTS
echo "Data folder:"$DIR_INPUT
echo "Output folder:"$DIR_OUTPUT

################## Testing Environment Variables ####################################################3

SAMPLING=$S

if [ ${#SAMPLING} -eq 0 ]; then
    echo "usage: $0 "
    echo environment variable SAMPLING has to be defined
    echo "SAMPLING=0 Importance Sampling is off"
    echo "SAMPLING=1 Importance Sampling is on"
    exit 1
fi

if [ $SAMPLING -eq 1 ]; then
	A="" # SAMPLING=1 Importance Sampling is on. Only rec.weight is deleted.
	B="#" #Only input sampling is read
	if [ ! -r ${DIR_OUTPUT}/sampling_rec ]; then
     echo sampling_rec should be generated in order to do importance sampling
	echo use SAMPLING=0 to generate it!
	exit 1
	fi
	rm ${DIR_OUTPUT}/rec.weight*
fi

if [ $SAMPLING -eq 0 ]; then  # If Imp Samp is off then all files are deleted
	A="#" # SAMPLING=0 Importance Sampling is off
	B="" # Only output sampling is saved
	rm -fr ${DIR_OUTPUT}
fi

if [ ${#scatter_param} -eq 0 -o ${#min_s} -eq 0 -o ${#max_s} -eq 0 ]; then
    echo "usage: $0 "
    echo environment variable SCATTER BINS has to be defined
    exit 1
fi

if [ ${#noisefree} -eq 0 ]; then
    echo "usage: $0 "
    echo environment variable NOISEFREE has to be defined
    exit 1
fi


if [ ${#min_z} -eq 0 -o ${#max_z} -eq 0 -o ${#num_aa_bins} -eq 0 -o ${#num_z_bins} -eq 0 -o ${#num_td_bins} -eq 0 -o ${#min_td} -eq 0 -o ${#max_td} -eq 0 -o ${#min_energy_window} -eq 0 ]; then
    echo "usage: $0 "
    echo environment variable BINNING PARAMS has to be defined
    exit 1
fi

if [ $scatter_param -eq 3 -a $min_s -eq 0 -a $max_s -eq 3 ]; then
	echo ""
	else if [ $scatter_param -eq 1 -a $min_s -eq 0 -a $max_s -eq 9 ]; then
		echo ""
else
	echo incorrect scatter bins values, only 3,0,3 or 1,0,9
	exit 1
	fi
fi

if [ ${#PHOTONS} -eq 0 ]; then
    echo "usage: $0 "
    echo environment variable PHOTONS has to be defined
    echo Contains the number of positrons to run
    exit 1
fi

if [ ${#LENGTH} -eq 0 ]; then
    echo "usage: $0 "
    echo environment variable LENGTH has to be defined
    echo Length of scan in seconds
    exit 1
fi

if [ ${#EMISS_DATA} -eq 0  ]; then
    echo "usage: $0 "
    echo environment variable EMISS_DATA has to be defined
    echo Emission Data Base Filename
    exit 1
fi


if [ ${#ATTEN_DATA} -eq 0  ]; then
    echo "usage: $0 "
    echo environment variable ATTEN_DATA has to be defined
    echo Attenuation Data Base Filename
    exit 1
fi

if [ ${#positron_range} -eq 0  ]; then
    echo "usage: $0 "
    echo environment variable positron_range has to be defined
    echo Values - true or false -
    exit 1
fi


if [ ${#no_colinearidad} -eq 0  ]; then
    echo "usage: $0 "
    echo environment variable no_colinearidad has to be defined
    echo Values - true or false -
    exit 1
fi

if [ "${INTERFILE}" == 1 ]; 
	then 
		if [ ! -r simulation/INTERFILE.sh ]; # If doesnt exit...
			then
			echo "INTERFILE.sh have to be installed!!!"; 
			exit 1;
		fi
else
	if [ ! -z ${INTERFILE} ] # If length of string is not zero
		then
		echo "INTERFILE must to be only 1 ";
		exit 1;
	else
	INTERFILE=0; # nothing
	fi; 
fi;

if [ "${ANALYZE}" == 1 ]; 
	then 
		if [ ! -r simulation/ANALYZE.sh ]; # If doesnt exit...
			then
			echo "ANALYZE.sh have to be installed!!!"; 
			exit 1;
		fi
else
	if [ ! -z ${ANALYZE} ] # If length of string is not zero
		then
		echo "ANALYZE must to be only 1 ";
		exit 1;
	else
	ANALYZE=0; # nothing
	fi; 
fi;

#exit on error

########### Building object for phg.rec ##############################################################3

if [ $HDR -eq 1 ]; then
	nslices=`printf_header_hdr "${EMISS_HDR}" |grep "Pixels en direccion Z" | awk '{ print($6) }'`
	ybins=`printf_header_hdr "${EMISS_HDR}" |grep "Pixels en direccion Y" | awk '{ print($6) }'`
	xbins=`printf_header_hdr "${EMISS_HDR}" |grep "Pixels en direccion X" | awk '{ print($6) }'`
	tpix=`printf_header_hdr "${EMISS_HDR}" |grep "Tamano pixel en Y" | awk '{ print($6) }'`
	tcorte=`printf_header_hdr "${EMISS_HDR}" |grep "Tamano pixel en Z" | awk '{ print($6) }'`
	
	nslices_a=`printf_header_hdr "${ATTEN_HDR}" |grep "Pixels en direccion Z" | awk '{ print($6) }'`
	ybins_a=`printf_header_hdr "${ATTEN_HDR}" |grep "Pixels en direccion Y" | awk '{ print($6) }'`
	xbins_a=`printf_header_hdr "${ATTEN_HDR}" |grep "Pixels en direccion X" | awk '{ print($6) }'`
	tpix_a=`printf_header_hdr "${ATTEN_HDR}" |grep "Tamano pixel en Y" | awk '{ print($6) }'`
	tcorte_a=`printf_header_hdr "${ATTEN_HDR}" |grep "Tamano pixel en Z" | awk '{ print($6) }'`
fi

#Different line is comented depending of which variable (C or D) is equal to "#"
C=""    #Activity table is default
D="#"
if [ $ACTTABLE -eq 1 ]; then  # If Activity table is user-defined
        C="#"
        D=""

	phantom_size=`du -B 1 ${EMISS_IMG} |awk '{ print $1 }'`
	echo "Phantom size is $phantom_size bytes"
	phantom_counts=`ncontes ${phantom_size} "${EMISS_IMG}" 1b`
	echo "Phantom has $phantom_counts counts"
	
	echo "${ATTEN_HDR}"
	echo $nslices
	echo $nslices_a
	echo $xbins
	echo $xbins_a
	echo $tpix
	echo $tpix_a
	echo $tcorte
	echo $tcorte_a
	
	phantom_dose=`echo ${phantom_counts}*${tpix_a}*${tpix_a}*${tcorte_a}/1000 | bc -l`
	echo "Total dose on the phantom is $phantom_dose"
	act_factor=`echo ${DOSE}*1000/${phantom_dose} | bc -l`
	echo "Calculated factor to change activity table is $act_factor"
	mkdir -p $DIR_INPUT/user_act_tables
    change_act_table $DIR_SIMSET/phg.data/phg_act_table $act_factor > $DIR_INPUT/user_act_tables/${patient}$N
fi


if [ $HV -eq 1 ]; then
	echo " Interfile inputs is not avaliable yet...SORRY! "
	exit 1
fi


# testing if att and emiss have the same dims
if [ ${nslices} -eq ${nslices_a} -a ${xbins} -eq ${xbins_a} -a ${ybins} -eq ${ybins_a} ]; then
	echo ""
	echo "Emission and Attenuation image: OK"
else
	echo "usage: $0 "
	echo Attenuation and Emission should be in the same matrix dimensions
	exit 1
fi


xMin=`echo -1*${xbins}*${tpix}/20 | bc -l`  	# cm
xMax=`echo ${xbins}*${tpix}/20 | bc -l`  	# cm
yMin=`echo -1*${ybins}*${tpix}/20 | bc -l`  	# cm
yMax=`echo ${xbins}*${tpix}/20 | bc -l`  	# cm

if [ ${#corte_central} -eq 0 ]; then
corte_central=0
fi

if [ ${corte_central} -gt ${nslices} ]; then
	echo "corte_central is out of object range"
	exit 1
fi

zMin=0
zMax=`echo ${nslices}*${tcorte}/10 | bc -l`  # cm
desplaz=`echo ${tcorte}*${corte_central}/10 | bc -l`  # cm
zMin=`echo ${zMin}-${desplaz} | bc -l`  # cm
zMax=`echo ${zMax}-${desplaz} | bc -l`  # cm

zMin_target=$zMin 
zMax_target=$zMax

# testing x,y,z coordinates and previous params
if [ ${#nslices} -eq 0 -o ${#xbins} -eq 0 -o ${#ybins} -eq 0 -o ${#xMin} -eq 0 -o ${#xMax} -eq 0 -o ${#yMin} -eq 0 -o ${#yMax} -eq 0 -o ${#zMin} -eq 0 -o ${#zMax} -eq 0 -o ${#zMin_target} -eq 0 -o ${#zMax_target} -eq 0 -o ${#radio_scanner} -eq 0 -o ${#tpix} -eq 0 -o ${#tcorte} -eq 0 ]; then
    echo "usage: $0 "
    echo environment variable OBJECT PARAMS have to be defined, error in hdr
    exit 1
fi
echo "Input Parameters in headers: OK "

cat ${DIR_SIMU}/template_phg_params.rec > ${DIR_SIMU}/template_phg.rec
make_phg_simset $nslices $xbins $ybins $xMin $xMax $yMin $yMax $zMin $zMax $zMin_target $zMax_target $radio_scanner >> ${DIR_SIMU}/template_phg.rec
cat ${DIR_SIMU}/template_phg_dirs.rec >> ${DIR_SIMU}/template_phg.rec

set -e

mkdir -p ${DIR_OUTPUT}

cd ${DIR_INPUT}
# Copying into DIR_OUTPUT what SimSET needs to run
cp ${DIR_SIMU}/template_bin.rec ${DIR_OUTPUT}
cp ${DIR_SIMU}/template_phg.rec ${DIR_OUTPUT}
cp ${EMISS_DATA} ${DIR_OUTPUT}/act${SIM_NUM}.dat
cp ${ATTEN_DATA} ${DIR_OUTPUT}/att${SIM_NUM}.dat
sed -e s%OUTPUT_DIRECTORY%"${DIR_OUTPUT}"% \
  < ${DETECTOR} > ${DIR_OUTPUT}/det.rec

ring_param_file=${DIR_SCRIPTS}/templates/det_files/${scanner}.ringparams
block_param_file=${DIR_SCRIPTS}/templates/det_files/${scanner}.blockparams
listmode_params=${DIR_SCRIPTS}/templates/listmode.params



if [ -e $ring_param_file ];then
    sed -e s%OUTPUT_DIRECTORY%"${DIR_OUTPUT}"% \
      < ${ring_param_file} > ${DIR_OUTPUT}/${scanner}.ringparams
fi

if [ -e $block_param_file ];then
    sed -e s%OUTPUT_DIRECTORY%"${DIR_OUTPUT}"% \
      < ${block_param_file} > ${DIR_OUTPUT}/${scanner}.blockparams
fi

if [ -e $listmode_params ];then
    sed -e s%NUM_Z_BINS%"${num_z_bins}"% \
        -e s%MIN_Z%"${min_z}"% \
        -e s%MAX_Z%"${max_z}"% \
        -e s%NUM_AA_BINS%"${num_aa_bins}"% \
        -e s%NUM_TD_BINS%"${num_td_bins}"% \
        -e s%MIN_TD%"${min_td}"% \
        -e s%MAX_TD%"${max_td}"% \
        -e s%MIN_ENERGY_WINDOW%"${min_energy_window}"% \
      < ${listmode_params} > ${DIR_OUTPUT}/listmode.params
fi


cd ${DIR_OUTPUT}
echo "ACTTABLE value is " $ACTTABLE

seed_nano=`date "+%N"`
echo "random_seed is " $seed_nano

# Building phg.rec and bin.rec from templates
sed -e s%SIMSET_DIRECTORY%"${DIR_SIMSET}"% \
    -e s%INPUT_DIRECTORY%"${DIR_INPUT}"% \
    -e s%OUTPUT_DIRECTORY%"${DIR_OUTPUT}"% \
    -e s%BIN.REC%bin"${SIM_NUM}".rec% \
    -e s%PHOTONS%"${myPhotons}"% \
    -e s%LENGTH%"${OriginalL}"% \
    -e s%S_SAMPLINGON%"${A}"% \
    -e s%S_SAMPLINGOFF%"${B}"% \
    -e s%ACTTABLEOFF%"${C}"% \
    -e s%ACTTABLEON%"${D}"% \
    -e s%POSITRON_RANGE%"${positron_range}"% \
    -e s%NO_COLINEARIDAD%"${no_colinearidad}"% \
    -e s%SEED_INPUT%"${seed_nano}"% \
    -e s%CUSTOMIZED_ACT_TABLE%"${patient}$N"% \
  < template_phg.rec > phg"${SIM_NUM}".rec


sed -e s%SIMSET_DIRECTORY%"${DIR_SIMSET}"% \
    -e s%INPUT_DIRECTORY%"${DIR_INPUT}"% \
    -e s%OUTPUT_DIRECTORY%"${DIR_OUTPUT}"% \
    -e s%SCATTER_PARAM%"${scatter_param}"% \
    -e s%MIN_S%"${min_s}"% \
    -e s%MAX_S%"${max_s}"% \
    -e s%NUM_Z_BINS%"${num_z_bins}"% \
    -e s%MIN_Z%"${min_z}"% \
    -e s%MAX_Z%"${max_z}"% \
    -e s%NUM_AA_BINS%"${num_aa_bins}"% \
    -e s%NUM_TD_BINS%"${num_td_bins}"% \
    -e s%MIN_TD%"${min_td}"% \
    -e s%MAX_TD%"${max_td}"% \
    -e s%MIN_ENERGY_WINDOW%"${min_energy_window}"% \
    -e s%ACTIVATE_LM%"${listmode}"% \
  < template_bin.rec > bin"${SIM_NUM}".rec
    
rm -rf template_bin.rec
rm -rf template_phg.rec

echo "PHG and BIN parameter files : OK"
##### Building index.dat to input in makeindexfile #######
############## RUN SIMSET ##########

echo phg${SIM_NUM}.rec > index${SIM_NUM}.dat
echo y >> index${SIM_NUM}.dat
echo y >> index${SIM_NUM}.dat
echo 0 >> index${SIM_NUM}.dat
echo y >> index${SIM_NUM}.dat
echo act${SIM_NUM}.dat >> index${SIM_NUM}.dat
echo 0 >> index${SIM_NUM}.dat
echo 0 >> index${SIM_NUM}.dat
echo 1 >> index${SIM_NUM}.dat
echo n >> index${SIM_NUM}.dat
echo n >> index${SIM_NUM}.dat
echo y >> index${SIM_NUM}.dat
echo y >> index${SIM_NUM}.dat
echo 0 >> index${SIM_NUM}.dat
echo y >> index${SIM_NUM}.dat
echo att${SIM_NUM}.dat >> index${SIM_NUM}.dat
echo 0 >> index${SIM_NUM}.dat
echo 0 >> index${SIM_NUM}.dat
echo 1 >> index${SIM_NUM}.dat
echo n >> index${SIM_NUM}.dat
echo n >> index${SIM_NUM}.dat

${DIR_SIMSET}/bin/makeindexfile < index${SIM_NUM}.dat >& ${DIR_OUTPUT}/makeindex.log

echo ""
echo "--------------------"
echo "Simulation Starts:" 
date 

$DIR_SIMSET/bin/phg phg${SIM_NUM}.rec > ${DIR_OUTPUT}/log

# Simulation finished

##################### POST SIMULATION ##########################

########## Generating log file  ###############

PHOTONS=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Sum of Events to Simulate in History" |awk '{ print $8 }'`
WEIGHTS=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Sum of weights in History" |awk '{ print $6 }' | cut -d ":" -f 2`
WEIGHTS2=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Sum of weights squared in History" |awk '{ print $7 }' | cut -d ":" -f 2`
ANG=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Binning: number of AA bins" |awk '{ print $6 }'`
BINS=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Binning: number of TD bins" |awk '{ print $6 }'`
BIN_MIN=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Binning: min Transaxial Distance" |awk '{ print $5 }'`
BIN_MAX=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Binning: max Transaxial Distance " |awk '{ print $5 }'`
BSIZE=`echo 2*${BIN_MAX}/${BINS} | bc -l`
Z=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Binning: number of Z bins" |awk '{ print $6 }'`
ZMIN=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Binning: min Z position" |awk '{ print $5 }'`
ZMAX=`$DIR_SIMSET/bin/printheader $DIR_OUTPUT/rec.weight |grep "Binning: max Z position" |awk '{ print $5 }'`
ZLEN=`echo ${ZMAX} - ${ZMIN} | bc -l`
DBR=`echo ${ZLEN}/${Z} | bc -l`

echo ""
echo "     Number of counts (N):" $WEIGHTS 
echo "     Standard Desviation:" $WEIGHTS2 
echo ""
echo "Simulation Finished:" 
date 
echo "--------------------"
echo ""

echo "w: " $WEIGHTS 
echo "w2: " $WEIGHTS2 
factor=`awk -v w=$WEIGHTS -v w2=$WEIGHTS2 'BEGIN{printf ("%10.10f",w2/w)}'`


if [ $noisefree -eq -1 ]; then
        PhotonsToSimulate=$nPhotons
	factor=1
fi

if [ $noisefree -eq 0 ]; then
        PhotonsToSimulate=`echo "$nPhotons * $factor " | bc `
fi

if [ $noisefree -eq 1 ]; then
	factor=`echo 100*${factor} | bc -l`
	PhotonsToSimulate=`echo "$nPhotons * $factor " | bc `
fi


if [ ${#PhotonsToSimulate} -eq 0 ]; then
    echo "usage: $0 "
    echo Error in factor w-w2 and PhotonstoSimulate
    echo Check run_SimSET_PET.sh
    echo "WEIGHTS="$WEIGHTS
    echo "WEIGHTS2="$WEIGHTS2   
    echo "factor="$factor
    exit 1
fi


echo "factor" $factor "then photons to simulate:" $PhotonsToSimulate "(before" $nPhotons")"
echo -e "N$N\t$nPhotons\t$WEIGHTS\t$WEIGHTS2\t$PhotonsToSimulate" >> $DIR_SIMU/simulationValues.dat

###############################################

############ Output options ####################

############  InterFile Output format module ####################
if [ "${INTERFILE}" -eq 1 ]; 
then
export DIR_OUTPUT ANG BINS Z DBR BSIZE DIR_INPUT scatter_param min_s max_s
$DIR_SCRIPTS/simulation/INTERFILE.sh 
fi
############  Analyze Output format module ####################
if [ "${ANALYZE}" -eq 1 ]; 
then
export DIR_OUTPUT ANG BINS Z DBR BSIZE DIR_INPUT scatter_param min_s max_s
echo "analyze:" $DIR_SCRIPTS/simulation/ANALYZE.sh 
$DIR_SCRIPTS/simulation/ANALYZE.sh 
fi
############################################################

gzip ${DIR_OUTPUT}/rec.weight
