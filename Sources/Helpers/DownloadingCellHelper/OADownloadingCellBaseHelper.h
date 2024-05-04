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

- (OARightIconTableViewCell *) getOrCreateCellForResourceId:(NSString *)resourceId;

- (OARightIconTableViewCell *) setupCellForResourceId:(NSString *)resourceId;
- (OARightIconTableViewCell *) setupCellForResourceId:(NSString *)resourceId title:(NSString *)title isTitleBold:(BOOL)isTitleBold desc:(NSString *)desc leftIconName:(NSString *)leftIconName rightIconName:(NSString *)rightIconName isDownloading:(BOOL)isDownloading;

- (void) updateCellProgressForResourceId:(NSString *)resourceId;

- (void) saveStatus:(EOAItemStatusType)status resourceId:(NSString *)resourceId;
- (void) saveProgress:(float)progress resourceId:(NSString *)resourceId;
- (void) setProgressForResourceId:(NSString *)resourceId progress:(float)progress status:(EOAItemStatusType)status;
- (BOOL) isInstalled:(NSString *)resourceId;

- (void) onDownloadTaskProgressChanged:(NSString *)resourceId progress:(float)progress;
- (void) onDownloadTaskFinished:(NSString *)resourceId;

@end
