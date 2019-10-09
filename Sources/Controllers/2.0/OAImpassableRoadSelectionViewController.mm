//
//  OAImpassableRoadSelectionViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImpassableRoadSelectionViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAAvoidSpecificRoads.h"
#import "OAIconTextButtonCell.h"
#import "OARouteAvoidSettingsViewController.h"

@interface OAImpassableRoadSelectionViewController ()

@end

@implementation OAImpassableRoadSelectionViewController
{
    NSArray *_data;
    
    OAAvoidSpecificRoads *_avoidRoads;
}

- (void) generateData
{
    if (!_avoidRoads)
        _avoidRoads = [OAAvoidSpecificRoads instance];
    NSMutableArray *roadList = [NSMutableArray array];
    const auto& roads = [_avoidRoads getImpassableRoads];
    if (!roads.empty())
    {
        
        for (const auto& r : roads)
        {
            [roadList addObject:@{ @"title"  : [OARouteAvoidSettingsViewController getText:r],
                                   @"key"    : @"road",
                                   @"roadId" : @((unsigned long long)r->id),
                                   @"descr"  : [OARouteAvoidSettingsViewController getDescr:r],
                                   @"header" : @"",
                                   @"type"   : @"OAIconTextButtonCell"} ];
        }
    }
    
    _data = [NSArray arrayWithArray:roadList];
}

- (BOOL)hasControlButtons
{
    return NO;
}

- (NSAttributedString *) getAttributedTypeStr
{
    return nil;
}

- (NSString *)getTypeStr
{
    return nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self generateData];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setEditing:YES];
    [self applySafeAreaMargins];
}

- (void)refreshContent
{
    [self generateData];
    [self.tableView reloadData];
}

- (UIView *) getTopView
{
    return self.navBar;
}

- (UIView *) getMiddleView
{
    return self.contentView;
}

- (UIView *)getBottomView
{
    return self.buttonsContentView;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
}

-(CGFloat) getNavBarHeight
{
    return gpxItemNavBarHeight;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL)supportFullScreen
{
    return YES;
}

- (void) applyLocalization
{
    self.titleView.text = OALocalizedString(@"shared_string_select_on_map");
}

- (void) cancelPressed
{
    if (self.delegate)
        [self.delegate btnCancelPressed];
}

- (CGFloat)contentHeight
{
    return _tableView.contentSize.height;
}

- (IBAction)buttonCancelPressed:(id)sender
{
    [self cancelPressed];
}

- (IBAction)buttonDonePressed:(id)sender
{
    [self cancelPressed];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OAIconTextButtonCell"])
    {
        NSString *value = item[@"descr"];
        return [OAIconTextButtonCell getHeight:item[@"title"] descHidden:(!value || value.length == 0) detailsIconHidden:NO cellWidth:tableView.bounds.size.width];
    }
    return 44.0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"selected_roads");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *text = item[@"title"];
    NSString *value = item[@"descr"];
    if ([item[@"type"] isEqualToString:@"OAIconTextButtonCell"])
    {
        static NSString* const identifierCell = @"OAIconTextButtonCell";
        OAIconTextButtonCell *cell = (OAIconTextButtonCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextButtonCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.iconView.image = [UIImage imageNamed:@"ic_custom_alert_color"];
            cell.descView.hidden = !value || value.length == 0;
            cell.descView.text = value;
            cell.buttonView.hidden = YES;
            cell.detailsIconView.hidden = YES;
            [cell.textView setText:text];
        }
        return cell;
    }
    return nil;
}


#pragma mark - UITableViewDelegate

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSDictionary *data = _data[indexPath.row];
        NSNumber *roadId = data[@"roadId"];
        if (roadId)
        {
            const auto& road = [_avoidRoads getRoadById:roadId.unsignedLongLongValue];
            if (road)
            {
                [_avoidRoads removeImpassableRoad:road];
                [self refreshContent];
            }
        }
    }
}

@end
