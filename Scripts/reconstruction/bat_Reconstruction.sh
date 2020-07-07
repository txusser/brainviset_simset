#!/usr/bin/env bash
# Pablo Aguiar - Berta October - Jesus Silva 2014
# STIR reconstruction of PET image from ECAT-EXACT / Biograph / Advance
# CHUS - CLINIC
###############################################
# Version 2.0
# Modified Aida Niñerola & Gemma Salvadó
# Date: January 2017
# Modified by Jesús Silva November 2017
###############################################
	
cd $DIR_PROJECTIONS
source ${paramsFile}
if [ -e "attImage" ];then
   echo "Att_Image already exists. We will use the existing attImage"
else
    echo "--------------------------------------------------------"
    echo "Calculating attenuation image"
    #Calculate the attenuation image by SimSET
    id_pat=1
    namePHG=`basename $paramsFile .sh`
    cp $namePHG$id_pat/phg$namePHG.rec phg$namePHG.rec

    #If attenuation params file exist delete it
    if [ -e "attParams.dat" ];  then
        rm -f attParams.dat
    fi

    #Create attenuation params file
    echo phg$namePHG.rec > attParams.dat
    echo attImage >> attParams.dat
    echo 1 >> attParams.dat

    #Call attenuation function of SimSET
    $DIR_SIMSET/bin/calcattenuation < attParams.dat >& logAttenuation.dat
fi

# Size of att file
size_att=`du -b attImage | awk '{ print($1) }'`
size_trues=`du -b trues$patient.img | awk '{ print($1) }'`
                                    
echo " Att Size is $size_att"
echo "Trues Size is $size_trues"

cut_end=$((${size_att}-${size_trues}))
echo " $cut_end bytes deleted from the end of attImage"

if [ $recons_type == 0 ];then
    co_trues_template=$DIR_SCRIPTS/templates/prompts_${scanner}_2D.hs
else
    co_trues_template=$DIR_SCRIPTS/templates/prompts_${scanner}.hs
fi

echo "Scanner is $scanner"

split -b $cut_end attImage attImage
mv attImageaa attImage.img
rm attImagea*
cp trues$patient.hdr attImage.hdr

echo "--------------------------------------------------------"
echo "Converting files to STIR format"

if [ ${B_ATTEN_PAR} -eq ";" ];then
    opera_imagen_hdr attImage.hdr full_sinograms${patient}.hdr full_sinograms${patient}.hdr fl multi
fi
    
conv_SimSET_STIR_hdr attImage.hdr $max_segment attImage.hdr
conv_SimSET_STIR_hdr full_sinograms${patient}.hdr $max_segment full_sinograms${patient}.hdr
conv_SimSET_STIR_hdr original_scatter_${patient}.hdr $max_segment original_scatter_${patient}.hdr
cp attImage.img attImage.s
cp full_sinograms${patient}.img prompts.s
cp original_scatter_${patient}.img additive_sinogram.s

echo "Conv sinogram to projections"
cortes=`echo ${num_z_bins}*${num_z_bins} | bc -l`

echo "Conv sinograms to proyections"
conv_sino2proy prompts.s fl ${num_aa_bins} ${num_td_bins} ${cortes} proyeccion.img fl
gen_hdr proyeccion ${num_td_bins} ${cortes} ${num_aa_bins} fl 1 1 1 0

if [ ${psf_value} != 0 ];then
	echo "Convolution with a PSF of (${psf_value} px)"
	convolucion_hdr proyeccion.hdr conv_proyeccion.hdr ${psf_value} 2d
else
	cp proyeccion.img conv_proyeccion.img
	echo "Avoiding convulution"

fi

echo "Conv projections back to sinograms"
conv_proy2sino conv_proyeccion.img fl ${num_aa_bins} ${num_td_bins} ${cortes} conv_sinograma.img fl
cp conv_sinograma.img prompts.s

sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/attImage.s"% \
< $co_trues_template > ${DIR_PROJECTIONS}/attImage.hs

sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/prompts.s"% \
< $co_trues_template > ${DIR_PROJECTIONS}/prompts.hs

sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/additive_sinogram.s"% \
< $co_trues_template > ${DIR_PROJECTIONS}/additive_sinogram.hs

if [ ${add_noise} != 0 ];then
	echo "Adding some noise to make things look more realistic"
	$DIR_STIR/poisson_noise -p ${DIR_PROJECTIONS}/noisy_prompts.hs ${DIR_PROJECTIONS}/prompts.hs $add_noise $RANDOM
    cp noisy_prompts.s prompts.s
fi

echo "--------------------------------------------------------"
echo "Done"

if [ $PRESERVE_FILES -eq 0 ];then
    echo"WARNING!!! PRESERVE_FILES is 0, temporal files are being deleted. WARNING!! Only added sinograms are preserved"
    rm -r ${namePHG}*
fi

export DIR_PROJECTIONS DIR_RECONSTRUCTIONS DIR_SCRIPTS NAME_STUDY patient recons_type DIR DIR_STIR #B_ATTEN_PAR B_SCATT_PAR
$DIR_SCRIPTS/reconstruction/run_STIR.sh $paramsFile

echo "End of reconstruction $DIR_RECONSTRUCTIONS" > $DIR_RECONSTRUCTIONS/endReconstruction.dat
date >> $DIR_RECONSTRUCTIONS/endReconstruction.dat
