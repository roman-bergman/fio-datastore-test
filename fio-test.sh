#!/bin/env sh

#    DATE: 2023-10-06
#  AUTHOR: Roman Bergman <roman.bergman@protonmail.com>
# RELEASE: 0.0.1
# LICENSE: AGPL-3.0

#DEFINE
disk = $1

if [ ! $disk ] {
    echo "Disk not set!"
    exit 1
}

fio_run () {
    test_name = $1
    disk = $2

    echo "RUN TEST: $test_name"
    fio --name="$test_name" --filename="$disk" --output-forman=json --ioengine=libaio --direct=1 --randrepeat=0 "$@" > "$test_name"-"$disk".json
    sleep 10
}

fio_run  randwrite_fsync  $disk    -rw=randwrite  -runtime=60  -bs=4k  -numjobs=1  -iodepth=1    -fsync=1
fio_run  randwrite_jobs4  $disk    -rw=randwrite  -runtime=60  -bs=4k  -numjobs=4  -iodepth=128  -group_reporting
