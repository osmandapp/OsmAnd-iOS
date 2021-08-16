//
//  OAProfileSettingsItem.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsItem.h"

@class OAApplicationMode, OAApplicationModeBean;

@interface OAProfileSettingsItem : OASettingsItem

@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) OAApplicationModeBean *modeBean;

+ (NSString *) getRendererByName:(NSString *)rendererName;
+ (NSString *) getRendererStringValue:(NSString *)renderer;
- (instancetype) initWithAppMode:(OAApplicationMode *)appMode;

@end
