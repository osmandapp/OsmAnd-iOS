//
//  OAFollowTrackBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OAGPXDocument;

@protocol OAFollowTrackBottomSheetDelegate <NSObject>

@optional

- (void) reloadUI;

@end


@interface OAFollowTrackBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic) id<OAFollowTrackBottomSheetDelegate> delegate;

- (instancetype) initWithFile:(OAGPXDocument *)gpx;
- (void)presentOpenTrackViewController:(BOOL)animated;

@end
