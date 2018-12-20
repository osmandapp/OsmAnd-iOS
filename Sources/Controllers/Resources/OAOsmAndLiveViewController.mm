//
//  OAOsmAndLiveViewController.mm
//  OsmAnd
//
//  Created by Paul on 11/29/18.
//  Copyright (c) 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveViewController.h"

#import "OAResourcesBaseViewController.h"
#import "OAOsmAndLiveSelectionViewController.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#include "Localization.h"
#import "OALocalResourceInfoCell.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAIconTextDescCell.h"
#import "OAQuickSearchTableController.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASizes.h"
#import "OAColors.h"

#import "OAOsmAndLiveHelper.h"

#include <OsmAndCore/IncrementalChangesManager.h>

#define kLeftMarginTextLabel 12

#define kButtonTag 22
#define kEnabledLabelTag 23
#define kAvailableLabelTag 24

#define kMapAvailableType @"availableMapType"
#define kMapEnabledType @"enabledMapType"

#define kCheckMapUrl @"https://osmand.net/api/osmlive_status"

typedef OsmAnd::ResourcesManager::LocalResource OsmAndLocalResource;

@interface OAOsmAndLiveViewController ()<UITableViewDelegate, UITableViewDataSource> {
    
    NSMutableArray *_enabledData;
    NSMutableArray *_availableData;
    
    NSArray *_localIndexes;
    
    NSDateFormatter *formatter;
    
    UIView *_enabledHeaderView;
    UIView *_availableHeaderView;
    
}

@end

@implementation OAOsmAndLiveViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
}

static const NSInteger enabledIndex = 0;
static const NSInteger availableIndex = 1;
static const NSInteger sectionCount = 2;

- (void) setLocalResources:(NSArray *)localResources;
{
    _localIndexes = localResources;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"osmand_live_title");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_segmentControl setTitle:OALocalizedString(@"res_updates") forSegmentAtIndex:0];
    [_segmentControl setTitle:OALocalizedString(@"osmand_live_reports") forSegmentAtIndex:1];
}

-(void)viewDidLoad
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _segmentControl.hidden = YES;
    [super viewDidLoad];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(CGFloat) getNavBarHeight
{
    CGFloat height = osmAndLiveNavBarHeight - (_segmentControl.hidden ? _segmentControl.frame.size.height : 0.0);
    return _timeLabel.hidden ? height : height + _timeLabel.frame.size.height;
}

- (NSString *) getDescription:(QString) resourceId
{
    uint64_t timestamp = _app.resourcesManager->getResourceTimestamp(resourceId);
    if (timestamp == -1)
        return @"";
    
    // Convert timestamp to seconds
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:(timestamp / 1000)];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd, yyyy HH:mm"];
    NSString *description = [NSString stringWithFormat:OALocalizedString(@"osmand_live_last_changed"), [formatter stringFromDate:date]];
    return description;
}

- (NSString *) getLiveDescription:(QString) resourceId
{
    NSString *regionName = QString(resourceId).remove(QStringLiteral(".map.obf")).toNSString();
    NSTimeInterval timestamp = [OAOsmAndLiveHelper getPreferenceLastUpdateForLocalIndex:regionName];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd, yyyy HH:mm"];
    NSString *dateString = timestamp == -1.0 ? OALocalizedString(@"osmand_live_not_updated") :
            [NSString stringWithFormat:OALocalizedString(@"osmand_live_last_live_update"), [formatter stringFromDate:date]];
    ELiveUpdateFrequency frequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:regionName];
    NSString *frequencyString = [OAOsmAndLiveHelper getFrequencyString:frequency];
    NSString *description = [NSString stringWithFormat:@"%@ • %@", frequencyString, dateString];
    return description;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    [self setLastUpdateDate];
    [self adjustViews];
    NSMutableArray *liveEnabled = [NSMutableArray array];
    NSMutableArray *liveDisabled = [NSMutableArray array];
    for (LocalResourceItem *item : _localIndexes)
    {
        NSString *itemId = item.resourceId.toNSString();
        BOOL isLive = [OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:QString(item.resourceId).remove(QStringLiteral(".map.obf")).toNSString()];
        NSString *countryName = [OAResourcesBaseViewController getCountryName:item];
        NSString *title = countryName == nil ? item.title : [NSString stringWithFormat:@"%@ %@", countryName, item.title];
        // Convert to seconds
        NSString * description = isLive ? [self getLiveDescription:item.resourceId] : [self getDescription:item.resourceId];
        NSDictionary *listItem = @{
                                   @"id" : itemId,
                                   @"title" : title,
                                   @"description" : description,
                                   @"type" : isLive ? kMapEnabledType : kMapAvailableType,
                                   };

        if (isLive)
            [liveEnabled addObject:listItem];
        else
            [liveDisabled addObject:listItem];
    }
    _enabledData = [NSMutableArray arrayWithArray:liveEnabled];
    _availableData = [NSMutableArray arrayWithArray:liveDisabled];
    [self.tableView reloadData];
}

