#!/bin/bash
# checks the latest bench ID against a saved cache
# if it is new, prints it with the print script
# then saves it

date
echo "checking bench similarity"

CACHE_FILENAME="bench_id.cache"
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CACHE_FILE="${SCRIPT_DIR}/${CACHE_FILENAME}"

benchresponse=$(curl -i -Ss "http://server.alifeee.co.uk/bench/full.cgi")

bench_id=$(echo "${benchresponse}" | pcregrep -o1 "Bench-URL: .*/bench/(.*)\r")

prev_bench_id=$(cat $CACHE_FILE)

# no cache
if [ -z $prev_bench_id ]; then
  echo "no cache! creating it..."
  echo $bench_id > $CACHE_FILE
  exit 0
fi

# no change (same bench)
if [ $bench_id -eq $prev_bench_id ]; then
  echo "benches are the same, doing nothing..."
  exit 0
fi

# new bench!
echo "a new bench!"
${SCRIPT_DIR}/printbench.sh
echo $bench_id > $CACHE_FILE
