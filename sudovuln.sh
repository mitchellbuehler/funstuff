#!/bin/sh
##
## Script Name: installed_applications.sh
## Purpose: To query the list of installed applications on
##          a Linux system.
##

#@INCLUDE=utils/os/linux_package_manager.sh
#@INCLUDE=utils/os/linux-abort-if-rpm-locked.sh
#@INCLUDE=utils/os/linux_os_generation.sh

#@START_INCLUDES_HERE
#------------ INCLUDES START - Do not edit between this line and INCLUDE ENDS -----
#- Begin file: utils/os/linux-abort-if-rpm-locked.sh
# Abort the process if an RPM lock is in place.

# To include this file, copy/paste: INCLUDE=utils/os/linux-abort-if-rpm-locked.sh

__db_locks() {
	_stat_command="$1"
	_stat_directory="$2"

	cd "$_stat_directory" && \
		"$_stat_command" -CA 2>/dev/null | \
		awk '/Locks grouped by lockers/{flag=1;next}/Locks grouped by object/{flag=0}flag' | \
		grep -v 'Count Status' | \
		grep -v '=-=-=-=-=-=-=-=-=-=' | \
		grep -q .
}

__rpm_is_locked() {
	echo "TSE-Error: RPM is locked by another process"
	exit
}

AbortIfRpmLocked() {
	_rpmdb_stat="/usr/lib/rpm/rpmdb_stat"

	if ! command -v rpm >/dev/null 2>/dev/null ; then
		return
	fi

	if [ ! -d /var/lib/rpm ] ; then
		return
	fi

	if [ -x "$_rpmdb_stat" ] ; then
		if __db_locks "$_rpmdb_stat" "/var/lib/rpm" ; then
			__rpm_is_locked
		fi

		return
	fi

	if ps -eo pid,comm,args | grep -v grep | grep -q '[ \/]rpm' ; then
		__rpm_is_locked
	fi
}

#- End file: utils/os/linux-abort-if-rpm-locked.sh
#- Begin file: utils/os/linux_package_manager.sh
# Used to return the type of package manager a Linux distribution uses

# To include this file, copy/paste: INCLUDE=utils/os/linux_package_manager.sh

linux_package_manager () {
	LINUX_TYPE=unknown
	if [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
		if grep -qi 'CentOS' /etc/redhat-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'Red Hat' /etc/redhat-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'Fedora' /etc/redhat-release; then
			LINUX_TYPE=rpm
		fi
	elif [ -f /etc/oracle-release ]; then
		if grep -qi 'Oracle' /etc/oracle-release; then
			LINUX_TYPE=rpm
		fi
	elif [ -f /etc/SuSE-release ]; then
		if grep -qi 'SUSE' /etc/SuSE-release; then
			LINUX_TYPE=rpm
		fi
	elif [ -f /etc/system-release ]; then
		# this branch includes RedHat, CentOS, Fedora, and Oracle also,
		# but they should have all been caught by the earlier checks
		if grep -qi 'Amazon Linux' /etc/system-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'Red Hat' /etc/system-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'CentOS' /etc/system-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'Fedora' /etc/system-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'Oracle' /etc/system-release; then
			LINUX_TYPE=rpm
		fi
	fi

	if [ "$LINUX_TYPE" = "unknown" ] && [ -f /etc/os-release ]; then
		if grep -qi 'Amazon Linux' /etc/os-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'CentOS' /etc/os-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'Red Hat' /etc/os-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'SUSE' /etc/os-release; then
			LINUX_TYPE=rpm
		elif grep -qi 'Ubuntu' /etc/os-release; then
			LINUX_TYPE=deb
		elif grep -qi 'Debian' /etc/os-release; then
			LINUX_TYPE=deb
		fi
	fi

	if [ "$LINUX_TYPE" = "unknown" ] && [ -f /usr/bin/lsb_release ]; then
		if lsb_release -d | grep -qi 'CentOS'; then
			LINUX_TYPE=rpm
		elif lsb_release -d | grep -qi 'Red Hat'; then
			LINUX_TYPE=rpm
		elif lsb_release -d | grep -qi 'SUSE'; then
			LINUX_TYPE=rpm
		elif lsb_release -i | grep -qi 'Ubuntu'; then
			LINUX_TYPE=deb
		elif lsb_release -i | grep -qi 'Debian'; then
			LINUX_TYPE=deb
		elif lsb_release -d | grep -qi 'Oracle'; then
			LINUX_TYPE=rpm
		fi
	fi
	echo "$LINUX_TYPE"
}

#- End file: utils/os/linux_package_manager.sh
#- Begin file: utils/os/linux_os_generation.sh
# Used when a very precise Linux os name must be produced. Basis for
# the OS Generation sensor.

# To include this file, copy/paste: INCLUDE=utils/os/linux_os_generation.sh

_os_release() {
	os_release_id=$(__os_release_id)
	case $os_release_id in
		ubuntu)
			echo "$(__os_release_name) $(__os_release_version_id)"
			;;
		centos)
			echo "$(__os_release_name) $(__os_release_version_id)" | sed -e 's/ Linux//'
			;;
		debian)
			echo "Debian $(__os_release_version_id)"
			;;
		ol)
			__os_release_pretty_name | sed -e "$_delete_minor_version"
			;;
		rhel)
			echo "$(__os_release_name) $(__os_release_version_id)" | sed -e "$_delete_server_substring" -e "$_delete_minor_version"
			;;
		amzn)
			pretty_name=$(__os_release_pretty_name)
			if echo "$pretty_name" | grep -qi ami; then
				echo 'Amazon Linux'
			else
				echo "$pretty_name"
			fi
			;;
		opensuse-tumbleweed*)
			__os_release_pretty_name
			;;
		opensuse-leap)
			__os_release_pretty_name | sed -e "$_delete_minor_version"
			;;
		opensuse)
			__os_release_pretty_name | sed -e "s/.*\(opensuse [0-9][0-9]*\).*/\1/i"
			;;
		*sles*|*sled*|*caasp*)
			__os_release_pretty_name | sed -e "$_delete_service_pack" -e "$_delete_minor_version" -e "$_delete_trailing_whitespace"
			;;
		*)
			pretty_name=$(__os_release_pretty_name)
			if [ -n "$pretty_name" ]; then
				echo "Not-Normalized: $pretty_name"
			fi
			;;
	esac
}

