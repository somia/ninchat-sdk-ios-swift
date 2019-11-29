//
//  NINPermissions.h
//  NinchatSDK
//
//  Created by Matti Dahlbom on 21/11/2018.
//  Copyright © 2018 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "NINPrivateTypes.h"

NS_ASSUME_NONNULL_BEGIN

/** Checks that the user has given the permission to access the Photo Library. */
void checkPhotoLibraryPermission(callbackWithErrorBlock callback);

/** Checks that the user has given the permission to access microphone. */
void checkMicrophonePermission(callbackWithErrorBlock callback);

/** Checks that the user has given the permission to access the camera. */
void checkVideoPermission(callbackWithErrorBlock callback);

NS_ASSUME_NONNULL_END
