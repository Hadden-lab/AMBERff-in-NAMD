#!/bin/bash
######FOR TESTING ONLY, clean directory before starting again########
#Set up environment
export IGNOREERRORS=1 # set this variable to 1 to ignore all errors when running tests
export cdir=$(pwd)
export script_dir=$cdir/scripts
mkdir -p $cdir/forcefield
export ffdir=$cdir/forcefield
mkdir -p $cdir/testing

echo "Welcome, the purpose of this code is to test single point energy deviations in force fields"
echo "refactored from AMBER format to CHARMM format"
echo ""
echo "If you're using this code please cite:"
echo "Antolínez, S.; Jones, P. E.; Phillips, J. C.; Hadden-Perilla J. A."
echo "AMBERff at scale: Multimillion-atom simulations with AMBER force fields in NAMD. Submitted (2023)"
echo "https://doi.org/10.1101/2023.10.10.561755"           
echo "Lab of Dr. Jodi A. Hadden-Perilla (jhadden@udel.edu)"
echo "Thank you :)"
echo ""
if [[ -z $AMBERHOME ]]; then
    echo "$AMBERHOME variable is not set, please make sure there is a local installation of AMBER"
    echo "available for running the tests"
    echo
    exit 1
else
    echo "found the following AMBER installation, using it for testing: $AMBERHOME"
fi

read -p "Asumming AMBER force field files to be used for comparison are located in $AMBERHOME/dat/leap, is this correct?" amberffloc
if [[ -z $amberffloc || ${amberffloc^^} == 'Y' || ${amberffloc^^} == "YES" ]]; then
    export Apath=$AMBERHOME/dat/leap
    export cmdpath=$Apath/cmd
    export parmpath=$Apath/parm
    export libpath=$Apath/lib
else
    read -p "Input location of AMBER force field files:" Apath
    export Apath=$Apath
    export cmdpath=$Apath
    export parmpath=$Apath
    export libpath=$Apath
fi
echo""  
export NAMDBIN=$(which namd2)
if [[ -z $NAMDBIN ]]; then
    export NAMDBIN=$(which namd3)
fi
if [[ -z $NAMDBIN ]];then
    echo "No NAMD binary found to run tests with."
    echo "please make sure a NAMD binary is in your PATH"
    exit 1
else
    echo "Using the following NAMD binary for testing: $NAMDBIN"
    read -p "Use another binary (specifify binary/ ENTER to use aforementioned binary)?" changenamdbin
    if [[ -n $changenamdbin ]];then
	export NAMDBIN=$changenamdbin
    fi
fi
echo ""
export VMDBIN=$(which vmd)
if [[ -z $VMDBIN ]];then
    echo "No VMD binary found to run tests with."
    echo "please make sure a VMD binary is in your PATH"
    exit 1
else
    echo "Using the following VMD binary for testing: $VMDBIN"
    read -p "Use another binary (specifify binary/ ENTER to use aforementioned binary)?" changenamdbin
    if [[ -n $changenamdbin ]];then
	export VMDBIN=$changenamdbin
    fi
fi
echo ""
echo "To get the best energy matches, a special compilation of NAMD using AMBER's Coulomb constant,"
read -p  "henceforth referred to as NAMBER, is required. Is such a binary available? (ENTER: no) " namberAvailable
if [[ -z $namberAvailable || ${namberAvailable^^} == "N" || ${namberAvailable^^} == "NO" ]]; then
    echo ""
    echo "WARNING: Skipping NAMBER tests"
    export TESTNAMBER=0
elif [[ ${namberAvailable^^} == 'Y' || ${namberAvailable^^} == "YES" ]];then
    export TESTNAMBER=1
    read -p "Input NAMBER binary:" NAMBERBIN
    export NAMBERBIN=$NAMBERBIN
    echo ""
    echo "INFO: Testing with NAMBER enabled"
else
    echo "ERROR: User did not scpecify whether or not to test with NAMBER"
    exit 1
fi
echo ""
read -p "Input name of the leaprc file (e.g. leaprc.protein.ff14SB): " Aleaprc
if [[ -z $Aleaprc ]];then
    echo "ERROR: User did not input leaprc file"
    exit 1
else
    export Aleaprc=$Aleaprc
fi

if [[ !(-f $cmdpath/$Aleaprc) ]];then
    echo "ERROR: specified leaprc $Aleaprc not not found in $cmdpath"
    exit 1
fi
echo ""

BASENAME=$( echo $Aleaprc | awk -F'[.]' '{print $(NF)}' )

echo "INFO: These test won't run unless the namdrc, topology and parameter files are located"
echo "INFO: in the top level forcefield dirctory"
echo ""
read -p "Input namdrc to be used in comparisons (default: namdrc.${BASENAME}): " NAMDRC
if [[ -z $NAMDRC ]];then
    export NAMDRC=namdrc.${BASENAME}
else
    export NAMDRC
