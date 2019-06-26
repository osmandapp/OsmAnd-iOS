//
//  OAUploadOsmPointsAsyncTask.h
//  OsmAnd
//
//  Created by Paul on 6/26/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAOsmEditingViewController.h"

@class OAOsmEditingPlugin;
@class OAOsmPoint;

@interface OAUploadOsmPointsAsyncTask : NSObject

- (id) initWithPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray<OAOsmPoint *> *)points closeChangeset:(BOOL)closeChangeset anonymous:(BOOL)anonymous comment:(NSString *)comment bottomSheetDelegate:(id<OAOsmEditingBottomSheetDelegate>)bottomSheetDelegate;

- (void) uploadPoints;

- (void) setInterrupted:(BOOL)interrupted;

@end
