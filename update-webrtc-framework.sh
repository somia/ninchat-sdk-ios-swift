#! /bin/sh -e

WEBRTC=webrtc_ios

# Add the tools to the path
export PATH="$PATH:`pwd`/webrtc/depot_tools"

# Download the WebRTC source code
mkdir -p $WEBRTC
cd $WEBRTC

# This will take some time
echo "Syncing in progress...."
fetch --nohooks webrtc_ios
gclient sync

# Build the framework, add --arch "arm64 x64" to specify the architecture
echo "Starting the build...."
cd src
tools_webrtc/ios/build_ios_libs.py --arch arm64 x64

# Copy built framework into the project's directory
cd ../..
cp -r $WEBRTC/src/out_ios_libs/WebRTC.framework Frameworks/NinchatWebRTC.framework
rm -rf $WEBRTC
echo "Build done"
