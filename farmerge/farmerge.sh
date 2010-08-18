#!/bin/bash

function usage() {
	echo
	echo "Usage: $(basename $0) --device <device name> -- <module name> [<module arg> ...]"
	echo
	echo "List of modules:"
	module_list "${MODULES_BASEDIR}" | while read module; do
		echo " * ${module}"
	done
}

export BASEDIR="$(dirname $0)"
export CONF_BASEDIR="${BASEDIR}/conf"
export LIB_BASEDIR="${BASEDIR}/lib"
export MODULES_BASEDIR="${BASEDIR}/modules"

source "${LIB_BASEDIR}/modules"

unset module args device
args=( )
while [[ "$1" != "" ]]; do
	if [[ "${module}" == "" ]]; then
		if [[ "$1" == "--device" ]]; then
			device="${2}"
			shift
		elif [[ "$1" == "--" ]]; then
			module="${2}"
			shift
		else
			echo "Error: argument not understood: ${1}"
			usage
			exit 255
		fi
	else
		args+=( "${1}" )
	fi
	shift
done

if [[ "${device}" == "" ]]; then
	echo "Error: --device must be specified"
	usage
	exit 255
fi
if [[ "${module}" == "" ]]; then
	echo "Error: a module must be specified"
	usage
	exit 255
fi

export DEVICE="${device}"
export DEVICE_BASEDIR="${basedir}/${device}"

source "${CONF_BASEDIR}/global.config" || echo "Warning: failed to load global configuration!"

"${MODULES_BASEDIR}/_exec-module" "${module}" "${args[@]}" || exit $?