- (void) adjustViews
{
    CGRect buttonFrame = _backButton.frame;
    CGRect titleFrame = _titleView.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    buttonFrame.origin.y = statusBarHeight;
    titleFrame.origin.y = statusBarHeight;
    _backButton.frame = buttonFrame;
    _titleView.frame = titleFrame;
    if (!_timeLabel.hidden)
    {
        CGRect timeLabelFrame = _timeLabel.frame;
        timeLabelFrame.origin.y = titleFrame.origin.y + titleFrame.size.height - 5.0;
        _timeLabel.frame = timeLabelFrame;
    }
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins];
        [self adjustViews];
        if (_enabledHeaderView)
        {
            UIView *switchView = [_enabledHeaderView viewWithTag:kButtonTag];
            CGRect buttonFrame = switchView.frame;
            CGFloat leftMargin = [OAUtilities getLeftMargin];
            buttonFrame.origin.x = _enabledHeaderView.frame.size.width - buttonFrame.size.width - leftMargin - 15.0;
            buttonFrame.origin.y = _enabledHeaderView.frame.size.height - buttonFrame.size.height - 10.0;
            switchView.frame = buttonFrame;
            UIView *label = [_enabledHeaderView viewWithTag:kEnabledLabelTag];
            [self adjustLabelToMargin:label parentView:_enabledHeaderView];
        }
        if (_availableHeaderView)
        {
            UIView *label = [_availableHeaderView viewWithTag:kAvailableLabelTag];
            [self adjustLabelToMargin:label parentView:_availableHeaderView];
        }
    } completion:nil];
}

-(void) adjustLabelToMargin:(UIView *)view parentView:(UIView *) parent
{
    view.frame = CGRectMake(kLeftMarginTextLabel + [OAUtilities getLeftMargin], 50 - 18, parent.frame.size.width, 18);
}

- (void) setLastUpdateDate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString * result = nil;
        NSError *err = nil;
        NSURL * urlToRequest = [NSURL   URLWithString:kCheckMapUrl];
        if(urlToRequest)
            result = [NSString stringWithContentsOfURL: urlToRequest
                                              encoding:NSUTF8StringEncoding error:&err];
        
        if(!err)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3f animations:^{
                    _timeLabel.frame = CGRectMake(0, _timeLabel.frame.origin.y, DeviceScreenWidth, _timeLabel.frame.size.height);
                    [_timeLabel setText:[NSString stringWithFormat:OALocalizedString(@"osmand_live_server_date"), result]];
                    _timeLabel.hidden = NO;
                    [self applySafeAreaMargins];
                    [self adjustViews];
                }];
            });
        }
    });
}

#pragma mark - UITableViewDataSource

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *value = item[@"description"];
    NSString *text = item[@"title"];
    return [OAIconTextDescCell getHeight:text value:value cellWidth:tableView.bounds.size.width];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    switch (section) {
        case enabledIndex:
            return _enabledData[indexPath.row];
        case availableIndex:
            return _availableData[indexPath.row];
        default:
            return nil;
    }
}

-(IBAction)backButtonClicked:(id)sender;
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == enabledIndex)
        return _enabledData.count;
    else if (section == availableIndex)
        return _availableData.count;
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    OAIconTextDescCell* cell = [OAQuickSearchTableController getIconTextDescCell:item[@"title"] tableView:tableView typeName:item[@"description"] icon:nil];
    BOOL isAvailable = [item[@"type"] isEqualToString:kMapAvailableType];
    if (!isAvailable)
    {
        ELiveUpdateFrequency frequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:[item[@"id"]
                                                                                                  stringByReplacingOccurrencesOfString:@".map.obf" withString:@""]];
        NSString *frequencyString = [OAOsmAndLiveHelper getFrequencyString:frequency];
        NSMutableAttributedString *formattedText = [self setColorForText:frequencyString inText:item[@"description"] withColor:UIColorFromRGB(color_live_frequency)];
        cell.descView.attributedText = formattedText;
    }
    [cell showImage:NO];
    [cell.arrowIconView setImage:[UIImage imageNamed:isAvailable ? @"ic_action_plus" : @"menu_cell_pointer"]];
    [self updateCellSizes:cell];
    if (isAvailable)
    {
        CGRect iconView = cell.arrowIconView.frame;
        CGFloat y = cell.frame.size.height / 2 - iconView.size.height / 2;
        iconView.origin.y = y;
        cell.arrowIconView.frame = iconView;
    }
    return cell;
}

