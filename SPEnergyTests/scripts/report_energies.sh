#!/bin/bash

tripept=$1

mkdir -p $tripept
cd $tripept

enerlog=energies.csv

declare -A Energies
declare -A NamdColumns
NamdColumns[BOND]=3
NamdColumns[ANGLE]=4

if [[ $USECMAP -eq 1 ]];then
    contributions=(BOND ANGLE DIHED CMAP ELECT VDW EPtot)
    Nrow=7
    NamdColumns[DIHED]=7
    NamdColumns[CMAP]=6
    NamdColumns[VDW]=9
    NamdColumns[ELECT]=8
    NamdColumns[EPtot]=15
else
    contributions=(BOND ANGLE DIHED ELECT VDW EPtot)
    Nrow=6
    NamdColumns[DIHED]=6
    NamdColumns[VDW]=8
    NamdColumns[ELECT]=7
    NamdColumns[EPtot]=14
fi

if [[ $TESTNAMBER -eq 1 ]];then
    softwares=(amber namd namber)
    Ncol=3
    fmatstr="%10s\t%10s\t%10s"
else
    softwares=(amber namd)
    Ncol=2
    fmatstr="%10s\t%10s"
fi

for ener in ${contributions[@]};do
    for sw in ${softwares[@]};do
	if [[ $sw == ${softwares[0]} ]];then
	    if [[ $ener != 'VDW' && $ener != 'ELECT' ]];then
		Energies[$ener,$sw]=$(awk -v pat=$ener '$0~pat {for (i=1;i<=NF;i++) {if($i==pat) printf $(i+2)}}' $sw/nve.info)
	    elif [[ $ener == 'VDW' ]];then
		Energies[$ener,$sw]=$(awk '/VDWAALS/ {s=$4+$11}END{print s}' $sw/nve.info)
	    else
		Energies[$ener,$sw]=$(awk '/EEL/ {if($1=="EELEC"){s+=$3} else {s+=$8}}END{print s}' $sw/nve.info)
	    fi
	else
	    if [[ $ener == 'DIHED' ]];then
 		Energies[$ener,$sw]=$(awk -v col=${NamdColumns[$ener]} '/^ENERGY:/ {print $5+$(col)}' $sw/nve.log)
	    else
		Energies[$ener,$sw]=$(awk -v col=${NamdColumns[$ener]} '/^ENERGY:/ {print $(col)}' $sw/nve.log)
	    fi
	fi
    done
done

echo "##### ENERGY SUMMARY FOR: $tripept ###############" > $enerlog
printf "%-10s\t" "ENERGY" >> $enerlog 
for sw in ${softwares[@]};do
    printf "%.10s\t\t" "${sw^^}" >> $enerlog 
done
printf "\n" >> $enerlog 
for ener in ${contributions[@]};do
    printf "%-10s" $ener >> $enerlog 
    for sw in ${softwares[@]};do
	printf "%10s\t" "${Energies[$ener,$sw]}" >> $enerlog 
    done
    printf "\n" >> $enerlog 
done
printf "\n" >> $enerlog 
printf "%-10s\t" "ENERGY" >> $enerlog 
for sw in ${softwares[@]};do
    printf "%.10s\t\t" "${sw^^}" >> $enerlog 
done
printf "\n" >> $enerlog 
for ener in ${contributions[@]};do
    printf "%-10s" ${ener}_DIFF >> $enerlog 
    for sw in ${softwares[@]};do
	diff=$(echo "${Energies[$ener,${softwares[0]}]} ${Energies[$ener,$sw]})"| awk '{print ($1-$2)}')
	printf "%10s\t" "$diff" >> $enerlog
	testdiff=$(echo $diff | awk -v tol=0.0002 '{ if ($1>tol || $1<-tol) {print 1} else {print 0}}')
	
	if [[ !($sw == ${softwares[1]} && ($ener == "ELECT" || $ener == "EPtot")) ]];then
	    if [[ $testdiff -eq 1 ]]; then
		echo "WARNING: $tripept shows significant energy deviations in $ener energy for ${sw^^} test"
	    fi
	fi
    done
    printf "\n" >> $enerlog 
done


exit
