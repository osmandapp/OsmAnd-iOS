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
#import "OAColors.h"
#import "Localization.h"
#import <SafariServices/SafariServices.h>

#define USER_CHANGES_URL @"https://osmand.net/changesets/user-changes"
#define CONTRIBUTIONS_URL @"https://www.openstreetmap.org/user/"
#define CHANGES_FOR_MAPPER_PROMO 30
#define VISIBLE_MONTHS_COUNT 6

@interface OAMappersViewController () <UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate>

@end

@implementation OAMappersViewController
{
    NSArray<NSArray *> *_data;
    NSMutableDictionary<NSNumber *, NSString *> *_headers;
    NSMutableDictionary<NSNumber *, NSString *> *_footers;

    OAAppSettings *_settings;
    NSDictionary<NSString *, NSNumber *> *_objectChanges;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _headers = [NSMutableDictionary dictionary];
    _footers = [NSMutableDictionary dictionary];

    [self generateData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self downloadChangesInfo];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionFooterHeight = 0.001;
    self.tableView.sectionHeaderHeight = kHeaderHeightDefault;

    self.subtitleLabel.text = @"";
    self.subtitleLabel.hidden = YES;
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"map_updates_for_mappers");
}

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
                                                                                 NSFontAttributeName : [UIFont systemFontOfSize:17.],
                                                                                 NSForegroundColorAttributeName : UIColor.blackColor
                                                                         }],
                    @"description" : availableDescription,
                    @"description_font" : [UIFont systemFontOfSize:15.],
                    @"right_icon" : rightIcon,
                    @"tint_color" : UIColorFromRGB(color_primary_purple),
                    @"top_right_content" : @(YES)
            },
            @{
                    @"key" : @"refresh_cell",
                    @"type": [OARightIconTableViewCell getCellIdentifier],
                    @"attributed_title": [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_refresh")
                                                                         attributes:@{
                                                                                 NSFontAttributeName : [UIFont systemFontOfSize:17. weight:UIFontWeightMedium],
                                                                                 NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple)
                                                                                     }],
                    @"right_icon": @"ic_custom_reset",
                    @"tint_color" : UIColorFromRGB(color_primary_purple)
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
                                   value:[UIFont systemFontOfSize:17.]
                                   range:NSMakeRange(0, dateAttributed.length)];
            [dateAttributed addAttribute:NSForegroundColorAttributeName
                                   value:UIColor.blackColor
                                   range:[dateAttributed.string rangeOfString:[formatterMonth stringFromDate:date].capitalizedString]];
            [dateAttributed addAttribute:NSForegroundColorAttributeName
                                   value:UIColorFromRGB(color_text_footer)
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
                                                                         NSFontAttributeName : [UIFont systemFontOfSize:17.],
                                                                         NSForegroundColorAttributeName : UIColor.blackColor
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
                                                                         NSFontAttributeName : [UIFont systemFontOfSize:17. weight:UIFontWeightMedium],
                                                                         NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple)
                                                                             }],
            @"right_icon" : @"ic_action_openstreetmap_logo",
            @"tint_color" : UIColorFromRGB(color_primary_purple),
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
    }];
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.selectionStyle = [item.allKeys containsObject:@"key"] ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

            BOOL fullSeparator = [[_headers objectForKey:@(indexPath.section)] isEqualToString:OALocalizedString(@"shared_string_contributions")] && indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 2;
            CGFloat leftInset = fullSeparator ? 0. : 20. + [OAUtilities getLeftMargin];
            cell.separatorInset = UIEdgeInsetsMake(0., leftInset, 0., 0.);

            cell.titleLabel.attributedText = item[@"attributed_title"];
            [cell descriptionVisibility:[item.allKeys containsObject:@"description"]];
            cell.descriptionLabel.text = item[@"description"];
            cell.descriptionLabel.font = [item.allKeys containsObject:@"description_font"] ? item[@"description_font"] : [UIFont systemFontOfSize:13.];

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
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = UIColor.blackColor;
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 20., 0., 0.);
            cell.titleLabel.attributedText = item[@"attributed_title"];
            cell.valueLabel.text = item[@"value"];

            [cell descriptionVisibility:[item.allKeys containsObject:@"description"]];
            cell.descriptionLabel.text = item[@"description"];
            cell.descriptionLabel.font = [item.allKeys containsObject:@"description_font"] ? item[@"description_font"] : [UIFont systemFontOfSize:13.];
        }
        return cell;
    }

    return nil;
}

#pragma mark - UITableViewDelegate

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _headers[@(section)];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _footers[@(section)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = _headers[@(section)];
    if (header)
    {
        UIFont *font = [UIFont systemFontOfSize:13.];
        CGFloat headerHeight = [OAUtilities calculateTextBounds:header
                                                          width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                           font:font].height + kPaddingOnSideOfHeaderWithText;
        return headerHeight;
    }

    return kHeaderHeightDefault;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