fi

if [[ !(-f $ffdir/$NAMDRC ) ]]; then
    echo "ERROR: namdrc file $NAMDRC not found in $ffdir"
    exit 1
fi
echo ""

read -p "Input rtf topology file to be used in comparisons (default: ${BASENAME}.rtf): " Artf
if [[ -z $Artf ]] ;then
    export Artf=${BASENAME}.rtf
else
    export Artf
fi

if [[ !(-f $ffdir/$Artf) ]];then
    echo "ERROR: rtf $file Artf not found in  $ffdir"
    exit 1
fi

cmap=$(grep '^CMAP' $ffdir/$Artf)

if [[ -z $cmap ]]; then
    export USECMAP=0
else
    export USECMAP=1
    echo "INFO: found CMAP terms in $Artf, taking that into account for energy tests"
fi
echo


echo "INFO: This test suite contains 2 types of tests: "
echo "INFO:     1. Single Residue test - Build and compare single point energies for all residues found in rtf"
echo "INFO:     2. Tripeptide test - (For protein force fields only) Build and compare single point energies for all possible tripeptide combinations in rtf"
echo
read -p "Please choose the test you want to perform (1-default /2):" chosenTest

if [[ -z $chosenTest || $chosenTest -eq 1 ]];then
    export ttype=singleRes
elif [[ $chosenTest -eq 2 ]];then
    export ttype=tripeptide
else
    echo "ERROR: Invalid option, please choose 1 or 2"
    exit 1
fi

if [[ $IGNOREERRORS -eq 1 ]];then
    echo "WARNING: Ignore Errors has been turned on.This will cause the script to try and build and test the complete"
    echo "WARNING: ensemble of test cases ignoring errors. No guarantee all test cases will be build properly."
fi


export ff_name=$Aleaprc
    
export runtest=${ttype}_test.sh
cd $cdir/testing
mkdir -p ${ttype}_test
cd ${ttype}_test

if [[ `ls  -1 | wc -l` -gt 0 ]]; then
    rm -r *
fi


cp $script_dir/$runtest $script_dir/make_energy_csv.sh .
testingdir=$(pwd)
echo
echo
echo "Starting ${ttype}_test" | tee -a ${ttype}_test.log
echo "" | tee -a ${ttype}_test.log
echo "Testing will be done using $runtest script" | tee -a ${ttype}_test.log
echo 'Testing will be done in the directory:' | tee -a ${ttype}_test.log
echo `pwd`| tee -a ${ttype}_test.log
echo "" | tee -a ${ttype}_test.log
echo "INFO: AMBER used in testing: $AMBERHOME" | tee -a ${ttype}_test.log
echo "INFO: NAMD used in testing: $NAMDBIN" | tee -a ${ttype}_test.log
echo "INFO: VMD used in testing: $VMDBIN" | tee -a ${ttype}_test.log

if [[ $TESTNAMBER -eq 1 ]]; then
    echo "INFO: testing with NAMBER enabled" | tee -a ${ttype}_test.log
    echo "NAMBER binary used for testing: $NAMBERBIN" | tee -a ${ttype}_test.log
else
    echo "WARNING: NAMBER testing diabled" | tee -a ${ttype}_test.log
fi

echo "" | tee -a ${ttype}_test.log    
echo "" | tee -a ${ttype}_test.log
echo "INFO: The following files will be used in testing:" | tee -a ${ttype}_test.log
echo "INFO: AMBER leaprc - $Aleaprc" | tee -a ${ttype}_test.log
echo "INFO: Refactored namdrc - $NAMDRC" | tee -a ${ttype}_test.log
echo "INFO: Refactored rtf topologgy - $Artf " | tee -a ${ttype}_test.log
echo "" |tee -a ${ttype}_test.log
if [[ $USECMAP -eq 1 ]]; then
    echo "INFO: CMAP terms were found in rtf" | tee -a ${ttype}_test.log
    echo "INFO: enabling tests with CAMP"| tee -a ${ttype}_test.log
fi
export TESTPID=$$
bash  $runtest | tee -a ${ttype}_test.log
echo "INFO: Gathering single point energies"
echo | tee -a ${ttype}_test.log
echo "INFO: AMBER energies can be found in $testingdir/energies_amber.csv" | tee -a ${ttype}_test.log
echo "INFO: NAMD energies can be found in $testingdir/energies_namd.csv" | tee -a ${ttype}_test.log
if [[ $TESTNAMBER -eq 1 ]];then 
    echo "INFO: NAMBER energies can be found in $testingdir/energies_namd.csv"| tee -a ${ttype}_test.log
fi
echo
bash make_energy_csv.sh 
echo "INFO: Testing complete :)"
echo "INFO: Please check $testingdir/${ttype}_test.log for outliers"
echo "INFO: Summary of energies obtained for each test case can be found in $testdir/\${test case}/energies.csv"
echo 

cd ..

exit 0

