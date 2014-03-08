#!/usr/bin/ksh

#
# AIX Path Refresh Script
# by: Joe M. Searcy
# email: jmsearcy@gmail.com
#
# This script is meant to be used as a utility to refresh paths from a specific controller
# within an AIX system. Originally developed for an issue where paths failed and would not 
# enable through regular methods. This will loop through all controllers with known paths
# and remove paths one by one for each hdisk, followed by recursively removing the controller.
# The script then scans the controller and paths back in. The script will skip any controllers 
# that supply 100% of enabled paths for any given hdisk.
#
#
#       v0.1 -> 02-07-2014
#               Initial Script
#

# Set DEBUG to nothing to actually perform destructive commands
DEBUG=echo

# Store HDISK names with Missing paths
#HDISKLIST=`lspath | awk '{print $2}' | sort -u`
FSCSILIST=`lspath | awk '{print $3}' | sort -u`

# Gather Info to CYA
lspath > /tmp/lspath.out
lspath -F "name path_id parent status" > /tmp/lspath2.out


hdisk_path_check () {

	# Track number of times we loop
	LOOPTIMES=1
	
	for disk in ${FSCSIDISKS}
		do
			# Disk path quantity variables
			TOTPATHS=`lspath -l ${disk} | wc -l`
			FSCSIPATHS=`lspath -l ${disk} | grep ${fscsictrl} | wc -l`
			FAILPATHS=`lspath -l ${disk} | grep -v ${fscsictrl} | grep -i failed | wc -l`
			MISSPATHS=`lspath -l ${disk} | grep -v ${fscsictrl} | grep -i missing | wc -l`
			ENABLEDPATHS=`lspath -l ${disk} | grep -v ${fscsictrl} | grep -i enabled | wc -l`

			echo "${disk}  	${TOTPATHS} 	${FSCSIPATHS}	${FAILPATHS} 	${MISSPATHS} 	${ENABLEDPATHS}"
			
			# Make sure disk has other good paths and update RMDISKLIST accordingly
			if [ ${ENABLEDPATHS} -ge 1 ]
				then
					#Check to see if this is the first loop or not for setting RMDISKLIST
					if [ ${LOOPTIMES} -eq 1 ]
						then 
								RMDISKLIST="${disk}"
						else
								RMDISKLIST="${RMDISKLIST} ${disk}"
					fi
			fi
			
			# Increment our loop counter
			((LOOPTIMES+=1))
					
	done
	
	# If all disks have good paths through another controller, continue with remove

	
	# Format FSCSIDISKS for comparison
	FSCSIDISKS=`echo ${FSCSIDISKS} | tr -d "[\n]"`
	
	# 
	if [ "${RMDISKLIST}" == "${FSCSIDISKS}" ]
		then
			controller_remove "${RMDISKLIST}"
		else
			echo
			echo "!!!! There aren't enough \"enabled\" paths on other controllers to continue !!!!"
			echo
	fi

}

controller_remove () {

	echo
	echo "It looks like you have plenty of good paths on other controllers....moving on"
	echo
	echo "Are you ready to remove all paths and the controller?"
	echo "Please answer \"Y/y\" or \"N/n\": "
	read continue_answer
	
	if [ ${continue_answer} == "Y" ] || [ ${continue_answer} == "y" ] || [ ${continue_answer} == "Yes" ] || [ ${continue_answer} == "yes" ]
		then
			echo
			echo "Disabling paths for \"${disk}\" on controller \"${fscsictrl}\" now..."
			
			# Disable and remove the paths
			for rmhdisk in ${RMDISKLIST}
				do
					${DEBUG} chpath -l ${disk} -p ${fscsictrl} -s disable
					${DEBUG} rmpath -dl ${disk} -p ${fscsictrl}
					
			done
			
			# Remove the controller recursively
			${DEBUG} rmdev -Rdl ${fscsictrl}
			validate_scan "${fscsictrl}" "${disk}" "${FSCSIPATHS}"
			
	elif [ ${continue_answer} == "N" ] || [ ${continue_answer} == "n" ] || [ ${continue_answer} == "No" ] || [ ${continue_answer} == "no" ]
		then
			echo
			echo "You selected to NOT continue, moving on..."
			
	elif [ ${continue_answer} == "Q" ] || [ ${continue_answer} == "q" ] || [ ${continue_answer} == "Quit" ] || [ ${continue_answer} == "quit" ]
		then
			echo
			echo "You selected to quit...Peace out!"
			echo
			exit 0
			
	else
		echo
		echo "You did not supply a valid option, bailing out."
		exit 1
	fi
}

validate_scan () {
	
	# Validate the controller was successfully removed
	if [ `lsdev -Cc driver -t efscsi | awk '{print $1}' | grep ${fscsictrl}` ]
		then
			
			echo
			echo "It doesn't look like the controller was removed...Please check things under the hood..."
			echo
			exit 2
			
		else	
			echo
			echo "Controller was successfully removed...Scanning now..."
			
			# Scan for new hardware
			cfgmgr 2>&1 >/dev/null
			
			# Validate the controller was scanned back in successfully
			if [ `lsdev -Cc driver -t efscsi | awk '{print $1}' | grep ${fscsictrl}` ]
				then
					echo
					echo "Controller is back! Checking for paths..."
					NEWPATHS=`lspath -l ${disk} -p ${fscsictrl} | grep -i enabled | wc -l`
					
					# Compare new paths to original paths
					if [ ${NEWPATHS} -eq ${FSCSIPATHS} ]
						then
							echo
							echo "All paths are back! Moving on..."
						else
							echo
							echo "All paths are NOT back...Please check under the hood"
							echo
							exit 3
					fi
					
				else
					echo
					echo "The controller is NOT back...Please check under the hood"
					echo
					exit 4
				fi
	fi		
}


for fscsictrl in ${FSCSILIST}
	do
		echo
		echo "############################################################################################"
		echo "Working on ${fscsictrl} now...."
		echo "############################################################################################"
		echo
		# Gather disks with paths off of controller ${fscsictrl}
		FSCSIDISKS=`lspath | grep " ${fscsictrl}" | awk '{print $2}' | sort -u`
		echo "These disks have paths on controller \"${fscsictrl}\""
		echo
		echo "Disk\t\tTot. Paths\tPaths on\tFailed Paths\tMissing Paths\tEnabled Paths"
		echo "\t\t\t\t\"${fscsictrl}\"\ton other\ton other\ton other"
		echo "============================================================================================"
		hdisk_path_check "${FSCSIDISKS}"
		
done

exit 0
