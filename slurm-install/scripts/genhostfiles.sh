#!/bin/bash



Aa=$(echo "obase=16; $((0xF00 ))" | bc | tail -c 3)


for i in {0..255}
do
	Aa=$(echo "obase=16; $((0xF$Aa + 0x01))" | bc | tail -c 3)
	Bb=$(echo "obase=10; $(( 0x$Aa ))" | bc)
	ip="192.168.168."$Bb
	name="vm"$Bb
	echo $ip $name

done

