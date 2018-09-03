//
//  OAFileNameTranslationHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAFileNameTranslationHelper : NSObject

+ (NSString *) getVoiceName:(NSString *)fileName;
+ (NSArray<NSString *> *) getVoiceNames:(NSArray *) languageCodes;

@end
