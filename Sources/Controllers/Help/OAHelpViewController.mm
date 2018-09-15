//
//  OATripRecordingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAHelpViewController.h"
#import "OAIconTextDescCell.h"
#import "Localization.h"
#import "OAWebViewController.h"

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
    _titleView.text = OALocalizedString(@"menu_help");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
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

- (void) setupView
{
    NSMutableArray *dataArr = [NSMutableArray array];
    
    [dataArr addObject:
     @{
       @"name" : @"help_first_use",
       @"title" : OALocalizedString(@"help_first_use"),
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
       @"title" : OALocalizedString(@"help_faq"),
       @"description" : OALocalizedString(@"help_faq_descr"),
       @"type" : kLinkInternalType,
       @"html" : @"faq"
       }];
    
    _firstStepsData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    // Features
    [dataArr addObject:
     @{
       @"name" : @"help_map_viewing",
       @"title" : OALocalizedString(@"help_map_viewing"),
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
       @"title" : OALocalizedString(@"help_trip_planning"),
       @"type" : kLinkInternalType,
       @"html" : @"trip-planning"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"help_legend",
       @"title" : OALocalizedString(@"help_legend"),
       @"type" : kLinkInternalType,
       @"html" : @"map-legend"
       }];
    
    _featuresData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    // Plugins
    [dataArr addObject:
     @{
       @"name" : @"online_maps",
       @"title" : OALocalizedString(@"map_settings_online"),
       @"type" : kLinkInternalType,
       @"html" : @"online-maps-plugin"
       }];
    [dataArr addObject:
     @{
       @"name" : @"trip_recording",
       @"title" : OALocalizedString(@"product_title_track_recording"),
       @"type" : kLinkInternalType,
       @"html" : @"trip-recording-plugin"
       }];
    [dataArr addObject:
     @{
       @"name" : @"contour_lines",
       @"title" : OALocalizedString(@"product_title_srtm"),
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
       @"name" : @"ski_map",
       @"title" : OALocalizedString(@"product_title_skimap"),
       @"type" : kLinkInternalType,
       @"html" : @"ski-plugin"
       }];
    
    _pluginsData = [NSArray arrayWithArray:dataArr];
    [dataArr removeAllObjects];
    
    // Other
    [dataArr addObject:
     @{
       @"name" : @"install_and_troublesoot",
       @"title" : OALocalizedString(@"help_install_and_troubleshoot"),
       @"type" : kLinkInternalType,
       @"html" : @"installation-and-troubleshooting"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"tech_articles",
       @"title" : OALocalizedString(@"help_tech_articles"),
       @"type" : kLinkInternalType,
       @"html" : @"technical-articles"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"versions",
       @"title" : OALocalizedString(@"help_versions"),
       @"type" : kLinkInternalType,
       @"html" : @"changes"
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"contact_us",
       @"title" : OALocalizedString(@"help_contact_us"),
       @"type" : kContactAction
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"about",
       @"title" : OALocalizedString(@"help_about"),
       @"description" : [NSString stringWithFormat:@"%@ %@", @"OsmAnd",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"]],
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
       @"description" : @"https://twitter.com/osmandapp",
       @"type" : kLinkExternalType
       }];
    
    [dataArr addObject:
     @{
       @"name" : @"facebook",
       @"title" : OALocalizedString(@"facebook"),
       @"description" : @"https://www.facebook.com/osmandapp",
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
        return 3;
    else if (section == featuresIndex)
        return 4;
    else if (section == pluginsIndex)
        return 6;
    else if (section == otherIndex)
        return 5;
    else if (section == followIndex)
        return 2;
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    OAIconTextDescCell *cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
        cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        cell.textView.numberOfLines = 0;
        cell.textView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        cell.descView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    }
    
    if (cell)
    {
        CGRect f = cell.textView.frame;
        f.origin.y = (item[@"description"] == nil || [item[@"description"] length] == 0) ? 10.0 : 0.0;
        f.size.height = cell.frame.size.height - 20.0;
        cell.textView.frame = f;
        
        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.arrowIconView.hidden = YES;
        [cell.textView setTextColor:[UIColor blackColor]];
        [cell.textView setText:item[@"title"]];
        [cell.descView setText:item[@"description"]];
        [cell showImage:NO];
    }
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.0;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == firstStepsIndex)
        return OALocalizedString(@"help_first_steps");
    else if (section == featuresIndex)
        return OALocalizedString(@"help_features");
    else if (section == pluginsIndex)
        return OALocalizedString(@"plugins");
    else if (section == otherIndex)
        return OALocalizedString(@"help_other_header");
    else if (section == followIndex)
        return OALocalizedString(@"help_follow_us");
    
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
