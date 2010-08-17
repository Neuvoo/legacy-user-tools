#!/bin/bash

function vrun () {
	local args
	args=( "${@}" )
	echo "Executing \"${args[@]}\"..."
	"${args[@]}"
	return $?
}

function setup_chroot() {
	local build_dir
	if [[ "$1" == "" ]]; then
		echo "Usage: takedown_chroot </path/to/chroot>"
		return 255
	fi
	build_dir="${1}"

	vrun mount --bind /proc "${build_dir}"/proc && \
	vrun mount --bind /sys "${build_dir}"/sys && \
	vrun mount --bind /dev/pts "${build_dir}"/dev/pts && \
	vrun cp -L /etc/resolv.conf "${build_dir}"/etc/ # && \
#	vrun mount --bind /usr/portage "${build_dir}"/usr/portage # should be handled by emerge --sync within chroot
	return $?
}

function takedown_chroot() {
	local build_dir
	if [[ "$1" == "" ]]; then
		echo "Usage: takedown_chroot </path/to/chroot>"
		return 255
	fi
	build_dir="${1}"

#	vrun umount "${build_dir}"/usr/portage && \
	vrun umount "${build_dir}"/dev/pts && \
	vrun umount "${build_dir}"/sys && \
	vrun umount "${build_dir}"/proc
	return $?
}

function lock_mirror () {
	local lock_ssh_uri lock_ssh_path
	if [[ "$2" == "" ]]; then
		echo "Usage: lock_mirror <user@host> </remote/path/to/lock>"
		return 255
	fi
	lock_ssh_uri="${1}"
	lock_ssh_path="${2}"

	echo "Locking mirror..."
	output="$(ssh ${lock_ssh_uri} '( [[ ! -d '"${lock_ssh_path}"' ]] && mkdir '"${lock_ssh_path}"' 2>/dev/null && echo '\'`uname -a`\'' > '"${lock_ssh_path}"'/host ) || echo $?' 2>/dev/null || echo local:$?)"
	if [[ -n "$output" ]]; then
		echo "Error acquiring lock:";
		echo "$output"
		return 1
	fi
}

function unlock_mirror () {
	local lock_ssh_uri lock_ssh_path
	if [[ "$2" == "" ]]; then
		echo "Usage: lock_mirror <user@host> </remote/path/to/lock>"
		return 255
	fi
	lock_ssh_uri="${1}"
	lock_ssh_path="${2}"

	echo "Unlocking mirror..."
	ssh "${lock_ssh_uri}" rm -r "${lock_ssh_path}"
	return $?
}
