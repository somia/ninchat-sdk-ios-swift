#!/bin/bash

set -e

echo "Will rebuild the low-level xcframework."

framework="NinchatLowLevelClient.framework"
xcframework="NinchatLowLevelClient.xcframework"

if [ -z "$GOPATH" ]
then
    GOPATH=$(go env GOPATH)
fi

modulename="github.com/ninchat/ninchat-go/mobile"
mygopath="`pwd`/go-sdk:$GOPATH"
gocodedir="`pwd`/go-sdk/src/$modulename"
tmpframework="/tmp/$xcframework"
frameworkdir="./Frameworks/$xcframework"

# Clean up previous builds
rm -rf "$tmpframework"

# Check that the go code dir exists
if [[ ! -d $gocodedir ]]
then
    echo "Could not find go code dir: $gocodedir"
    exit 1
fi

# We need to be in a directory to avoid 'no exported names in the package ...' error
pushd "$gocodedir" > /dev/null
    echo "Running gomobile tool.."
    GOPATH=$mygopath gomobile bind -target ios -prefix NINLowLevel \
          -o $tmpframework $modulename
popd > /dev/null

# Remove `nullable` modifier from `init` functions as it has conflicts with default NSObject `init` function
sed -i'.sedbackup' 's/- (nullable instancetype)init;/- (nonnull instancetype)init;/g' $tmpframework/**/$framework/Headers/NINLowLevelClient.objc.h
rm -rf $tmpframework/**/$framework/Headers/NINLowLevelClient.objc.h.sedbackup

if [[ -d $tmpframework ]]
then
    # Remove old framework and copy the whole new xcframework
    rm -rf "$frameworkdir"
    cp -r "$tmpframework" "$frameworkdir"
else
    echo "Could not find resulting xcframework in tmp dir: $tmpframework"
    exit 1
fi

echo "Done."
