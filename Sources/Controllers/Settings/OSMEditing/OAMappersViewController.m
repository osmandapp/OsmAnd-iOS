//
//  OAMappersViewController.m
//  OsmAnd
//
//  Created by Skalii on 05.09.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAMappersViewController.h"
#import "OARightIconTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAAppSettings.h"
#import "OANetworkUtilities.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import <SafariServices/SafariServices.h>
#import "GeneratedAssetSymbols.h"

#define USER_CHANGES_URL @"https://osmand.net/changesets/user-changes"
#define CONTRIBUTIONS_URL @"https://www.openstreetmap.org/user/"
#define CHANGES_FOR_MAPPER_PROMO 30
#define VISIBLE_MONTHS_COUNT 6

@interface OAMappersViewController () <SFSafariViewControllerDelegate>

@end

@implementation OAMappersViewController
{
    NSArray<NSArray *> *_data;
    NSMutableDictionary<NSNumber *, NSString *> *_headers;
    NSMutableDictionary<NSNumber *, NSString *> *_footers;

    OAAppSettings *_settings;
    NSDictionary<NSString *, NSNumber *> *_objectChanges;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _headers = [NSMutableDictionary dictionary];
    _footers = [NSMutableDictionary dictionary];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self downloadChangesInfo];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"map_updates_for_mappers");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];

    long expireTime = [_settings.mapperLiveUpdatesExpireTime get];
    BOOL isAvailable = expireTime > [NSDate date].timeIntervalSince1970;
    NSString *availableTitle;
    NSString *availableDescription;
    NSString *rightIcon;
    if (isAvailable)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        availableTitle = [[OALocalizedString(@"shared_string_available_until") stringByAppendingString:@" "]
                stringByAppendingString:[dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:expireTime]]];
        availableDescription = OALocalizedString(@"enough_contributions_descr");
        rightIcon = @"ic_custom_download_map";
    }
    else
    {
        availableTitle = OALocalizedString(@"map_updates_are_unavailable_yet");
        availableDescription = [NSString stringWithFormat:OALocalizedString(@"not_enough_contributions_descr"),
                @(CHANGES_FOR_MAPPER_PROMO).stringValue,
                [[@"(" stringByAppendingString:[self getMonthPeriod]] stringByAppendingString:@")"]];
        rightIcon = @"ic_custom_download_map_unavailable";
    }

    [data addObject:@[
            @{
                    @"type" : [OARightIconTableViewCell getCellIdentifier],
                    @"attributed_title" : [[NSAttributedString alloc] initWithString:availableTitle
                                                                         attributes:@{
                                                                                 NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                                                 NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
                                                                         }],
                    @"description" : availableDescription,
                    @"description_font" : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline],
                    @"right_icon" : rightIcon,
                    @"tint_color" : [UIColor colorNamed:ACColorNameIconColorActive],
                    @"top_right_content" : @(YES)
            },
            @{
                    @"key" : @"refresh_cell",
                    @"type": [OARightIconTableViewCell getCellIdentifier],
                    @"attributed_title": [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_refresh")
                                                                         attributes:@{
                                                                                 NSFontAttributeName : [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium],
                                                                                 NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorActive]
                                                                                     }],
                    @"right_icon": @"ic_custom_reset",
                    @"tint_color" : [UIColor colorNamed:ACColorNameIconColorActive]
            }
    ]];

    NSMutableArray<NSDictionary *> *dateCells = [NSMutableArray array];
    if (_objectChanges)
    {
        NSDateFormatter *formatterFrom = [[NSDateFormatter alloc] init];
        [formatterFrom setDateFormat:@"yyyy-LL"];
        NSDateFormatter *formatterTo = [[NSDateFormatter alloc] init];
        [formatterTo setDateFormat:@"LLLL yyyy"];
        NSDateFormatter *formatterMonth = [[NSDateFormatter alloc] init];
        [formatterMonth setDateFormat:@"LLLL"];
        NSDateFormatter *formatterYear = [[NSDateFormatter alloc] init];
        [formatterYear setDateFormat:@"yyyy"];

        NSDate *date = [NSDate date];
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        for (NSInteger i = 0; i < VISIBLE_MONTHS_COUNT; i ++)
        {
            NSString *dateStr = [formatterFrom stringFromDate:date];
            NSString *value = [_objectChanges.allKeys containsObject:dateStr] ? [_objectChanges[dateStr] stringValue] : @"0";

            NSMutableAttributedString *dateAttributed =
                    [[NSMutableAttributedString alloc] initWithString:[formatterTo stringFromDate:date].capitalizedString];
            [dateAttributed addAttribute:NSFontAttributeName
                                   value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                   range:NSMakeRange(0, dateAttributed.length)];
            [dateAttributed addAttribute:NSForegroundColorAttributeName
                                   value:[UIColor colorNamed:ACColorNameTextColorPrimary]
                                   range:[dateAttributed.string rangeOfString:[formatterMonth stringFromDate:date].capitalizedString]];
            [dateAttributed addAttribute:NSForegroundColorAttributeName
                                   value:[UIColor colorNamed:ACColorNameTextColorSecondary]
                                   range:[dateAttributed.string rangeOfString:[formatterYear stringFromDate:date]]];

            [dateCells addObject:@{
                    @"type": [OAValueTableViewCell getCellIdentifier],
                    @"attributed_title": dateAttributed,
                    @"value": value,
                    @"original_value" : dateStr
            }];

            date = [calendar dateByAddingUnit:NSCalendarUnitMonth value:-1 toDate:date options:0];
        }

        [dateCells sortUsingComparator:^NSComparisonResult(NSDictionary *cell1, NSDictionary *cell2) {
            return [cell2[@"original_value"] compare:cell1[@"original_value"]];
        }];
    }

    [dateCells insertObject:@{
            @"type": [OAValueTableViewCell getCellIdentifier],
            @"attributed_title": [[NSAttributedString alloc] initWithString:OALocalizedString(@"last_two_month_total")
                                                                 attributes:@{
                                                                         NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleBody],
                                                                         NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorPrimary]
                                                                 }],
            @"value": [NSString stringWithFormat:@"%li", [self getChangesSize]],
            @"description": [self getMonthPeriod]
    }
                    atIndex:0];

    NSString *userName = [_settings.osmUserDisplayName get];
    NSString *url = [[CONTRIBUTIONS_URL stringByAppendingString:
            [userName stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]
                                        stringByAppendingString:@"/history"];
    [dateCells addObject:@{
            @"key" : @"profile_cell",
            @"type" : [OARightIconTableViewCell getCellIdentifier],
            @"attributed_title" : [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_profile")
                                                                 attributes:@{
                                                                         NSFontAttributeName : [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium],
                                                                         NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorActive]
                                                                             }],
            @"right_icon" : @"ic_action_openstreetmap_logo",
            @"tint_color" : [UIColor colorNamed:ACColorNameIconColorActive],
            @"url" : [NSURL URLWithString:url]
    }];
    [data addObject:dateCells];
    _headers[@(data.count - 1)] = OALocalizedString(@"shared_string_contributions");
    _footers[@(data.count - 1)] = OALocalizedString(@"contributions_may_calculate_with_delay");

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _headers[@(section)];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _footers[@(section)];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.selectionStyle = [item.allKeys containsObject:@"key"] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

            BOOL fullSeparator = [[_headers objectForKey:@(indexPath.section)] isEqualToString:OALocalizedString(@"shared_string_contributions")] && indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 2;
            CGFloat leftInset = fullSeparator ? 0. : 20. + [OAUtilities getLeftMargin];
            cell.separatorInset = UIEdgeInsetsMake(0., leftInset, 0., 0.);

            cell.titleLabel.attributedText = item[@"attributed_title"];
            [cell descriptionVisibility:[item.allKeys containsObject:@"description"]];
            cell.descriptionLabel.text = item[@"description"];
            cell.descriptionLabel.font = [item.allKeys containsObject:@"description_font"] ? item[@"description_font"] : [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];

            BOOL hasRightIcon = [item.allKeys containsObject:@"right_icon"];
            cell.rightIconView.image = hasRightIcon ? [UIImage templateImageNamed:item[@"right_icon"]] : nil;
            cell.rightIconView.tintColor = item[@"tint_color"];

            BOOL topRightContent = item[@"top_right_content"];
            [cell anchorContent:topRightContent ? EOATableViewCellContentTopStyle : EOATableViewCellContentCenterStyle];
            [cell textIndentsStyle:topRightContent ? EOATableViewCellTextIncreasedTopCenterIndentStyle : EOATableViewCellTextNormalIndentsStyle];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 20., 0., 0.);
            cell.titleLabel.attributedText = item[@"attributed_title"];
            cell.valueLabel.text = item[@"value"];

            [cell descriptionVisibility:[item.allKeys containsObject:@"description"]];
            cell.descriptionLabel.text = item[@"description"];
            cell.descriptionLabel.font = [item.allKeys containsObject:@"description_font"] ? item[@"description_font"] : [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        }
        return cell;
    }

    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"profile_cell"])
    {
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:item[@"url"]];
        [self presentViewController:safariViewController animated:YES completion:nil];
    }
    if ([key isEqualToString:@"refresh_cell"])
    {
        [self downloadChangesInfo];
    }
}

