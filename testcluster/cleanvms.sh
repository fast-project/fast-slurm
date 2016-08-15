virsh list --all | grep vm[0-9] | awk {'print $2'} | while read line
do
   # do something with $line here
	virsh destroy $line
	virsh undefine $line
done
