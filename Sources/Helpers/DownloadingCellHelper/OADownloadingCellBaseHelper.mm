//
//  OADownloadingCellBaseHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellBaseHelper.h"
#import "OAResourcesUIHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OADownloadingCell

@end


@implementation OADownloadingCellBaseHelper
{
    NSMutableDictionary<NSString *, OADownloadingCell *> *_cells;
    NSMutableDictionary<NSString *, NSNumber *> *_statuses;
    NSMutableDictionary<NSString *, NSNumber *> *_progresses;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cells = [NSMutableDictionary dictionary];
        _statuses = [NSMutableDictionary dictionary];
        _progresses = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Resource methods

// Override in subclass
- (BOOL) isInstalled:(NSString *)resourceId
{
    if (_statuses[resourceId])
    {
        EOAItemStatusType status = ((EOAItemStatusType)_statuses[resourceId].integerValue);
        if (status == EOAItemStatusFinishedType)
            return YES;
    }
    return NO;
}

// Override in subclass
- (BOOL) isDownloading:(NSString *)resourceId
{
    NSNumber *status = _statuses[resourceId];
    if (status)
        return status.integerValue == EOAItemStatusInProgressType;
    return NO;
}

- (void) startDownload:(NSString *)resourceId
{
    // Override in subclass
}

- (void) stopDownload:(NSString *)resourceId
{
    // Override in subclass
}


#pragma mark - Cell setup methods

- (OADownloadingCell *) getOrCreateCell:(NSString *)resourceId
{
    if (!_statuses[resourceId])
        _statuses[resourceId] = @(EOAItemStatusNone);
    if (!_progresses[resourceId])
        _progresses[resourceId] = @(0.);
    
    OADownloadingCell *cell = _cells[resourceId];
    if (!cell)
    {
        cell = [self setupCell:resourceId];
        _cells[resourceId] = cell;
    }
    return cell;
}

// Override in subclass
- (OADownloadingCell *) setupCell:(NSString *)resourceId
{
    return [self setupCell:resourceId title:@"" isTitleBold:NO desc:nil leftIconName:nil rightIconName:nil isDownloading:NO];
}

// Override in subclass
- (OADownloadingCell *) setupCell:(NSString *)resourceId title:(NSString *)title isTitleBold:(BOOL)isTitleBold desc:(NSString *)desc leftIconName:(NSString *)leftIconName rightIconName:(NSString *)rightIconName isDownloading:(BOOL)isDownloading
{
    if (!_hostTableView)
        return nil;
    
    OADownloadingCell *cell = _cells[resourceId];
    if (cell == nil)
        cell = [_hostTableView dequeueReusableCellWithIdentifier:[OADownloadingCell getCellIdentifier]];
    
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADownloadingCell getCellIdentifier] owner:self options:nil];
        cell = (OADownloadingCell *) nib[0];
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
        cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        cell.rightIconView.image = [UIImage templateImageNamed:[self getRightIconName]];
    }
    
    if (leftIconName && leftIconName.length > 0)
    {
        [cell leftIconVisibility:YES];
        cell.leftIconView.image = [UIImage templateImageNamed:leftIconName];
        if ([self isInstalled:resourceId] && _isDownloadedRecolored)
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        else
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
        
    }
    else
    {
        [cell leftIconVisibility:NO];
    }
    
    cell.titleLabel.text = title ? title : @"";
    if (isTitleBold || _isBoldStyle)
    {
        cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
        cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
    }
    else
    {
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    }
    
    if (desc && desc.length > 0)
    {
        [cell descriptionVisibility:YES];
        cell.descriptionLabel.text = desc;
        cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        cell.descriptionLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    }
    else
    {
        [cell descriptionVisibility:NO];
    }
    
    if (isDownloading)
    {
        [cell rightIconVisibility:NO];
        _cells[resourceId] = cell;
        [self refreshCellProgress:resourceId];
    }
    else
    {
        [self setupRightIconForIdleCell:cell rightIconName:rightIconName resourceId:resourceId];
    }
    return cell;
}

