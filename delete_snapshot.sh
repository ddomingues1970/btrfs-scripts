#!/bin/bash
# DELETE ONE SNAPSHOT BY SUBVOLID
# usage delete_snapshot.sh subvolid [device]
# subvolid - ID of snapshot to be deleted. 
# Get the ID using the listsubvolumes script or execute the command btrfs subvolume list /
# device - optional -  Default is where @ root subvolume is monted.

# Arguments
declare -i subvolid=${1:?"Invalid subvolid"}
device=${2:-`grep -m1 '/@ ' /proc/mounts | cut -d' ' -f1`}

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
path=$(btrfs subvolume list $mountpoint | while read c1 id c3 c4 c5 c6 c7 c8 path; do    	
    [ $id -eq $subvolid ] && echo $path && break   		
done) 

# Validating 
[ -z $path ] && echo "Snapshot source ID $subvolid not found." && Unmount 1
[  $(echo $path | grep -v -c snapshot) -eq 1 ] && echo "Source ID $path is not a snapshot." && Unmount 1


while true; do
        read -p "Delete ID $subvolid - $path? (y/n) " yn
        case $yn in
        [Yy]* ) 
        
                btrfs subvolume delete -c $mountpoint/$path
                
                break;;
        [Nn]* ) Unmount;;
        * ) echo "Please answer yes or no."		
        ;;
        esac
done

Unmount

exit 1