//
//  OAItemExistViewControllers.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAItemExistViewController.h"
#import "OAImportCompleteViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickActionType.h"
#import "OAQuickAction.h"
#import "OAMapSource.h"
#import "OAMenuSimpleCell.h"
#import "OAResourcesUIHelper.h"

#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"

@interface OAItemExistViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAItemExistViewController
{
    OsmAndAppInstance _app;
    NSMutableArray<NSMutableArray<NSDictionary *> *> *_data;
    NSArray<OAApplicationMode *> * _profileList;
    NSArray<OAQuickActionType *> *_quickActionsList;
    NSArray<OAResourceItem *> *_mapSources;
    NSArray<OAMapSource * > *_renderStyles;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];
    [self generateData];
}

- (void) generateFakeData
{
    //TODO: for now here is generating fake data, just for demo
    _data = [NSMutableArray new];
    _profileList = [NSArray arrayWithObject:OAApplicationMode.CAR];
    NSArray<OAQuickActionType *> *allQuickActions = [[OAQuickActionRegistry sharedInstance] produceTypeActionsListWithHeaders];
    _quickActionsList = [allQuickActions subarrayWithRange:NSMakeRange(3,2)];
    _mapSources = [OAResourcesUIHelper getSortedRasterMapSources:NO];
    _renderStyles = @[_app.data.lastMapSource];
}

- (void) generateData
{
    [self generateFakeData];
    
    if (_profileList.count > 0)
    {
        NSMutableArray<NSDictionary *> *profileItems = [NSMutableArray new];
        [profileItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"shared_string_profiles"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_profiles") lowerCase]]
        }];
        for (OAApplicationMode *profile in _profileList)
        {
            [profileItems addObject: @{
                @"cellType": kMenuSimpleCell,
                @"label": profile.toHumanString,
                @"description": profile.getProfileDescription,
                @"icon": profile.getIcon,
                @"iconColor": UIColorFromRGB(profile.getIconColor)
            }];
        }
        [_data addObject:profileItems];
    }
    
    if (_quickActionsList.count > 0)
    {
        NSMutableArray<NSDictionary *> *quickActionsItems = [NSMutableArray new];
        [quickActionsItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"shared_string_quick_actions"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_quick_actions") lowerCase]]
        }];
        for (OAQuickActionType *action in _quickActionsList)
        {
            [quickActionsItems addObject: @{
                @"cellType": kMenuSimpleCell,
                @"label": action.name,
                @"description": @"",
                @"icon": [UIImage imageNamed:action.iconName]
            }];
        }
        [_data addObject:quickActionsItems];
    }
    
    if (_mapSources.count > 0)
    {
        NSMutableArray<NSDictionary *> *mapSourcesItems = [NSMutableArray new];
        [mapSourcesItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"map_sources"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"map_sources") lowerCase]]
        }];
        for (OAResourceItem *mapSource in _mapSources)
        {
            [mapSourcesItems addObject: @{
                @"cellType": kMenuSimpleCell,
                @"label": ((OAOnlineTilesResourceItem *) mapSource).mapSource.name,
                @"description": @"",
                @"icon": [UIImage imageNamed:@"ic_custom_map_style"]
            }];
        }
        [_data addObject:mapSourcesItems];
    }
    
    if (_renderStyles.count > 0)
    {
        NSMutableArray<NSDictionary *> *mapSourcesItems = [NSMutableArray new];
        [mapSourcesItems addObject: @{
            @"cellType": kMenuSimpleCellNoIcon,
            @"label": OALocalizedString(@"shared_string_rendering_styles"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_rendering_styles") lowerCase]]
        }];
        for (OAMapSource *style in _renderStyles)
        {
            UIImage *icon;
            NSString *iconName = [NSString stringWithFormat:@"img_mapstyle_%@", [style.resourceId stringByReplacingOccurrencesOfString:@".render.xml" withString:@""]];
            if (iconName)
                icon = [UIImage imageNamed:iconName];
            
            [mapSourcesItems addObject: @{
                @"cellType": kMenuSimpleCell,
                @"label": style.name,
                @"description": @"",
                @"icon": icon
            }];
        }
        [_data addObject:mapSourcesItems];
    }
};

- (void) applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"import_duplicates_title");
}

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    
    self.additionalNavBarButton.hidden = YES;
    [self setupBottomViewMultyLabelButtons];
    
    [super viewDidLoad];
}

- (void) setupBottomViewMultyLabelButtons
{
    self.primaryBottomButton.hidden = NO;
    self.secondaryBottomButton.hidden = NO;
    
    [self setToButton: self.secondaryBottomButton firstLabelText:OALocalizedString(@"keep_both") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:UIColorFromRGB(color_primary_purple) secondLabelText:OALocalizedString(@"keep_both_desc") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:UIColorFromRGB(color_icon_inactive)];
    
    [self setToButton: self.primaryBottomButton firstLabelText:OALocalizedString(@"replace_all") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:[UIColor whiteColor] secondLabelText:OALocalizedString(@"replace_all_desc") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5]];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self generateHeaderForTableView:tableView withFirstSessionText:OALocalizedString(@"import_duplicates_description") forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self generateHeightForHeaderWithFirstHeaderText:OALocalizedString(@"import_duplicates_description") inSection:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"cellType"] isEqualToString:kMenuSimpleCellNoIcon])
    {
        static NSString* const identifierCell = kMenuSimpleCellNoIcon;
        OAMenuSimpleCell* cell;
        cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCellNoIcon owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
        }
        cell.textView.text = item[@"label"];
        cell.descriptionView.text = item[@"description"];
        return cell;
    }
    
    else if ([item[@"cellType"] isEqualToString:kMenuSimpleCell])
    {
        static NSString* const identifierCell = kMenuSimpleCell;
        OAMenuSimpleCell* cell;
        cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCell owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62., 0.0, 0.0);
        }
        cell.textView.text = item[@"label"];
        
        if (((NSString *)item[@"description"]).length > 0)
        {
            cell.descriptionView.hidden = NO;
            cell.descriptionView.text = item[@"description"];
        }
        else
        {
            cell.descriptionView.hidden = YES;
        }
        
        if (item[@"icon"] && item[@"iconColor"])
        {
            cell.imgView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = UIColorFromRGB(color_chart_orange);
            //cell.imgView.tintColor = item[@"iconColor"];
        }
        else if (item[@"icon"])
        {
            cell.imgView.image = item[@"icon"];
        }
        else
        {
            cell.imgView.hidden = YES;
        }
        
        return cell;
    }
}

- (IBAction)primaryButtonPressed:(id)sender
{
    NSLog(@"primaryButtonPressed");
    OAImportCompleteViewController* importComplete = [[OAImportCompleteViewController alloc] init];
    [self.navigationController pushViewController:importComplete animated:YES];
}

- (IBAction)secondaryButtonPressed:(id)sender
{
    NSLog(@"secondaryButtonPressed");
}

@end
