//
//  OAPointOptionsBottomSheetViewController.h
//  OsmAnd
//
//  Created by Paul on 31.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"
#import "OAClearPointsCommand.h"
#import "OAInfoBottomView.h"

@class OAGpxTrkPt, OAMeasurementEditingContext;

@protocol OAPointOptionsBottmSheetDelegate <NSObject>

- (void) onMovePoint:(NSInteger)point;
- (void) onClearPoints:(EOAClearPointsMode)mode;
- (void) onAddPoints:(EOAAddPointMode)type;
- (void) onDeletePoint;

- (void) onChangeRouteTypeBefore;
- (void) onChangeRouteTypeAfter;
- (void) onSplitPointsBefore;
- (void) onSplitPointsAfter;
- (void) onJoinPoints;

- (void) onCloseMenu;
- (void) onClearSelection;

@end

@interface OAPointOptionsBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic, weak) id<OAPointOptionsBottmSheetDelegate> delegate;

- (instancetype) initWithPoint:(OAGpxTrkPt *)point index:(NSInteger)pointIndex editingContext:(OAMeasurementEditingContext *)editingContext;

@end
