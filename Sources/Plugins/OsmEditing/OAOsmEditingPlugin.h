//
//  OAOsmEditingPlugin.h
//  OsmAnd
//
//  Created by Paul on 1/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OAOpenStreetMapUtilsProtocol;
@protocol OAOsmBugsUtilsProtocol;

@class OAOsmBugsDBHelper, OAOsmEditsDBHelper, OAOsmPoint;

@interface OAOsmEditingPlugin : OAPlugin

- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationUtil;
- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationLocalUtil;
- (id<OAOpenStreetMapUtilsProtocol>)getPoiModificationRemoteUtil;

- (id<OAOsmBugsUtilsProtocol>)getLocalOsmNotesUtil;
- (id<OAOsmBugsUtilsProtocol>)getOsmNotesRemoteUtil;

-(void) openOsmNote:(double)latitude longitude:(double)longitude message:(NSString *)message autoFill:(BOOL)autofill;

+ (NSString *) getTitle:(OAOsmPoint *)osmPoint;
+ (NSString *) getCategory:(OAOsmPoint *)point;

@end

NS_ASSUME_NONNULL_END
