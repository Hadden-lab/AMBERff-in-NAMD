#!/bin/bash

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


residues=$(awk '/RESI/ {print $2}' $ffdir/$Artf)
echo
echo "INFO: Found the following residues for testing:"
echo "INFO: $residues" |tr "\n" " "
echo

for RES in $residues; do
    export RES
    (bash build_sp_amber.sh $RES || buildfailure AMBER $RES
     bash build_sp_namd.sh namd $NAMDBIN $RES  || buildfailure NAMD $RES
     if [[ $TESTNAMBER -eq 1 ]]; then
	 bash build_sp_namd.sh namber $NAMBERBIN $RES  || buildfailure NAMBER $RES
     fi
     bash report_energies.sh $RES )&  
done
wait

exit 0

