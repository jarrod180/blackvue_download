#!/bin/bash
OUTPUT_DIR=/data/vod
CAM_IP=10.99.77.1
MAX_RETRIES=30

# See if we can get to the dashcam
echo "Trying to connect to the dashcam at $CAM_IP"
success=0; cnt=1; until nc -vzw 1 $CAM_IP 80 && success=1 || ((cnt >= $MAX_RETRIES)); do ((cnt+=1)); sleep 1; done
test $success -eq 0 && echo "Failed to connect to dashcam at $CAM_IP after $MAX_RETRIES retries" && exit 1
echo "Connected to dashcam at $CAM_IP"

# Download the files
function download_from {
    direction=$1
    echo "Downloading from direction: $direction"
    curl -s "http://$CAM_IP/blackvue_vod.cgi?direction=$direction" | while read line ; do
        if [[ $line == v:* ]]; then continue; fi;
        f=`echo $line | sed -r 's|.*(/Record/.*.mp4).*|\1|g'`
        date=`echo $line | sed -r 's|.*/Record/([0-9]+)_.*|\1|g'`
        url="http://$CAM_IP$f"
        dir=$OUTPUT_DIR/$date
        echo $date
        echo "Downloading $url ---> $dir/"
        mkdir -p $dir
        (cd $dir && curl -O -C - "$url")
    done
}

download_from F
download_from R

echo "Exiting normally"
exit 0
