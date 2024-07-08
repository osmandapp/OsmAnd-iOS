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
#import "Localization.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OARightIconTableViewCell.h"
#import "OAQuickSearchTableController.h"
#import "OADonationSettingsViewController.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OASubscriptionBannerCardView.h"
#import "OAChoosePlanHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAWorldRegion.h"
#import "OAOsmAndLiveHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/IncrementalChangesManager.h>

#define kLeftMarginTextLabel 12

#define kButtonTag 22
#define kEnabledLabelTag 23
#define kAvailableLabelTag 24

#define kMapAvailableType @"availableMapType"
#define kMapEnabledType @"enabledMapType"

#define kCheckMapUrl @"https://osmand.net/api/osmlive_status"

typedef OsmAnd::ResourcesManager::LocalResource OsmAndLocalResource;

@interface OAOsmAndLiveViewController () <UITableViewDelegate, UITableViewDataSource, OASubscriptionBannerCardViewDelegate>
{
    NSMutableArray *_enabledData;
    NSMutableArray *_availableData;
    
    NSMutableArray *_localIndexes;
    
    NSDateFormatter *formatter;
    
    UIView *_enabledHeaderView;
    UIView *_availableHeaderView;
    
    UIBarButtonItem *_donationSettings;
    UIStackView *_stackView;
    UILabel *_titleLabel;
    UILabel *_timeLabel;
    
    OAAutoObserverProxy* _osmAndLiveDownloadedObserver;
    OAAutoObserverProxy* _localResourcesChangedObserver;
}

@end

@implementation OAOsmAndLiveViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAIAPHelper *_iapHelper;
    OASubscriptionBannerCardView *_subscriptionBannerView;
}

static const NSInteger enabledIndex = 0;
static const NSInteger availableIndex = 1;
static const NSInteger sectionCount = 2;

- (void) viewDidLoad
{
    [super viewDidLoad];

    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _iapHelper = [OAIAPHelper sharedInstance];
    _localIndexes = [NSMutableArray new];
    
    [self createNavigationTitle];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.shadowColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurAppearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    blurAppearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    
    [self prefersStatusBarHidden];
    [self setupView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productRestored:) name:OAIAPProductsRestoredNotification object:nil];

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
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createNavigationTitle
{
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = UIColor.clearColor;
    _titleLabel.textColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    _titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightSemibold maximumSize:22.];
    _titleLabel.text = OALocalizedString(@"live_updates");
    
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.backgroundColor = UIColor.clearColor;
    _timeLabel.textColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    _timeLabel.font = [UIFont scaledSystemFontOfSize:13. maximumSize:18.];
    
    _stackView = [[UIStackView alloc] initWithArrangedSubviews:@[_titleLabel, _timeLabel]];
    _stackView.backgroundColor = UIColor.clearColor;
    _stackView.distribution = UIStackViewDistributionEqualCentering;
    _stackView.alignment = UIStackViewAlignmentCenter;
    _stackView.axis = UILayoutConstraintAxisVertical;
    [_stackView layoutSubviews];
    
    self.navigationItem.titleView = _stackView;
}

- (UIView *) getMiddleView
{
    return _tableView;
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
    NSString *regionName = QString(resourceId).remove(QStringLiteral(".obf")).toNSString();
    NSTimeInterval timestamp = [OAOsmAndLiveHelper getPreferenceLastUpdateForLocalIndex:regionName];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM dd, yyyy HH:mm"];
    NSString *dateString = timestamp == -1.0 ? OALocalizedString(@"osmand_live_not_updated") :
            [NSString stringWithFormat:OALocalizedString(@"last_update"), [formatter stringFromDate:date]];
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
            || !item.resource->localPath.startsWith(_app.resourcesManager->localStoragePath)
            || item.resourceId.compare(QString(kWorldSeamarksKey)) == 0
            || item.resourceId.compare(QString(kWorldBasemapKey)) == 0)
            continue;
        
        NSString *itemId = item.resourceId.toNSString();
        BOOL isLive = [OAOsmAndLiveHelper getPreferenceEnabledForLocalIndex:QString(item.resourceId).remove(QStringLiteral(".obf")).toNSString()];
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

