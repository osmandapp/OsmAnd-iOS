//
//  OADeleteWaypointsViewController.h
//  OsmAnd
//
//  Created by Skalii on 13.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAGPXTableSectionData;

@protocol OATrackMenuViewControllerDelegate;

@interface OADeleteWaypointsViewController : OACompoundViewController

- (instancetype)initWithSectionsData:(NSArray<OAGPXTableSectionData *> *)sectionsData
                      waypointGroups:(NSDictionary *)waypointGroups
                      isCurrentTrack:(BOOL)isCurrentTrack
                         gpxFilePath:(NSString *)gpxFilePath;

@property (nonatomic, weak) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

@end
