# Configurables:
name="NinchatSDKSwift"
builddir="$(PWD)/Build"

# Build the simulator build
echo "Building for simulator.."
xcodebuild build -workspace $name.xcworkspace -scheme $name \
           -sdk iphonesimulator SYMROOT=$builddir
if [ $? -ne 0 ]; then
    echo "Simulator build failed."
    exit
fi

# Build the device build
echo "Building for device.."
xcodebuild archive -workspace $name.xcworkspace -scheme $name \
           -sdk iphoneos SYMROOT=$builddir
if [ $? -ne 0 ]; then
    echo "Device build failed."
    exit
fi

device_path="$builddir/Release-iphoneos/$name.framework"
device_file="$device_path/$name"
simulator_file="$builddir/Debug-iphonesimulator/$name.framework/$name"

# Check both files exist
if [ ! -f $device_file ]; then
    echo "Device Build file not found: $device_file"
    exit
fi
if [ ! -f $simulator_file ]; then
    echo "Simulator Build file not found: $simulator_file"
    exit
fi

universal_path="$builddir/$name.framework"
universal_file="$universal_path/$name"
rm -rf $universal_path

echo "Building universal framework to: $universal_path"

# Use the device framework as the basis for the combined universal framework
cp -r $device_path $universal_path

# Combine into universal framework under the current dir
lipo -create $device_file $simulator_file -output $universal_file

# Create a deliverable archive of the framework
archive="$builddir/NinchatSDK-Universal-Framework.tgz"
rm -f $archive

dir="$(dirname $universal_path)"
file="$(basename $universal_path)"

tar czf $archive -C $dir $file

echo "Done."
