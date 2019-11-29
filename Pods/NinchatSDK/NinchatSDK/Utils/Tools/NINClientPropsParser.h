//
//  NINClientPropsParser.h
//  AppRTC
//
//  Created by Matti Dahlbom on 12/07/2018.
//

#import <Foundation/Foundation.h>

@import NinchatLowLevelClient;

/** Parses a ClientProps object via its -accept method. */
@interface NINClientPropsParser : NSObject <NINLowLevelClientPropVisitor>

/** Parsed properties. The value types will be NSString, NSNumber, ClientProps, ClientObjects or ClientStrings. */
@property (nonatomic, strong) NSDictionary<NSString*, id>* properties;

@end
