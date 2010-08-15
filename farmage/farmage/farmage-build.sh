#!/bin/bash

source "$(dirname $0)/farmage-lib.sh"

function usage() {
	echo "Usage: $(basename $0) --action [add|remove|add-world|remove-world] --cpv [category/package-version] --build-dir [/path/to/chroot/] --staging-ssh-uri [user@host] --staging-ssh-path [/path/to/staging] --mirror-ssh-uri [user@host] --mirror-ssh-path [/path/to/mirror] --mirror-http-uri [http://host/path/to/mirror] --lock-ssh-uri [user@host] --lock-ssh-path [/path/to/lock]"
}

while [[ "$1" != "" ]]; do
	if [[ "$1" == "--cpv" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		cpv="${2}"
		shift
	elif [[ "$1" == "--action" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		action="${2}"
		shift
	elif [[ "$1" == "--build-dir" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		build_dir="${2}"
		shift
	elif [[ "$1" == "--lock-ssh-uri" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		lock_ssh_uri="${2}"
		shift
	elif [[ "$1" == "--lock-ssh-path" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		lock_ssh_path="${2}"
		shift
	elif [[ "$1" == "--staging-ssh-uri" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		staging_ssh_uri="${2}"
		shift
	elif [[ "$1" == "--staging-ssh-path" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		staging_ssh_path="${2}"
		shift
	elif [[ "$1" == "--mirror-ssh-uri" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		mirror_ssh_uri="${2}"
		shift
	elif [[ "$1" == "--mirror-ssh-path" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		mirror_ssh_path="${2}"
		shift
	elif [[ "$1" == "--mirror-http-uri" ]]; then
		if [[ "$2" == "" ]]; then
			usage
			exit 255
		fi
		mirror_http_uri="${2}"
		shift
	else
		echo "$1 not understood"
		usage
		exit 255
	fi
	shift
done

if [[ ! -n "${cpv}" ]]; then
	echo "--cpv required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${action}" ]]; then
	action="add"
	echo "--action empty, using default ${action}"
fi
if [[ ! -n "${build_dir}" ]]; then
	echo "--build-dir required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${lock_ssh_uri}" ]]; then
	echo "--lock-ssh-uri required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${lock_ssh_path}" ]]; then
	echo "--lock-ssh-path required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${staging_ssh_uri}" ]]; then
	echo "--staging-ssh-uri required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${staging_ssh_path}" ]]; then
	echo "--staging-ssh-path required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${mirror_ssh_uri}" ]]; then
	echo "--mirror-ssh-uri required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${mirror_ssh_path}" ]]; then
	echo "--mirror-ssh-path required, but not given"
	usage
	exit 255
fi
if [[ ! -n "${mirror_http_uri}" ]]; then
	echo "--mirror-http-uri required, but not given"
	usage
	exit 255
fi

binpkg_dir="/binpkgs"

trap 'takedown_chroot "${build_dir}"
      if [[ "${lock_acquired}" == "1" ]]; then unlock_mirror "${lock_ssh_uri}" "${lock_ssh_path}"; fi' 0
# the following handler will exit the script on receiving these signals
# the trap on "0" (EXIT) from above will be triggered by this trap's "exit" command
trap 'echo "Killed." >&2
      exit 1' 1 2 3 15

lock_mirror "${lock_ssh_uri}" "${lock_ssh_path}" || exit $?
lock_acquired="1"

setup_chroot "${build_dir}" || exit $?

cat > "${build_dir}/chroot.run" <<EOF
#!/bin/bash
env-update && source /etc/profile

export PKGDIR="${binpkg_dir}"
export DISTDIR="/tmp/distdir"
export PORTAGE_BINHOST="${mirror_http_uri}"
emerge --sync -v
emerge -GuDNv world system || exit $?
cp -v "${binpkg_dir}/.world" /var/lib/portage/world || exit $?
EOF

if [[ "${action}" == "add" ]]; then
	cat >> "${build_dir}/chroot.run" <<EOF
emerge -bgDNv "${cpv}" || exit $?
revdep-rebuild || exit $?
EOF
elif [[ "${action}" == "remove" ]]; then
	cat >> "${build_dir}/chroot.run" <<EOF
emerge --depclean "${cpv}" || exit $?
EOF
elif [[ "${action}" == "remove-world" ]]; then
	cat >> "${build_dir}/chroot.run" <<EOF
emerge --deselect "${cpv}" || exit $?
EOF
elif [[ "${action}" == "add-world" ]]; then
	cat >> "${build_dir}/chroot.run" <<EOF
emerge --select "${cpv}" || exit $?
EOF
else
	echo "Error: action not understood: ${action}"
	usage	
	exit 255
fi

cat >> "${build_dir}/chroot.run" <<EOF
cp -v /var/lib/portage/world ${binpkg_dir}/.world || exit $?
EOF

rsync_args=( -cav --progress --delete --exclude='.lock' --exclude='.staging' )

rsync "${rsync_args[@]}" "${mirror_ssh_uri}":/"${mirror_ssh_path}"/ "${build_dir}/${binpkg_dir}"/ && \
vrun chroot "${build_dir}" /bin/bash /chroot.run && \
rsync "${rsync_args[@]}" "${build_dir}/${binpkg_dir}"/ "${staging_ssh_uri}":/"${staging_ssh_path}"/ && \
ssh "${mirror_ssh_uri}" rsync "${rsync_args[@]}" "${staging_ssh_path}"/ "${mirror_ssh_path}"

exit $?
