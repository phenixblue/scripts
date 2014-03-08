#!/usr/bin/ksh

DEBUG=echo
SRC_DISK=hdisk2
DEST_DISK=hdisk4
LV_LIST="jfslog1_lv mksysb_lv lpp_source spot software"

echo "###### Starting PV Migration for each logical volume ######"
echo

for lv in ${LV_LIST}

	do
	
		echo "# Starting migration of \"$lv\" from ${SRC_DISK} to ${DEST_DISK}...."
		$DEBUG pvmigrate -l $lv ${SRC_DISK} ${DEST_DISK}
		echo "Finished migration...."
		echo
		
done