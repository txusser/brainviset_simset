#!/usr/bin/env bash
###################################################################################
#
# Author: Aida Niñerola
# Date: April 2017
# Description: BrainVISET
#
###################################################################################
#
#Launch the simulation as ./bat_Patients.sh $paramsFile
#Logs are stored in the logs directory

NC='\e[0m' # No Color
blue='\e[1;34m'
yellow='\e[1;33m'
purple='\e[0;35m'
red='\e[0;31m'

echo -e "${yellow}#####################${blue}@@${yellow}###############${blue}@@${yellow}##################${NC}"
echo -e "${blue}#####  ###### ###### ## #   #  #    # ## ##### ##### #####${NC}"
echo -e "${blue}##  ## ##   # ##  ## ## ##  #   #   # ## ##    ##      #  ${NC}"
echo -e "${blue}#####  ###### ###### ## ### #    #  # ## ##### #####   #  ${NC}"
echo -e "${blue}##  ## ## ##  #   ## ## # ###     ### ##    ## ##      #  ${NC}"
echo -e "${blue}#####  ##  ## #   ## ## #  ##      ## ## ##### #####   #  ${NC}"
echo -e "${yellow}##################${blue}@@${yellow}######################################${NC}"
echo -e "${blue}           #####  ##  #      ##  #####  #####  #####       ${NC}"
echo -e "${blue}           ##     ##  ##    ###  #      ##       #         ${NC}"
echo -e "${blue}           #####  ##  # #  # ##  #####  #####    #         ${NC}"
echo -e "${blue}              ##  ##  #  ##  ##     ##  ##       #         ${NC}"
echo -e "${blue}           #####  ##  #      ##  #####  #####    #         ${NC}"
echo -e "${yellow}##########################################################${NC}"
echo " "
echo -e "${blue}----------------------------------------------------------${NC}"
echo -e "${blue}                     WELCOME${NC}"
echo -e "${blue}----------------------------------------------------------${NC}"
echo " "
echo -e "${purple}-----------------------------------------------------------${NC}"
echo -e "${purple}      Last Version: November 2017 Jesús & Aida${NC}"
echo -e "${purple}-----------------------------------------------------------${NC}"
echo " "
sleep 3

paramsFile=$1

#Going up from Scripts to BrainViset Mother Directory
cd ..

#Setting BrainViset Directories
DIR=$PWD
DIR_SCRIPTS=$DIR/Scripts
DIR_TEMPLATES=$DIR_SCRIPTS/templates
DIR_RUNSIMPET=$DIR_SCRIPTS/simulation
DIR_EXES=$DIR/Exes

#Export my Directories to the global environment
export DIR DIR_SCRIPTS DIR_TEMPLATES DIR_RUNSIMPET DIR_EXES

#inicialize global variables for Simulation and reconstruction
source $DIR_SCRIPTS/$paramsFile

#Defining Patient Directories
if [ $CESGA -eq 1 ]
then
dataPath=$CESGA_DATA_PATH/Data/$patient
DIR_PROJ=$CESGA_DATA_PATH/Results/$output_name/$scanner/Projections
DIR_REC=$CESGA_DATA_PATH/Results/$output_name/$scanner/Reconstructions
DIR_SIMSCR=$CESGA_DATA_PATH/Results/$output_name/$scanner/Scripts
else
dataPath=$DIR/Data/$patient
#DIR_PROJ=$DIR/Results/$output_name/$scanner/Projections
#DIR_REC=$DIR/Results/$output_name/$scanner/Reconstructions
#DIR_SIMSCR=$DIR/Results/$output_name/$scanner/Scripts
DIR_RESULTS=/media/usuario3/HDD2/brainviset_simset/Results
DIR_PROJ=$DIR_RESULTS/$output_name/$scanner/Projections
DIR_REC=$DIR_RESULTS/$output_name/$scanner/Reconstructions
DIR_SIMSCR=$DIR_RESULTS/$output_name/$scanner/Scripts

fi

mapsPath=$dataPath/Maps
DIR_LOG=$DIR/Logs/$output_name/$scanner

echo "PROCESSING STUDY:$output_name" > $DIR/"SimulationTime${output_name}${scanner}.txt"
date >> $DIR/"SimulationTime${output_name}${scanner}.txt"

