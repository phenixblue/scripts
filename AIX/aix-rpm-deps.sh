#!/bin/bash

#
# AIX RPM Dependency Script
# by: Joe M. Searcy
# email: jmsearcy@gmail.com
#
# This script is used to determine dependencies for a specified rpm on AIX. This script requires the following
# to be installed outside of native AIX packages: wget
#
# This script also requires connectivity to "http://www.oss4aix.org" and its sub-directories.
#
# This ocncept is based off of information on "http://www.perzl.org/aix/index.php?n=FAQs.FAQs#rpm-dependency-hell"
#
#	Usage: aix-rpm-deps.sh [ -d ] -r <rpm>
#
#		-d	specified in order to also download dependent rpm's
#		-r	Specified along with the target rpm to solve dependencies for
#
#	v1.0 -> 05-15-2014
#		Initial script
#

#### Variables ####
AIX_VERS="aix61"
TARGET_DIR="/tmp/aix_rpm_deps_`date '+%m%d%Y_%H%M'`"
RPM_DIR="${TARGET_DIR}/rpm"
TMP_DIR="${TARGET_DIR}/tmp"
RPM_LIST="${TMP_DIR}/rpm.txt"
RPM_TMP_LIST="${TMP_DIR}/rpm.tmp.txt"
DEPS_LIST="${TMP_DIR}/deps.txt"
LS=/bin/ls
CAT=/bin/cat
ECHO=/bin/echo
GREP=/bin/grep
MKDIR=/bin/mkdir
AWK=/usr/bin/awk
SED=/bin/sed
SORT=/usr/bin/sort
WGET=/usr/bin/wget
# Don't touch these, they are set later on
DEPS=
RPM=

#### Functions ####

usage() {

	${ECHO}
	${ECHO} -e "\tUsage: $0 [ -d ] -r <rpm>" 1>&2
	${ECHO}
	exit 1

}

get_options() {

	while getopts ":dr:h" opt; do
	
		case $opt in
			d)
				OPT_D="TRUE"
				;;
			r)
				OPT_R="TRUE"
				r_value=${OPTARG}
				;;
			h)
				usage
				exit 1
				;;
			\?)
				${ECHO}
				${ECHO} -e "\tInvalid option: -$OPTARG" >&2
				${ECHO}
				exit 1
				;;
			:)
				${ECHO}
				${ECHO} -e "\tOption -$OPTARG requires an argument." >&2
				${ECHO}
				exit 1
				;;
			*)
				usage
				exit 1
				;;
		esac
	done
	
	PACKAGE=`/bin/echo ${r_value} | sed 's/.rpm//'`
	BASE_DEPS="${PACKAGE}.deps"
	
}

create_dirs() {

	for dir in "${TARGET_DIR}" "${RPM_DIR}" "${TMP_DIR}"
		
		do

			if [ -d ${dir} ]; then
			
					${ECHO} "Directory \"${dir}\" already exists."
					
			else
				
				${MKDIR} -p ${dir}
					
				if [ -d ${DIR} ]; then
						
					${ECHO} "Directory \"${dir}\" has been created successfully."
					
				else
					
					${ECHO} "Directory \"${dir}\" was NOT created, check under the hood. #### ERROR ####"
						
					exit 1
					
				fi
				
			fi
			
	done

}

rpm_to_deps() {

	${ECHO} ${1} | ${SED} 's/\(^.*\)rpm/\1deps/'

}

deps_to_rpm() {

	${ECHO} ${1} | ${SED} 's/\(^.*\)deps/\1rpm/'

}

download_deps() {
	
	${WGET} -q -P ${TARGET_DIR} http://www.oss4aix.org/download/rpmdb/deplists/${AIX_VERS}/${1}
	
	${CAT} ${TARGET_DIR}/${1} | ${SORT} -u > ${RPM_TMP_LIST}

	RPM=`deps_to_rpm "${1}"`
	
	for rpm in `${CAT} ${RPM_TMP_LIST} | ${SORT} -u | ${GREP} -v ${RPM}`
	
		do
		
			DEPS=`rpm_to_deps "${rpm}"`
				
			if [ -f ${TARGET_DIR}/${DEPS} ]; then
			
				${ECHO} "Dependency list for \"${rpm}\"  has already been downloaded."
				
				continue
				
			else
			
				${ECHO} "Dependency list for \"${rpm}\"  has been downloaded."
				
				download_deps "${DEPS}"
				
			fi
			
	done
	
}

build_rpm_list() {

	${ECHO} "Building Dependency list."
	
	${CAT} ${TARGET_DIR}/*.deps | ${SORT} -u > ${RPM_LIST}

	for top_rpm in `${LS} ${TARGET_DIR}/*deps | ${AWK} -F/ '{print $4}'`
		do
			TOP_LEVEL_RPM=`deps_to_rpm "${top_rpm}"`

			if [ `${GREP} "${TOP_LEVEL_RPM}" ${RPM_LIST} | wc -l` -lt 1 ]; then
				echo "${TOP_LEVEL_RPM}" >> ${RPM_LIST}
			fi
	done
}

download_rpm_list() {
	
	${ECHO} "Downloading rpm's now."
	
	${WGET} -q -P ${RPM_DIR} -B http://www.oss4aix.org/download/everything/RPMS/ -i ${RPM_LIST}

}

#### Start Main ####

# Grab options from user
get_options "$@"

if [ "${OPT_R}" = "TRUE" ] && [ "${OPT_D}" = "TRUE" ]; then

	# Create the working directory
	create_dirs

	# Download RPM dependencies
	download_deps "${BASE_DEPS}"

	# Build the RPM list
	build_rpm_list
	
	# Download the rpm's
	download_rpm_list
	
elif [ "${OPT_R}" = "TRUE" ]; then
	
		# Create the working directory
	create_dirs

	# Download RPM dependencies
	download_deps "${BASE_DEPS}"

	# Build the RPM list
	build_rpm_list
	
else

	usage
	exit 1
	
fi
