#!/bin/bash

function usage() {
	echo "Usage: $(basename $0) [build|remove|shell|force-unlock|setup-chroot] --device <device name> [--cpv <[category/]package[-version]>] [--tarball /path/to/stage5-tarball] [--ask] [--once]"
}

basedir="$(dirname $0)"
first_arg="1"

unset action cpv device tarball extra_args
extra_args=( )
while [[ "$1" != "" ]]; do
	if [[ "$1" == "--cpv" ]]; then
		if [[ "$2" == "" ]]; then
			echo "--cpv requires an argument, but none given"
			usage
			exit 255
		fi
		cpv="$2"
		shift
	elif [[ "$1" == "--device" ]]; then
		if [[ "$2" == "" ]]; then
			echo "--device requires an argument, but none given"
			usage
			exit 255
		fi
		device="$2"
		shift
	elif [[ "$1" == "--tarball" ]]; then
		if [[ "$2" == "" ]]; then
			echo "--tarball requires an argument, but none given"
			usage
			exit 255
		fi
		tarball="$2"
		shift
	elif [[ "$1" == "--ask" ]]; then
		extra_args+=( --ask )
	elif [[ "$1" == "--once" ]]; then
		extra_args+=( --once )
	elif [[ "${first_arg}" == "1" ]]; then
		action="${1}"
	else
		echo "argument not understood: $1"
		usage
		exit 255
	fi
	first_arg=""
	shift
done

if [[ "${action}" == "" ]]; then
	action="build"
	echo "action empty, defaulting to ${action}"
fi
if [[ "${device}" == "" ]]; then
	echo "--device required"
	usage
	exit 255
fi
if [[ "${cpv}" == "" ]]; then
	cpv="world"
	echo "cpv empty, defaulting to ${cpv}"
fi

source "${basedir}/config" || exit $?

if [[ "${action}" == "build" || "${action}" == "remove" || "${action}" == "shell" ]]; then
	if [[ ! -d "${build_dir}" ]]; then
		echo "Error: chroot directory doesn't exist: ${build_dir}"
		echo "Run '$(basename $0) setup-chroot' to create this."
		exit 2
	fi
	if [[ "${action}" == "build" ]]; then
		action="add"
	fi
	"${basedir}/modules/build" --action "${action}" --cpv "${cpv}" --build-dir "${build_dir}" --staging-ssh-uri "${staging_ssh_uri}" --staging-ssh-path "${staging_ssh_path}" --mirror-ssh-uri "${mirror_ssh_uri}" --mirror-ssh-path "${mirror_ssh_path}" --mirror-http-uri "${mirror_http_uri}" --lock-ssh-uri "${lock_ssh_uri}" --lock-ssh-path "${lock_ssh_path}" "${extra_args[@]}"
elif [[ "$action" == "force-unlock" ]]; then
	source "${basedir}/modules/lib"
	unlock_mirror "${lock_ssh_uri}" "${lock_ssh_path}"
elif [[ "$action" == "setup-chroot" ]]; then
	if [[ ! -n "${tarball}" ]]; then
		echo "--tarball is required for setup-chroot, but none given"
		usage
		exit 255
	fi

	"${basedir}/modules/setup-chroot" --build-dir "${build_dir}" --tarball "${tarball}" --tarball-is-stage5 --timezone-path "${timezone_path}"
else
	echo "action not understood: ${action}"
	usage
	exit 255
fi
