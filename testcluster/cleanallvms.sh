
for s in {1..4}
do
	ssh fast-0$s 'sudo /cluster/cleanvms.sh'
done
