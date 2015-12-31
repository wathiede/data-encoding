#!/bin/sh
set -e

info() { echo "[1;36mInfo:[m $1"; }

info "Build in release mode."
cargo build --release

info "Test in release mode."
cargo test --release

info "Download kcov."
wget -q https://github.com/SimonKagstrom/kcov/archive/master.tar.gz

info "Build kcov."
tar xf master.tar.gz
mkdir kcov-master/build
( cd kcov-master/build
  cmake ..
  make >/dev/null
)

info "Test in debug mode with coverage."
cargo test --no-run
find target/debug -maxdepth 1 -type f -perm /u+x -printf '%P\n' |
while IFS= read -r test; do
  ./kcov-master/build/src/kcov --verify --include-path=src/ \
    target/kcov-"$test" ./target/debug/"$test"
done; unset test

info "Send coverage to coveralls.io."
./kcov-master/build/src/kcov --coveralls-id="$TRAVIS_JOB_ID" \
  --merge target/kcov target/kcov-*

info "Done."