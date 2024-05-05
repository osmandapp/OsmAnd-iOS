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

@interface OADownloadingCell : OARightIconTableViewCell

@end


@interface OADownloadingCellBaseHelper : NSObject

@property (weak, nonatomic) UITableView *hostTableView;

@property (nonatomic) NSString *rightIconName;
@property (nonatomic) BOOL isBoldStyle;
@property (nonatomic) BOOL isAlwaysClickable;
@property (nonatomic) BOOL isRightIconAlwaysVisible;
@property (nonatomic) BOOL isShevronInsteadRightIcon;
@property (nonatomic) BOOL isDownloadedRecolored;


- (BOOL) isInstalled:(NSString *)resourceId;
- (BOOL) isDownloading:(NSString *)resourceId;
- (void) startDownload:(NSString *)resourceId;
- (void) stopDownload:(NSString *)resourceId;

- (OADownloadingCell *) getOrCreateCell:(NSString *)resourceId;
- (OADownloadingCell *) setupCell:(NSString *)resourceId;
- (OADownloadingCell *) setupCell:(NSString *)resourceId title:(NSString *)title isTitleBold:(BOOL)isTitleBold desc:(NSString *)desc leftIconName:(NSString *)leftIconName rightIconName:(NSString *)rightIconName isDownloading:(BOOL)isDownloading;
- (NSString *) getRightIconName;

- (void) onCellClicked:(NSString *)resourceId;

- (void) refreshCellProgresses;
- (void) refreshCellProgress:(NSString *)resourceId;
- (void) setCellProgress:(NSString *)resourceId progress:(float)progress status:(EOAItemStatusType)status;
- (void) saveStatus:(EOAItemStatusType)status resourceId:(NSString *)resourceId;
- (void) saveProgress:(float)progress resourceId:(NSString *)resourceId;

- (void) onDownloadTaskProgressChanged:(NSString *)resourceId progress:(float)progress;
- (void) onDownloadTaskFinished:(NSString *)resourceId;

@end
