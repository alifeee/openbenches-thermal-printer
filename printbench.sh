#!/bin/bash
# print the latest bench from OpenBenches.org to an ESC/POS thermal printer
# usage:
#  ./printbench.sh
# The first argument can be used to select 2nd/3rd/4th/etc oldest bench, i.e.,
#  ./printbench.sh 3 prints the 3rd oldest bench

# set -x # debug

# temporary image file
IMG_FILE="temp.jpeg"
# pixel width of images for printer
PRINTER_WIDTH="384"

benchresponse=$(curl -i -Ss "http://server.alifeee.co.uk/bench/full.cgi?n=$1")

bench_id=$(echo "${benchresponse}" | pcregrep -o1 "Bench-URL: .*/bench/(.*)\r")
bench_text=$(echo "${benchresponse}" | sed '1,/^\r$/d')

bench_info_json=$(curl -s "https://openbenches.org/api/bench/${bench_id}")

# choose image, in the preference bench > inscription > view (not all images are guaranteed)
inscription_pic_url=$(echo "${bench_info_json}" | jq -r '.features | .[].properties.media | .[] | select(.media_type | contains("inscription")) | .URL')
bench_pic_url=$(echo "${bench_info_json}" | jq -r '.features | .[].properties.media | .[] | select(.media_type | contains("bench")) | .URL')
view_pic_url=$(echo "${bench_info_json}" | jq -r '.features | .[].properties.media | .[] | select(.media_type | contains("view")) | .URL')
if [ ! -z $bench_pic_url ]; then
  media_url="${bench_pic_url}"
elif [ ! -z $inscription_pic_url ]; then
  media_url="${inscription_pic_url}"
elif [ ! -z $view_pic_url ]; then
  media_url="${view_pic_url}"
else
  echo "no image found :("
  exit 1
fi

echo "downloading image"
wget -O $IMG_FILE "https://openbenches.org$media_url"
echo "auto-rotating image"
mogrify -auto-orient -resize $PRINTER_WIDTH $IMG_FILE

# echo "reset printer formatting"
# printf "\033@" > /dev/usb/lp0 # reset

echo "print image and text"
./env/bin/python printwescpos.py $IMG_FILE "${bench_text}"

# echo "print inscription: ${bench_text}"
# printf "\n" > /dev/usb/lp0
# printf "${bench_text}" > /dev/usb/lp0
# printf "\n\n\n\n" > /dev/usb/lp0
# printf "\033@" > /dev/usb/lp0 # reset
