# SQLite

The [SQLite](https://sqlite.org) C library for Ziran programs, as a package.

```sh
ziran add https://github.com/ziranlang/sqlite.git
```

```zi
#import "sqlite/SQLite"

database: *void = null
flags: s32 = SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE
if SqliteOpen(path, *database, flags) == SQLITE_OK {
    SqliteExecText(database, "create table if not exists votes (voter text, score integer)")
}
```

The functions keep SQLite's names and return codes (`SqlitePrepare`,
`SqliteStep`, `SqliteColumnText`, `SqliteBindInt64`, …). The `*Text` and
`*String` variants take Ziran strings and copy them to the NUL-terminated
text SQLite expects, so a temporary string is safe to pass.

A program links SQLite itself: the system `libsqlite3`, or the SQLite
amalgamation compiled into its own build (as web and Android builds do).
The package calls into C, so it runs in native builds, not the portable
bundle.

## Test

```sh
make check    # needs libsqlite3; set SQLITE_LIBS if pkg-config cannot find it
```
