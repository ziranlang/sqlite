.DEFAULT_GOAL := check

ZIRAN ?= ziran
CC ?= cc
BUILD := build
SQLITE_LIBS ?= $(shell pkg-config --libs sqlite3 2>/dev/null || echo -lsqlite3)

.PHONY: check test clean

# Checks the package, then runs the test against the system SQLite. The
# portable bundle cannot call into the SQLite C library, so the test is
# native only.
check: test

test:
	$(ZIRAN) check --project
	$(ZIRAN) build --project --target=c --entry sqlite_test:main \
		-o $(BUILD)/test-c tests/sqlite_test.zi
	$(CC) -std=c99 -pedantic-errors -I$$($(ZIRAN) pkg path ziran)/include \
		-I$(BUILD)/test-c $(BUILD)/test-c/*.c $(SQLITE_LIBS) -o $(BUILD)/sqlite-test
	$(BUILD)/sqlite-test

clean:
	rm -rf $(BUILD)
