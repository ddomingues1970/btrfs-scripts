#!/bin/bash

# usage delete_snapshot.sh [count] [device]
# count: Snapshots to keep (grouped by date). Default: 7

count=${1:-7}

# Get the default device where root is mounted
device=${2:-`grep '/@ ' /proc/mounts | cut -d' ' -f1`}

mountpoint="$(mktemp -d)"
    
mount $device $mountpoint || exit 1

# List snapshots grouping by date
declare -i dt_count=0
for dt in $(btrfs subvolume list $mountpoint | grep snapshots | cut -d/ -f2 | cut -d_ -f1-3 | sort -r | uniq); do
    
    # Only count snapshots inside a directory with a standart name YYYY_MM_DD
    ref_date=$(date --date=${dt//_/-} +%s) && dt_count=$(($dt_count+1))
        
    [ $dt_count -eq $count ] && break
                    
done

declare -i no_delete_flag=0
for snapshot in $(btrfs subvolume list $mountpoint | grep snapshots | cut -d' ' -f9); do
                        
        # Get snapshot date using the directory name
        dt=${snapshot:10:10}
                
        # Only check snapshots inside a directory with a standart name YYYY_MM_DD
        snapshot_date=$(date --date=${dt//_/-} +%s) || continue            
                        
        no_delete_flag=$(grep -c "NO_DELETE" "$mountpoint/$snapshot/.subvol_comments") || no_delete_flag=0
        
        # If snapshot date is lower (older) than or equal the reference date and there is no NO_DELETE flag, delete the snapshot
        [ $snapshot_date -lt $ref_date ] && [ $no_delete_flag -eq 0 ] && btrfs subvolume delete -c $mountpoint/$snapshot	
                
        # If snapshot directory is empty, remove it        
        [ $(ls $mountpoint/${snapshot%%@*} | wc -l) -eq 0 ] && rmdir $mountpoint/${snapshot%%@*}        
              
done

umount $mountpoint && rmdir $mountpoint

exit 0