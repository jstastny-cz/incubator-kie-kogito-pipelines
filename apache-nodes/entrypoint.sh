#!/bin/bash
set -e

# cgroup v2: enable nesting
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
	echo "in cgroupv2 branch"
	# move the processes from the root group to the /init group,
	# otherwise writing subtree_control fails with EBUSY.
	# An error during moving non-existent process (i.e., "cat") is ignored.
	sudo mkdir -p /sys/fs/cgroup/init
	sudo bash -c "xargs -rn1 < /sys/fs/cgroup/cgroup.procs > /sys/fs/cgroup/init/cgroup.procs || :"
	# enable controllers
	sudo bash -c "sed -e 's/ / +/g' -e 's/^/+/' < /sys/fs/cgroup/cgroup.controllers > /sys/fs/cgroup/cgroup.subtree_control"
fi


# To make jenkins docker plugin happy container is supposed to process command passed to it and not perform entrypoint first.
# https://github.com/docker-library/official-images#consistency
# Start docker if a shell is opened or docker cmd passed directly
if [[ $# -eq 0 ]] || [[ "$1" = @(sh|bash|docker) ]]; then
	# Start docker and print logs
	start-docker.sh
else
	# Don't produce logs
	start-docker.sh > /dev/null
fi

# process the command passed, only for some (if above) docker is started before
exec "$@"
