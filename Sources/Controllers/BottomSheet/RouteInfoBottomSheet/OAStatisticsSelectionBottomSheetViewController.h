//
//  OAStatisticsSelectionBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABottomSheetViewController.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAWaypointUIHelper.h"

@class OAGPXTrackAnalysis;

@class OAStatisticsSelectionBottomSheetViewController;

@protocol OAStatisticsSelectionDelegate <NSObject>

@required

- (void) onTypesSelected:(NSArray<NSNumber *> *)types;

@end

@interface OAStatisticsSelectionBottomSheetScreen : NSObject<OABottomSheetScreen>

@end

@interface OAStatisticsSelectionBottomSheetViewController : OABottomSheetTwoButtonsViewController

@property (nonatomic, readonly) NSArray<NSNumber *> *types;
@property (nonatomic, readonly) OAGPXTrackAnalysis *analysis;
@property (nonatomic, weak) id<OAStatisticsSelectionDelegate> delegate;

- (instancetype)initWithTypes:(NSArray<NSNumber *> *)types analysis:(OAGPXTrackAnalysis *)analysis;

@end

