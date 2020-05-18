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

#In case of OSEM reconstruction and scanner Siemens mCT the attenuation correction will be done during the OSEM process.
echo "Scanner is $scanner"
if [ $scanner == "Siemens_mCT" ] || [ $scanner == "Vereos" ];then
    B_ATTEN_PAR=""
    B_SCATT_PAR=""

    #We split the attImage as required
    split -b $cut_end attImage attImage
    mv attImageaa attImage.img
    rm attImagea*
    cp trues$patient.hdr attImage.hdr
                    
    cp trues$patient.hdr attImage.hdr

    if [ $detector_model == "blocks" ]; then
        opera_imagen_hdr attImage.hdr ${DIR_SCRIPTS}/templates/det_files/${scanner}_normalization.hdr attImage.hdr fl divid
    fi
                                                                            
    echo "--------------------------------------------------------"
    echo "Converting files to STIR format"
    conv_SimSET_STIR_hdr attImage.hdr $max_segment attImage.hdr
    conv_SimSET_STIR_hdr full_sinograms${patient}.hdr $max_segment full_sinograms${patient}.hdr
    conv_SimSET_STIR_hdr original_scatter_${patient}.hdr $max_segment original_scatter_${patient}.hdr
    cp attImage.img attImage.s
    cp full_sinograms${patient}.img prompts.s
    cp original_scatter_${patient}.img additive_sinogram.s

    sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/attImage.s"% \
    < $co_trues_template > ${DIR_PROJECTIONS}/attImage.hs

    sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/prompts.s"% \
    < $co_trues_template > ${DIR_PROJECTIONS}/prompts.hs

    sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/additive_sinogram.s"% \
    < $co_trues_template > ${DIR_PROJECTIONS}/additive_sinogram.hs

    echo "--------------------------------------------------------"
    echo " "

elif [ $scanner == "GE_Discovery" ];then

    #B_ATTEN_PAR=""
    #B_SCATT_PAR=";"

    separa_nbytes attImage $size_att  0 $cut_end  attImage.img
    cp trues$patient.hdr attImage.hdr

    echo "--------------------------------------------------------"
    echo "Converting files to STIR format"
    
    conv_SimSET_STIR_hdr attImage.hdr $max_segment attImage.hdr
    conv_SimSET_STIR_hdr full_sinograms${patient}.hdr $max_segment full_sinograms${patient}.hdr
    cp attImage.img attImage.s
    cp full_sinograms${patient}.img prompts.s

### 
    echo "Conv sinogram to projections"
    # #conv_sino2proy prompts.s fl 280 293 576 aux fl
    cortes=`echo ${num_z_bins}*${num_z_bins} | bc -l`
    conv_sino2proy prompts.s fl ${num_aa_bins} ${num_td_bins} ${cortes} aux fl

    cp aux proyeccion.img
    cp $DIR_SCRIPTS/templates/template_proyeccion.hdr proyeccion.hdr 	

    echo "Convolution...(${psf_value} px)"
    convolucion_hdr proyeccion.hdr conv_proyeccion.hdr ${psf_value} 2d
     #convolucion_hdr proyeccion.hdr conv_proyeccion.hdr 0.75 2d

    echo "Conv projection to sinograms"
     #conv_proy2sino conv_proyeccion.img fl 280 293 576 conv_sinograma.img fl
    conv_proy2sino conv_proyeccion.img fl ${num_aa_bins} ${num_td_bins} ${cortes} conv_sinograma.img fl
    cp conv_sinograma.img prompts.s
    #cp conv_sinograma.img co_trues_PSF075px.s
    #cp co_trues.hs co_trues_PSF01125px.hs
    #sed -e s%co_trues.s%"co_trues_PSF01125px.s"% < co_trues.hs > co_trues_PSF01125px.hs
    #sed -e s%co_trues.s%"co_trues_PSF075px.s"% < co_trues.hs > co_trues_PSF075px.hs

###

    sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/attImage.s"% \
    < $co_trues_template > ${DIR_PROJECTIONS}/attImage.hs

    sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/prompts.s"% \
    < $co_trues_template > ${DIR_PROJECTIONS}/prompts.hs

    echo "--------------------------------------------------------"
    echo " "

elif [ $scanner == "GE_Advance" ] || [ $scanner == "Siemens_Biograph" ];then    

    #B_ATTEN_PAR=";"
    #B_SCATT_PAR=";"
    
    #Only the first images of attImage interest us
    separa_nbytes attImage $size_att  0 $cut_end  attImage.img

    echo "--------------------------------------------------------"
    echo "Correcting attenuation"
    cp trues$patient.hdr attImage.hdr
    opera_imagen_hdr full_sinograms$patient.hdr attImage.hdr prompts.hdr fl multi

    echo "--------------------------------------------------------"
    echo "Converting files to STIR format"
    echo "conv_SimSET_STIR_hdr prompts.hdr $max_segment prompts.hdr"
    conv_SimSET_STIR_hdr prompts.hdr $max_segment prompts.hdr

    cp prompts.img prompts.s

    sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/prompts.s"% \
    < $co_trues_template > ${DIR_PROJECTIONS}/prompts.hs

    echo "--------------------------------------------------------"
    echo " "

fi

#Delete the param... directories to free space, only if PRESERVE_FILES is equal to 0
if [ $PRESERVE_FILES -eq 0 ];then
    echo"WARNING!!! PRESERVE_FILES is 0, temporal files are being deleted. WARNING!! Only added sinograms are preserved"
    rm -r ${namePHG}*
fi

export DIR_PROJECTIONS DIR_RECONSTRUCTIONS DIR_SCRIPTS NAME_STUDY patient recons_type DIR DIR_STIR #B_ATTEN_PAR B_SCATT_PAR
$DIR_SCRIPTS/reconstruction/run_STIR.sh $paramsFile

echo "End of reconstruction $DIR_RECONSTRUCTIONS" > $DIR_RECONSTRUCTIONS/endReconstruction.dat
date >> $DIR_RECONSTRUCTIONS/endReconstruction.dat
