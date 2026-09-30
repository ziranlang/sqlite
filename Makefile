.DEFAULT_GOAL := check

ZIRAN ?= ziran
CC ?= cc
BUILD := build
AR ?= ar
TARGET ?= all
LOCK_FLAGS := $(if $(wildcard ziran.local.toml),,--locked)
SQLITE_A := $(BUILD)/native/libsqlite3.a

.PHONY: check test native prepare clean

# Build the locked upstream engine, then test the same API on every backend.
check: test

prepare:
	$(ZIRAN) fetch $(LOCK_FLAGS)

native: $(SQLITE_A)

$(SQLITE_A): Makefile ziran.lock $(wildcard ziran.local.toml) | prepare
	mkdir -p $(BUILD)/sqlite3 $(BUILD)/native
	cd $(BUILD)/sqlite3 && "$$($(ZIRAN) pkg path sqlite3)/configure" \
		--disable-shared --disable-readline --disable-tcl
	$(MAKE) -C $(BUILD)/sqlite3 sqlite3.c
	$(CC) -O2 -fPIC -DSQLITE_THREADSAFE=1 -DSQLITE_ENABLE_FTS5 \
		-c $(BUILD)/sqlite3/sqlite3.c -o $(BUILD)/native/sqlite3.o
	$(CC) -shared $(BUILD)/native/sqlite3.o -lm -ldl -pthread \
		-o $(BUILD)/native/libsqlite3.so
	$(AR) rcs $@ $(BUILD)/native/sqlite3.o

test: native
	python3 "$$($(ZIRAN) pkg path ziran)/scripts/test_native_package.py" \
		--ziran "$(ZIRAN)" --source tests/sqlite_test.zi --entry sqlite_test:main \
		--library-dir $(BUILD)/native '--libraries=-lsqlite3 -lm -ldl -pthread' \
		--target $(TARGET)

clean:
	rm -rf $(BUILD)
