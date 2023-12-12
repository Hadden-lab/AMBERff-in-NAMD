#!/bin/bash
dirs=$(ls -d */)

if [[ $TESTNAMBER -eq 1 ]];then
    namddirs=(namd namber)
else
    namddirs=(namd)
fi

if [[ $USECMAP -eq 1 ]]; then
    Energies="Residue,Bond,Angle,Torsion,Cmap,Electrostatics,VDW,Total"
    echo $Energies > energies_amber.csv
    (for res in $dirs;do
	 cmapPresent=$(grep 'CMAP' $res/amber/nve.info)
	 if [[ -n $cmapPresent ]];then
	     echo "${res%/},`tail -n+3 $res/amber/nve.info |tr '\n' ' '|awk -F" " '{printf "%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f",$12,$15,$18,$27,$35+$41,$31+$38,$9}'`">>energies_amber.csv
	 else
	     echo "${res%/},`tail -n+3 $res/amber/nve.info |tr '\n' ' '|awk -F" " '{printf "%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f",$12,$15,$18,0.0,$26+$32,$22+$29,$9}'`">>energies_amber.csv
	 fi
     done)&

    for ext in ${namddirs[@]};do
	echo $Energies > energies_${ext}.csv
	(for res in $dirs;do
	     echo "${res%/},`awk -F" " '/^ENERGY:/ {printf "%.10f,%.10f,%.10f,%.10f,%.10f,%.10f,%.10f", $3,$4,$5+$7,$6,$8,$9,$15}' $res/$ext/nve.log`" >> energies_${ext}.csv
	 done)&
    done

else
    Energies="Residue,Bond,Angle,Torsion,Electrostatics,VDW,Total"
    (for res in $dirs;do
	 echo "${res%/},`tail -n+3 $res/amber/nve.info |tr '\n' ' '|awk -F" " '{printf "%.10f,%.10f,%.10f,%.10f,%.10f,%.10f",$12,$15,$18,$26+$32,$22+$29,$9}'`">>energies_amber.csv
     done)&
    
    for ext in ${namddirs[@]};do
	echo $Energies > energies_${ext}.csv
	(for res in $dirs;do
	     echo "${res%/},`awk -F" " '/^ENERGY:/ {printf "%.10f,%.10f,%.10f,%.10f,%.10f,%.10f", $3,$4,$5+$6,$7,$8,$14}' $res/$ext/nve.log`" >> energies_${ext}.csv
	 done)&
    done

fi


wait

exit 0

