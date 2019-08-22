#!/bin/bash

for mach in $(lxc-ls -f | egrep 'RUNNING.*eb-group' | cut -d ' ' -f1)
do
	echo
	echo "<<<" $mach ">>>"
	echo

	lxc-attach -n $mach -- /root/eb_scripts/update_debian.sh
done
