# Guide to building the Ninchat iOS SDK

This document describes the steps to take when developing, updating and releasing the Ninchat iOS SDK. 

The library has been written in Swift wrapping legacy [Ninchat Objective-c SDK](https://github.com/somia/ninchat-sdk-ios) in a modern swift version. The library is being published using Cocoapods, the de-facto standard dependency manager for iOS.

## Development

The SDK will provide backward compability as much as possible, so no shotgun effect happens on current clients. However, clients need to update to the new SKD as **the *NinchatSDK* is no longer maintained for new features**.

**TODO**

## Use of the Ninchat Go SDK

This project uses the Ninchat Go SDK to take care of API communication.

### Prerequisites

You must have `go` and `gomobile` installed. Install them by running:

```sh
brew install go
go get -u golang.org/x/mobile/cmd/gomobile
gomobile init
```

### Updating the Go Framework

You will need Go 1.8+ installed to perform this step; it requires building the existing Ninchat Go SDK into a static library callable from iOS code.

Update the Framework by running the script:

```sh
update-go-framework.sh
```

To do the steps manually, do the following:

1. Make sure you have the latest code:
```sh
git submodule init
git submodule update
git fetch
git merge <origin-branch>
```
2. Enter the Go mobile package directory:
```sh
cd /path/to/project/go-sdk/src/github.com/ninchat/ninchat-go/mobile
```
3. Create the Framework:
```sh
GOPATH=$GOPATH:/path/to/project/go-sdk gomobile bind -target ios -o /tmp/NinchatGo.framework
```
4. Replace the version in the iOS project
```sh
rm -rf /path/to/project/Frameworks/NinchatGo.framework
cp -r /tmp/NinchatGo.framework /path/to/project/Frameworks/NinchatGo.framework
```

## Releasing new SDK version

First of all you need to have configured the private podspecs repo:

```sh
git repo add ninchat-podspecs git@github.com:somia/ninchat-podspecs.git
```

To release a new SDK version on the said podspec repository, take the following steps:

* Update NinchatSDK.podspec and set s.version to match the upcoming tag
* Commit all your changes, merge all pending accepted *Merge ('pull') Requests*
* Create a new tag following [Semantic Versioning](http://semver.org/); eg. `git tag -a 1.0.1 -m "Your tag comment"`
* `git push --tags`
* `pod repo push ninchat-podspecs NinchatSDKSwift.podspec`



