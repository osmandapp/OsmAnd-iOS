//
//  OAGPXEditItemViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OAGPX;
@class OAGPXDocument;

@interface OAGPXEditItemViewControllerState : OATargetMenuViewControllerState

@property (nonatomic, assign) BOOL showFullScreen;
@property (nonatomic, assign) CGFloat scrollPos;
@property (nonatomic, assign) BOOL showCurrentTrack;

@end

@interface OAGPXEditItemViewController : OATargetMenuViewController

@property (nonatomic) OAGPX *gpx;

@property (nonatomic, readonly) BOOL showCurrentTrack;

- (id)initWithGPXItem:(OAGPX *)gpxItem;
- (id)initWithGPXItem:(OAGPX *)gpxItem ctrlState:(OAGPXEditItemViewControllerState *)ctrlState;
- (id)initWithCurrentGPXItem;
- (id)initWithCurrentGPXItem:(OAGPXEditItemViewControllerState *)ctrlState;


@end
