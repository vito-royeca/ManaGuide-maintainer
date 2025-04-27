#! /bin/bash

rm -fvr .build/release/ManaGuide*
swift build -c release
sudo cp .build/release/managuide /usr/local/bin
