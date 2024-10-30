//
//  OAOpenAddTrackViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

typedef NS_ENUM(NSInteger, EOAPlanningTrackScreenType) {
    EOAOpenExistingTrack = 0,
    EOAAddToATrack,
    EOAFollowTrack,
    EOASelectTrack
};

@class OASGpxFile;

@protocol OAOpenAddTrackDelegate <NSObject>

@required

- (void) onFileSelected:(NSString *)gpxFilePath;

@optional

- (void) closeBottomSheet;
- (void) onSegmentSelected:(NSInteger)position gpx:(OASGpxFile *)gpx;

@end

@interface OAOpenAddTrackViewController : OABaseNavbarViewController

@property (nonatomic, weak) id<OAOpenAddTrackDelegate> delegate;

- (instancetype) initWithScreenType:(EOAPlanningTrackScreenType)screenType;
- (instancetype) initWithScreenType:(EOAPlanningTrackScreenType)screenType showCurrent:(BOOL)showCurrent;

@end
