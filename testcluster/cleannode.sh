node=$1

scontrol update NodeName=$node State=down Reason=hung_proc;
scontrol update NodeName=$node State=resume
