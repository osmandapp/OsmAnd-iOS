//
//  OARouteDetailsViewController.m
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteDetailsViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAStateChangedListener.h"
#import "OARoutingHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OANativeUtilities.h"
#import "OALineChartCell.h"
#import "OARouteInfoCell.h"
#import "OsmAndApp.h"
#import "OARouteStatisticsHelper.h"
#import "OARouteCalculationResult.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OARouteStatistics.h"

#include <OsmAndCore/Utilities.h>

@interface OARouteDetailsViewController () <OAStateChangedListener, OARouteInformationListener>

@end

@implementation OARouteDetailsViewController
{
    NSDictionary *_data;
    OARoutingHelper *_routingHelper;
    
    OAGPXTrackAnalysis *_analysis;
}

- (void) generateData
{
    _analysis = _routingHelper.getTrackAnalysis;
    
    NSMutableDictionary *dataArr = [NSMutableDictionary new];
    NSMutableArray *sectionData = [NSMutableArray array];
    NSInteger section = 0;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OALineChartCell" owner:self options:nil];
    OALineChartCell *routeStatsCell = (OALineChartCell *)[nib objectAtIndex:0];
    [GpxUIHelper refreshLineChartWithChartView:routeStatsCell.lineChartView analysis:_analysis useGesturesAndScale:YES];
    [dataArr setObject:@[routeStatsCell] forKey:@(section++)];
    
    const auto& originalRoute = _routingHelper.getRoute.getOriginalRoute;
    if (!originalRoute.empty())
    {
        NSArray<OARouteStatistics *> *routeInfo = [OARouteStatisticsHelper calculateRouteStatistic:originalRoute];
        
        for (OARouteStatistics *stat in routeInfo)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OARouteInfoCell" owner:self options:nil];
            OARouteInfoCell *cell = (OARouteInfoCell *)[nib objectAtIndex:0];
            cell.titleView.text = [self getLocalizedRouteInfoProperty:stat.name];
            [cell.detailsButton setTitle:OALocalizedString(@"rendering_category_details") forState:UIControlStateNormal];
            
            [GpxUIHelper refreshBarChartWithChartView:cell.barChartView statistics:stat analysis:_analysis nightMode:[OAAppSettings sharedManager].nightMode];
            
            [sectionData addObject:cell];
        }
        [dataArr setObject:sectionData forKey:@(section++)];
    }
    
    _data = [NSDictionary dictionaryWithDictionary:dataArr];
}

- (NSString *) getLocalizedRouteInfoProperty:(NSString *)properyName
{
    return OALocalizedString([NSString stringWithFormat:@"%@_name", properyName]);
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
    
    _routingHelper = [OARoutingHelper sharedInstance];
    [_routingHelper addListener:self];
    [self setupRouteInfo];
    
    [self generateData];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.contentInset = UIEdgeInsetsMake(0., 0., [self getToolBarHeight], 0.);
    [_tableView setScrollEnabled:NO];
//    _tableView.rowHeight = UITableViewAutomaticDimension;
    [self applySafeAreaMargins];
    
    UIColor *eleTint = UIColorFromRGB(color_text_footer);
    _eleUpImageView.image = [_eleUpImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _eleDownImageView.image = [_eleDownImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _eleUpImageView.tintColor = eleTint;
    _eleDownImageView.tintColor = eleTint;
    
    CGRect bottomDividerFrame = _bottomToolBarDividerView.frame;
    bottomDividerFrame.size.height = 0.5;
    _bottomToolBarDividerView.frame = bottomDividerFrame;
    
    [self centerMapOnRoute];
}

- (void) centerMapOnRoute
{
    NSString *error = [_routingHelper getLastRouteCalcError];
    OABBox routeBBox;
    routeBBox.top = DBL_MAX;
    routeBBox.bottom = DBL_MAX;
    routeBBox.left = DBL_MAX;
    routeBBox.right = DBL_MAX;
    if ([_routingHelper isRouteCalculated] && !error)
    {
        routeBBox = [_routingHelper getBBox];
        if ([_routingHelper isRoutePlanningMode] && routeBBox.left != DBL_MAX)
        {
            [[OARootViewController instance].mapPanel displayCalculatedRouteOnMap:CLLocationCoordinate2DMake(routeBBox.top, routeBBox.left) bottomRight:CLLocationCoordinate2DMake(routeBBox.bottom, routeBBox.right)];
        }
    }
}

- (void) setupRouteInfo
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OsmAndAppInstance app = [OsmAndApp instance];
        if (![_routingHelper isRouteCalculated])
        {
            NSString *emptyEle = [NSString stringWithFormat:@"0 %@", OALocalizedString(@"units_m")];;
            _routeInfoLabel.text = OALocalizedString(@"no_active_route");
            _elevationLabel.text = emptyEle;
            _descentLabel.text = emptyEle;
        }
        else
        {
            NSDictionary *numericAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20 weight:UIFontWeightSemibold], NSForegroundColorAttributeName : UIColor.blackColor};
            NSDictionary *alphabeticAttributes = @{NSFontAttributeName: [UIFont systemFontOfSize:20], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)};
            NSString *dist = [app getFormattedDistance:[_routingHelper getLeftDistance]];
            NSAttributedString *distance = [self formatDistance:dist numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];
            NSAttributedString *time = [self getFormattedTimeInterval:[_routingHelper getLeftTime] numericAttributes:numericAttributes alphabeticAttributes:alphabeticAttributes];
            
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
            NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
            NSAttributedString *bullet = [[NSAttributedString alloc] initWithString:@"•" attributes:alphabeticAttributes];
            [str appendAttributedString:distance];
            [str appendAttributedString:space];
            [str appendAttributedString:bullet];
            [str appendAttributedString:space];
            [str appendAttributedString:time];
            
            _routeInfoLabel.attributedText = str;
            OAGPXTrackAnalysis *trackAnalysis = _routingHelper.getTrackAnalysis;
            if (trackAnalysis)
            {
                _elevationLabel.text = [app getFormattedAlt:trackAnalysis.maxElevation];
                _descentLabel.text = [app getFormattedAlt:trackAnalysis.minElevation];
            }
        }
    });
}