-(void)updateCellSizes:(OAIconTextDescCell *)cell
{
    CGFloat w = cell.bounds.size.width;
    CGFloat h = cell.bounds.size.height;
    
    CGFloat titleTextWidthKoef = (320.0 / 154.0);
    
    CGFloat textX = 11.0;
    CGFloat textWidth = w - titleTextWidthKoef;
    CGFloat titleHeight = [OAUtilities calculateTextBounds:cell.textView.text width:w font:[UIFont fontWithName:@"AvenirNext-Regular" size:16.0]].height + 5.0 * 2;
    
    if (cell.descView.hidden)
    {
        cell.textView.frame = CGRectMake(textX, 0.0, textWidth, MAX(50.0, titleHeight));
    }
    else
    {
        CGFloat descHeight = [OAUtilities calculateTextBounds:cell.descView.text width:w font:[UIFont fontWithName:@"AvenirNext-Regular" size:13.0]].height + 5.0 * 2;
        cell.textView.frame = CGRectMake(textX, 0.0, textWidth, titleHeight);
        cell.descView.frame = CGRectMake(textX, h - descHeight, textWidth, descHeight);
    }
}

-(NSMutableAttributedString *)setColorForText:(NSString*)textToFind inText:(NSString *)wholeText withColor:(UIColor*) color
{
    NSRange range = [wholeText rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:wholeText];
    if (range.location != NSNotFound)
        [string addAttribute:NSForegroundColorAttributeName value:color range:range];
    return string;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 55.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    const QString regionName = QString::fromNSString(item[@"id"]).remove(QStringLiteral(".map.obf"));
    OAOsmAndLiveSelectionViewController *selectionController = [[OAOsmAndLiveSelectionViewController alloc] initWithRegionName:regionName titleName:item[@"title"]];
    [self.navigationController pushViewController:selectionController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat leftMargin = [OAUtilities getLeftMargin];
    switch (section) {
        case enabledIndex:
            if (!_enabledHeaderView) {
                UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 55.0)];
                CGRect viewFrame = headerView.frame;
                UISwitch *button = [[UISwitch alloc] init];
                button.tag = kButtonTag;
                CGRect buttonFrame = button.frame;
                buttonFrame.origin.x = viewFrame.size.width - buttonFrame.size.width - leftMargin - 15.0;
                buttonFrame.origin.y = viewFrame.size.height - buttonFrame.size.height - 10.0;
                button.frame = buttonFrame;
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kLeftMarginTextLabel + leftMargin, 50 - 18, tableView.frame.size.width, 18)];
                label.tag = kEnabledLabelTag;
                label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
                [label setFont:[UIFont systemFontOfSize:13]];
                [label setText:[OALocalizedString(@"osmand_live_updates") upperCase]];
                [button setOn:_settings.settingOsmAndLiveEnabled];
                [button addTarget:self action:@selector(sectionHeaderButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:button];
                [headerView addSubview:label];
                _enabledHeaderView = headerView;
            }
            return _enabledHeaderView;
        case availableIndex:
            if (!_availableHeaderView) {
                UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 55.0)];
                UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kLeftMarginTextLabel + leftMargin, 50 - 18, tableView.frame.size.width, 18)];
                label.tag = kAvailableLabelTag;
                label.textColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
                [label setFont:[UIFont systemFontOfSize:13]];
                [label setText:[OALocalizedString(@"osmand_live_available_maps") upperCase]];
                [headerView addSubview:label];
                _availableHeaderView = headerView;
            }
            return _availableHeaderView;
        default:
            return nil;
    }
}

-(void) sectionHeaderButtonPressed:(id)sender
{
    UISwitch *btn = (UISwitch *)sender;
    BOOL newValue = !_settings.settingOsmAndLiveEnabled;
    [_settings setSettingOsmAndLiveEnabled:newValue];
    [btn setOn:newValue];
}

@end
