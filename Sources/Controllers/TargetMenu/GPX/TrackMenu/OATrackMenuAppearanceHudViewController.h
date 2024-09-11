//
//  OATrackMenuAppearanceHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OsmAndSharedWrapper.h"

@class OATrackMenuViewControllerState, OAColoringType, OAGPX;

@interface OATrackAppearanceItem : NSObject

@property (nonatomic) OAColoringType *coloringType;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *attrName;
@property (nonatomic, assign) BOOL isAvailable;
@property (nonatomic, assign) BOOL isEnabled;

- (instancetype)initWithColoringType:(OAColoringType *)coloringType
                               title:(NSString *)title
                            attrName:(NSString *)attrName
                         isAvailable:(BOOL)isAvailable
                           isEnabled:(BOOL)isEnabled;

@end

@interface OATrackMenuAppearanceHudViewController : OABaseTrackMenuHudViewController

// FIXME: remove
- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATrackMenuViewControllerState *)state;
- (instancetype)initWithGpx:(OAGPX *)gpx tracks:(NSArray<OAGPX *> *)tracks state:(OATrackMenuViewControllerState *)state;

- (instancetype)initWithNewGpx:(OASGpxDataItem *)gpx state:(OATrackMenuViewControllerState *)state;
- (instancetype)initWithNewGpx:(OASGpxDataItem *)gpx tracks:(NSArray<OASGpxDataItem *> *)tracks state:(OATrackMenuViewControllerState *)state;

@end