__os_release_id() {
	grep -e '^ID=' "$OS_RELEASE" | awk -F= '{ print $2 }' | tr -d '"' | sed -e "$_delete_trailing_whitespace"
}

__os_release_name() {
	grep -e '^NAME=' "$OS_RELEASE" | awk -F= '{ print $2 }' | tr -d '"' | sed -e "$_delete_trailing_whitespace"
}

__os_release_version_id() {
	grep -e '^VERSION_ID=' "$OS_RELEASE" | awk -F= '{ print $2 }' | tr -d '"' | sed -e "$_delete_trailing_whitespace"
}

__os_release_pretty_name() {
	grep -e '^PRETTY_NAME=' "$OS_RELEASE" | awk -F= '{ print $2 }' | tr -d '"' | sed -e "$_delete_trailing_whitespace"
}

_oracle_release() {
	sed -e "$_delete_release_substring" -e "$_delete_minor_version" "$ORACLE_RELEASE"
}

_redhat_release() {
	sed -e "$_delete_release_substring" -e "$_delete_server_substring" -e "$_delete_trailing_paren_contents" -e "$_delete_trailing_whitespace" -e "$_delete_minor_version" "$REDHAT_RELEASE"
}

_debian_version() {
	version=$(sed -e "$_only_major_version" "$DEBIAN_VERSION")
	echo "Debian $version"
}

_delete_trailing_paren_contents='s/\(^.*\)(.*$/\1/'
_delete_trailing_whitespace='s/\s\s*$//'
_delete_release_substring='s/\s\s*release\s\s*/ /i'
_delete_server_substring='s/\s\s*server\s\s*/ /i'
_delete_minor_version='s/\([0-9][0-9]*\)\.[0-9][0-9]*$/\1/'
_delete_service_pack='s/sp[0-9][0-9]*$//i'
_only_major_version='s/^\([0-9][0-9]*\).*$/\1/'

output() {
	if [ -n "$1" ]; then
		echo "$1"
	else
		echo "Not-Normalized: Unknown Linux"
	fi
}

operating_system_generation() {
	OS_RELEASE="$1"
	ORACLE_RELEASE="$2"
	REDHAT_RELEASE="$3"
	DEBIAN_VERSION="$4"

	[ -z "$OS_RELEASE" ] && OS_RELEASE=/etc/os-release
	[ -z "$ORACLE_RELEASE" ] && ORACLE_RELEASE=/etc/oracle-release
	[ -z "$REDHAT_RELEASE" ] && REDHAT_RELEASE=/etc/redhat-release
	[ -z "$DEBIAN_VERSION" ] && DEBIAN_VERSION=/etc/debian_version

	# order of operations matters here
	[ -f $OS_RELEASE ] && output "$(_os_release)" && return 0
	[ -f $ORACLE_RELEASE ] && output "$(_oracle_release)" && return 0
	[ -f $REDHAT_RELEASE ] && output "$(_redhat_release)" && return 0
	[ -f $DEBIAN_VERSION ] && output "$(_debian_version)" && return 0
	output # fallback to default
}
#- End file: utils/os/linux_os_generation.sh
#------------ INCLUDES END - Do not edit above this line and INCLUDE STARTS -----



PACKAGE_MANAGER=`linux_package_manager`
OS_GENERATION=`operating_system_generation`
INSTALLED_SUDO=""

#get installed sudo version
if [ "rpm" = "$PACKAGE_MANAGER" ]; then
	if hash rpm 2>/dev/null #rpm based solutions
	then
		AbortIfRpmLocked
		
		INSTALLED_SUDO=rpm -q sudo --queryformat "%{VERSION}.%{RELEASE}\n"
	fi
elif [ "deb" = "$PACKAGE_MANAGER" ]; then
	#implement logic here if systems in environment use debian based distribution
	echo "Not applicable for Debian based distributions"
	exit
else
	echo "Unknown Linux Distribution"
	exit
fi

#check if installed sudo version is vulnerable, per OS generation
if [ "CentOS 7" = "$OS_GENERATION" ]; then
	INSTALLED_SUDO="$INSTALLED_SUDO" | sed 's/.el7*//'
	if [ "1.8.23.10" = "$INSTALLED_SUDO" ]; then
		echo "False"
	else
		echo "True"
	fi
fi
	
#implement additional logic here for other distributions, based on the applicable fix version for each OS



