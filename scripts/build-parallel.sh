#!/bin/bash
# Parallel (multi-process) build orchestrator for Kujo SSG.
#
# Mirrors how fast SSGs (incl. the reference SSG) scale: shard the embarrassingly-parallel
# per-post rendering across CPU cores using independent `kujo run` processes,
# then merge. The default single-process `kujo run ./build.kujo` is unchanged;
# this is an opt-in fast path for large sites.
#
# Many *small* shards (≈200–300 posts each) keep every worker in the fast linear
# regime; a bounded concurrency (≈ CPU cores) avoids oversubscription.
#
# Usage:
#   bash scripts/build-parallel.sh <shards> <concurrency> [build args...]
#
# Example (12-core machine, 10k posts → ~40 shards of ~250):
#   KUJO_BIN=/path/to/kujo bash scripts/build-parallel.sh 40 12 \
#       --content content --output output --site-url https://example.com --posts-per-page 25
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: bash scripts/build-parallel.sh <shards> <concurrency> [build args...]" >&2
    exit 2
fi

SHARDS="$1"; shift
CONCURRENCY="$1"; shift
KUJO="${KUJO_BIN:-kujo}"
BUILD="./build.kujo"

for n in "$SHARDS" "$CONCURRENCY"; do
    if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ]; then
        echo "shards and concurrency must be positive integers" >&2
        exit 2
    fi
done

start=$(date +%s.%N)

echo "[1/3] setup"
"$KUJO" run "$BUILD" -- --phase setup "$@"

echo "[2/3] rendering posts: $SHARDS shards, $CONCURRENCY at a time"
fail_flag="$(mktemp)"
# Bounded parallelism in fixed-size batches. This avoids `wait -n`, which is
# unavailable on the bash 3.2 that ships with macOS (where the fallback `wait`
# serialized every shard after the first batch). Each batch launches up to
# CONCURRENCY independent `kujo run` workers and waits for the whole batch.
i=0
while [ "$i" -lt "$SHARDS" ]; do
    batch_end=$((i + CONCURRENCY))
    [ "$batch_end" -gt "$SHARDS" ] && batch_end="$SHARDS"
    j="$i"
    while [ "$j" -lt "$batch_end" ]; do
        (
            "$KUJO" run "$BUILD" -- --phase posts --shard "$j" --shards "$SHARDS" "$@" \
                || echo "shard $j failed" >>"$fail_flag"
        ) &
        j=$((j + 1))
    done
    wait
    i="$batch_end"
done

if [ -s "$fail_flag" ]; then
    echo "A posts shard failed:" >&2; cat "$fail_flag" >&2; rm -f "$fail_flag"
    exit 1
fi
rm -f "$fail_flag"

echo "[3/3] finalize"
"$KUJO" run "$BUILD" -- --phase finalize --shards "$SHARDS" "$@"

end=$(date +%s.%N)
printf "Parallel build complete in %.1fs (%s shards, %s concurrency)\n" \
    "$(echo "$end - $start" | bc)" "$SHARDS" "$CONCURRENCY"
