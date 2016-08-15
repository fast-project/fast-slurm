
for s in {1..3}
do
	ssh -t fast-0$s '/cluster/cleanvms.sh'
done
