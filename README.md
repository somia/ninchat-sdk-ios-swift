# Ninchat iOS SDK Swift Integrator's Guide
![build_status](https://travis-ci.org/somia/ninchat-sdk-ios-swift.svg?branch=master)
![cocoapods compatible](https://img.shields.io/badge/Cocoapods-compatible-4BC51D.svg?style=flat)
![Licence](https://img.shields.io/github/license/somia/ninchat-sdk-ios-swift)

This document describes integrating the Ninchat iOS SDK Swift into an iOS application.

## Installation

Install the SDK via CocoaPods.

Example Podfile:

```
platform :ios, '10.0'
use_frameworks!

source 'https://cdn.cocoapods.org/'
source 'https://github.com/somia/ninchat-podspecs.git'

target 'NinchatClient' do
    pod 'NinchatSDKSwift'
end
```
Then, run pod commands in *Terminal*: ```pod update && pod install```

## Usage

#### Creating the API client

The SDK's API client is to be re-created every time a new chat session is started; once it has terminated, it cannot be used any more and must be disposed of to deallocate memory.

To initialize the client, you need a configuration key which will point the SDK to your organization. You obtain that from Ninchat. Optionally, you may specify a list of siteconfig environments to use over the default one. 

You must keep a reference to the created API client instance until the SDK UI terminates. Using the following code, the SDK can be instaniated:

```swift
import NinchatSDKSwift
import NinchatLowLevelClient

self.ninchatSession = NINChatSession(configKey: configKey)
```

or in a more advanced way:

```swift
import NinchatSDKSwift
import NinchatLowLevelClient

self.ninchatSession = NINChatSession(configKey: configKey, queueID: queueID, environments: ["env1"], metadata: NINLowLevelClientProps.initiate(dictionary: ["key": "value"]))
```

##### Optional parameters

* `queueID` define a valid queue ID to join the queue directly; omit the paramter to show queue selection view.
* `metadata` is an optional dictionary that can include some info about the client.
* `environments` is optional and may not be required for your deployment.

##### User Agent Header (Optional)

To append information as the user agent header to your requests, use the following format to set value to  `appDetails` prior to call `start(callBack:)` function:

```swift
ninchatSession.appDetails = "app-name/version (more; details)"
```

#### Starting the API client

The SDK must perform some asynchornous networking tasks before it is ready to use; this is done by calling the `start` method as follows. The callback includes credentials that could be saved for resuming the session later. The function throws an error if it cannot start the session properly.

```swift
self.ninchatSession.delegate = self
try self.ninchatSession.start { (credentials: NINSessionCredentials?, error: Error?) in
    if let error = error {
         /// Some errors in starting a new session.
    }
    /// Save/Cache `credentials` for resuming the session later.
}
```
#### Resuming a session

The SDK provides support to resume a session. In case of any issues in resuming the session using provided credentials, the corresponded optional delegate is called to ask if a new session should be started or not. The function throws an error if it cannot start the session properly.

```swift
self.ninchatSession.delegate = self
try self.ninchatSession.start(credentials: credentials) { (credentials: NINSessionCredentials?, error: Error?) in
    if let error = error {
        /// Some errors in resuming the session.
    }                      
    /// Update saved/cached `credentials` with the new one.
}
```

#### Showing the SDK UI

Once you have started the API client, you can retrieve its UI to be displayed in your application's UI stack. Typically you would do this within the `start` callback upon successful completion. The API can be started with and without using `UINavigationController`.  If the iOS application doesn't provide a valid `UINavigationController` the SDK will start its own navigation controller.

```swift
if let navigation = try self.ninchatSession.chatSession(within: nil) as? UINavigationController {
    self.present(navigation, animated: true)
}
```

But if the application has a valid ``UINavigationController``, the SDK can be easily pushed on the app's navigation controller.

```swift
if let controller = try self.ninchatSession.chatSession(within: self.navigationController) as? UIViewController {
    self.navigationController?.pushViewController(controller, animated: true)
}
```

#### Implementing the API client's delegate methods

The SDK uses a delegate pattern for providing callbacks into the host application. See below for implementing these methods. All of these methods are always called on the main UI thread.

```swift
// MARK: From NINChatSessionDelegate

/// This method is called when the chat session has terminated.
/// The host app should remove the SDK UI from its UI stack and restore
/// the navigation bar if it uses one.
func ninchatDidEnd(_ ninchat: NINChatSession) {
    self.navigationController?.popToViewController(self, animated: true)
  	self.ninchatSession = nil
}

/// This method is called when ever loading an overrideable graphics asset;
/// the host app may supply a custom UIImage to be shown in the SDK UI.
/// For any asset it does NOT wish to override, return nil.
func ninchat(_ session: NINChatSession, overrideImageAssetForKey assetKey: NINImageAssetKey) -> UIImage? {
    switch assetKey {
    case .buttonPrimaryText:
        return .yellow
    default:
        return nil
    }
}

func ninchat(_ session: NINChatSession, overrideImageAssetForKey assetKey: AssetConstants) -> UIImage? {
    switch assetKey {
    case .queueViewProgressIndicator:
        return UIImage(named: "icon_queue_progress_indicator")
    default:
        return nil
    }
}

/// This method is called when ever a low-level API event is received.
/// The host application may respond to these events by using the exposed
/// low-level library; see NINChatSession.session. Optional method.
func ninchat(_ session: NINChatSession, onLowLevelEvent params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
    let eventType = try! params.getString("event")
    switch eventType {
    case "channel_joined":
        log.debug("We joined a channel.");
    default:
        break
    }
}

/// This method is called when the SDK emits a log message. Optional method.
func ninchat(_ session: NINChatSession, didOutputSDKLog message: String) {
    log.debug("Ninchat session ended; removing the SDK UI")
}

/// This method is called when the SDK was unable to resume a session using provided credentials.
/// The return value determines if the SDK should initiate a new session or not.
func ninchatDidFail(toResumeSession session: NINChatSession) -> Bool {
     return true
} 
```

#### Info.plist keys Required by the SDK

The host application must define the following keys in its `Info.plist` file:

* `NSPhotoLibraryUsageDescription` - For accessing photos
* `NSPhotoLibraryAddUsageDescription` - For saving chat images to photos album
* `NSMicrophoneUsageDescription` - For video conferencing
* `NSCameraUsageDescription` - For video conferencing

## Low level API

The SDK exposes the low-level communications interface as `NINChatSession.session`. The host app may use this object to communicate to the server, bypassing the SDK logic.

See [Ninchat API Reference](https://github.com/ninchat/ninchat-api/blob/v2/api.md) for information about the API's outbound Actions and inbound Events.

## Limitations imposed by the SDK

There are some limitations that the SDK imposes on the host app linking to it:

- Missing Bitcode support. The host application must be configured to not use bitcode. The SDK's Cocoapods installer will do this automatically.
- Parts of the SDK are missing the DWARF symbols used for crash symbolication; you must untick the  "Include app symbols" checkbox when submitting an app archive to the App Store / TestFlight.

These issues are caused by limitations of the [gomobile bind tool](https://godoc.org/golang.org/x/mobile/cmd/gobind) used to generate the low-level communications library.

## Overriding the Image Assets

Using the API delegate method `overrideImageAsset(session:forKey:)` you may supply your own Image assets as `UIImage` objects. See the table below for explanations on the supported asset keys.

Note that all the buttons may not be available in the UI.

All the assets should be transparent where there is no color.

| Asset key       | Related UI control(s)           | Notes  |
|:------------- |:-------------|:-----|
| .primaryButton | Background for the 'primary' button | |
| .secondaryButton | Background for the 'secondary' button | |
| .iconDownload | Download button icon | |
| .iconLoader   | Progress indicator icon in queue view. |  |
| .chatWritingIndicator      | User is typing.. Indicator icon in chat bubble | Should be [animated](https://developer.apple.com/documentation/uikit/uiimage/1624149-animatedimagewithimages). |
| .chatBackground    | Chat view's repeating texture. | Should be repeatable (tiling). |
| .chatCloseButton              | Background for 'close chat' button. |  |
| .iconChatCloseButton              | Close icon for 'close chat' button. |  |
| .chatBubbleLeft              | Background for left side chat bubble (first message) | Must be [sliced](https://developer.apple.com/documentation/uikit/uiimage/1624102-resizableimagewithcapinsets?language=objc) as it needs to stretch. |
| .chatBubbleLeftRepeated              | Background for left side chat bubble (serial message) | Must be [sliced](https://developer.apple.com/documentation/uikit/uiimage/1624102-resizableimagewithcapinsets?language=objc) as it needs to stretch. |
| .chatBubbleRight              | Background for reveright side chat bubble (first message) | Must be [sliced](https://developer.apple.com/documentation/uikit/uiimage/1624102-resizableimagewithcapinsets?language=objc) as it needs to stretch. |
| .chatBubbleRightRepeated              | Background for right side chat bubble (serial message) | Must be [sliced](https://developer.apple.com/documentation/uikit/uiimage/1624102-resizableimagewithcapinsets?language=objc) as it needs to stretch. |
| .iconRatingPositive   | Ratings view positive icon |  |
| .iconRatingNeutral   | Ratings view neutral icon |  |
| .iconRatingNegative   | Ratings view negative icon |  |
| .chatAvatarRight   | Placeholder avatar icon for my messages. |  |
| .chatAvatarLeft   | Placeholder avatar icon for others' messages. |  |
| .chatPlayVideo   | Play icon for videos |  |
| .iconTextareaCamera | Start video call button | |
| .iconTextareaAttachment | Add attachment button | |
| .textareaSubmitButton | Background for send message button | When button title is set |
| .iconTextareaSubmitButtonIcon | Icon for send message button | When no button title is set |
| .iconVideoToggleFull | Expand video to fullscreen | |
| .iconVideoToggleNormal | Shrink video to fit a window | |
| .iconVideoSoundOn | Sound is enabled | |
| .iconVideoSoundOff | Sound is muted | |
| .iconVideoMicrohoneOn | Microphone is enabled | |
| .iconVideoMicrophoneOff | Microphone is muted | |
| .iconVideoCameraOn | Camera is on | |
| .iconVideoCameraOff | Camera is off | |
| .iconVideoHangup | End the video call | |

## Overriding the Color Assets

Using the API delegate method `overrideColorAsset(session:forKey:)` you may supply your own color assets as `UIColor` objects. See the table below for explanations on the supported asset keys.

| Asset key       | Related UI control(s)
|:------------- |:-------------|
| .buttonPrimaryText | Text on 'primary' buttons
| .buttonSecondaryText | Text on 'secondary' buttons
| .infoText | Chat view's meta information (eg. 'Chat started')
| .chatName | User name above chat bubbles
| .chatTimestamp | Timestamp above chat bubbles
| .chatBubbleLeftText | Text in others' chat messages
| .chatBubbleRightText | Text in my chat messages
| .textareaText | Chat input text
| .textareaSubmitText | Message submit button title
| .chatBubbleLeftLink | Link color in others' messages
| .chatBubbleRightLink | Link color in my messages
| .modalBackground | Background in 'modal dialogs'
| .modalText | Text in 'modal dialogs'
| .backgroundTop | Background of the top part in some views
| .textTop | Text in top parts of some views
| .link | Link color (except in chat bubbles)
| .backgroundBottom | Background of the bottom part in some views
| .textBottom | Text in bottom parts of some views
| .ratingPositiveText | Text of the positive rating button
| .ratingNeutralText | Text of the neutral rating button
| .ratingNegativeText | Text of the negative rating button

## Contact

If you have any questions, feel free to contact me:
* Hassan Shahbazi / Ninchat <hassan@ninchat.com>
