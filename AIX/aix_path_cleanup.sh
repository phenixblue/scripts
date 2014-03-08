#!/usr/bin/ksh

# AIX Path Cleanup Script

DEBUG=echo

# Store HDISK names with Missing paths
HDISKLIST=`lspath | grep Missing | awk '{print $2}' | sort -u`

# Gather Info to CYA
lspath > /tmp/lspath.out
lspath -F "name path_id parent status" > /tmp/lspath2.out

for disk in ${HDISKLIST}
	do
		echo
		echo "##########################################"
		echo "Working on ${disk} now...."
		echo "##########################################"
		echo
		MISSINGPATHS=`lspath -l ${disk} -H -F "name parent path_id connection status" | grep Missing | awk '{print $3}'`
		
		for pathid in ${MISSINGPATHS}
			do
				echo "Removing PATH ID \"${pathid}\" for ${disk} now...."
				
				${DEBUG} rmpath -d -l ${disk} -i ${pathid}
				
				# Validate Path ID was successfully removed
				echo "Validating path removal...."
				echo
				
				PATHRMSUCCESS=`lspath -l ${disk} -H -F "path_id" | grep -x ${pathid} | wc -l`
				
				if [ ${PATHRMSUCCESS} -gt 0 ]
					then
						echo "!!!! The path was NOT removed successfully !!!!"
					else
						echo "The path was removed successfully"
				fi
				
				echo
		done		
done