#!/bin/bash

source "$(dirname $0)/farmage-lib.sh"

function usage() {
	echo "Usage: $(basename $0) --action [shell|add|remove] --cpv [category/package-version] --build-dir [/path/to/chroot/] --staging-ssh-uri [user@host] --staging-ssh-path [/path/to/staging] --mirror-ssh-uri [user@host] --mirror-ssh-path [/path/to/mirror] --mirror-http-uri [http://host/path/to/mirror] --lock-ssh-uri [user@host] --lock-ssh-path [/path/to/lock] [--ask] [--once]"
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
	elif [[ "$1" == "--ask" ]]; then
		ask="1"
	elif [[ "$1" == "--once" ]]; then
		once="1"
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
dist_dir="/tmp/distdir"
rsync_args=( -cav --progress --delete --exclude='.lock' --exclude='.staging' )

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
EOF

cat "$(dirname $0)/farmage-lib.sh" >> "${build_dir}/chroot.run"

cat >> "${build_dir}/chroot.run" <<EOF
export PKGDIR="${binpkg_dir}"
export DISTDIR="${dist_dir}"
export PORTAGE_BINHOST="${mirror_http_uri}"
export USE="bindist"

# Initial setup required before any action
which layman 2>&1 > /dev/null && vrun layman -S || exit \$?
vrun emerge --sync -v # || exit \$? # squashfs-hooks messes up this exit thing. :/
vrun emerge -GuDNv world system || exit \$?
EOF

# Bug: there has to be at least one argument here
emerge_args=( -v )

if [[ "${ask}" == "1" ]]; then
	emerge_args+=( -a )
fi
if [[ "${once}" == "1" ]]; then
	emerge_args+=( -1 )
fi

if [[ "${action}" == "shell" ]]; then
	cat >> "${build_dir}/chroot.run" <<EOF
echo "You can now edit ${build_dir}/.* files"
echo "Exit when finished"
vrun bash --login
EOF

elif [[ "${action}" == "add" ]]; then
	cat >> "${build_dir}/chroot.run" <<EOF
vrun emerge "${emerge_args[@]}" -bguDN "${cpv}" || exit \$?
vrun revdep-rebuild || exit \$?
EOF

elif [[ "${action}" == "remove" ]]; then
	cat >> "${build_dir}/chroot.run" <<EOF
vrun emerge "${emerge_args[@]}" --depclean "${cpv}" || exit \$?
vrun revdep-rebuild || exit \$?
EOF

else
	echo "Error: action not understood: ${action}"
	usage	
	exit 255
fi

# Sync mirror to local
vrun rsync "${rsync_args[@]}" "${mirror_ssh_uri}":/"${mirror_ssh_path}"/ "${build_dir}"/"${binpkg_dir}"/ || exit $?

# Copy mirror's files into place
vrun cp -v "${build_dir}"/"${binpkg_dir}/.world" "${build_dir}"/var/lib/portage/world || exit $?
vrun rsync --delete -av "${build_dir}"/"${binpkg_dir}/.portage/" "${build_dir}"/etc/portage/ || exit $?

echo "Entering chroot"
vrun chroot "${build_dir}" /bin/bash /chroot.run; exit_status="$?"
echo "Exiting chroot"

if [[ "${exit_status}" != "0" ]]; then exit "${exit_status}"; fi

# Copy file into local mirror copy
vrun cp -v "${build_dir}"/var/lib/portage/world "${build_dir}"/"${binpkg_dir}"/.world || exit $?
vrun rsync --delete -av "${build_dir}"/etc/portage/ "${build_dir}"/"${binpkg_dir}/.portage/" || exit $?

# Sync local mirror copy to staging
vrun rsync "${rsync_args[@]}" "${build_dir}"/"${binpkg_dir}"/ "${staging_ssh_uri}":/"${staging_ssh_path}"/ || exit $?
# Copy staging into place on mirror
vrun ssh "${mirror_ssh_uri}" rsync "${rsync_args[@]}" "${staging_ssh_path}"/ "${mirror_ssh_path}" || exit $?
