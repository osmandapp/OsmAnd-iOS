//
//  OAOsmEditsSettingsItem.h
//  OsmAnd
//
//  Created by nnngrach on 01.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACollectionSettingsItem.h"
#import "OAOpenStreetMapPoint.h"

static NSString * const kID_KEY = @"id";
static NSString * const kNAME_KEY = @"name";
static NSString * const kLAT_KEY = @"lat";
static NSString * const kLON_KEY = @"lon";
static NSString * const kCOMMENT_KEY = @"comment";
static NSString * const kACTION_KEY = @"action";
static NSString * const kTYPE_KEY = @"type";
static NSString * const kTAGS_KEY = @"tags";
static NSString * const kENTITY_KEY = @"entity";
static NSString * const kAUTHOR_KEY = @"author";
static NSString * const kTEXT_KEY = @"text";

@interface OAOsmEditsSettingsItem : OACollectionSettingsItem<OAOpenStreetMapPoint *>

@end
