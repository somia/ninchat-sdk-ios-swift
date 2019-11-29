//
//  NINSiteConfiguration.m
//  NinchatSDK
//
//  Created by Kosti Jokinen on 23/08/2019.
//  Copyright © 2019 Somia Reality Oy. All rights reserved.
//

#import "NINSiteConfiguration.h"

@interface NINSiteConfiguration ()

@property (nonatomic, strong) NSDictionary* configDict;

@end

@implementation NINSiteConfiguration

-(id)valueForKey:(NSString*)key {
    for (NSString* env in self.environments) {
        NSObject* value = self.configDict[env][key];
        if (value != nil) {
            return value;
        }
    }
    return self.configDict[@"default"][key];
}

-(NSArray<NSString*>*)availableConfigurations {
    return [self.configDict allKeys];
}

/** Instantiates with provided siteconfig json. */
+(NINSiteConfiguration*)siteConfigurationWith:(NSDictionary*)dict {
    NINSiteConfiguration* config = [[NINSiteConfiguration alloc] init];
    config.configDict = dict;
    return config;
}

@end
