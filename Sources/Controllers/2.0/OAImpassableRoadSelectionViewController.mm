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
#import "OAStateChangedListener.h"
#import "OARoutingHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Utilities.h>

@interface OAImpassableRoadSelectionViewController () <OAStateChangedListener>

@end

@implementation OAImpassableRoadSelectionViewController
{
    NSArray *_data;
    
    OAAvoidSpecificRoads *_avoidRoads;
}

- (void) generateData
{
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
    _avoidRoads = [OAAvoidSpecificRoads instance];
    [_avoidRoads addListener:self];
    
    [self setupRouteInfo];
    
    [self generateData];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.contentInset = UIEdgeInsetsMake(0., 0., [self getToolBarHeight], 0.);
    [_tableView setEditing:YES];
    [_tableView setScrollEnabled:NO];
    [_tableView setAllowsSelectionDuringEditing:YES];
    
    UIColor *eleTint = UIColorFromRGB(color_text_footer);
    _eleUpImageView.image = [_eleUpImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _eleDownImageView.image = [_eleDownImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _eleUpImageView.tintColor = eleTint;
    _eleDownImageView.tintColor = eleTint;
    
    CGRect bottomDividerFrame = _bottomToolBarDividerView.frame;
    bottomDividerFrame.size.height = 0.5;
    _bottomToolBarDividerView.frame = bottomDividerFrame;
}

- (void) setupRouteInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OsmAndAppInstance app = [OsmAndApp instance];
        if (![self.routingHelper isRouteCalculated])
        {
            NSString *emptyEle = [NSString stringWithFormat:@"0 %@", OALocalizedString(@"units_m")];;
            _routeInfoLabel.text = OALocalizedString(@"no_active_route");
            _elevationLabel.text = emptyEle;
            _descentLabel.text = emptyEle;
        }
        else
        {
            _routeInfoLabel.attributedText = [self getFormattedDistTimeString];
            OAGPXTrackAnalysis *trackAnalysis = self.routingHelper.getTrackAnalysis;
            if (trackAnalysis)
            {
                _elevationLabel.text = [app getFormattedAlt:trackAnalysis.maxElevation];
                _descentLabel.text = [app getFormattedAlt:trackAnalysis.minElevation];
            }
        }
    });
}

- (void) setupToolBarButtonsWithWidth:(CGFloat)width
{
    CGFloat w = width - 32.0 - OAUtilities.getLeftMargin * 2;
    CGRect leftBtnFrame = _clearAllButton.frame;
    leftBtnFrame.origin.x = 16.0 + OAUtilities.getLeftMargin;
    leftBtnFrame.size.width = w / 2 - 8;
    _clearAllButton.frame = leftBtnFrame;
    
    CGRect rightBtnFrame = _selectButton.frame;
    rightBtnFrame.origin.x = CGRectGetMaxX(leftBtnFrame) + 16.;
    rightBtnFrame.size.width = leftBtnFrame.size.width;
    _selectButton.frame = rightBtnFrame;
    
    [self setupButtonAppearance:_clearAllButton iconName:@"ic_custom_clear_list" color:UIColorFromRGB(color_primary_purple)];
    [self setupButtonAppearance:_selectButton iconName:@"ic_custom_add" color:UIColor.whiteColor];
}

- (void) setupButtonAppearance:(UIButton *) button iconName:(NSString *)iconName color:(UIColor *)color
{
    button.layer.cornerRadius = 6.;
    [button setImage:[[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [button setTintColor:color];
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
    return self.bottomToolBarView;
}

- (CGFloat)getToolBarHeight
{
    return 60.;
}

- (CGFloat)getNavBarHeight
{
    return navBarWithSearchFieldHeight;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL)hasBottomToolbar
{
    return YES;
}

- (BOOL) needsLayoutOnModeChange
{
    return NO;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFixed;
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
    self.titleView.text = OALocalizedString(@"impassable_road");
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
    [self.clearAllButton setTitle:OALocalizedString(@"shared_string_clear_all") forState:UIControlStateNormal];
    [self.selectButton setTitle:OALocalizedString(@"key_hint_select") forState:UIControlStateNormal];
}

- (void) cancelPressed
{
    if (self.delegate)
        [self.delegate openRouteSettings];
}

- (CGFloat)contentHeight
{
    return _tableView.contentSize.height;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _tableView.contentInset = UIEdgeInsetsMake(0., 0., [self getToolBarHeight], 0.);
    } completion:nil];
}

- (IBAction)buttonCancelPressed:(id)sender
{
    [self cancelPressed];
}

- (IBAction)buttonDonePressed:(id)sender
{
    [self cancelPressed];
}

- (IBAction)clearAllPressed:(id)sender
{
    const auto& roads = [_avoidRoads getImpassableRoads];
    if (!roads.empty())
    {
        
        for (const auto& r : roads)
        {
            [_avoidRoads removeImpassableRoad:r];
        }
    }
    [self refreshContent];
    [self.delegate requestHeaderOnlyMode];
    [self.delegate contentHeightChanged:_tableView.contentSize.height];
}

- (IBAction)selectPressed:(id)sender
{
    [self.delegate requestHeaderOnlyMode];
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
                [self.delegate contentHeightChanged:_tableView.contentSize.height];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *data = _data[indexPath.row];
    NSNumber *roadId = data[@"roadId"];
    if (roadId)
    {
        const auto& road = [_avoidRoads getRoadById:roadId.unsignedLongLongValue];
        if (road)
        {
            CLLocation *location = [_avoidRoads getLocation:road->id];
            Point31 pos31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude))];
            OAMapViewController* mapViewController = [[OARootViewController instance].mapPanel mapViewController];
            [mapViewController goToPosition:pos31 andZoom:16 animated:NO];
            [self.delegate requestFullMode];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    [self refreshContent];
}

@end
