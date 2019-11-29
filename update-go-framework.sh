#!/bin/bash

set -e

echo "Will rebuild the low-level framework."

framework="NinchatLowLevelClient.framework"

if [ -z "$GOPATH" ]
then GOPATH=$(go env GOPATH)
fi

mygopath="`pwd`/go-sdk:$GOPATH"
gocodedir="`pwd`/go-sdk/src/github.com/ninchat/ninchat-go/mobile/"
tmpframework="/tmp/$framework"
frameworkdir="Frameworks/$framework"

# Clean up previous builds
rm -rf "$tmpframework"

# Check that the go code dir exists
if [[ ! -d $gocodedir ]]
then
    echo "Could not find go code dir: $gocodedir"
    exit 1
fi

echo "Running gomobile tool.."
GOPATH=$mygopath gomobile bind -target ios -prefix NINLowLevel \
      -o $tmpframework github.com/ninchat/ninchat-go/mobile

# Copy the main header + the binary over to the framework dir
cp "$tmpframework/Headers/NINLowLevelClient.objc.h" "$frameworkdir/Headers/"
cp "$tmpframework/Client" "$frameworkdir/Versions/Current/NinchatLowLevelClient"

echo "Done."
