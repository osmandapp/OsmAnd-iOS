//
//  OAOsmAndLiveViewController.mm
//  OsmAnd
//
//  Created by Paul on 11/29/18.
//  Copyright (c) 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveViewController.h"

#import "OAResourcesUIHelper.h"
#import "OAOsmAndLiveSelectionViewController.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#include "Localization.h"
#import "OALocalResourceInfoCell.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAIconTextDescCell.h"
#import "OAQuickSearchTableController.h"
#import "OADonationSettingsViewController.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAOsmLiveBannerView.h"
#import "OAChoosePlanHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAWorldRegion.h"

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

@interface OAOsmAndLiveViewController ()<UITableViewDelegate, UITableViewDataSource, OAOsmLiveBannerViewDelegate> {
    
    NSMutableArray *_enabledData;
    NSMutableArray *_availableData;
    
    NSMutableArray *_localIndexes;
    
    NSDateFormatter *formatter;
    
    UIView *_enabledHeaderView;
    UIView *_availableHeaderView;
    
    OAAutoObserverProxy* _osmAndLiveDownloadedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;
}

@end

@implementation OAOsmAndLiveViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;
    
    OAOsmLiveBannerView *_osmLiveBanner;
}

static const NSInteger enabledIndex = 0;
static const NSInteger availableIndex = 1;
static const NSInteger sectionCount = 2;

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"osmand_live_title");
    [_segmentControl setTitle:OALocalizedString(@"res_updates") forSegmentAtIndex:0];
    [_segmentControl setTitle:OALocalizedString(@"osmand_live_reports") forSegmentAtIndex:1];
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _iapHelper = [OAIAPHelper sharedInstance];
    _segmentControl.hidden = YES;
    _localIndexes = [NSMutableArray new];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    if (_osmLiveBanner)
        [_osmLiveBanner updateFrame:self.tableView.frame.size.width margin:[OAUtilities getLeftMargin]];
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self prefersStatusBarHidden];
    [self setupView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    
    _osmAndLiveDownloadedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onOsmAndLiveUpdated)
                                                                andObserve:_app.osmAndLiveUpdatedObservable];
    
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
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

- (void)buildTableDataAndRefresh {
    NSMutableArray *liveEnabled = [NSMutableArray array];
    NSMutableArray *liveDisabled = [NSMutableArray array];
    for (OALocalResourceItem *item : _localIndexes)
    {
        if (item.resourceType != OsmAnd::ResourcesManager::ResourceType::MapRegion
            || item.resourceId.compare(QString(kWorldSeamarksKey)) == 0
            || item.resourceId.compare(QString(kWorldBasemapKey)) == 0)
            continue;
        
        NSString *itemId = item.resourceId.toNSString();
        BOOL isLive = [OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:QString(item.resourceId).remove(QStringLiteral(".map.obf")).toNSString()];
        NSString *countryName = [OAResourcesUIHelper getCountryName:item];
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

- (void) setupView
{
    [self applySafeAreaMargins];
    [self setLastUpdateDate];
    [self adjustViews];
    
    if (!_iapHelper.subscribedToLiveUpdates)
    {
        OASubscription *cheapest = [_iapHelper getCheapestMonthlySubscription];
        if (cheapest && cheapest.formattedPrice)
        {
            NSString *minPriceStr = [NSString stringWithFormat:OALocalizedString(@"osm_live_payment_month_cost_descr"), cheapest.formattedMonthlyPrice];
            _osmLiveBanner = [OAOsmLiveBannerView bannerWithType:EOAOsmLiveBannerUnlockUpdates minPriceStr:minPriceStr];
            _osmLiveBanner.delegate = self;
            [_osmLiveBanner updateFrame:self.tableView.frame.size.width margin:[OAUtilities getLeftMargin]];
        }
    }
    else
    {
        _osmLiveBanner = nil;
    }
    self.tableView.tableHeaderView = _osmLiveBanner ? _osmLiveBanner : [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    self.donationSettings.hidden = ![_iapHelper.monthlyLiveUpdates isAnyPurchased];
    
    [self updateContent];
}

- (void) adjustViews
{
    CGRect buttonFrame = _backButton.frame;
    CGRect titleFrame = _titleView.frame;
    CGRect settingsButtonFrame = _donationSettings.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    buttonFrame.origin.y = statusBarHeight;
    titleFrame.origin.y = statusBarHeight;
    settingsButtonFrame.origin.y = statusBarHeight;
    _donationSettings.frame = settingsButtonFrame;
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
            buttonFrame.origin.x = DeviceScreenWidth - buttonFrame.size.width - leftMargin - 15.0;
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
            result = [result stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm"];
            NSDate *dateFromServer = [dateFormatter dateFromString:result];
            if (!dateFromServer)
                return;
            
            NSTimeInterval timeZoneSeconds = [[NSTimeZone localTimeZone] secondsFromGMT];
            NSDate *dateInLocalTimezone = [dateFromServer dateByAddingTimeInterval:timeZoneSeconds];
            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:0.3f animations:^{
                    _timeLabel.frame = CGRectMake(0, _timeLabel.frame.origin.y, DeviceScreenWidth, _timeLabel.frame.size.height);
                    [_timeLabel setText:[NSString stringWithFormat:OALocalizedString(@"osmand_live_server_date"), [dateFormatter stringFromDate:dateInLocalTimezone]]];
                    _timeLabel.hidden = NO;
                    [self applySafeAreaMargins];
                    [self adjustViews];
                }];
            });
        }
    });
}

- (void)onOsmAndLiveUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || !self.view.window || !self.tableView)
            return;
        
        [self buildTableDataAndRefresh];
    });
}

