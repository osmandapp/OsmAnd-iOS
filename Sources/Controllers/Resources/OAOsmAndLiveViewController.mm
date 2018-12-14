//
//  OAOsmAndLiveViewController.mm
//  OsmAnd
//
//  Created by Paul on 11/29/18.
//  Copyright (c) 2018 OsmAnd. All rights reserved.
//

#import "OAOsmAndLiveViewController.h"

#import "OAResourcesBaseViewController.h"
#import "OsmAndApp.h"
#include "Localization.h"
#import "OALocalResourceInfoCell.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Reachability.h"

#import "OAOsmAndLiveHelper.h"

#include <OsmAndCore/IncrementalChangesManager.h>

#define kMapAvailableType @"availableMapType"
#define kMapEnabledType @"enabledMapType"

#define kCheckMapUrl @"https://osmand.net/api/osmlive_status"

typedef OsmAnd::ResourcesManager::LocalResource OsmAndLocalResource;

@interface OAOsmAndLiveViewController ()<UITableViewDelegate, UITableViewDataSource> {
    
    NSMutableArray *_enabledData;
    NSMutableArray *_availableData;
    
    NSArray *_localIndexes;
    
    NSDateFormatter *formatter;
    
}

@end

@implementation OAOsmAndLiveViewController
{
    OsmAndAppInstance _app;
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
    return _timeLabel.hidden ? osmAndLiveNavBarHeight : osmAndLiveNavBarHeight + _timeLabel.frame.size.height;
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

- (NSString *)getFrequencyString:(NSInteger)frequency {
    switch (frequency) {
        case 0:
            return OALocalizedString(@"osmand_live_hourly");
            break;
        case 1:
            return OALocalizedString(@"osmand_live_daily");
            break;
        case 2:
            return OALocalizedString(@"osmand_live_weekly");
            break;
            
        default:
            return @"";
            break;
    }
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
    NSInteger frequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:regionName];
    NSString *frequencyString = [self getFrequencyString:frequency];
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
    } completion:nil];
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
    
    return [OAMenuSimpleCellNoIcon getHeight:text desc:value cellWidth:tableView.bounds.size.width];
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

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == enabledIndex ? OALocalizedStringUp(@"osmand_live_updates") : OALocalizedStringUp(@"osmand_live_available_maps");
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    OAMenuSimpleCellNoIcon *cell = (OAMenuSimpleCellNoIcon *)[tableView dequeueReusableCellWithIdentifier:@"OAMenuSimpleCellNoIcon"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMenuSimpleCellNoIcon" owner:self options:nil];
        cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.descriptionView.hidden = item[@"description"] == nil || [item[@"description"] length] == 0 ? YES : NO;
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [cell.textView setTextColor:[UIColor blackColor]];
        [cell.textView setText:item[@"title"]];
        if ([item[@"type"] isEqualToString:kMapAvailableType])
            [cell.descriptionView setText:item[@"description"]];
        else
        {
            NSInteger frequency = [OAOsmAndLiveHelper getPreferenceFrequencyForLocalIndex:[item[@"id"]
                                                                                                    stringByReplacingOccurrencesOfString:@".map.obf" withString:@""]];
            NSString *frequencyString = [self getFrequencyString:frequency];
            NSMutableAttributedString *formattedText = [self setColorForText:frequencyString inText:item[@"description"] withColor:UIColorFromRGB(color_live_frequency)];
            cell.descriptionView.attributedText = formattedText;
        }
    }
    return cell;
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

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    const QString regionName = QString::fromNSString(item[@"id"]).remove(QStringLiteral(".map.obf"));
    if ([type isEqualToString:kMapAvailableType])
    {
        [_availableData removeObjectAtIndex:indexPath.row];
        NSDictionary *newItem =  @{
                                   @"id" : item[@"id"],
                                   @"title" : item[@"title"],
                                   @"description" : [self getLiveDescription:QString::fromNSString(item[@"id"])],
                                   @"type" : kMapEnabledType,
                                   };
        [_enabledData addObject:newItem];
        [OAOsmAndLiveHelper setDefaultPreferencesForLocalIndex:regionName.toNSString()];
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
            [OAOsmAndLiveHelper downloadUpdatesForRegion:regionName resourcesManager:_app.resourcesManager];
        
        [tableView reloadData];
        
    }
    else
    {
        [_enabledData removeObjectAtIndex:indexPath.row];
        NSDictionary *newItem =  @{
                                  @"id" : item[@"id"],
                                  @"title" : item[@"title"],
                                  @"description" : [self getDescription:QString::fromNSString(item[@"id"])],
                                  @"type" : kMapAvailableType,
                                  };
        [_availableData addObject:newItem];
        [OAOsmAndLiveHelper removePreferencesForLocalIndex:regionName.toNSString()];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _app.resourcesManager->changesManager->deleteUpdates(regionName);
        });
        [tableView reloadData];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
