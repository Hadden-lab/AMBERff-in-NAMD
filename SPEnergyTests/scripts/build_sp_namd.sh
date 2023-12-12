#!/bin/bash

namdtype=$1
namdbin=$2
if [[ "$#" -eq 5 ]];then
    RESN=$3
    RES=$4
    RESC=$5
    tripept=$RESN-$RES-$RESC
    terpatches=""
elif [[ "$#" -eq 3 ]];then
    RES=$3
    tripept=$RES
    terpatches="first None;last None"
else
    echo "ERROR: Wrong number of arguments there are "$#" arguments,they are $@"
    exit 1 
fi

error () {
    echo "ERROR: $1"
    exit 1
}
mkdir -p $tripept/$namdtype
cd $tripept/$namdtype
if [[ $namdtype == "namd" ]]; then
    cat > build.tcl <<EOF
package require psfgen
topology $ffdir/$Artf
mol new ../amber/leapout.prmtop waitfor all
mol addfile ../amber/leapout.rst7 waitfor all
set prt [atomselect top all]
\$prt set segname PRT
\$prt writepdb PRT.pdb
segment PRT { pdb PRT.pdb;$terpatches}
regenerate angles dihedrals
coordpdb PRT.pdb
guesscoord
writepsf psfgen.psf
writepdb psfgen.pdb
quit
EOF
fi

if [[ $USECMAP -eq 1 ]];then
    cmapterm="no"
else
    cmapterm="yes"
fi

cat > nve.conf <<EOF
structure       psfgen.psf
coordinates     psfgen.pdb
#
#
#
source		 $ffdir/$NAMDRC
restartfreq         1
dcdfreq             1
xstFreq             1
outputEnergies      1
outputPressure      0
outputname          nve
temperature         0
amber          off
rigidBonds     None
rigidTolerance 1.0e-8
cutoff         999.0
pairlistdist   1000.0
switching      off
exclude        scaled1-4
readexclusions yes
1-4scaling     0.83333333
mergeCrossterms $cmapterm
#
timestep            2.00
nonbondedFreq       1
fullElectFrequency  1
stepspercycle       10
langevin            off
langevinPiston      off
PME                 off
PMETolerance        1.0e-6
PMEInterpOrder      4
FFTWUseWisdom       no
PMEGridSizeX        48
PMEGridSizeY        48
PMEGridSizeZ        48
binaryOutput 	    off
run       	    0
EOF

if [[ $namdtype == "namd" ]];then
    if [[ !( -f "../amber/leapout.rst7") ]]; then
        error "AMBER structure not found for comparison"
    fi
	
    $VMDBIN -dispdev text -e build.tcl > vmd.log || error "Unable to build PSF"
elif [[ $namdtype == "namber" ]];then
    if [[ !( -f "../namd/psfgen.psf") ]];then
	error "No PSF file found"
    fi
    cp ../namd/psfgen.* .
else
    error "namdtype $namdtype not supported"
fi
$namdbin nve.conf > nve.log || error "${namdtype^^} single point energy calculation failed"


exit 0