#pragma mark - Additions

- (long)getChangesSize
{
    long changesSize = 0;
    NSDateFormatter *formatterFrom = [[NSDateFormatter alloc] init];
    [formatterFrom setDateFormat:@"yyyy-LL"];

    NSString *date = [formatterFrom stringFromDate:[NSDate date]];
    changesSize += [_objectChanges.allKeys containsObject:date] ? [_objectChanges[date] longValue] : 0;

    date = [formatterFrom stringFromDate:[NSCalendar.autoupdatingCurrentCalendar dateByAddingUnit:NSCalendarUnitMonth
                                                                                            value:-1
                                                                                           toDate:[NSDate date]
                                                                                          options:0]];
    changesSize += [_objectChanges.allKeys containsObject:date] ? [_objectChanges[date] longValue] : 0;

    return changesSize;
}

- (void)checkLastChanges
{
    long size = [self getChangesSize];
    if (size >= CHANGES_FOR_MAPPER_PROMO)
    {
        NSCalendar *calendar = NSCalendar.autoupdatingCurrentCalendar;
        NSDate *date = [NSDate date];
        date = [calendar dateByAddingUnit:NSCalendarUnitMonth value:1 toDate:date options:0];
        date = [calendar dateBySettingUnit:NSCalendarUnitDay value:16 ofDate:date options:0];
        date = [calendar dateBySettingUnit:NSCalendarUnitHour value:0 ofDate:date options:0];
        date = [calendar dateBySettingUnit:NSCalendarUnitMinute value:0 ofDate:date options:0];
        date = [calendar dateBySettingUnit:NSCalendarUnitSecond value:0 ofDate:date options:0];
        [_settings.mapperLiveUpdatesExpireTime set:(long) date.timeIntervalSince1970];
    }
    else
    {
        [_settings.mapperLiveUpdatesExpireTime resetToDefault];
    }
}

