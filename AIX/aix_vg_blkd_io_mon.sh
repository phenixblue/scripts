#!/usr/bin/ksh

TARGETVG=test_vg
POLL_INTERVAL=5
CUR_BLK_COUNT=`lvmo -v ${TARGETVG} -a | grep pervg_blocked | awk -F= '{print $2}'`
DATE=`date +"%r | %m-%d-%Y"`

clear
echo "The current number of blocked I/O's is: ${CUR_BLK_COUNT} (${DATE})"

while [ ${CUR_BLK_COUNT} -gt 0 ]
	do
		sleep ${POLL_INTERVAL}
		
		NEW_BLK_COUNT=`lvmo -v ${TARGETVG} -a | grep pervg_blocked | awk -F= '{print $2}'`
	
		if [ ${NEW_BLK_COUNT} == ${CUR_BLK_COUNT} ]

			then
			
				NEW_BLK_COUNT=${CUR_BLK_COUNT}
				#echo "No change."
				

				
			else
			
				NEW_BLK_COUNT=`lvmo -v ${TARGETVG} -a | grep pervg_blocked | awk -F= '{print $2}'`
				IO_DIFF=`echo "${NEW_BLK_COUNT} - ${CUR_BLK_COUNT}" | bc`
				DATE=`date +"%r | %m-%d-%Y"`
				echo "The current number of blocked I/O's is: ${CUR_BLK_COUNT}. This is a change of ${IO_DIFF} I/O's (${DATE})"
				
		fi
		
done