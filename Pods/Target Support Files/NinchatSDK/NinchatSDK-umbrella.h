#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "NINMessageThrottler.h"
#import "NINSessionManager.h"
#import "NINVideoThumbnailManager.h"
#import "NinchatSDK.h"
#import "NINChatSession.h"
#import "NINPublicTypes.h"
#import "NINChoiceDialog.h"
#import "NINChoiceDialogRow.h"
#import "NINCloseChatButton.h"
#import "NINConfirmCloseChatDialog.h"
#import "NINExpandingTextView.h"
#import "NINNavigationBar.h"
#import "NINToast.h"
#import "NINVideoCallConsentDialog.h"
#import "NINChatBubbleCell.h"
#import "NINChatMetaCell.h"
#import "NINChatView.h"
#import "NINComposeMessageView.h"
#import "NINChatViewController.h"
#import "NINFullScreenImageViewController.h"
#import "NINInitialViewController.h"
#import "NINBaseViewController.h"
#import "NINQueueViewController.h"
#import "NINRatingViewController.h"
#import "NINAvatarConfig.h"
#import "NINChannelMessage.h"
#import "NINChannelUser.h"
#import "NINChatMessage.h"
#import "NINChatMetaMessage.h"
#import "NINFileInfo.h"
#import "NINQueue.h"
#import "NINSiteConfiguration.h"
#import "NINTextMessage.h"
#import "NINUIComposeMessage.h"
#import "NINUserTypingMessage.h"
#import "NINChatSession+Internal.h"
#import "NINPrivateTypes.h"
#import "NINUtils.h"
#import "NINClientPropsParser.h"
#import "NINPermissions.h"
#import "NSDateFormatter+Ninchat.h"
#import "NSMutableAttributedString+Ninchat.h"
#import "NSString+Ninchat.h"
#import "UIButton+Ninchat.h"
#import "NINTouchView.h"
#import "UIImageView+Ninchat.h"
#import "UITextView+Ninchat.h"
#import "RTCICECandidate+Dictionary.h"
#import "RTCSessionDescription+Dictionary.h"
#import "NINWebRTCClient.h"
#import "NINWebRTCServerInfo.h"

FOUNDATION_EXPORT double NinchatSDKVersionNumber;
FOUNDATION_EXPORT const unsigned char NinchatSDKVersionString[];

