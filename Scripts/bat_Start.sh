#!/usr/bin/env bash
###################################################################################
# Authors: 
# Pablo Aguiar
# Berta Marti
# Jesus Silva
###################################################################################
# Date: November 2016 (Gemma Salvadó & Aida Niñerola-Baizán)
# Description: Modified for mCT reconstruction and easier variable generalisation
# Version: 4.5
# ./bat_Start.sh parametersfile (absolute path)
###################################################################################

paramsFile=$1
source $paramsFile

#Variabe for log folder
dataLog=`date +%Y_%m_%d_%H%M`


if [ $simulation -eq 1 ] 
then

    #Parameters from ParamPET file
    OriginalL=$LENGTH
    initialPhotons=$PHOTONS
    samplingPhotons=$SAMPLINGPHOTONS

    paramsFileRec=STIRparameters_${scanner}.sh

    #Create patient folder of simulation and simulation results
    mkdir -p $DIR_SIMSCRIPTS
    #mkdir -p $DIR_PROJECTIONS

    if [ -e "$DIR_PROJECTIONS/" ]
    then
        if [ $user -eq 1 ]
        then
            echo "WARNING. A projections directory for this simulation already exists. This will delete it."
            rm -Rf $DIR_PROJECTIONS
        else
            read -p "WARNING. A projections directory for this simulation already exists. This will delete it. Press [Enter] to continue or [Ctrl+c] to abort"
        fi
    else
	mkdir -p $DIR_PROJECTIONS
    fi

    cd $DIR_SIMSCRIPTS

    #Looks for a prior simulation directory.

                       
    #Remove old folders of this patient if exists
    rm -Rf $DIR_SIMSCRIPTS/Sim_*

    #Calculating the new length of scan 
    #OriginalL=`awk -v l=$OriginalL -v d=$division 'BEGIN{print (l / d)}'`
    OriginalL=`echo ${OriginalL}/${division} | bc -l`
    initialPhotons=`echo ${initialPhotons}/${division} | bc -l`	
    #Showing new values
    echo " "
    echo "============================================================="
    echo "Number of paralel simulation: $division"
    echo "Length of scan of each simulation: $OriginalL"
    echo "Number of photons of each simulation: $initialPhotons"

    ############################## SIMULATION ##################################
    #Dividing the simulation
    cSim=1
    echo " "
    while [ $cSim -le $division ]
    do
        #Dir individual simulations	
        DIR_SIMU=$DIR_SIMSCRIPTS/Sim_$cSim
        
        #Create each simulation script
        mkdir -p $DIR_SIMU

        #Copy det.rec to each folder
        cp $DIR_TEMPLATES/det_files/det_${detector_model}_${scanner}.rec $DIR_SIMU/det.rec
        DETECTOR=$DIR_SIMU/det.rec

        #Copy templates to each folders
        cp $DIR_TEMPLATES/template_bin.rec $DIR_SIMU/
        cp $DIR_TEMPLATES/template_phg_dirs.rec $DIR_SIMU/
        cp $DIR_TEMPLATES/template_phg_params.rec $DIR_SIMU/
        cp $DIR_RUNSIMPET/bat_Simulation.sh $DIR_SIMU/

        
        echo "Simulation Sim_$cSim starts"

        #Export variables
        export OriginalL cSim initialPhotons samplingPhotons paramsFile DETECTOR DOSE noisefree
        export DIR_SCRIPTS DIR_MAPS DIR_SIMSCRIPTS DIR_RUNSIMPET DIR_SIMSET DIR_SIMU
        export DIR_PROJECTIONS DIR_RECONSTRUCTIONS
        export EMISS_HDR EMISS_IMG ATTEN_HDR

        cd $DIR_SIMU

        #The simulations have a gap of 5s
        sleep 5; 
	if [ $CESGA -eq 1 ]
	then
	    sbatch -t $cesga_max_time -c 1  --mem=16000 --get-user-env -o simLog_SIM${cSim}.log  bat_Simulation.sh
	else
        ./bat_Simulation.sh >> "simLog_SIM${cSim}.log" &
	fi
        ((cSim++))
        
    done
    echo " "
	echo "Waiting simulation end..."
    startAddition=0
    while [ $startAddition -le 0 ]
    do
        cRec=1    
        sleep 5s;
        allSimDone=0
        
        while [ $cRec -le $division ]
        do

                if [ -e "$DIR_SIMSCRIPTS/Sim_$cRec/endSimulation.dat" ]
                then
                    (( allSimDone++ ))			    
					#echo allsimdone=$allSimDone
                fi
                
                (( cRec++ ))
				#echo crec=$cRec
                            
        done
        #echo "all sim done"
        if [ $allSimDone -eq $division ]
        then
            #Open the projections directory
            cd $DIR_PROJECTIONS

            #Copy the first trues and scatter
            id_pat=1
            nameSimu=`basename $paramsFile .sh`

            cp ${nameSimu}${id_pat}/trues.hdr trues${patient}.hdr
            cp ${nameSimu}${id_pat}/trues.img trues${patient}.img
            cp ${nameSimu}${id_pat}/scatter.hdr scatter${patient}.hdr
            cp ${nameSimu}${id_pat}/scatter.img scatter${patient}.img

            cp trues${patient}.img trues_aux.img

            echo " "
            echo "=============================================================="
            echo "Adding sinograms..."
            
            #Add the other images to the first one if there are more than one
            if [ $division -gt 1 ]
            then
                id_pat=2 
                while [ $id_pat -le $division ]
                do
                        #echo "------Adding sinogram $id_pat----"
                        opera_imagen_hdr trues$patient.hdr $nameSimu$id_pat/trues.hdr trues$patient.hdr fl sumar
                        opera_imagen_hdr scatter$patient.hdr $nameSimu$id_pat/scatter.hdr scatter$patient.hdr fl sumar
                        ((id_pat++))
                done
            fi

            cp scatter$patient.hdr original_scatter_$patient.hdr
            cp scatter$patient.img original_scatter_$patient.img
            echo "Analytic correction factor is (1 = No correction. 0 = Trues only ): $ANALYTIC_SCATTER_CORRECTIONFACTOR"
            opera_imagen_hdr -C $ANALYTIC_SCATTER_CORRECTIONFACTOR original_scatter_$patient.hdr scatter_$patient.hdr fl multi
            opera_imagen_hdr trues$patient.hdr scatter_$patient.hdr full_sinograms$patient.hdr fl sumar
            #Get the number of counts of the final image
            size_proj=`du -b trues$patient.img | grep trues$patient.img | awk '{ print $1 }'`

            (( startAddition++ ))
            echo "Finished adding sinograms..."
            echo " "
        fi
    done
            
    #Saving simulation log file
    cSim=1
    while [ $cSim -le $division ]
    do
        DIR_SIMU=$DIR_SIMSCRIPTS/Sim_$cSim
        projName=`basename $paramsFile .sh`
        mv $DIR_SIMU/simulationValues.dat $DIR_PROJECTIONS/.
        mv $DIR_SIMU/simLog_SIM$cSim* $DIR_PROJECTIONS/.
        ((cSim++))
    done
    
    #Saving params file
    cp $paramsFile $DIR_PROJECTIONS/$projName.sh
    
