#!/bin/bash

# usage list_subvolumes [device]
# device - Default where root /@ subvolume is mounted 

device=${1:-`cat /proc/mounts | grep "/@" | head -1 | cut -d' ' -f1`}

mountpoint="$(mktemp -d)"

declare -i is_mounted=$(lsblk | grep sda1 | grep $mountpoint | wc -l)

mount $device $mountpoint
	
if [ $? -ne 0 ]; then
	exit 1
fi

subvols=$(btrfs subvolume list $mountpoint)

declare -i len=0
declare -i header=0

echo "$subvols" | while read c1 c2 c3 c4 c5 c6 c7 c8 c9; do
	
	h2=ID; h4=GEN; h7=TL; h9=PATH; h10=COMMENTS 
	test $header -gt 0 || (printf "%-4s %-6s %-2s %-40s %-45s \n" $h2 $h4 $h7 $h9 $h10; true) && header=1
	
	test $len -lt ${#c9} && len=${#c9} 
	
	comments=""	
			
	comments_file="$mountpoint/$c9/.subvol_comments"
	
	if [ -f "$comments_file" ]; then
		comments="$(cat $comments_file | tr -s ' ')"
		true
	fi	
	
	printf "%-4s %-6s %-2s %-40s %-45s \n" "$c2" "$c4" "$c7" "$c9" "$comments"
		
done 

umount $mountpoint && rmdir $mountpoint

exit 0
