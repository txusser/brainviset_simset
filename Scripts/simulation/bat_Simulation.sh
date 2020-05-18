#!/usr/bin/env bash
# Berta Marti October 2011
# Run PET simulation using SAMPLING (3 simulations)

#Scripts directory
#DIR_SCRIPTS=$PWD

#Parameters file name (must be in the same folder than this batch)
# parametersFileName=$DIR_Scripts/$paramsFile
parametersFileName=$paramsFile

#Script name
scriptName=$DIR_SIMU

# Noise level (noisefree=1 (no available yet!) for simulations w=100*w2 and noisefree=0 for simulations w=w2)
#noisefree=0 #(no changes please)

# Initial number of histories to simulate
nPhotons=$initialPhotons
sPhotons=$samplingPhotons

#Length of Scan (in seconds): I divided the simulation into 6 simulations of 6 seconds
lengthOfScan=$OriginalL

#Export this variables to run_SimSET_PET.sh
export nPhotons
export sPhotons
export lengthOfScan
export scriptName
export ACTTABLE
export DOSE
export DIR_SCRIPTS DIR_MAPS dataPath DIR_SIMSCRIPTS
export radio_scanner num_z_bins min_z max_z num_aa_bins num_td_bins min_td max_td min_energy_window

N=$cSim

cd $DIR_RUNSIMPET



  echo ""
  echo "--------------------------------------------------------------------------"
  S=0
  export S
  myPhotons=$sPhotons
  export myPhotons
  echo "Beginning of the previous simulation to estimate nPhotons with sampling:$S (sim num:$N)"
  echo "Parameters used file: $parametersFileName"
  export N
   if [ -e "$scriptName/simulationValues.dat" ]
     then
     rm -f $scriptName/simulationValues.dat
   fi
   echo "Tracking $myPhotons photons and time $OriginalL (job $N of $division)"
   echo "params file: $parametersFileName"
   
   echo "myPhotons: $myPhotons "
   ./run_SimSET_PET.sh $parametersFileName 
   echo "End of simulation previous simulation: $N"
   echo "--------------------------------------------------------------------------"

  echo ""

  S=1
  export S

  myPhotons=-1
  
  if [ $noisefree -eq -1 ]
	then
	myPhotons=$nPhotons
  fi
  if [ $noisefree -eq 0 -o $noisefree -eq 1 ]
	then
	myPhotons=`cat $scriptName/simulationValues.dat | grep "N$N" | cut -f 5`
  fi
          echo $ATTEN_HDR
  export myPhotons
  export EMISS_HDR EMISS_IMG ATTEN_HDR
  export patient
  echo ""
  echo "--------------------------------------------------------------------------"
  echo "Beginning of the final simulation with sampling:$S (sim num:$N)"
  echo "Tracking $myPhotons photons(noisefree=$noisefree) and time $OriginalL (job $N of $division)"
  ./run_SimSET_PET.sh $parametersFileName
  echo "End of the  simulation: $N"
  echo "--------------------------------------------------------------------------"


echo -e "End simulation $DIR_SIMU" >> $DIR_SIMU/endSimulation.dat
date >> $DIR_SIMU/endSimulation.dat

