#!/bin/bash
# print the latest bench from OpenBenches.org to an ESC/POS thermal printer
# usage:
#  ./printbench.sh
# The first argument can be used to select 2nd/3rd/4th/etc oldest bench, i.e.,
#  ./printbench.sh 3 prints the 3rd oldest bench

# set -x # debug

echo "[printbench.sh]"
date

if [ -z $1 ]; then
  echo "must specify bench ID, e.g: ./printbench 32004"
  exit 1
fi

# temporary image file
IMG_FILENAME="temp.jpeg"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IMG_FILE="${SCRIPT_DIR}/${IMG_FILENAME}"
# pixel width of images for printer
PRINTER_WIDTH="384"

bench_id=$1
echo "printing bench id ${bench_id}"

bench_info_json=$(curl -s "https://openbenches.org/api/bench/${bench_id}")
echo "json data: ${bench_info_json}"
if [ "${bench_info_json}" == "{}" ]; then
  echo "no data. a duplicate bench? a redirect?"
  exit 15
fi

bench_text=$(echo "${bench_info_json}" | jq -r '.features | .[].properties.popupContent' | sed 's/<br \/>//g' | sed 's/^\s*//' | sed 's/\s*$//')
echo "bench text: ${bench_text}"

# choose image, in the preference bench > inscription > view (not all images are guaranteed)
# try inscription
pic_url=$(echo "${bench_info_json}" | jq -r '.features | .[].properties.media | .[] | select(.media_type | contains("inscription")) | .URL')
# try bench
if [ -z "${pic_url}" ]; then
  pic_url=$(echo "${bench_info_json}" | jq -r '.features | .[].properties.media | .[] | select(.media_type | contains("bench")) | .URL')
fi
# try view
if [ -z "${pic_url}" ]; then
  pic_url=$(echo "${bench_info_json}" | jq -r '.features | .[].properties.media | .[] | select(.media_type | contains("view")) | .URL')
fi
if [ -z "${pic_url}" ]; then
  echo "no image found :("
  exit 1
fi

echo "got image(s): ${pic_url}"

if [ $(echo "${pic_url}" | wc -l) -gt 1 ];then
  echo "looks like multiple images were found! taking only the first"
  pic_url=$(echo "${pic_url}" | head -n1)
fi

echo "downloading image: ${pic_url}"
wget -nv -O $IMG_FILE "https://openbenches.org${pic_url}"
echo "auto-rotating image"
mogrify -auto-orient -resize $PRINTER_WIDTH $IMG_FILE

# echo "reset printer formatting"
# printf "\033@" > /dev/usb/lp0 # reset

echo "print image and text"
${SCRIPT_DIR}/env/bin/python "${SCRIPT_DIR}/printwescpos.py" $IMG_FILE "${bench_text}"
ec=$?
if [ $ec -ne 0 ]; then
  echo "failed to print! exit code ${ec}"
  exit $ec
fi

echo "printed!"

# echo "print inscription: ${bench_text}"
# printf "\n" > /dev/usb/lp0
# printf "${bench_text}" > /dev/usb/lp0
# printf "\n\n\n\n" > /dev/usb/lp0
# printf "\033@" > /dev/usb/lp0 # reset
