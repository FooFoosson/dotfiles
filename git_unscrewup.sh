#!/bin/bash


#find . -type f | 
git fsck --lost-found |
	while read line; do
		LINE=$(echo "$line" | tr -d '/') 
		echo "[LOG] checkouting to '${LINE:12}'"
		git checkout -f ${LINE:12}
		ls /home/syrmia/furious-hdd-manager/src/include | egrep 'perf_test_api[.]h$'
		if [[ $? -eq 0 ]] ; then
			echo "Found FILE in commit '${LINE:12}'"1
		fi
	done
