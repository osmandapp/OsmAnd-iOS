//
//  OAUploadOsmPOINoteViewProgressController.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 24.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAUploadOsmPOINoteViewProgressController.h"
#import "Localization.h"
#import "OAUploadOsmPointsAsyncTask.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAProgressBarCell.h"
#import "OAValueTableViewCell.h"
#import "OATextMultilineTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OARootViewController.h"
#import "GeneratedAssetSymbols.h"

#define kUploadingValueCell @"kUploadingValueCell"

typedef NS_ENUM(NSInteger, EOAOsmUploadViewConrollerMode) {
    EOAOsmUploadViewConrollerModeUploading = 0,
    EOAOsmUploadViewConrollerModeSuccess,
    EOAOsmUploadViewConrollerModeFailed
};

@interface OAUploadOsmPOINoteViewProgressController () <OAUploadTaskDelegate>

@end

@implementation OAUploadOsmPOINoteViewProgressController
{
    OATableDataModel *_data;
    
    OAProgressBarCell *_progressBarCell;
    OAValueTableViewCell *_progressValueCell;
    
    OAUploadOsmPointsAsyncTask *_uploadTask;
    EOAOsmUploadViewConrollerMode _mode;
}

#pragma mark - Initialization

- (instancetype)initWithParam:(id)param
{
    self = [super init];
    if (self)
    {
        _uploadTask = param;
        _mode = EOAOsmUploadViewConrollerModeUploading;
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"upload_to_openstreetmap");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getBottomButtonTitle
{
    switch (_mode)
    {
        case EOAOsmUploadViewConrollerModeUploading:
        case EOAOsmUploadViewConrollerModeSuccess:
            return OALocalizedString(@"shared_string_done");
        case EOAOsmUploadViewConrollerModeFailed:
            return OALocalizedString(@"retry");
        default:
            return @"";
    }
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    switch (_mode)
    {
        case EOAOsmUploadViewConrollerModeUploading:
            return EOABaseButtonColorSchemeInactive;
        case EOAOsmUploadViewConrollerModeSuccess:
            return EOABaseButtonColorSchemeGraySimple;
        case EOAOsmUploadViewConrollerModeFailed:
            return EOABaseButtonColorSchemePurple;
    }
}

#pragma mark - Table data

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    
    if (_mode == EOAOsmUploadViewConrollerModeFailed)
    {
        BOOL isNoInternet = !AFNetworkReachabilityManager.sharedManager.isReachable;
        
        OATableSectionData *section = [_data createNewSection];
        section.headerText = @" ";
        
        OATableRowData *titleRow = [section createNewRow];
        [titleRow setCellType:[OATextMultilineTableViewCell getCellIdentifier]];
        [titleRow setTitle: isNoInternet ? OALocalizedString(@"no_internet_avail") : OALocalizedString(@"osm_upload_failed_title")];
        [titleRow setObj:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                  forKey:@"font"];
        
        OATableRowData *descrRow = [section createNewRow];
        [descrRow setCellType:[OATextMultilineTableViewCell getCellIdentifier]];
        [descrRow setTitle: isNoInternet ? OALocalizedString(@"osm_upload_no_internet") :OALocalizedString(@"osm_upload_failed_descr")];
        [descrRow setObj:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                  forKey:@"font"];
    }
    else
    {
        _progressBarCell = [self getProgressBarCell];
        _progressValueCell = [self getProgressValueCell];
        
        OATableSectionData *uploadingSection = [_data createNewSection];
        uploadingSection.headerText = @" ";
        
        OATableRowData *progressValueCell = [uploadingSection createNewRow];
        [progressValueCell setCellType:[OAValueTableViewCell getCellIdentifier]];
        [progressValueCell setKey:kUploadingValueCell];
        OATableRowData *progressBarCell = [uploadingSection createNewRow];
        [progressBarCell setCellType:[OAProgressBarCell getCellIdentifier]];
    }
}

- (OAProgressBarCell *)getProgressBarCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAProgressBarCell getCellIdentifier] owner:self options:nil];
    OAProgressBarCell *resultCell = (OAProgressBarCell *)[nib objectAtIndex:0];
    [resultCell.progressBar setProgress:0.0 animated:NO];
    [resultCell.progressBar setProgressTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
    resultCell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return resultCell;
}

- (OAValueTableViewCell *)getProgressValueCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
    OAValueTableViewCell *resultCell = (OAValueTableViewCell *)[nib objectAtIndex:0];
    [resultCell descriptionVisibility:NO];
    [resultCell leftIconVisibility:NO];
    [resultCell setCustomLeftSeparatorInset:YES];
    resultCell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
    resultCell.titleLabel.text = OALocalizedString(@"shared_string_uploading");
    resultCell.valueLabel.text = @"0%";
    return resultCell;
}

- (NSString *)getTitleForHeader:(NSInteger)section;
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OAProgressBarCell getCellIdentifier]])
        return 22;
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *cellType = item.cellType;
    
    if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        NSString *key = [item key];
        if (key && [key isEqualToString:kUploadingValueCell])
            return _progressValueCell;
        
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = item.descr;
            cell.accessibilityLabel = item.title;
            cell.accessibilityValue = item.descr;
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
        }
        if (cell)
        {
            cell.textView.text = item.title;
            cell.textView.font = [item objForKey:@"font"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAProgressBarCell getCellIdentifier]])
    {
        return _progressBarCell;
    }
    return nil;
}

#pragma mark - Aditions

- (void)setProgress:(float)progress
{
    [_progressBarCell.progressBar setProgress:progress animated:YES];
    int percentage = (int)(progress * 100);
    _progressValueCell.valueLabel.text = [NSString stringWithFormat:@"%d%%", percentage];
}

- (void)setUploadResultWithFailedPoints:(NSArray<OAOsmPoint *> *)points successfulUploads:(NSInteger)successfulUploads
{
    if (points.count > 0)
    {
        _mode = EOAOsmUploadViewConrollerModeFailed;
        [self generateData];
        [self.tableView reloadData];
    }
    else
    {
        _mode = EOAOsmUploadViewConrollerModeSuccess;
    }
    [self setupBottomButtons];
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (_uploadTask)
        [_uploadTask setInterrupted:YES];
    
    [super onLeftNavbarButtonPressed];
}

- (void)onBottomButtonPressed
{
    if (_mode == EOAOsmUploadViewConrollerModeFailed)
    {
        _mode = EOAOsmUploadViewConrollerModeUploading;
        [self generateData];
        [self.tableView reloadData];
        _uploadTask.delegate = self;
        [_uploadTask retryUpload];
    }
    else
    {
        [super onLeftNavbarButtonPressed];
    }
}

#pragma mark - OAUploadTaskDelegate

- (void)uploadDidProgress:(float)progress
{
    [self setProgress:progress];
}

- (void)uploadDidFinishWithFailedPoints:(NSArray<OAOsmPoint *> *)points successfulUploads:(NSInteger)successfulUploads
{
    [self setUploadResultWithFailedPoints:points successfulUploads:successfulUploads];
}

- (void)uploadDidCompleteWithSuccess:(BOOL)success
{
    if ([self.delegate respondsToSelector:@selector(uploadFinished:)])
        [self.delegate uploadFinished:!success];
}

@end
