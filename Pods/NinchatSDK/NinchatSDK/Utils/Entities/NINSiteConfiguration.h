//
//  NINSiteConfiguration.h
//  NinchatSDK
//
//  Created by Kosti Jokinen on 23/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Manages siteconfig data. */
@interface NINSiteConfiguration : NSObject

/** Environments to use. */
@property (nonatomic, strong) NSArray<NSString*>* environments;

/** Value for given key from selected config, or "default" if not available. */
-(id)valueForKey:(NSString*)key;

/** Returns the list of available configuration names. */
-(NSArray<NSString*>*)availableConfigurations;

/** Instantiates with provided siteconfig json. */
+(NINSiteConfiguration*)siteConfigurationWith:(NSDictionary*)dict;

@end
