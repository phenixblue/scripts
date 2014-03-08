#!/usr/bin/ksh

#
# PowerVM vSCSI Path Balancing Script
# by: Joe M. Searcy
# email: jmsearcy@gmail.com
#
# 
# This script is used to direct vSCSI path priority to "$VSCSI0" for all even numbered disks, and to
# "$VSCSI1" for all odd number disks. This is to help balance the CPU/Memory load attributed to vSCSI 
# traffic across 2 VIO Servers.
#
#       v1.0 -> 08-16-2012
#               Initial script
#
#

# Variables ######
EVENS="0"
ODDS="1"
TOTDISKS=`lspv | awk '{ print $1 }' | wc -l | sed 's/^ *//'`
TOTDISKS2="$TOTDISKS"
VSCSI0="vscsi0"
VSCSI1="vscsi1"

# Print total number of disks
echo
echo "Total disks in this system: $TOTDISKS"
echo

# Determine even or odd number of disks
let x="$TOTDISKS % 2"

if [ $x -gt 0 ]

		then
		
			ISODD=true
			
		else
		
			ISODD=false
			
fi

# Uncomment for DEBUG
#echo "This is an odd number of disks: $ISODD"
#echo

# Main Routine
if [ $ISODD == true ]

		then
			
			let LASTEVEN="$TOTDISKS - 1"
			let LASTODD="$TOTDISKS"
			
			echo "#### EVEN DISKS ############"
			echo
			
			while [ $EVENS -le $LASTEVEN ]
			
				do
					
					chpath -l hdisk$EVENS -p $VSCSI0 -a priority=1
					chpath -l hdisk$EVENS -p $VSCSI1 -a priority=2
					
					echo "hdisk$EVENS's path for $VSCSI0 is now set to Priority 1"
					
					((EVENS+=2))
					
					if [ $EVENS -gt $LASTEVEN ]
						
						then
						
							echo "No more even numbered disks."
							echo
							echo

						else
							
							echo "The next even numbered disk is \"hdisk$EVENS\""
							echo
							
					fi
					
			done
			
			echo "#### ODD DISKS ############"
			echo
					
			while [ $ODDS -le $LASTODD ]
			
				do
					
					chpath -l hdisk$ODDS -p $VSCSI0 -a priority=2
					chpath -l hdisk$ODDS -p $VSCSI1 -a priority=1
					
					echo "hdisk$ODDS's path for $VSCSI1 is now set to Priority 2"
					
					((ODDS+=2))

					if [ $ODDS -gt $LASTODD ]
						
						then
						
							echo "No more odd numbered disks."
							echo
							echo

						else
						
							echo "The next odd numbered disk is \"hdisk$ODDS\""
							echo							
							
					fi
					
			done
			
		else
		
			let LASTEVEN="$TOTDISKS"
			let LASTODD="$TOTDISKS - 1"
			
			echo "#### EVEN DISKS ############"
			echo
					
			while [ $EVENS -le $LASTEVEN ]
			
				do

					chpath -l hdisk$EVENS -p $VSCSI0 -a priority=1
					chpath -l hdisk$EVENS -p $VSCSI1 -a priority=2
					
					echo "hdisk$EVENS's path for $VSCSI0 is now set to Priority 1"
					
					((EVENS+=2))
					
					if [ $EVENS -gt $LASTEVEN ]
						
						then
						
							echo "No more even numbered disks."
							echo
							echo

						else
							
							echo "The next even numbered disk is \"hdisk$EVENS\""
							echo
							
					fi
					
			done
			
			echo "#### ODD DISKS ############"
			echo
					
			while [ $ODDS -le $LASTODD ]
			
				do
					
					chpath -l hdisk$ODDS -p $VSCSI0 -a priority=2
					chpath -l hdisk$ODDS -p $VSCSI1 -a priority=1
					
					echo "hdisk$ODDS's path for $VSCSI1 is now set to Priority 2"
					
					((ODDS+=2))
					
					if [ $ODDS -gt $LASTODD ]
						
						then
						
							echo "No more odd numbered disks."
							echo
							echo

						else
						
							echo "The next odd numbered disk is \"hdisk$ODDS\""
							echo	
							
					fi
					
			done
			
fi

exit