#!/bin/env sh

#    DATE: 2023-10-06
#  AUTHOR: Roman Bergman <roman.bergman@protonmail.com>
# RELEASE: 0.2.12
# LICENSE: AGPL-3.0

#DEFINE
disk=$1
timestamp=$(date +%s)

if [ -z "$disk" ] 
then
    echo "Disk not set!"
    exit 1
fi

fio_run () {
    test_name=$1

    shift 
    (
        #set -x

        echo "RUN TEST: $test_name"
        fio --name=$test_name --filename=$disk --output-format=json --ioengine=libaio --direct=1 --randrepeat=0 "$@" > $timestamp-$test_name.json
        sleep 10
    )  
}

fio_run randwrite_fsync --rw=randwrite  --runtime=60    --bs=4k --numjobs=1     --iodepth=1     --fsync=1
fio_run randwrite_jobs4 --rw=randwrite  --runtime=60    --bs=4k --numjobs=4     --iodepth=128   --group_reporting
fio_run randwrite       --rw=randwrite  --runtime=60    --bs=4k --numjobs=1     --iodepth=128
fio_run write           --rw=write      --runtime=60    --bs=4M --numjobs=1     --iodepth=16
fio_run randread_fsync  --rw=randread   --runtime=60    --bs=4k --numjobs=1     --iodepth=1     --fsync=1
fio_run randread_jobs4  --rw=randread   --runtime=60    --bs=4k --numjobs=4     --iodepth=128   --group_reporting
fio_run randread        --rw=randread   --runtime=60    --bs=4k --numjobs=1     --iodepth=128
fio_run read            --rw=read       --runtime=60    --bs=4M --numjobs=1     --iodepth=16


data="$(cat *.json | jq -sc . | gzip -9 | base64 -w0)"
report_file=$timestamp-fio_result$(echo $disk | sed "s/\//\-/g").json

{
for i in $(find ./ -name "$timestamp*write*" | sort -V); do
        cat $i | jq -rc '.jobs[0] | {"name": ."job options".name, "iodepth": ."job options".iodepth, bs: ."job options".bs, jobs: ."job options".numjobs, "clat_ms": (.write.clat_ns.mean/1000)|floor, "bw_mbs": (.write.bw_mean/1024)|floor, iops: .write.iops_mean|floor}'
done

for i in $(find ./ -name "$timestamp*read*" | sort -V); do
  cat $i | jq -rc '.jobs[0] | {"name": ."job options".name, "iodepth": ."job options".iodepth, bs: ."job options".bs, jobs: ."job options".numjobs, "clat_ms": (.read.clat_ns.mean/1000)|floor, "bw_mbs": (.read.bw_mean/1024)|floor, iops: .read.iops_mean|floor}'
done
} | jq -s "{\"$disk\": {results: ., data: \"$data\" }}" > $report_file

echo "REPORT SAVE TO: $report_file"
