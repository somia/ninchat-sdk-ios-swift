# Ninchat iOS SDK Swift Integrator's Guide

This document describes integrating the Ninchat iOS SDK into an iOS application.

## Installation

Install the SDK via CocoaPods.

Example Podfile:

```
platform :ios, '9.0'

source 'https://cdn.cocoapods.org/'
source 'https://github.com/somia/ninchat-podspecs.git'

target 'NinchatClient' do
    pod 'NinchatSDKSwift'
    pod 'NinchatSDK', :git => 'https://github.com/somia/ninchat-sdk-ios', :branch => 'swift'
end
```

Install by running `pod install`.

## Usage

#### Creating the API client

The SDK's API client is to be re-created every time a new chat session is started; once it has terminated, it cannot be used any more and must be disposed of to deallocate memory.

To initialize the client, you need a server address and a configuration key (and optionally a site secret). These will point the SDK to your chat server realm. You obtain these from Ninchat. Optionally, you may specify a list of siteconfig environments to use over the default one. 

You must keep a reference to the created API client instance until the SDK UI terminates.

```swift
import NinchatSDKSwift
import NinchatLowLevelClient

self.ninchatSession = NINChatSession(configKey: configKey, queueID: queueID, environments: environments)
self.ninchatSession.delegate = self
```

##### Optional parameters

* `siteSecret` is optional and may not be required for your deployment
* `queueID` define a valid queue ID to join the queue directly; specify nil to show queue selection view.

#### Starting the API client

The SDK must perform some asynchornous networking tasks before it is ready to use; this is done by calling the `start` method as follows:

```swift
ninchatSession.start { [unowned self] error in
    self.spinner.stopAnimating()
    self.startChatButton.isEnabled = true

    if let error = error {
        log.error("Ninchat SDK chat session failed to start with error: \(error))")
        self.ninchatSession = nil
        self.errorMessageLabel.text = "\(error)"
        return
    }
}
```


#### Showing the SDK UI

Once you have started the API client, you can retrieve its UI to be displayed in your application's UI stack. Typically you would do this within the `start` callback upon successful completion. The API returns an `UIViewController` which you must display using a `UINavigationController` as such:

```swift
do {
    let controller = try self.ninchatSession.viewController(withNavigationController: false)

    self.navigationController?.setNavigationBarHidden(true, animated: true)
    self.navigationController?.pushViewController(controller!, animated: true)
} catch {
    log.error("Failed to instantiate SDK UI: \(error.localizedDescription)")
}
```

If your application doesn't use an `UINavigationController`, specify `withNavigationController: true` and the SDK will provide one for you.

#### Implementing the API client's delegate methods

The SDK uses a delegate pattern for providing callbacks into the host application. See below for implementing these methods. All of these methods are always called on the main UI thread.

```swift
// MARK: From NINChatSessionDelegate

/// This method is called when the chat session has terminated.
/// The host app should remove the SDK UI from its UI stack and restore
/// the navigation bar if it uses one.
func didEndSession(session: NINChatSession) {
    log.debug("Ninchat session ended; removing the SDK UI");
    self.navigationController?.popToViewController(self, animated: true)
    ninchatSession = nil
    self.navigationController?.setNavigationBarHidden(false, animated: true)
}

/// This method is called when ever loading an overrideable graphics asset;
/// the host app may supply a custom UIImage to be shown in the SDK UI.
/// For any asset it does NOT wish to override, return nil.
func overrideColorAsset(session: NINChatSession, forKey assetKey: ColorConstants) -> UIColor? {
    switch assetKey {
    case .queueViewProgressIndicator:
        return UIImage.init(named: "icon_queue_progress_indicator")
    default:
        return nil
    }
}

/// This method is called when ever a low-level API event is received.
/// The host application may respond to these events by using the exposed
/// low-level library; see NINChatSession.session. Optional method.
func onLowLevelEvent(session: NINChatSession, params: NINLowLevelClientProps, payload: NINLowLevelClientPayload, lastReply: Bool) {
    let eventType = try! params.getString("event")
    switch eventType {
    case "channel_joined":
        log.debug("We joined a channel.");
    default:
        break
    }
}

/// This method is called when the SDK emits a log message. Optional method.
func didOutputSDKLog(session: NINChatSession, value: String) {
    log.debug("** NINCHAT SDK **: \(message)")
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

In addition, you will see the following linker error - which you may simply ignore - for the i386 architecture:

```sh
ld: warning: PIE disabled. Absolute addressing (perhaps -mdynamic-no-pic) not allowed in code signed PIE, but used in sync/atomic.(*Value).Store from /Users/matti/src/ninchat-sdk-ios-testclient/Pods/NinchatLowLevelClient/Frameworks/NinchatLowLevelClient.framework/NinchatLowLevelClient(go.o). To fix this warning, don't compile with -mdynamic-no-pic or link with -Wl,-no_pie
```

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

If you have any questions, contact:
* Hassan Shahbazi / Ninchat <hassan@ninchat.com>
