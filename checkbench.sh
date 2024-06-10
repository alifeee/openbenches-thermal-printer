#!/bin/bash
# checks the latest bench ID against a saved cache
# if it is new, prints it with the print script
# then saves it

echo ""
echo "[checkbench.sh]"
date
echo "checking bench similarity"

CACHE_FILENAME="bench_id.cache"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CACHE_FILE="${SCRIPT_DIR}/${CACHE_FILENAME}"
echo "opening cache file ${CACHE_FILE}"

benchresponse=$(curl -i -Ss "http://server.alifeee.co.uk/bench/full.cgi")
if [ -z $benchresponse ]; then
  echo "request failed somehow :("
  exit 1
fi
bench_id=$(echo "${benchresponse}" | pcregrep -o1 "Bench-URL: .*/bench/(.*)\r")
prev_bench_id=$(cat $CACHE_FILE)

echo "bench IDs. current: <${bench_id}>, cached: <${prev_bench_id}>"

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
echo "a new bench! running ${SCRIPT_DIR}/printbench.sh"
${SCRIPT_DIR}/printbench.sh
echo "saving new bench ID to cache"
echo $bench_id > $CACHE_FILE
