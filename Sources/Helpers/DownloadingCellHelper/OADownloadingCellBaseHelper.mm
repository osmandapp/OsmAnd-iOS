//
//  OADownloadingCellBaseHelper.m
//  OsmAnd Maps
//
//  Created by Max Kojin on 03/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OADownloadingCellBaseHelper.h"
#import "OAResourcesUIHelper.h"
#import "OARightIconTableViewCell.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OADownloadingCellBaseHelper
{
    NSMutableDictionary<NSString *, OARightIconTableViewCell *> *_cells;
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

- (OARightIconTableViewCell *) getOrCreateCell:(NSString *)resourceId
{
    if (!_statuses[resourceId])
        _statuses[resourceId] = @(EOAItemStatusNone);
    if (!_progresses[resourceId])
        _progresses[resourceId] = @(0.);
    
    OARightIconTableViewCell *cell = _cells[resourceId];
    if (!cell)
    {
        cell = [self setupCell:resourceId];
        _cells[resourceId] = cell;
    }
    return cell;
}

// Override in subclass
- (OARightIconTableViewCell *) setupCell:(NSString *)resourceId
{
    return [self setupCell:resourceId title:@"" isTitleBold:NO desc:nil leftIconName:nil rightIconName:nil isDownloading:NO];
}

// Override in subclass
- (OARightIconTableViewCell *) setupCell:(NSString *)resourceId title:(NSString *)title isTitleBold:(BOOL)isTitleBold desc:(NSString *)desc leftIconName:(NSString *)leftIconName rightIconName:(NSString *)rightIconName isDownloading:(BOOL)isDownloading
{
    if (!_hostTableView)
        return nil;
    
    OARightIconTableViewCell* cell = [_hostTableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OARightIconTableViewCell *) nib[0];
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
        cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_download"];
    }
    
    if (leftIconName && leftIconName.length > 0)
    {
        [cell leftIconVisibility:YES];
        cell.leftIconView.image = [UIImage templateImageNamed:leftIconName];
        cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    }
    else
    {
        [cell leftIconVisibility:NO];
    }
    
    cell.titleLabel.text = title;
    if (isTitleBold)
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
        cell.accessoryView = nil;
        if (rightIconName && rightIconName.length > 0)
        {
            if (![self isInstalled:resourceId])
            {
                [cell rightIconVisibility:YES];
                cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_download"];
                cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            }
            else
            {
                [cell rightIconVisibility:NO];
            }
        }
        else
        {
            [cell rightIconVisibility:NO];
        }
    }
    return cell;
}


#pragma mark - Cell behavior methods

// Default on click behavior
- (void) onCellClicked:(NSString *)resourceId
{
    if (![self isInstalled:resourceId])
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

// Override in subclass
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
    
    OARightIconTableViewCell *cell = _cells[resourceId];
    if (cell)
    {
        FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
        if (!progressView && status != EOAItemStatusFinishedType)
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
            progressView.progress = progress - 0.001;
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
                [cell rightIconVisibility:YES];
                [self saveStatus:EOAItemStatusNone resourceId:resourceId];
            }
            else
            {
                // Downloading success
                [cell rightIconVisibility:NO];
                cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            }
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.accessoryView = nil;
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
