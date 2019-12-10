#!/bin/bash

# usage create_snapshot.sh ["subvol"] ["comments"] [device]
# subvol - list of subvolumes - Default: all subvolumes in top level 5
# comments - Default: On demand + your comments or Scheduled when executed by cron / anacron
# device - Default: where root /@ subvolume is mounted 
# use double quotes "" when sending an argument list
#
# Example 1: create_snapshot @home "Snapshot @home only"
# Example 2: create_snapshot "@ @home @opt"  "" /dev/sdb
# Example 3: create_snapshot ""  "NO_DELETE" /dev/sda1 
# NO_DELETE inside comments is used by delete_snapshot script.

[ -z $USER ] && comments="Scheduled" || comments="On demand - $2"   
device=${3:-`grep '/@ ' /proc/mounts | cut -d' ' -f1`}

mountpoint="$(mktemp -d)"

mount "$device" "$mountpoint" || exit 1

function Unmount() {

    local ret=${1:-0}

    umount $mountpoint && rmdir $mountpoint

    exit $ret
}

snapdir=$mountpoint/snapshots/$(date +%Y_%m_%d_%H-%M-%S)

[ -d "$snapdir" ] || mkdir -p "$snapdir" || exit 1

for subvol in ${1:-`ls $mountpoint | grep @`}; do

	btrfs subvolume snapshot $mountpoint/$subvol $snapdir/$subvol && echo -n "$comments" > $snapdir/$subvol/.subvol_comments || Unmount 1

done

exit 0
