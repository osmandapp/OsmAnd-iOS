//
//  OAMapSettingsMapillaryScreen.h
//  OsmAnd
//
//  Created by Paul on 31/05/19.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapSettingsScreen.h"
#import "OAPOIUIFilter.h"

@protocol OAMapillaryScreenDelegate <NSObject>

@required

- (void) setData:(NSArray<NSString *> *)data;

@end

@interface OAMapSettingsMapillaryScreen : NSObject<OAMapSettingsScreen>

@end