- (void) setupRightIconForIdleCell:(OADownloadingCell *)cell rightIconName:(NSString *)rightIconName resourceId:(NSString *)resourceId
{
    if (_isShevronInsteadRightIcon)
    {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell.accessoryView = nil;
        cell.accessoryType = UITableViewCellAccessoryNone;
        if (rightIconName && rightIconName.length > 0)
        {
            cell.rightIconView.image = [UIImage templateImageNamed:[self getRightIconName]];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            if ([self isInstalled:resourceId] && !_isRightIconAlwaysVisible)
                [cell rightIconVisibility:NO];
            else
                [cell rightIconVisibility:YES];
        }
        else
        {
            [cell rightIconVisibility:NO];
        }
    }
}

- (NSString *) getRightIconName
{
    return _rightIconName ? _rightIconName : @"ic_custom_download";
}

#pragma mark - Cell behavior methods

// Default on click behavior
- (void) onCellClicked:(NSString *)resourceId
{
    if (![self isInstalled:resourceId] || _isAlwaysClickable)
    {
        if (![self isDownloading:resourceId])
            [self startDownload:resourceId];
        else
            [self stopDownload:resourceId];
    }
    else
    {
        // do nothing
    }
}

#pragma mark - Cell progress update methods

- (void) refreshCellProgresses
{
    for (NSString *resourceId in [_cells allKeys])
    {
        OADownloadingCell *cell = _cells[resourceId];
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
        if (progressView && progressView.isSpinning)
            [progressView startSpinProgressBackgroundLayer];
    }
}

- (void) refreshCellProgress:(NSString *)resourceId
{
    float progress = _progresses[resourceId] ? _progresses[resourceId].floatValue : 0.;
    EOAItemStatusType status = _statuses[resourceId] ? ((EOAItemStatusType) _statuses[resourceId].intValue) : EOAItemStatusNone;
    [self setCellProgress:resourceId progress:progress status:status];
}

- (void) setCellProgress:(NSString *)resourceId progress:(float)progress status:(EOAItemStatusType)status
{
    [self saveStatus:status resourceId:resourceId];
    [self saveProgress:progress resourceId:resourceId];
    
    OADownloadingCell *cell = _cells[resourceId];
    if (cell)
    {
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
        if (!progressView && status != EOAItemStatusFinishedType && status != EOAItemStatusNone)
        {
            progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0., 0., 25., 25.)];
            progressView.iconView = [[UIView alloc] init];
            progressView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.accessoryView = progressView;
            [cell rightIconVisibility:NO];
            status = EOAItemStatusStartedType;
        }
        
        if (status == EOAItemStatusStartedType)
        {
            progressView.iconPath = [UIBezierPath bezierPath];
            progressView.progress = 0.;
            if (!progressView.isSpinning)
                [progressView startSpinProgressBackgroundLayer];
        }
        else if (status == EOAItemStatusInProgressType)
        {
            progressView.iconPath = nil;
            if (progressView.isSpinning)
                [progressView stopSpinProgressBackgroundLayer];
            float visualProgress = progress - 0.001;
            if (visualProgress < 0.001)
                visualProgress = 0.001;
            progressView.progress = visualProgress;
        }
        else if (status == EOAItemStatusFinishedType)
        {
            if (progressView)
            {
                progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
                progressView.progress = 0.;
                if (!progressView.isSpinning)
                    [progressView startSpinProgressBackgroundLayer];
            }
            
            if (progress < 1)
            {
                // Downloading interupted by user
                [self saveStatus:EOAItemStatusNone resourceId:resourceId];
            }
            [self setupRightIconForIdleCell:cell rightIconName:[self getRightIconName] resourceId:resourceId];
        }
    }
}

- (void) saveStatus:(EOAItemStatusType)status resourceId:(NSString *)resourceId
{
    _statuses[resourceId] = @(status);
}

- (void) saveProgress:(float)progress resourceId:(NSString *)resourceId
{
    _progresses[resourceId] = @(progress);
}

@end
