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

@class OASWptPt, OAMeasurementEditingContext;

@protocol OAPointOptionsBottmSheetDelegate <NSObject>

- (void) onMovePoint:(NSInteger)point;
- (void) onClearPoints:(EOAClearPointsMode)mode;
- (void) onAddPoints:(EOAAddPointMode)type;
- (void) onDeletePoint;

- (void) onChangeRouteTypeBefore;
- (void) onChangeRouteTypeAfter;

@optional
- (void) onSplitPointsBefore;
- (void) onSplitPointsAfter;
- (void) onJoinPoints;

- (void) onCloseMenu;

@required
- (void) onClearSelection;

@end

@interface OAPointOptionsBottomSheetViewController : OABaseBottomSheetViewController

@property (nonatomic, weak) id<OAPointOptionsBottmSheetDelegate> delegate;

- (instancetype) initWithPoint:(OASWptPt *)point index:(NSInteger)pointIndex editingContext:(OAMeasurementEditingContext *)editingContext;

@end
