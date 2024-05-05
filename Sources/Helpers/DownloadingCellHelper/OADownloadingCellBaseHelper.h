//
//  OADownloadingCellBaseHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, EOAItemStatusType)
{
    EOAItemStatusNone = -1,
    EOAItemStatusStartedType = 0,
    EOAItemStatusInProgressType,
    EOAItemStatusFinishedType
};

@class OARightIconTableViewCell;

@interface OADownloadingCellBaseHelper : NSObject

@property (weak, nonatomic) UITableView *hostTableView;

@property (nonatomic) NSString *rightIconName;
@property (nonatomic) BOOL isBoldStyle;
@property (nonatomic) BOOL isAlwaysClickable;
@property (nonatomic) BOOL isRghtIconAlwaysVisible;
@property (nonatomic) BOOL isDownloadedRecolored;


- (BOOL) isInstalled:(NSString *)resourceId;
- (BOOL) isDownloading:(NSString *)resourceId;
- (void) startDownload:(NSString *)resourceId;
- (void) stopDownload:(NSString *)resourceId;

- (OARightIconTableViewCell *) getOrCreateCell:(NSString *)resourceId;
- (OARightIconTableViewCell *) setupCell:(NSString *)resourceId;
- (OARightIconTableViewCell *) setupCell:(NSString *)resourceId title:(NSString *)title isTitleBold:(BOOL)isTitleBold desc:(NSString *)desc leftIconName:(NSString *)leftIconName rightIconName:(NSString *)rightIconName isDownloading:(BOOL)isDownloading;

- (void) onCellClicked:(NSString *)resourceId;

- (void) refreshCellProgress:(NSString *)resourceId;
- (void) setCellProgress:(NSString *)resourceId progress:(float)progress status:(EOAItemStatusType)status;
- (void) saveStatus:(EOAItemStatusType)status resourceId:(NSString *)resourceId;
- (void) saveProgress:(float)progress resourceId:(NSString *)resourceId;

- (void) onDownloadTaskProgressChanged:(NSString *)resourceId progress:(float)progress;
- (void) onDownloadTaskFinished:(NSString *)resourceId;

@end
