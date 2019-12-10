#!/bin/bash

# usage restore_snapshot.sh subvolid_src subvolid_dest [device]
# subvolid_src - ID of source snapshot to restore from. 
# subvolid_dest - ID of destination subvolume to restore to.
# Get the IDs using listsubvolumes script or execute the command btrfs subvolume list /
# device - optional -  Default is where @ root subvolume is monted.

# Arguments
declare -i subvolid_src=${1:?"Invalid subvolid_src"}
declare -i subvolid_dest=${2:?"Invalid subvolid_dest"}
device=${3:-`grep '/@ ' /proc/mounts | cut -d' ' -f1`}

# Mounting the file system
mountpoint="$(mktemp -d)"
mount $device $mountpoint || exit 1

# Exit point
function Unmount() {
    local ret=${1:-0}
    umount $mountpoint && rmdir $mountpoint
    exit $ret
}

# Searching the paths of the IDs
path_src=$(btrfs subvolume list $mountpoint | while read c1 id c3 c4 c5 c6 c7 c8 path; do    	
    [ $id -eq $subvolid_src ] && echo $path && break   		
done) 
path_dest=$(btrfs subvolume list $mountpoint | while read c1 id c3 c4 c5 c6 c7 c8 path; do    	
    [ $id -eq $subvolid_dest ] && echo $path && break   		
done) 

# Validating 
[ $subvolid_src -eq $subvolid_dest ] && echo "Source ID $subvolid_src and destination ID $subvolid_dest are the same." && Unmount 1
[ -z $path_src ] && echo "Snapshot source ID $subvolid_src not found." && Unmount 1
[ -z $path_dest ] && echo "Subvolume destination ID $subvolid_dest not found." && Unmount 1
[  $(echo $path_src | grep -v -c snapshot) -eq 1 ] && echo "Source ID $path_src is not a snapshot." && Unmount 1
[  $(echo $path_dest | grep -c snapshot) -eq 1 ] && echo "Destination ID $path_dest is a snapshot." && Unmount 1
[ ${path_src##*'/'} != $path_dest ] && echo "Source ID $subvolid_src (${path_src##*'/'}) and destination ID $subvolid_dest ($path_dest) are diferent subvolumes" && Unmount 1

# Create a snapshot (backup) before restoring.
./create_snapshot.sh $path_dest "Before restoring from $subvolid_src." $device && btrfs subvolume delete -c $mountpoint/$path_dest && btrfs subvolume snapshot $mountpoint/$path_src $mountpoint/$path_dest && echo "Restored from $subvolid_src" > $mountpoint/$path_dest/.subvol_comments

Unmount

exit 1