- (NSAttributedString *) formatDistance:(NSString *)dist numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
{
    NSMutableAttributedString *res = [[NSMutableAttributedString alloc] init];
    if (dist.length > 0)
    {
        NSArray<NSString *> *components = [[dist trim] componentsSeparatedByString:@" "];
        NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
        for (NSInteger i = 0; i < components.count; i++)
        {
            NSAttributedString *str = [[NSAttributedString alloc] initWithString:components[i] attributes:i % 2 == 0 ? numericAttributes : alphabeticAttributes];
            [res appendAttributedString:str];
            if (i != components.count - 1)
                [res appendAttributedString:space];
        }
    }
    return res;
}

- (NSAttributedString *) getFormattedTimeInterval:(NSTimeInterval)timeInterval numericAttributes:(NSDictionary *) numericAttributes alphabeticAttributes:(NSDictionary *)alphabeticAttributes
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSMutableAttributedString *time = [[NSMutableAttributedString alloc] init];
    NSAttributedString *space = [[NSAttributedString alloc] initWithString:@" "];
    
    if (hours > 0)
    {
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", hours] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_hour") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    if (minutes > 0)
    {
        if (time.length > 0)
            [time appendAttributedString:space];
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", minutes] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_min_short") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    if (minutes == 0 && hours == 0)
    {
        if (time.length > 0)
            [time appendAttributedString:space];
        NSAttributedString *val = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d", seconds] attributes:numericAttributes];
        NSAttributedString *units = [[NSAttributedString alloc] initWithString:OALocalizedString(@"units_sec_short") attributes:alphabeticAttributes];
        [time appendAttributedString:val];
        [time appendAttributedString:space];
        [time appendAttributedString:units];
    }
    
    NSString *eta = [NSString stringWithFormat:@" (%@)", [self getTimeAfter:timeInterval]];
    [time appendAttributedString:[[NSAttributedString alloc] initWithString:eta attributes:alphabeticAttributes]];
    
    return [[NSAttributedString alloc] initWithAttributedString:time];
}

- (NSString *)getTimeAfter:(NSTimeInterval)timeInterval
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:timeInterval hours:&hours minutes:&minutes seconds:&seconds];
    
    NSDate *date = [NSDate date];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    NSInteger nowHours = [components hour];
    NSInteger nowMinutes = [components minute];
    nowHours = nowMinutes + minutes >= 60 ? nowHours + 1 : nowHours;
    return [NSString stringWithFormat:@"%02ld:%02ld", (nowHours + hours) % 24, (nowMinutes + minutes) % 60];
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
    [self refreshContent];
    [self.delegate requestHeaderOnlyMode];
}

- (IBAction)selectPressed:(id)sender
{
    [self.delegate requestHeaderOnlyMode];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_data[@(section)]).count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return 140.0;
    return 118.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.001 : 16.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _data[@(indexPath.section)][indexPath.row];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *data = _data[@(indexPath.section)][indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OAStateChangedListener

- (void) stateChanged:(id)change
{
    [self refreshContent];
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    [self setupRouteInfo];
}

- (void) routeWasUpdated
{
    [self setupRouteInfo];
}

- (void) routeWasCancelled
{
    [self setupRouteInfo];
}

- (void) routeWasFinished
{
    [self setupRouteInfo];
}

@end