else
    #Simulation is not performed, so allSimDone = division
    let allSimDone=$division
fi

sleep 5

############################ RECONSTRUCTION #####################################

if [ $reconstruction -eq 1 ]
then

    if [ $simulation -eq 0 ]
    then
	cd $DIR_PROJECTIONS
    	id_pat=1
        nameSimu=`basename $paramsFile .sh`

        cp $nameSimu$id_pat/trues.hdr trues$patient.hdr
        cp $nameSimu$id_pat/trues.img trues$patient.img
        cp $nameSimu$id_pat/scatter.hdr scatter$patient.hdr
        cp $nameSimu$id_pat/scatter.img scatter$patient.img
	    cp trues$patient.img trues_aux.img

        echo " "
        echo "=============================================================="
        echo "Adding sinograms..."
            
        #Add the other images to the first one if there are more than one
        if [ $division -gt 1 ]
        then
        	id_pat=2 
        	while [ $id_pat -le $division ]
                do
                	#echo "------Adding sinogram $id_pat----"
                        opera_imagen_hdr trues$patient.hdr $nameSimu$id_pat/trues.hdr trues$patient.hdr fl sumar
                        opera_imagen_hdr scatter$patient.hdr $nameSimu$id_pat/scatter.hdr scatter$patient.hdr fl sumar
                        ((id_pat++))
        	done
        fi

        mv scatter$patient.hdr original_scatter_$patient.hdr
        mv scatter$patient.img original_scatter_$patient.img
        
        
        cd $DIR_PROJECTIONS
        echo "SCATTER_CORRECTION FACTOR: $ANALYTIC_SCATTER_CORRECTIONFACTOR"
        opera_imagen_hdr -C $ANALYTIC_SCATTER_CORRECTIONFACTOR original_scatter_$patient.hdr scatter_$patient.hdr fl multi
        opera_imagen_hdr trues$patient.hdr scatter_$patient.hdr full_sinograms$patient.hdr fl sumar
        cd -
    fi

    #Create patient folder of reconstruction files if it doesn't exist
    mkdir -p $DIR_RECONSTRUCTIONS
  
    startReconstruction=0
    while [ $startReconstruction -le 0 ]
    do

        if [ $allSimDone -eq $division ]
        then
            #echo "The number of simulations ended is equal than the number of simulations ($allSimDone=$division)"
            
            echo " "
            echo "=============================================================="
            echo "Reconstructing"
                    export DIR_PROJECTIONS DIR_RECONSTRUCTIONS DIR_TEMPLATES DIR_SIMSET DIR_SCRIPTS DIR dataPath DIR_STIR PRESERVE_FILES user
                    export patient paramsFile division scanner recons_type max_segment ATTEN_HDR
                    #qsub -V -N LPET_${patient}_RECONS -d $PWD -l mem=2048mb -k oe -j oe $DIR_SCRIPTS/reconstruction/bat_Reconstruction.sh
                    $DIR_SCRIPTS/reconstruction/bat_Reconstruction.sh > $DIR_RECONSTRUCTIONS/"recLog.log"
            echo "=============================================================="
            echo " "
            (( startReconstruction++ ))
        fi			
    done

    #Saving params file
    cp $paramsFile $DIR_RECONSTRUCTIONS/$projName.sh

fi

echo "BrainViset Iteration Finished"