if [ ! -d $mapsPath ]; then
  mkdir -p $mapsPath
fi

cp $dataPath/$act_map.hdr $mapsPath/$patient.$act_map.act1.hdr
cp $dataPath/$act_map.img $mapsPath/$patient.$act_map.act1.img
cp $dataPath/$att_map.hdr $mapsPath/$patient.$att_map.att.hdr
cp $dataPath/$att_map.img $mapsPath/$patient.$att_map.att.img
cambia_formato_hdr $mapsPath/$patient.$act_map.act1.hdr $mapsPath/$patient.$act_map.act1.hdr 1B >> /dev/null
cambia_formato_hdr $mapsPath/$patient.$att_map.att.hdr $mapsPath/$patient.$att_map.att.hdr 1B >> /dev/null

let iteration=1

#Start eration process
Old_test_value=0
while [ $iteration -le $maximumIteration ];do
    echo " "
    echo -e "${red}==============================================================${NC}"
    echo -e "${red}Processing patient ${yellow}$patient${red} in ${yellow}$scanner${red}. Iteration ${NC}$iteration ${NC}"
    date
    echo " "

    DIR_PROJECTIONS=$DIR_PROJ/Iteration$iteration
    DIR_RECONSTRUCTIONS=$DIR_REC/Iteration$iteration
    DIR_SIMSCRIPTS=$DIR_SIMSCR/Iteration$iteration
    
    EMISS_HDR=$mapsPath/$patient.$act_map.act$iteration.hdr
    EMISS_IMG=$mapsPath/$patient.$act_map.act$iteration.img
    ATTEN_HDR=$mapsPath/$patient.$att_map.att.hdr
    PET_HDR=${dataPath}/${pet_image}.hdr

    #Remove the file that indicates that the simulation and the reconstruction ended
    rm -f $DIR_RECONSTRUCTIONS/endReconstruction.dat

    export DIR_PROJECTIONS DIR_RECONSTRUCTIONS DIR_SIMSCRIPTS dataPath
    export EMISS_HDR EMISS_IMG ATTEN_HDR patient

    #Start simulation and reconstruction
    $DIR_SCRIPTS/bat_Start.sh $DIR/Scripts/$paramsFile

    
    if [ $reconstruction -eq 0 ]
    then
        iteration=`expr $iteration + 1`
    else
	    simuEnds=0
    	    #Wait until the simulation and the reconstruction end
    	    while [ $simuEnds -le 0 ]
    	    do
   	    sleep 10s;
    	    #echo "Check if simulation ended"	
            	if [ -e "$DIR_RECONSTRUCTIONS/endReconstruction.dat" ]
        	then
            		simuEnds=`expr $simuEnds + 1`
            		echo "END OF ITERATION $iteration of: $patient" >> $DIR/"SimulationTime${patient}${scanner}.txt"
        	fi
    	    done

	    #Getting data for the final OSEM iteration
	    output_prefix=$DIR_RECONSTRUCTIONS/${recFileName}_${numberOfIterations}
	    output_hdr=$DIR_RECONSTRUCTIONS/${recFileName}_${numberOfIterations}_it$iteration.hdr
	    output_img=$DIR_RECONSTRUCTIONS/${recFileName}_${numberOfIterations}_it$iteration.img

	    #Now we are going to read the .hv header to get the values for the .hdr header
	    line_voxx="$(grep -F "matrix size [1]" ${output_prefix}.hv)"
	    voxx="$(echo $line_voxx | python -c "print raw_input()[:].split()[-1]")"
	    line_voxy="$(grep -F "matrix size [2]" ${output_prefix}.hv)"
	    voxy="$(echo $line_voxy | python -c "print raw_input()[:].split()[-1]")"
	    line_voxz="$(grep -F "matrix size [3]" ${output_prefix}.hv)"
	    voxz="$(echo $line_voxz | python -c "print raw_input()[:].split()[-1]")"

	    line_svoxx="$(grep -F "scaling factor (mm/pixel) [1]" ${output_prefix}.hv)"
	    svoxx="$(echo $line_svoxx | python -c "print raw_input()[:].split()[-1]")"
	    line_svoxy="$(grep -F "scaling factor (mm/pixel) [2]" ${output_prefix}.hv)"
	    svoxy="$(echo $line_svoxy | python -c "print raw_input()[:].split()[-1]")"
	    line_svoxz="$(grep -F "scaling factor (mm/pixel) [3]" ${output_prefix}.hv)"
	    svoxz="$(echo $line_svoxz | python -c "print raw_input()[:].split()[-1]")"

	    #Now we generate a new Analyze Image
	    gen_hdr ${output_prefix}_it$iteration $voxx $voxy $voxz fl $svoxx $svoxy $svoxz 0
	    mv $output_prefix.v $output_img

            $DIR_SCRIPTS/new_map_generation_spm.py $output_hdr $PET_HDR $SPM_RUN

	    if 	[ $maximumIteration -gt 1 ]
            then
		echo "Evaluating the results of the simulation..."
		corr_sim=$DIR_RECONSTRUCTIONS/r${recFileName}_${numberOfIterations}_it$iteration.hdr	
                #test_value=$(fsl5.0-fslcc $corr_sim $PET_HDR | tail -c 5)
		test_value=$(/opt/FSL/bin/fslcc $corr_sim $PET_HDR | tail -c 5)

		echo -e "${yellow}Correlation coefficient between simulated and real image is: $test_value${NC}"
		st=`echo "${test_value} > ${min_cc}" | bc`
		st2=`echo "${Old_test_value} > ${test_value}" | bc`	    
		if [ $st -eq 1 -o ${st2} -eq 1 ]; then
			echo -e "${blue}No more iterations needed.${NC}"
                    	echo -e "${blue}Final map stored in ${mapsPath}/finalmap.hdr${NC}"
			cp ${EMISS_HDR} ${mapsPath}/finalmap.hdr
                        
			if [ ${st2} -eq 1 ]; then			
				cp ${mapsPath}/${patient}.act${OldIt}.img ${mapsPath}/finalmap.img
				rm -r ${mapsPath}/${patient}.act${iteration}*
			else #st -eq 1
				cp ${mapsPath}/${patient}.act${iteration}.img ${mapsPath}/finalmap.img
			fi
			iteration=`expr $maximumIteration + 1`
		else	
		    Old_test_value=${test_value} 
                    OldIt=$iteration
                    iteration=`expr $iteration + 1`
		  
		    if [ $iteration -le $maximumIteration ] #When it is not last iteration, new map must be performed
		    then
                        echo -e "${yellow}Not converging yet. Preparing new iteration ${iteration}.${NC}"
		
			division_hdr=$DIR_RECONSTRUCTIONS/division.hdr
			new_map=${mapsPath}/new_map

			echo "opera_imagen_hdr ${mapsPath}/${patient}.act${OldIt}.hdr $division_hdr ${new_map}.hdr fl multi"
                        opera_imagen_hdr ${mapsPath}/${patient}.act${OldIt}.hdr $division_hdr ${new_map}.hdr fl multi
                        
                        ${DIR_SCRIPTS}/scal_map.py ${new_map}.hdr ${mapsPath}/${patient}.act${iteration}.hdr
			cambia_formato_hdr ${mapsPath}/${patient}.act${iteration}.hdr ${mapsPath}/${patient}.act${iteration}.hdr 1B > /dev/null 
		    else
			echo -e "${blue}Maximum number of iterations reached.${NC}"
                        echo -e "${blue}Final map stored in ${mapsPath}/finalmap.hdr${NC}"
			cp ${EMISS_HDR} ${mapsPath}/finalmap.hdr
			cp ${mapsPath}/${patient}.act${OldIt}.img ${mapsPath}/finalmap.img

			#rm -r ${mapsPath}/analysis_${patient}.act${iteration}*                                						            	    
		    fi 
		
		fi 
	    else
		iteration=`expr $iteration + 1`   
            fi
    fi
done

cp -r ${DIR_RECONSTRUCTIONS} ${DIR_RESULTS}/Finished/${output_name}

echo " "
echo -e "${blue}=============================================================="
echo -e "${blue}Processed patient $patient "
echo -e "${blue}Total Number of Iterations was $OldIt"
echo -e "${blue}Finishing time is:";date
echo -e "${blue}=============================================================="
echo " "
date >> $DIR/"SimulationTime${patient}${scanner}.txt"
echo "END PROCESSING STUDY:$patient" >> $DIR/"SimulationTime${patient}${scanner}.txt"
