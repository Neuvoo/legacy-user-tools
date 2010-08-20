#!/bin/bash

function usage() {
	echo
	echo "Usage: $(basename $0) --device <device name> -- <module name> [<module arg> ...]"
	echo
	echo "List of modules:"
	module_list "${MODULES_BASEDIR}" | while read module; do
		echo " * ${module}"
	done
	echo
	echo "Execute a module with --help to retrieve module-specific usage."
}

export BASEDIR="$(dirname $0)"
export CONF_BASEDIR="${BASEDIR}/conf"
export LIB_BASEDIR="${BASEDIR}/lib"
export MODULES_BASEDIR="${BASEDIR}/modules"
export TMP_BASEDIR="$(mktemp -d)"

trap 'source ${LIB_BASEDIR}/hooks
      echo
      echo "Pre-exit cleaning..."
      execute_hooks exit
      rm -r "${TMP_BASEDIR}"' 0
# the following handler will exit the script on receiving these signals
# the trap on "0" (EXIT) from above will be triggered by this trap's "exit" command
trap 'echo "Killed." >&2
      exit 1' 1 2 3 15

source "${LIB_BASEDIR}/modules" || exit $?

unset module args device
args=( )
while [[ "$1" != "" ]]; do
	if [[ "${module}" == "" ]]; then
		if [[ "$1" == "--device" ]]; then
			device="${2}"
			shift
		elif [[ "$1" == "--help" ]]; then
			usage
			exit 255
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

if ! source "${CONF_BASEDIR}/global.config"; then
	echo "Error: failed to load global configuration!" >&2
	echo "You can create an empty configuration, but it is much easier to fill it out." >&2
	exit 1
fi

"${MODULES_BASEDIR}/_exec-module" "${module}" "${args[@]}" || exit $?
