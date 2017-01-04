#!/bin/bash

#intel performance counter monitor tools
intelfolder=/cluster/intel/IntelPerformanceCounterMonitor-V2.11.1

#contains the configure
sinstall=/cluster/slurm-install/configs/KPIs

#this specific node
node=$(hostname)

mcores=$sinstall/logs/$node"_cores_main.txt"
mmem=$sinstall/logs/$node"_mem_main.txt"

outf=$sinstall/KPI$node".txt"

rm $mcores
rm $mmem
rm $outf

while [ -f $mcores ] || [-f $mmem ] || [ -f $outf ]
do
  sleep 1
done

rm -f $mmem $mcores

#for cleanup when job is killed
trap 'jobs -p | xargs kill' EXIT


#changes the env variables, and keeps the changes in the calling script
. $intelfolder/env.sh

#$intelfolder/pcm.x -ns -nsys -r /csv=$mcores  &
$intelfolder/pcm.x -ns -nsys -r /csv > $mcores  &
CPID=$(echo $!)

$intelfolder/pcm-memory.x          /csv > $mmem   &
MPID=$(echo $!)


#wait for the files to be ready
while [ $(wc -l < $mmem) -lt 2 ] || [ $(wc -l < $mcores) -lt 2 ]; do
	sleep 1
	echo "Waiting for files to be ready"
done


coresHead=$(head -n 2 $mcores)
memHead=$(head -n 2 $mmem)


echo "Ready"


while [ 1 -eq 1 ]; do

sleep 5


cores=$(sed '1d' $mcores)
mem=$(sed '1d' $mmem)
#cores="$coresHead\n"$(cat $mcores | tail -n 5)
#mem="$memHead\n"$(cat $mmem | tail -n 5)

#echo -e "$mem"
#echo -e "$cores" | awk -F';' -v col='Mem Read (MB/s)' 'NR==1{for(i=1;i<=NF;i++){if($i==col){c=i;break}} print $c} NR>1{print $c}'
# tail -n 5 $mcores | awk  '{ print $NF-2 }'

echo -e "$coresHead" > $mcores
echo -e "$memHead" > $mmem



#sleep 2

#avg nominal IPC of assigned cores
rawdata=$( echo -e "$cores" |  awk -F';' 'NR==1{for(i=1; i<=NF; i++) if ($i=="EXEC") {a[i]++;} } { for (i in a) printf "%s ", $i; printf "\n"}')

#socket 1
s1IPC=$(echo -e "$rawdata" |	 cut -d' ' -f2-17 | sed '1d' | awk '{for(i=1;i<=NF;i++) t+=$i; print t/16; t=0}' | \
			awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')
#socket 2
s2IPC=$( echo -e "$rawdata" | cut -d' ' -f18-33 | sed '1d' | awk '{for(i=1;i<=NF;i++) t+=$i; print t/16; t=0}' | \
			awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

#do L3 stuff
rawdata=$( echo -e "$cores" |  awk -F';' 'NR==1{for(i=1; i<=NF; i++) if ($i=="L3MISS") {a[i]++;} } { for (i in a) printf "%s ", $i; printf "\n"}')

#socket 1
s1L3=$(echo -e "$rawdata" |	 cut -d' ' -f2-17 | sed '1d' | awk '{for(i=1;i<=NF;i++) t+=$i; print t/16; t=0}' | \
			awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

#socket 2
s2L3=$( echo -e "$rawdata" | cut -d' ' -f18-33 | sed '1d' | awk '{for(i=1;i<=NF;i++) t+=$i; print t/16; t=0}' | \
			awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')


#do L2 stuff
rawdata=$( echo -e "$cores" |  awk -F';' 'NR==1{for(i=1; i<=NF; i++) if ($i=="L2HIT") {a[i]++;} } { for (i in a) printf "%s ", $i; printf "\n"}')

#socket 1
s1L2=$(echo -e "$rawdata" |	 cut -d' ' -f2-17 | sed '1d' | awk '{for(i=1;i<=NF;i++) t+=$i; print t/16; t=0}' | \
			awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')
#socket 2
s2L2=$( echo -e "$rawdata" | cut -d' ' -f18-33 | sed '1d' | awk '{for(i=1;i<=NF;i++) t+=$i; print t/16; t=0}' | \
			awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')

#Mem Read (MB/s) Mem Write (MB/s) Mem Write (MB/s)
rawdata=$( echo -e "$mem" |  awk -F';' 'NR==1{for(i=1; i<=NF; i++) if ($i=="Mem Read (MB/s)") {a[i]++;} } { for (i in a) printf "%s ", $i; printf "\n"}')

s1BW=$( echo -e "$rawdata" | awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')
s2BW=$( echo -e "$rawdata" | awk '{ sum += $2; n++ } END { if (n > 0) print sum / n; }')


# Read Memory
BW=$( echo -e "$mem" |  awk -F';' 'NR==1{for(i=1; i<=NF; i++) if ($i=="Read") {a[i]++;} } { for (i in a) printf "%s ", $i; printf "\n"}' | \
		 awk '{ sum += $1; n++ } END { if (n > 0) print sum / n; }')


#print all single values
#printf " s1IPC: $s1IPC \n s2IPC: $s2IPC \n s1L3: $s1L3 \n s2L3: $s2L3 \n"
#printf " s1L2: $s1L2 \n s2L2: $s2L2 \n s1BW: $s1BW \n s2BW: $s2BW \n BW: $BW \n"

s1BW=${s1BW%.*}
s2BW=${s2BW%.*}
BW=${BW%.*}

printf " s1IPC: $s1IPC \n s2IPC: $s2IPC \n s1L3: $s1L3 \n s2L3: $s2L3 \n" > $outf
printf " s1L2: $s1L2 \n s2L2: $s2L2 \n s1BW: $s1BW \n s2BW: $s2BW \n BW: $BW \n" >> $outf



done


kill -9 $CPID  $MPID
