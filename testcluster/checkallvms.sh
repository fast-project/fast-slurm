
for s in {1..4}
do
	echo "VMs on fast-0$s"
	ssh fast-0$s '(. /cluster/libvirt-1.3.3/bin/set_environment.sh; virsh list)'
done
