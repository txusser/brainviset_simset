#!/usr/bin/env bash
#Batch to run OSEM STIR
#Author: Berta Marti
#15/11/2011
#Modified by: Jesus Silva
#Introduction of FBP2D and FBP3D, OSMAPOSL 2D and 2D recons.
#Directory correction for STIR 2.2
#24/12/2012

unset sensitivityFileName reconstructionFileName 
unset zoomFactor zoom_z xyOutputize zOutputZie 
unset numberOfSubsets numberOfIterations savingInterval

#set variables
source $1


if [ $recons_type -eq 0 ] || [ $recons_type -eq 1 ];
then
	# Building paramsOSEM.par
	sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/prompts.hs"% \
	    -e s%ATTIMAGE_STIR%"${DIR_PROJECTIONS}/attImage.hs"% \
	    -e s%SCATTERIMAGE_STIR%"${DIR_PROJECTIONS}/additive_sinogram.hs"% \
	    -e s%B_ATTEN%"${B_ATTEN_PAR}"% \
	    -e s%B_SCATT%"${B_SCATT_PAR}"% \
      -e s%SENSITIVITY_FILE%"${DIR_RECONSTRUCTIONS}/sens.s"% \
	    -e s%ZOOMFACTOR%"${zoomFactor}"% \
      -e s%ZOOM_Z%"${zoom_z}"% \
	    -e s%XYOUTPUTSIZE%"${xyOutputSize}"% \
	    -e s%ZOUTPUTSIZE%"${zOutputSize}"% \
	    -e s%SUBSETS%"${numberOfSubsets}"% \
	    -e s%ITERATIONS%"${numberOfIterations}"% \
 	    -e s%INTERVAL_SAVE%"${savingInterval}"% \
	    -e s%OUTPUT_FILE%"${reconstructionFileName}"% \
	  < $DIR_TEMPLATES/template_paramsOSEM.par > $DIR_SCRIPTS/reconstruction/ParamsOSEM.par

mv $DIR_SCRIPTS/reconstruction/ParamsOSEM.par $DIR_RECONSTRUCTIONS/
cd $DIR_RECONSTRUCTIONS/

##Call OSEM algorithm
echo "--------------------------------------------------------"
echo "Running OSMAPOL STIR"
$DIR_STIR/OSMAPOSL ParamsOSEM.par > logSTIR.log 2>> logSTIR.log
echo "--------------------------------------------------------"
echo " "
fi

if [ $recons_type -eq 2 ];
then
        # Building paramsFBP3DRP.par
        sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/prompts.hs"% \
            -e s%SENSITIVITY_FILE%"${DIR_RECONSTRUCTIONS}/sens.s"% \
            -e s%ZOOMFACTOR%"${zoomFactor}"% \
            -e s%XYOUTPUTSIZE%"${xyOutputSize}"% \
            -e s%ZOUTPUTSIZE%"${zOutputSize}"% \
            -e s%SUBSETS%"${numberOfSubsets}"% \
            -e s%ITERATIONS%"${numberOfIterations}"% \
            -e s%INTERVAL_SAVE%"${savingInterval}"% \
            -e s%OUTPUT_FILE%"${reconstructionFileName}"% \
          < $DIR_TEMPLATES/template_paramsFBP3DRP.par > $DIR_SCRIPTS/reconstruction/ParamsFBP3DRP.par



mv $DIR_SCRIPTS/reconstruction/ParamsFBP3DRP.par $DIR_RECONSTRUCTIONS/
cd $DIR_RECONSTRUCTIONS/
##Call FBP3DRP algorithm
echo "--------------------------------------------------------"
echo "Running FBP3DRP STIR"
$DIR_STIR/FBP3DRP ParamsFBP3DRP.par >> logSTIR.log 2>> logSTIR.log
echo "--------------------------------------------------------"
echo " "

fi


if [ $recons_type -eq 3 ];
then
        # Building paramsFBP3DRP.par
        sed -e s%PROJECTIONS_SIMSET%"${DIR_PROJECTIONS}/prompts.hs"% \
            -e s%SENSITIVITY_FILE%"${DIR_RECONSTRUCTIONS}/sens.s"% \
            -e s%ZOOMFACTOR%"${zoomFactor}"% \
            -e s%XYOUTPUTSIZE%"${xyOutputSize}"% \
            -e s%ZOUTPUTSIZE%"${zOutputSize}"% \
            -e s%SUBSETS%"${numberOfSubsets}"% \
            -e s%ITERATIONS%"${numberOfIterations}"% \
            -e s%INTERVAL_SAVE%"${savingInterval}"% \
            -e s%OUTPUT_FILE%"${reconstructionFileName}"% \
          < $DIR_TEMPLATES/template_paramsFBP2D.par > $DIR_SCRIPTS/reconstruction/ParamsFBP2D.par



mv $DIR_SCRIPTS/reconstruction/ParamsFBP2D.par $DIR_RECONSTRUCTIONS/
cd $DIR_RECONSTRUCTIONS/
##Call FBP2D algorithm
echo "--------------------------------------------------------"
echo "Running FBP2D STIR"
$DIR_STIR/FBP2D ParamsFBP2D.par >> logSTIR.log 2>> logSTIR.log
echo "--------------------------------------------------------"
echo " "

fi