- (void)setupSubscriptionBanner
{
    BOOL isSubscribed = [OAIAPHelper isSubscribedToLiveUpdates];
    if (!isSubscribed && !_subscriptionBannerView)
    {
        _subscriptionBannerView = [[OASubscriptionBannerCardView alloc] initWithType:EOASubscriptionBannerUpdates];
        _subscriptionBannerView.delegate = self;
    }
    else if (isSubscribed)
    {
        _subscriptionBannerView = nil;
    }

    if (_subscriptionBannerView)
        [_subscriptionBannerView updateView];

    self.tableView.tableHeaderView = _subscriptionBannerView ? _subscriptionBannerView : [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
}

- (void) setupView
{
    [self applySafeAreaMargins];
    [self setLastUpdateDate];
    [self setupSubscriptionBanner];
    [self updateContent];
    
    if ([_iapHelper.monthlyLiveUpdates isAnyPurchased] || [_iapHelper.proMonthly isAnyPurchased])
    {
        _donationSettings = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"ic_navbar_settings"] style:UIBarButtonItemStylePlain target:self action:@selector(donationSettingsClicked:)];
        [self.navigationController.navigationBar.topItem setRightBarButtonItem:_donationSettings animated:YES];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins];
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
        [self setupSubscriptionBanner];
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
                    [_timeLabel setText:[NSString stringWithFormat:OALocalizedString(@"osmand_live_server_date"), [dateFormatter stringFromDate:dateInLocalTimezone]]];
                    [self applySafeAreaMargins];
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
        item.date = [[[NSFileManager defaultManager] attributesOfItemAtPath:resource->localPath.toNSString() error:NULL] fileModificationDate];

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
    
    OARightIconTableViewCell* cell;
    cell = (OARightIconTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
        cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        [cell leftIconVisibility:NO];
    }
    if (cell)
    {
        [cell.titleLabel setText:item[@"title"]];
        [cell descriptionVisibility:item[@"description"] != nil || [item[@"description"] length] != 0];
        BOOL isAvailable = [item[@"type"] isEqualToString:kMapAvailableType];
        if (!isAvailable)
        {
            ELiveUpdateFrequency frequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:[item[@"id"]
                                                                                                      stringByReplacingOccurrencesOfString:@".obf" withString:@""]];
            NSString *frequencyString = [OAOsmAndLiveHelper getFrequencyString:frequency];
            NSMutableAttributedString *formattedText = [self setColorForText:frequencyString inText:item[@"description"] withColor:UIColorFromRGB(color_live_frequency)];
            cell.descriptionLabel.text = nil;
            cell.descriptionLabel.attributedText = formattedText;
        }
        else
        {
            cell.descriptionLabel.attributedText = nil;
            [cell.descriptionLabel setText:item[@"description"]];
        }
        [cell.rightIconView setImage:[[UIImage imageNamed:isAvailable ? @"ic_action_plus" : @"menu_cell_pointer"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        if (isAvailable)
        {
            CGRect iconView = cell.rightIconView.frame;
            CGFloat y = cell.frame.size.height / 2 - iconView.size.height / 2;
            iconView.origin.y = y;
            cell.rightIconView.frame = iconView;
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
    const QString regionName = QString::fromNSString(item[@"id"]).remove(QStringLiteral(".obf"));
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
                label.textColor = [[UIColor colorNamed:ACColorNameTextColorPrimary] colorWithAlphaComponent:0.5];
                [label setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
                label.adjustsFontForContentSizeCategory = YES;
                [label setText:[OALocalizedString(@"live_updates") upperCase]];
                [button setOn:_settings.settingOsmAndLiveEnabled.get && [OAIAPHelper isSubscribedToLiveUpdates]];
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
                label.textColor = [[UIColor colorNamed:ACColorNameTextColorPrimary] colorWithAlphaComponent:0.5];
                [label setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]];
                label.adjustsFontForContentSizeCategory = YES;
                [label setText:[OALocalizedString(@"available_maps") upperCase]];
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
    BOOL newValue = !_settings.settingOsmAndLiveEnabled.get;
    if (![OAIAPHelper isSubscribedToLiveUpdates])
    {
        newValue = NO;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_live_ask_for_purchase") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [_settings.settingOsmAndLiveEnabled set:newValue];
    [btn setOn:newValue];
    if (newValue)
        [_app checkAndDownloadOsmAndLiveUpdates];
}

#pragma mark - OASubscriptionBannerCardViewDelegate

- (void)onButtonPressed
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.HOURLY_MAP_UPDATES navController:self.navigationController];
}

- (void)productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
        CATransition *animation = [CATransition animation];
        [animation setType:kCATransitionPush];
        [animation setSubtype:kCATransitionFromBottom];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [animation setFillMode:kCAFillModeBoth];
        [animation setDuration:.3];
        [[self.tableView layer] addAnimation:animation forKey:@"UITableViewReloadDataAnimationKey"];
    });
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

- (void) productRestored:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
    });
}

@end
