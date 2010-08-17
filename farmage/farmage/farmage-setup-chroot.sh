#!/bin/bash

source "$(dirname $0)/farmage-lib.sh"

function usage() {
	echo "Usage: $(basename $0) --build-dir [/path/to/chroot/] --tarball [/path/to/tarball] --timezone-path [/usr/share/zoneinfo/timezone] [--tarball-is-stage5]"
}

while [[ "$1" != "" ]]; do
	if [[ "$1" == "--build-dir" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		build_dir="${2}"
		shift
	elif [[ "$1" == "--tarball" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		tarball="${2}"
		shift
	elif [[ "$1" == "--timezone-path" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		timezone_path="${2}"
		shift
	elif [[ "$1" == "--tarball-is-stage5" ]]; then
		tarball_is_stage5="1"
	else
		echo "$1 not understood"
		usage
		exit 255
	fi
	shift
done

if [[ ! -n "${build_dir}" ]]; then
	echo "--build-dir required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${tarball}" ]]; then
	echo "--tarball required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${timezone_path}" ]]; then
	echo "--timezone-path required, but none given"
	usage
	exit 255
fi

if [[ "${tarball}" == *stage5* ]]; then
	tarball_is_stage5="1"
else
	echo "WARNING: this may not be a stage5 tarball!"
	echo "Please cancel this if you are not using a stage5 tarball, unless you know what you're doing!"
	sleep 5
fi

if [[ ! -n "${tarball_is_stage5}" ]]; then
	echo "--tarball ought to reference a stage5 tarball, or whichever has the most packages."
	echo "If you are certain the tarball specified is a the right one, append --tarball-is-stage5 to arguments"
	usage
	exit 255
fi

vrun mkdir "${build_dir}" && \
vrun tar -xvpf "${tarball}" -C "${build_dir}" && \
vrun chmod +rx "${build_dir}" && \
vrun ln -sf "${timezone_path}" "${build_dir}/etc/localtime"
exit $?