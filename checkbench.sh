#!/bin/bash
# checks the latest bench ID against a saved cache
# if it is new, prints it with the print script
# then saves it

echo ""
echo "[checkbench.sh]"
date
echo "checking bench similarity"

CACHE_FILENAME="printed.cache"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CACHE_FILE="${SCRIPT_DIR}/${CACHE_FILENAME}"
echo "opening cache file ${CACHE_FILE}"

benchresponse=$(curl -i -Ss "http://server.alifeee.co.uk/bench/full.cgi")
if [ -z "${benchresponse}" ]; then
  echo "request failed somehow :("
  exit 1
fi
bench_id=$(echo "${benchresponse}" | pcregrep -o1 "Bench-URL: .*/bench/(.*)\r")
prev_bench_id=$(cat $CACHE_FILE | tail -n1)

echo "bench IDs. current: <${bench_id}>, last printed: <${prev_bench_id}>"

# no cache
if [ -z $prev_bench_id ]; then
  echo "no cache! creating it and exiting..."
  echo $bench_id > $CACHE_FILE
  exit 0
fi

# no change (same bench)
if [ $bench_id -eq $prev_bench_id ]; then
  echo "benches are the same, doing nothing..."
  exit 0
fi

# new bench!
next_id=$(( $prev_bench_id + 1 ))
echo "a new bench! running ${SCRIPT_DIR}/printbench.sh with last ID + 1 = ${next_id}"
${SCRIPT_DIR}/printbench.sh $next_id
ec=$?
if [ $ec -eq 14 ]; then
  echo "usb printer not plugged in. will retry later"
  exit $ec
fi
if [ $ec -ne 0 ]; then
  echo "failed to print bench. exit code ${ec}. not saving to cache... quitting..."
  exit $ec
fi
echo "saving new bench ID to cache"
echo $next_id >> $CACHE_FILE