- (NSString *)getMonthPeriod
{
    NSDateFormatter *formatterFrom = [[NSDateFormatter alloc] init];
    [formatterFrom setDateFormat:@"LLLL"];
    NSString *currentMonth = [formatterFrom stringFromDate:[NSDate date]];
    NSString *prevMonth = [formatterFrom stringFromDate:[NSCalendar.autoupdatingCurrentCalendar dateByAddingUnit:NSCalendarUnitMonth
                                                                             value:-1
                                                                            toDate:[NSDate date]
                                                                           options:0]];
    return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_dash"), prevMonth.capitalizedString, currentMonth.capitalizedString];
}

- (void)downloadChangesInfo
{
    NSString *userName = [_settings.osmUserDisplayName get];
    NSMutableDictionary<NSString *, NSString *> *params = [NSMutableDictionary dictionary];
    params[@"name"] = userName;

    OANetworkRequest *request = [[OANetworkRequest alloc] init];
    request.url = USER_CHANGES_URL;
    request.params = params;
    request.post = NO;

    [OANetworkUtilities sendRequest:request async:YES onComplete:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
    {
        if (data && response)
        {
            NSMutableDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            if (((NSHTTPURLResponse *) response).statusCode == 200 && !error && result.count > 0)
            {
                @try
                {
                    _objectChanges = result[@"objectChanges"];
                    [self checkLastChanges];
                    [self generateData];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                    });
                }
                @catch (NSException *e)
                {
                    NSLog(e.reason);
                }
            }
        }
    }];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
