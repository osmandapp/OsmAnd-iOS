//
//  OADownloadingCellBaseHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OARightIconTableViewCell.h"

typedef NS_ENUM(NSInteger, EOAItemStatusType)
{
    EOAItemStatusNone = -1,
    EOAItemStatusStartedType = 0,
    EOAItemStatusInProgressType,
    EOAItemStatusFinishedType
};

typedef NS_ENUM(NSInteger, EOADownloadingCellRightIconType)
{
    EOADownloadingCellRightIconTypeHideIconAfterDownloading = 0,
    EOADownloadingCellRightIconTypeShowIconAlways,
    EOADownloadingCellRightIconTypeShowShevronAlways,
    EOADownloadingCellRightIconTypeShowIconAndShevronAlways,
    EOADownloadingCellRightIconTypeShowShevronBeforeDownloading,
    EOADownloadingCellRightIconTypeShowShevronAfterDownloading,
    EOADownloadingCellRightIconTypeShowInfoAndShevronAfterDownloading,
};

@interface OADownloadingCell : OARightIconTableViewCell

@end


@interface OADownloadingCellBaseHelper : NSObject

@property (nonatomic, copy) NSString *rightIconName;
@property (nonatomic, copy) NSString *rightIconColorName;
@property (nonatomic) BOOL isBoldTitleStyle;
@property (nonatomic) BOOL isAlwaysClickable;
@property (nonatomic) BOOL isDownloadedRecolored;
@property (nonatomic) EOADownloadingCellRightIconType rightIconStyle;

- (UITableView *) hostTableView;
- (void) setHostTableView:(UITableView *)tableView;

- (BOOL) helperHasItemFor:(NSString *)resourceId;
- (BOOL) isInstalled:(NSString *)resourceId;
- (BOOL) isDownloading:(NSString *)resourceId;
- (void) startDownload:(NSString *)resourceId;
- (void) stopDownload:(NSString *)resourceId;

- (OADownloadingCell *) getOrCreateCell:(NSString *)resourceId;
- (OADownloadingCell *) setupCell:(NSString *)resourceId;
- (OADownloadingCell *) setupCell:(NSString *)resourceId title:(NSString *)title isTitleBold:(BOOL)isTitleBold desc:(NSString *)desc leftIconName:(NSString *)leftIconName rightIconName:(NSString *)rightIconName isDownloading:(BOOL)isDownloading;
- (NSString *) getRightIconName;
- (NSString *) getRightIconColorName;

- (void) onCellClicked:(NSString *)resourceId;

- (void) refreshCellSpinners;
- (void) refreshCellProgress:(NSString *)resourceId;
- (void) setCellProgress:(NSString *)resourceId progress:(float)progress status:(EOAItemStatusType)status;
- (void) saveStatus:(EOAItemStatusType)status resourceId:(NSString *)resourceId;
- (void) saveProgress:(float)progress resourceId:(NSString *)resourceId;
- (void) cleanCellCache;

@end
