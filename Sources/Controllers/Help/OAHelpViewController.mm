//
//  OATripRecordingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAHelpViewController.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "Localization.h"
#import "OAWebViewController.h"
#import "OALinks.h"
#import "OAAppVersionDependentConstants.h"

#define kLinkInternalType @"internal_link"
#define kLinkExternalType @"ext_link"
#define kContactAction @"send_email"

#define contactEmailUrl @"mailto:support@osmand.net"

@interface OAHelpViewController ()

@end

@implementation OAHelpViewController
{
    NSArray *_firstStepsData;
    NSArray *_featuresData;
    NSArray *_pluginsData;
    NSArray *_otherData;
    NSArray *_followData;
}

static const NSInteger firstStepsIndex = 0;
static const NSInteger featuresIndex = 1;
static const NSInteger pluginsIndex = 2;
static const NSInteger otherIndex = 3;
static const NSInteger followIndex = 4;
static const NSInteger groupCount = 5;


-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"shared_string_help");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
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

- (void) setupView
{
    [self applySafeAreaMargins];
    NSMutableArray *dataArr = [NSMutableArray array];
    
    [dataArr addObject:
     @{
       @"name" : @"help_first_use",
       @"title" : OALocalizedString(@"first_usage_item"),
       @"description" : OALocalizedString(@"help_first_use_descr"),
       @"type" : kLinkInternalType,
       @"html" : @"start"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"help_navigation",
       @"title" : OALocalizedString(@"routing_settings"),
       @"description" : OALocalizedString(@"help_navigation_descr"),
       @"type" : kLinkInternalType,
       @"html" : @"navigation"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"help_faq",
       @"title" : OALocalizedString(@"faq_item"),
       @"description" : OALocalizedString(@"help_faq_descr"),
       @"type" : kLinkInternalType,
       @"html" : @"faq"
       }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_legend",
      @"title" : OALocalizedString(@"map_legend"),
      @"description" : OALocalizedString(@"help_legend_descr"),
      @"type" : kLinkInternalType,
      @"html" : @"map-legend"
      }];
    
    _firstStepsData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    // Features
    [dataArr addObject:
     @{
       @"name" : @"help_map_viewing",
       @"title" : OALocalizedString(@"map_viewing_item"),
       @"type" : kLinkInternalType,
       @"html" : @"map-viewing"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"help_search",
       @"title" : OALocalizedString(@"help_search"),
       @"type" : kLinkInternalType,
       @"html" : @"find-something-on-map"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"help_trip_planning",
       @"title" : OALocalizedString(@"planning_trip_item"),
       @"type" : kLinkInternalType,
       @"html" : @"trip-planning"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"help_navigation_profiles",
       @"title" : OALocalizedString(@"navigation_profiles_item"),
       @"type" : kLinkInternalType,
       @"html" : @"navigation-profiles"
       }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_purchases",
      @"title" : OALocalizedString(@"osmand_purchases_item"),
      @"type" : kLinkInternalType,
      @"html" : @"osmand_purchases"
      }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_osmand_live",
      @"title" : OALocalizedString(@"subscription_osmandlive_item"),
      @"type" : kLinkInternalType,
      @"html" : @"subscription"
      }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_favorites",
      @"title" : OALocalizedString(@"favorites_item"),
      @"type" : kLinkInternalType,
      @"html" : @"favourites"
      }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_markers",
      @"title" : OALocalizedString(@"map_markers"),
      @"type" : kLinkInternalType,
      @"html" : @"map-markers"
      }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_travel",
      @"title" : OALocalizedString(@"help_travel"),
      @"type" : kLinkInternalType,
      @"html" : @"travel"
      }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_ruler",
      @"title" : OALocalizedString(@"map_widget_ruler_control"),
      @"type" : kLinkInternalType,
      @"html" : @"ruler"
      }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_quick_action",
      @"title" : OALocalizedString(@"configure_screen_quick_action"),
      @"type" : kLinkInternalType,
      @"html" : @"quick-action"
      }];
    
    [dataArr addObject:
    @{
      @"name" : @"help_mapillary",
      @"title" : OALocalizedString(@"help_mapillary"),
      @"type" : kLinkInternalType,
      @"html" : @"mapillary"
      }];
    
    _featuresData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    // Plugins
    [dataArr addObject:
     @{
       @"name" : @"online_maps",
       @"title" : OALocalizedString(@"shared_string_online_maps"),
       @"type" : kLinkInternalType,
       @"html" : @"online-maps-plugin"
       }];
    [dataArr addObject:
     @{
       @"name" : @"trip_recording",
       @"title" : OALocalizedString(@"monitoring_settings"),
       @"type" : kLinkInternalType,
       @"html" : @"trip-recording-plugin"
       }];
    [dataArr addObject:
     @{
       @"name" : @"contour_lines",
       @"title" : OALocalizedString(@"srtm_plugin_name"),
       @"type" : kLinkInternalType,
       @"html" : @"contour-lines-plugin"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"parking_position",
       @"title" : OALocalizedString(@"product_title_parking"),
       @"type" : kLinkInternalType,
       @"html" : @"parking-plugin"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"nautical_maps",
       @"title" : OALocalizedString(@"product_title_nautical"),
       @"type" : kLinkInternalType,
       @"html" : @"nautical-charts"
       }];
    
    [dataArr addObject:
    @{
      @"name" : @"osm_editing",
      @"title" : OALocalizedString(@"osm_editing_plugin_name"),
      @"type" : kLinkInternalType,
      @"html" : @"osm-editing-plugin"
      }];
    
    [dataArr addObject:
     @{
       @"name" : @"ski_map",
       @"title" : OALocalizedString(@"product_desc_skimap"),
       @"type" : kLinkInternalType,
       @"html" : @"ski-plugin"
       }];
    
    _pluginsData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    // Other
    [dataArr addObject:
     @{
       @"name" : @"help_what_is_new",
       @"title" : OALocalizedString(@"help_what_is_new"),
       @"type" : kLinkExternalType,
       @"description" : kDocsLatestVersion
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"install_and_troublesoot",
       @"title" : OALocalizedString(@"instalation_troubleshooting_item"),
       @"type" : kLinkInternalType,
       @"html" : @"installation-and-troubleshooting"
       }];
    
    // issue #355 no versions html for ios
    /*
    [dataArr addObject:
     @{
       @"name" : @"versions",
       @"title" : OALocalizedString(@"versions_item"),
       @"type" : kLinkInternalType,
       @"html" : @"changes"
       }];
     */
    
    [dataArr addObject:
     @{
       @"name" : @"contact_us",
       @"title" : OALocalizedString(@"help_contact_us"),
       @"type" : kContactAction
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"feedback",
       @"title" : OALocalizedString(@"feedback"),
       @"description" : kOsmAndPoll,
       @"type" : kLinkExternalType
       }];
    
    NSString *versionNumber = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    [dataArr addObject:
     @{
       @"name" : @"about",
       @"title" : OALocalizedString(@"shared_string_about"),
       @"description" : [NSString stringWithFormat:@"%@ %@", @"OsmAnd", OAAppVersionDependentConstants.getVersion],
       @"type" : kLinkInternalType,
       @"html" : @"about"
       }];
    
    _otherData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    // Follow us
    [dataArr addObject:
     @{
       @"name" : @"twitter",
       @"title" : OALocalizedString(@"twitter"),
       @"description" : kCommunityTwitter,
       @"type" : kLinkExternalType
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"reddit",
       @"title" : OALocalizedString(@"reddit"),
       @"description" : kCommunityReddit,
       @"type" : kLinkExternalType
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"facebook",
       @"title" : OALocalizedString(@"facebook"),
       @"description" : kCommunityFacebook,
       @"type" : kLinkExternalType
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"vk",
       @"title" : OALocalizedString(@"vk"),
       @"description" : kCommunityVk,
       @"type" : kLinkExternalType
       }];
    
    _followData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    [self.tableView reloadData];
    
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    long section = indexPath.section;
    switch (section) {
        case firstStepsIndex:
            return _firstStepsData[indexPath.row];
        case featuresIndex:
            return _featuresData[indexPath.row];
        case pluginsIndex:
            return _pluginsData[indexPath.row];
        case otherIndex:
            return _otherData[indexPath.row];
        case followIndex:
            return _followData[indexPath.row];
        default:
            return nil;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return groupCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == firstStepsIndex)
        return _firstStepsData.count;
    else if (section == featuresIndex)
        return _featuresData.count;
    else if (section == pluginsIndex)
        return _pluginsData.count;
    else if (section == otherIndex)
        return _otherData.count;
    else if (section == followIndex)
        return _followData.count;
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    OAMenuSimpleCellNoIcon *cell = (OAMenuSimpleCellNoIcon *)[tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCellNoIcon getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCellNoIcon getCellIdentifier] owner:self options:nil];
        cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.descriptionView.hidden = item[@"description"] == nil || [item[@"description"] length] == 0 ? YES : NO;
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [cell.textView setTextColor:[UIColor blackColor]];
        [cell.textView setText:item[@"title"]];
        [cell.descriptionView setText:item[@"description"]];
        [cell.textView setFont:[UIFont systemFontOfSize:16]];
        [cell.descriptionView setFont:[UIFont systemFontOfSize:12]];
        if ([cell needsUpdateConstraints])
            [cell updateConstraints];
    }
    return cell;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == firstStepsIndex)
        return OALocalizedString(@"help_first_steps");
    else if (section == featuresIndex)
        return OALocalizedString(@"features_menu_group");
    else if (section == pluginsIndex)
        return OALocalizedString(@"plugins_menu_group");
    else if (section == otherIndex)
        return OALocalizedString(@"other_location");
    else if (section == followIndex)
        return OALocalizedString(@"follow_us");
    
    return 0;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([kLinkExternalType isEqualToString:type]) {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:item[@"description"]]];
    } else if ([kLinkInternalType isEqualToString:type]) {
        NSURL *url =[[NSBundle mainBundle] URLForResource:item[@"html"] withExtension:@"html"];
        OAWebViewController *webView = [[OAWebViewController alloc] initWithUrlAndTitle:url.absoluteString title:item[@"title"]];
        [self.navigationController pushViewController:webView animated:YES];
    } else if ([kContactAction isEqualToString:type]) {
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString:contactEmailUrl]];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@end
