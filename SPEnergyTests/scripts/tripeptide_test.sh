#!/bin/bash


#Artf=/mnt/biostore/santolinezc/forcefields_2_distribute/ff14SB/ff14SB.rtf
#ttype=tripeptide
cp $script_dir/build_sp_*.sh $script_dir/report_energies.sh .

buildfailure () {
    echo "ERROR: ${1^^} single point energies failed on $2 check ${ttype}_test.log and  "
    echo "ERROR: `pwd`/${2}/${1,,} log files for more information."
    if [[ $IGNOREERRORS -ne 1 ]];then 
	if [[ -z $TESTPID ]];then
	    kill -- -$$
	else
	    kill -- -$TESTPID
	fi
    
	exit 1
    fi
}


residues=$( awk '/RESI/ {print $2}' $ffdir/$Artf)
NTERS=($( awk '/PATCH/ {print $3}' $ffdir/$Artf))
CTERS=($( awk '/PATCH/ {print $5}' $ffdir/$Artf))
echo
echo "INFO: Found the following residues for testing:"
echo "INFO: $residues" |tr "\n" " "
echo
if [[ $ttype == "tripeptide" ]]; then
    nresidues=${residues/NME/}
    nresidues=${nresidues/NHE/}
    cresidues=${residues/ACE/}

    residues=${residues/NME/}
    residues=${residues/NHE/}
    residues=${residues/ACE/}
fi

for RESN in  $nresidues; do
    export RESN
    for RES in $residues; do
	export RES
	echo "Testing $RESN-$RES-* combinations"
	for RESC in $cresidues; do
	    export RESC
	    (bash build_sp_amber.sh $RESN $RES $RESC || buildfailure AMBER $RESN-$RES-$RESC
	     bash build_sp_namd.sh namd $NAMDBIN $RESN $RES $RESC || buildfailure NAMD $RESN-$RES-$RESC
	     if [[ $TESTNAMBER -eq 1 ]]; then
		 bash build_sp_namd.sh namber $NAMBERBIN $RESN $RES $RESC || buildfailure NAMBER $RESN-$RES-$RESC
	     fi
	     bash report_energies.sh $RESN-$RES-$RESC )&
	    
	done
	wait
    done
done

exit 0

