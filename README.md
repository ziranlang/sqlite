# SQLite

The [SQLite](https://sqlite.org) C library for Ziran programs, as a package.

```sh
ziran add https://github.com/ziranlang/sqlite.git
```

```zi
#import "sqlite/SQLite"

database: *void = null
flags: s32 = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
if SqliteOpenText(":memory:", *database, flags) == SQLITE_OK {
    SqliteExecText(database, "create table if not exists votes (voter text, score integer)")
    SqliteClose(database)
}
```

The functions keep SQLite's names and return codes (`SqlitePrepare`,
`SqliteStep`, `SqliteColumnText`, `SqliteBindInt64`, …). The `*Text` and
`*String` variants take Ziran strings and copy them to the NUL-terminated
text SQLite expects, so a temporary string is safe to pass.

The module provides connections, prepared statements, text and binary
bindings, integer and floating-point values, NULLs, error reporting, busy
timeouts, change counts and database backup. `SqliteOpenText` opens a path
from a Ziran string; `SqliteBindBlob` copies bytes including embedded NULs,
and an empty slice binds an empty BLOB. Column pointers and error messages
are borrowed from SQLite; consume or copy them before their owner changes.

The complete official SQLite source is a Git source dependency pinned to
an exact upstream commit in `ziran.lock`. `ziran fetch --locked` retrieves
it and `ziran pkg path sqlite3` locates it. A submodule is unnecessary:
Ziran's lockfile records and fetches the original source itself.

On Linux, `make native` generates the upstream amalgamation out of tree
and builds `build/native/libsqlite3.a` and `libsqlite3.so`, without an
installed system SQLite. Link with `LDFLAGS=-L/path/to/build/native` and
`LDLIBS='-lsqlite3 -lm -ldl -pthread'`. C and C++ use its C ABI, Go uses
cgo (`CGO_ENABLED=1`), Rust carries the flags in its Cargo project, and
Python uses ctypes with the shared library. Add `build/native` to
`LD_LIBRARY_PATH` when running linked programs. These bindings all use
the same SQLite engine and database format. The portable `.zib` VM cannot
call arbitrary native libraries.

## Test

```sh
make check             # C, C++, Go, Rust and Python, source and saved IR
make check TARGET=go   # one backend
```

The full check needs a C/C++ compiler, Python, Go and Cargo. It tests
Unicode text, statement reuse, large integers, binary data, empty BLOBs,
floating-point values, NULLs, invalid SQL and database backup. This is a
binding for the documented API above, rather than every SQLite extension.
