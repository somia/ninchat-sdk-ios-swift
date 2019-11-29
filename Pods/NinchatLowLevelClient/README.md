# Ninchat iOS SDK

This document describes integrating the Ninchat iOS SDK into a native iOS application.

This document uses Swift programming language for the usage samples.

**NOTE this is for the project Phase 1 PoC.**

## Installation

Example Podfile:

```
platform :ios, '9.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/somia/ninchat-podspecs.git'

def all_pods
  pod 'NinchatSDK', '~> 0.0.1'
end

target 'NinchatSDKTestClient' do
  all_pods
end

target 'NinchatSDKTestClientTests' do
  all_pods
end
```

Install by running `pod install`.

## Usage

Create the API client:

```swift
import NinchatSDK

ninchatClient = NINChat.create()
```

Call the test API methods:

```swift
// Show the mock Ninchat UI from the SDK
let controller = ninchatClient.initialViewController()
self.present(controller, animated: true, completion: nil)

// Do a connection test using the SDK..
let returnValue = ninchatClient.connectionTest()
log.debug("Connection test success: \(returnValue)")
```

## Xamarin usage

To use a Cocoapods distribution in Xamarin, refer to the following documentation by Microsoft: 

https://docs.microsoft.com/en-us/xamarin/cross-platform/macios/binding/objective-sharpie/examples/cocoapod

## Contact

If you have any questions, contact:
* Matti Dahlbom / Qvik <matti@qvik.com>
