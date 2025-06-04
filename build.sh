#! /bin/bash

rm -fvr .build/aarch64-unknown-linux-gnu/release/ManaGuide_maintainer.build/*.o
swift build -c release
sudo cp .build/release/managuide /usr/local/bin
