//
//  OARoutePreferencesMainScreen.h
//  OsmAnd
//
//  Created by Alexey Kulish on 02/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutePreferencesScreen.h"

@interface OARoutePreferencesMainScreen : NSObject<OARoutePreferencesScreen>

+ (void) applyVoiceProvider:(NSString *)provider;
+ (void) selectVoiceGuidance:(BOOL (^)(NSString * result))callback;

@end
