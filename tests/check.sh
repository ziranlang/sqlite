#!/bin/sh
set -eu

case "$1" in
    all) targets='c go' ;;
    c|go) targets=$1 ;;
    *) printf 'Unsupported native target: %s\n' "$1" >&2; exit 2 ;;
esac

unset DISPLAY WAYLAND_DISPLAY XAUTHORITY DBUS_SESSION_BUS_ADDRESS
export LD_LIBRARY_PATH="$PWD/build/native${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export LDFLAGS="-L$PWD/build/native ${LDFLAGS:-}"
export LDLIBS="${LDLIBS:-} -lsqlite3 -lm -ldl -pthread"
export GO111MODULE=off CGO_ENABLED=1

run_test() {
    target=$1
    form=$2
    shift 2
    destination="$out/$target/$form"
    if [ "$target" = go ]; then
        "$ZIRAN" build --target=go --pkg main --exe --entry "$entry" -o "$destination" "$@"
        (cd "$destination" && go build -o "$name" .)
    else
        "$ZIRAN" build --target=c --exe --entry "$entry" -o "$destination" "$@"
    fi
    "$destination/$name"
    printf 'PASS %s %s %s\n' "$name" "$form" "$target"
}

check_suite() {
    name=$1
    shift
    source=tests/$name.zi
    entry=$name:main
    out=$PWD/build/native-test/$name
    "$ZIRAN" check --project ${LOCK_FLAGS:-} "$source"
    "$ZIRAN" ir --project ${LOCK_FLAGS:-} --entry "$entry" -o "$out/ir" "$source"
    for target in "$@"; do
        run_test "$target" source --project ${LOCK_FLAGS:-} "$source"
        run_test "$target" saved --root "$out/ir" "$out/ir"/*.zir
    done
}

check_suite sqlite_test $targets
check_suite sqlite_callback_test c
