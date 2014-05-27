#!/usr/bin/ksh

#
# AIX Path Cleanup Script
# by: Joe M. Searcy
# email: jmsearcy@gmail.com
#
# This script is used to clean up missing/failed paths from an AIX system. The missing/failed paths are usually
# a result of a physical move, or an install from a mksysb where previous devices were not cleaned up.
#
#       v1.1 -> 05-20-2014
#               Replaced "grep" statements with the "-s" flag for the lspath command to filter out missing/failed paths
#				Added the "PATHSTATUS" variable to make path filtering more flexible
#				Added script header info and change log
#

#### VARIABLES ####

# By default "DEBUG=echo". This allows for testing prior to actually removing the paths. Set "DEBUG=" to actually remove the paths.
DEBUG=echo
# By default "PATHSTATUS=missing". You can change "missing" to "failed" to remove failed paths instead.
PATHSTATUS=missing
# Store HDISK names with Missing paths
HDISKLIST=`lspath -s ${PATHSTATUS} | awk '{print $2}' | sort -u`


#### Gather Info to CYA ####
lspath > /tmp/lspath.out
lspath -F "name path_id parent status" > /tmp/lspath2.out

#### Start main loop ####
for disk in ${HDISKLIST}
	do
		echo
		echo "##########################################"
		echo "Working on ${disk} now...."
		echo "##########################################"
		echo
		MISSINGPATHS=`lspath -l ${disk}  -s ${PATHSTATUS} -F "name parent path_id connection" | awk '{print $3}'`
		
		for pathid in ${MISSINGPATHS}
			do
				echo "Removing PATH ID \"${pathid}\" for ${disk} now...."
				
				${DEBUG} rmpath -d -l ${disk} -i ${pathid}
				
				# Validate Path ID was successfully removed
				echo "Validating path removal...."
				echo
				
				PATHRMSUCCESS=`lspath -l ${disk} -F "path_id" | grep -x ${pathid} | wc -l`
				
				if [ ${PATHRMSUCCESS} -gt 0 ]
					then
						echo "!!!! The path was NOT removed successfully !!!!"
					else
						echo "The path was removed successfully"
				fi
				
				echo
		done		
done
