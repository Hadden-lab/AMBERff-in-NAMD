#!/bin/bash

error () {
    echo "ERROR: $1"
    exit 1
}

minFailure () {
    return 1 
}
TLEAP=$AMBERHOME/bin/tleap
PMEMD=$AMBERHOME/bin/pmemd
PMEMDCUDA=$AMBERHOME/bin/pmemd.cuda_DPFP

if [[ "$#" -eq 3 ]]; then
    RESN=$1
    RES=$2
    RESC=$3
    tripept=$RESN-$RES-$RESC



    residues=$( awk '/RESI/ {print $2}' $ffdir/$Artf)
    NTERS=($( awk '/PATCH/ {print $3}' $ffdir/$Artf))
    CTERS=($( awk '/PATCH/ {print $5}' $ffdir/$Artf))
    i=0
    declare -A nterpatch cterpatch
    for res in $residues ; do
	nterpatch[$res]=${NTERS[$i]}
	cterpatch[$res]=${CTERS[$i]}
	i=$((i+1))
    done

    chrn=0
    chrc=0
    c1=${nterpatch[$RESN]}
    if [[ $c1 == "NONE" ]]; then c1=$RESN;chrn=1; fi
    c2=${cterpatch[$RESC]}
    if [[ $c2 == "NONE" ]]; then c2=$RESC;chrc=1; fi
elif [[ "$#" -eq 1 ]];then
    RES=$1
    tripept=$RES
fi

mkdir -p $tripept
cd $tripept
mkdir amber
cd amber

cat > build.tleap << EOF
addPath $cmdpath
source $Aleaprc
x = sequence {$c1 $RES $c2}
set x box { 48 48 48 }
savepdb x bf_min.pdb
saveamberparm x leapout.prmtop bf_min.rst7
quit
EOF

cat > writepdb.tcl << EOF
mol new leapout.prmtop waitfor all
mol addfile min.rst7 type netcdf waitfor all
set sel [atomselect top "all" frame last]
\$sel writepdb min.pdb
quit
EOF

cat > min.mdin << EOF
Minimize system using SD/CG at NVE
# Fingers crossed 
 &cntrl
 imin = 1,
 ntp = 0, ntb = 1,
 ntmin = 1, maxcyc = 200, ncyc = 50,
 ntwx = 100, ntpr = 100,
 /
EOF
cat > rebuild.tleap << EOF
addPath $cmdpath
source $Aleaprc
x = loadpdbUsingSeq min.pdb  {$c1 $RES $c2}
savepdb x leapout.pdb
saveamberparm x leapout.prmtop leapout.rst7
quit
EOF

cat > nve.mdin <<EOF
Production MD NVE
&cntrl
ntx=1, irest=0,
ntc=1, ntf=1, tol=1.0e-8,
nstlim=0, dt=0.002,
ntpr=1, ntwx=0, ntwr=0,
cut=999.0, fswitch=0,
ntt=0, ntb=0, ntp=0,
ioutfm=1, ntave=1000,
jfastw=0,igb=6,
/
&ewald
ew_type=0,
vdwmeth=0,
eedmeth=1,
/
EOF

$TLEAP -f build.tleap > leap.log || error "tleap failed to build system"
MINFAILED=0
$PMEMD -O -i min.mdin -p leapout.prmtop -c bf_min.rst7 -o min.out -r min.rst7 -x min.nc -inf min.info || MINFAILED=1
if [[ $MINFAILED -eq 1 ]]; then
    echo "WARNING: AMBER minimization failed on $1, attempting single point energy test without minimizing"
    cp bf_min.rst7 min.rst7
    sed -i 's/netcdf/rst7/g' writepdb.tcl
fi
$VMDBIN -dispdev text -e writepdb.tcl > vmd.log || error "Unable to write minimized PDB"
$TLEAP -f rebuild.tleap >> leap.log || error "tleap failed to build minimized system"
inputcrd=leapout.rst7

$PMEMDCUDA -O -i nve.mdin -p leapout.prmtop -c $inputcrd -o nve.out -r nve.rst7 -x nve.nc -inf nve.info || error "AMBER single point energy calculation failed"

exit 0