- (void)onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
            return;
        
        [self updateContent];
    });
}

-(void) updateContent
{
    for (const auto& resource : _app.resourcesManager->getLocalResources())
    {
        
        OAWorldRegion *match = [OAResourcesUIHelper findRegionOrAnySubregionOf:_app.worldRegion
                                                          thatContainsResource:resource->id];
        
        if (!match || (resource->type != OsmAnd::ResourcesManager::ResourceType::MapRegion))
            continue;
        
        OALocalResourceItem *item = [[OALocalResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        if (match)
            item.title = [OAResourcesUIHelper titleOfResource:resource
                                                     inRegion:match
                                               withRegionName:YES
                                             withResourceType:NO];
        else
            item.title = resource->id.toNSString();
        
        item.resource = resource;
        item.size = resource->size;
        item.worldRegion = match;
        
        if (item.title != nil)
        {
            if (![_localIndexes containsObject:item])
                [_localIndexes addObject:item];
        }
    }
    [_localIndexes sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSString *str1;
        NSString *str2;
        
        if ([obj1 isKindOfClass:[OAWorldRegion class]])
        {
            str1 = ((OAWorldRegion *)obj1).name;
        }
        else
        {
            OAResourceItem *item = obj1;
            str1 = [NSString stringWithFormat:@"%@%d", item.title, item.resourceType];
        }
        
        if ([obj2 isKindOfClass:[OAWorldRegion class]])
        {
            str2 = ((OAWorldRegion *)obj2).name;
        }
        else
        {
            OAResourceItem *item = obj2;
            str2 = [NSString stringWithFormat:@"%@%d", item.title, item.resourceType];
        }
        
        return [str1 localizedCaseInsensitiveCompare:str2];
    }];
    [self buildTableDataAndRefresh];
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
    return UITableViewAutomaticDimension;
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

- (IBAction) backButtonClicked:(id)sender;
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) donationSettingsClicked:(id)sender
{
    OADonationSettingsViewController *donationController = [[OADonationSettingsViewController alloc] init];
    [self.navigationController pushViewController:donationController animated:YES];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == enabledIndex)
        return _enabledData.count;
    else if (section == availableIndex)
        return _availableData.count;
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    OAIconTextDescCell* cell;
    cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAIconTextDescCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDescCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        
        cell.textView.numberOfLines = 0;
        cell.descView.font = [UIFont systemFontOfSize:12.];
        cell.iconView.hidden = YES;
        [cell.arrowIconView setTintColor:UIColorFromRGB(color_icon_inactive)];
    }
    if (cell)
    {
        [cell.textView setText:item[@"title"]];
        cell.descView.hidden = item[@"description"] == nil || [item[@"description"] length] == 0;
        BOOL isAvailable = [item[@"type"] isEqualToString:kMapAvailableType];
        if (!isAvailable)
        {
            ELiveUpdateFrequency frequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:[item[@"id"]
                                                                                                      stringByReplacingOccurrencesOfString:@".map.obf" withString:@""]];
            NSString *frequencyString = [OAOsmAndLiveHelper getFrequencyString:frequency];
            NSMutableAttributedString *formattedText = [self setColorForText:frequencyString inText:item[@"description"] withColor:UIColorFromRGB(color_live_frequency)];
            cell.descView.attributedText = formattedText;
        } else
            [cell.descView setText:item[@"description"]];
        [cell.arrowIconView setImage:[[UIImage imageNamed:isAvailable ? @"ic_action_plus" : @"menu_cell_pointer"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        if (isAvailable)
        {
            CGRect iconView = cell.arrowIconView.frame;
            CGFloat y = cell.frame.size.height / 2 - iconView.size.height / 2;
            iconView.origin.y = y;
            cell.arrowIconView.frame = iconView;
        }
    }
    return cell;
}

- (NSMutableAttributedString *) setColorForText:(NSString*)textToFind inText:(NSString *)wholeText withColor:(UIColor*)color
{
    NSRange range = [wholeText rangeOfString:textToFind options:NSCaseInsensitiveSearch];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:wholeText];
    if (range.location != NSNotFound)
        [string addAttribute:NSForegroundColorAttributeName value:color range:range];
    return string;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 55.0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
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

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat leftMargin = [OAUtilities getLeftMargin];
    switch (section)
    {
        case enabledIndex:
        {
            if (!_enabledHeaderView)
            {
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
                [button setOn:_settings.settingOsmAndLiveEnabled && _iapHelper.subscribedToLiveUpdates];
                [button addTarget:self action:@selector(sectionHeaderButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
                [headerView addSubview:button];
                [headerView addSubview:label];
                _enabledHeaderView = headerView;
            }
            return _enabledHeaderView;
        }
        case availableIndex:
        {
            if (!_availableHeaderView)
            {
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
        }
        default:
            return nil;
    }
}

- (void) sectionHeaderButtonPressed:(id)sender
{
    UISwitch *btn = (UISwitch *)sender;
    BOOL newValue = !_settings.settingOsmAndLiveEnabled;
    if (!_iapHelper.subscribedToLiveUpdates)
    {
        newValue = NO;
        [[[UIAlertView alloc] initWithTitle:nil message:OALocalizedString(@"osm_live_ask_for_purchase") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil] show];
    }
    [_settings setSettingOsmAndLiveEnabled:newValue];
    [btn setOn:newValue];
    if (newValue)
        [_app checkAndDownloadOsmAndLiveUpdates];
}

#pragma mark OAOsmLiveBannerViewDelegate

- (void) osmLiveBannerPressed
{
    [OAChoosePlanHelper showChoosePlanScreenWithProduct:nil navController:self.navigationController];
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

@end
