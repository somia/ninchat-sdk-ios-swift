//
//  PrivateTypes.h
//  Pods
//
//  Created by Matti Dahlbom on 08/07/2018.
//

#ifndef PrivateTypes_h
#define PrivateTypes_h

@class NINWebRTCServerInfo;

typedef void (^emptyBlock)(void);
typedef void (^callbackWithErrorBlock)(NSError* _Nullable);
typedef void (^queueProgressCallback)(NSError* _Nullable error, NSInteger queuePosition);
typedef BOOL (^notificationBlock)(NSNotification* _Nonnull);
typedef void (^fetchSiteConfigCallbackBlock)(NSDictionary* _Nullable, NSError* _Nullable);
typedef void (^beginICECallbackBlock)(NSError* _Nullable, NSArray<NINWebRTCServerInfo*>* _Nullable stunServers, NSArray<NINWebRTCServerInfo*>* _Nullable turnServers);

// WebRTC client operating modes
typedef NS_CLOSED_ENUM(NSInteger, NINWebRTCClientOperatingMode) {
    NINWebRTCClientOperatingModeCaller,
    NINWebRTCClientOperatingModeCallee
};

// Values for chat rating
typedef NS_CLOSED_ENUM(NSInteger, NINChatRating) {
    // Do not change these values
    kNINChatRatingSad = -1,
    kNINChatRatingNeutral = 0,
    kNINChatRatingHappy = 1
};

#endif /* PrivateTypes_h */
