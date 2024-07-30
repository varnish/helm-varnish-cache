#!/bin/sh -e
#
# Fetch latest tag from the given repository
#

BASE_DIR=$(cd "$(dirname "$0")/.." || exit 1; pwd -P)
cd "$BASE_DIR/" || exit 1

check_cmd() {
    cmd=$1
    if ! command -v "$cmd" >/dev/null; then
        echo >&2 "${cmd} is required to run $(basename "$0")"
        exit 1
    fi
}

version_gte() {
    left=$(echo $1 | tr -C '[0-9]' '.'); shift
    right=$(echo $1 | tr -C '[0-9]' '.'); shift

    # https://havoc.io/post/shellsemver/
    min_ver=$(printf "%s\\n%s" "$left" "$right" |
        sort -t "." -n -k1,1 -k2,2 -k3,3 -k4,4 -k5,5 -k6,6 -k7,7 -k8,8 -k9,9 |
        head -n 1)

    if [ "$right" = "$min_ver" ]; then
        return 0
    fi

    return 1
}

latest_version() {
    latest_version=0.0.0

    while read -r p; do
        if version_gte "$p" "$latest_version"; then
            latest_version="$p"
        fi
    done

    if [ "$latest_version" = "0.0.0" ]; then
        echo >&2 "Unable to determine latest version"
        exit 1
    fi

    echo "$latest_version"
}

# Sanity check
check_cmd egrep
check_cmd head
check_cmd jq
check_cmd printf
check_cmd tr
check_cmd skopeo
check_cmd sort
check_cmd tail

if [ $# -lt 1 ]; then
    echo >&2 "Usage: $(basename "$0") REPO"
    exit 1
fi

REPO=$1; shift
FILTER=${1:-"[0-9]+\.[0-9\.]+$"}

skopeo list-tags "$REPO" |
    jq -r '.Tags[]' |
    egrep "$FILTER" |
    latest_version
