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

`SqliteGetAutocommit(database)` reports whether the live connection has no
active transaction, following SQLite's `sqlite3_get_autocommit`. It returns
false for a null handle. Keep the connection alive while calling it.

`SqliteCreateFunction` binds `sqlite3_create_function_v2` directly. Its
`SqliteScalar` and `SqliteDestructor` types use `#c_call`; callback programs
require the native C backend. The common connection and statement APIs still
support C and Go. Pass a NUL-terminated function name and SQLite's documented
argument count and encoding flags; use null step/final callbacks for a scalar.
No validation or early return in the binding changes SQLite's destructor rules.

The data pointer remains the caller's responsibility until SQLite calls its
destructor. SQLite calls that destructor on replacement, deletion, connection
close, and registration failure, including a name longer than 255 UTF-8 bytes.
Do not free the same data again after an error. `SqliteUserData` returns this
pointer inside the registered callback; each connection has its own
registration. See the [function registration contract](https://www.sqlite.org/c3ref/create_function.html)
and [user data contract](https://www.sqlite.org/c3ref/user_data.html).

`SqliteValueType`, `SqliteValueBytes` and `SqliteValueBlob` inspect callback
arguments; blob bytes are borrowed and may be null for empty values. Inspect
the type before conversions and consume bytes within the callback, following
SQLite's [value lifetime rules](https://www.sqlite.org/c3ref/value_blob.html).
`SqliteResultDouble` sets the callback result. Keep callback context, argument
pointers and returned user data within their documented lifetimes; a callback
must not close its active database or reset/finalize its active statement.

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
make check             # available backends, source and saved IR; native C callbacks
make check TARGET=go   # one backend
```

The current toolchain check needs a C compiler, Python and Go. Older toolchains
also provide C++, Rust and Python backends and require their build tools. It tests
Unicode text, statement reuse, large integers, binary data, empty BLOBs,
floating-point values, NULLs, invalid SQL and database backup. This is a
binding for the documented API above, rather than every SQLite extension.
A separate C source/saved callback suite exercises value types, binary bytes,
connection-local data, replacement, deletion, close and real failed-registration
destructor calls, without requiring callback support from Go.
