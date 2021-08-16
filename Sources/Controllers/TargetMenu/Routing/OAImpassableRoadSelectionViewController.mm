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
#import "OAMenuSimpleCell.h"
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
    NSArray<OAAvoidRoadInfo *> *roads = [_avoidRoads getImpassableRoads];
    if (roads.count > 0)
    {
        for (OAAvoidRoadInfo *r in roads)
        {
            [roadList addObject:@{ @"title"  : r.name ? r.name : OALocalizedString(@"shared_string_road"),
                                   @"key"    : @"road",
                                   @"roadId" : @((unsigned long long)r.roadId),
                                   @"descr"  : [OARouteAvoidSettingsViewController getDescr:r],
                                   @"header" : @"",
                                   @"type"   : [OAMenuSimpleCell getCellIdentifier]} ];
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
    [button setImage:[UIImage templateImageNamed:iconName] forState:UIControlStateNormal];
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

- (BOOL)hideButtons
{
    return YES;
}

- (BOOL)offerMapDownload
{
    return NO;
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
    for (OAAvoidRoadInfo *r in [_avoidRoads getImpassableRoads])
        [_avoidRoads removeImpassableRoad:r];
    
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"selected_roads");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *text = item[@"title"];
    NSString *value = item[@"descr"];
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell *cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.imgView.image = [UIImage imageNamed:@"ic_custom_alert_color"];
            cell.descriptionView.hidden = !value || value.length == 0;
            cell.descriptionView.text = value;
            [cell.textView setText:text];
            
            [cell updateConstraintsIfNeeded];
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
            OAAvoidRoadInfo *roadInfo = [_avoidRoads getRoadInfoById:roadId.unsignedLongLongValue];
            if (roadInfo)
            {
                [_avoidRoads removeImpassableRoad:roadInfo];
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
        OAAvoidRoadInfo *roadInfo = [_avoidRoads getRoadInfoById:roadId.unsignedLongLongValue];
        if (roadInfo)
        {
            CLLocation *location = [_avoidRoads getLocation:roadInfo.roadId];
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
