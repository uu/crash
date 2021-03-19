all: shards prebuild build-static strip

shards:
	shards install --production
shards-devel:
	shards install
prebuild:
	mkdir -p bin
build:
	crystal build --release --no-debug -s -p -t src/crash.cr -o bin/crash
build-static:
	apk add openssl-libs-static
	crystal build --release --static --no-debug -s -p -t src/crash.cr -o bin/crash
strip:
	strip bin/crash
run:
	crystal run src/crash.cr
test: shards-devel
	crystal spec
