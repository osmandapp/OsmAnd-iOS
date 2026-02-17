//
//  OATargetInfoViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAAmenityInfoRow.h"

static NSString *kCollapseDetailsRowType = @"kCollapseDetailsRowType";
static NSString *kDescriptionRowType = @"kDescriptionRowType";
static NSString *kShortDescriptionRowType = @"kShortDescriptionRowType";
static NSString *kShortDescriptionWikiRowType = @"kShortDescriptionWikiRowType";
static NSString *kShortDescriptionTravelRowType = @"kShortDescriptionTravelRowType";
static NSString *kCommentRowType = @"kCommentRowType";
static NSString *kTimestampRowType = @"kTimestampRowType";
static NSString *kGroupRowType = @"kGroupRowType";

@interface OATargetInfoViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSArray<OAAmenityInfoRow *> *additionalRows;

@property (nonatomic) BOOL showTitleIfTruncated;
@property (nonatomic) BOOL customOnlinePhotosPosition;

- (BOOL) needBuildCoordinatesRow;
- (void) buildTopInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows;
- (void) buildMainImage:(NSMutableArray<OAAmenityInfoRow *> *)rows;
- (void) buildDescription:(NSMutableArray<OAAmenityInfoRow *> *)rows;
- (void) buildInternal:(NSMutableArray<OAAmenityInfoRow *> *)rows;
- (void) buildMenu:(NSMutableArray<OAAmenityInfoRow *> *)rows;
- (void) buildDateRow:(NSMutableArray<OAAmenityInfoRow *> *)rows timestamp:(NSDate *)timestamp;
- (void) buildCommentRow:(NSMutableArray<OAAmenityInfoRow *> *)rows comment:(NSString *)comment;
- (void) buildPhotosRow;
- (void) buildCoordinateRows:(NSMutableArray<OAAmenityInfoRow *> *)rows;
- (void) rebuildRows;
- (void) setInfoRows:(NSMutableArray<OAAmenityInfoRow *> *)rows;
- (void) appendInfoRow:(OAAmenityInfoRow *)row;

+ (UIImage *) getIcon:(NSString *)fileName;
+ (UIImage *) getIcon:(NSString *)fileName size:(CGSize)size;

@end
