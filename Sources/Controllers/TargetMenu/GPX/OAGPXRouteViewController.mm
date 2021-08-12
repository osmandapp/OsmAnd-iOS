//
//  OAGPXRouteViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteViewController.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "PXAlertView.h"
#import "OAEditGroupViewController.h"
#import "OAEditColorViewController.h"
#import "OADefaultFavorite.h"
#import "OASizes.h"

#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASavingTrackHelper.h"
#import "OAGpxWptItem.h"
#import "OAAppSettings.h"

#import "OAGPXRouteDocument.h"
#import "OAGPXRouter.h"

#import "OAGPXRouteWptListViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>


@implementation OAGPXRouteViewControllerState
@end

@interface OAGPXRouteViewController () <OAGPXRouteWptListViewControllerDelegate>

@end

@implementation OAGPXRouteViewController
{
    OAGPXRouteWptListViewController *_waypointsController;
    
    OsmAndAppInstance _app;
    OAGPXRouter *_gpxRouter;
    NSDateFormatter *_dateTimeFormatter;
    
    OAGpxRouteSegmentType _segmentType;
    CGFloat _scrollPos;
    BOOL _wasInit;

    UIView *_badge;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _gpxRouter = [OAGPXRouter sharedInstance];
        
        _wasInit = NO;
        _scrollPos = 0.0;
        _segmentType = kSegmentRoute;
    }
    return self;
}

- (instancetype)initWithSegmentType:(OAGpxRouteSegmentType)segmentType
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _gpxRouter = [OAGPXRouter sharedInstance];
        
        _wasInit = NO;
        _scrollPos = 0.0;
        _segmentType = segmentType;
    }
    return self;
}

- (instancetype)initWithCtrlState:(OAGPXRouteViewControllerState *)ctrlState
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _gpxRouter = [OAGPXRouter sharedInstance];
        
        _wasInit = NO;
        _scrollPos = ctrlState.scrollPos;
        _segmentType = ctrlState.segmentType;
    }
    return self;
}

-(NSAttributedString *)getAttributedTypeStr
{
    int wptCount = (int)_gpxRouter.routeDoc.activePoints.count;
    NSTimeInterval tripDuration = [_gpxRouter getRouteDuration];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
    
    NSString *waypointsStr = [NSString stringWithFormat:@"%d", wptCount];
    NSString *timeMovingStr = [[OsmAndApp instance] getFormattedTimeInterval:tripDuration shortFormat:NO];
    
    NSMutableAttributedString *stringWaypoints = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", waypointsStr]];
    NSMutableAttributedString *stringTimeMoving;
    if (tripDuration > 0)
        stringTimeMoving = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"   %@", timeMovingStr]];
    
    NSTextAttachment *waypointsAttachment = [[NSTextAttachment alloc] init];
    waypointsAttachment.image = [UIImage imageNamed:@"ic_gpx_points.png"];
    
    NSTextAttachment *timeMovingAttachment;
    if (tripDuration > 0)
    {
        NSString *imageName = [_gpxRouter getRouteVariantTypeSmallIconName];
        timeMovingAttachment = [[NSTextAttachment alloc] init];
        timeMovingAttachment.image = [UIImage imageNamed:imageName];
    }
    
    NSAttributedString *waypointsStringWithImage = [NSAttributedString attributedStringWithAttachment:waypointsAttachment];
    NSAttributedString *timeMovingStringWithImage;
    if (tripDuration > 0)
        timeMovingStringWithImage = [NSAttributedString attributedStringWithAttachment:timeMovingAttachment];
    
    [stringWaypoints replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:waypointsStringWithImage];
    [stringWaypoints addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
    if (tripDuration > 0)
    {
        [stringTimeMoving replaceCharactersInRange:NSMakeRange(1, 1) withAttributedString:timeMovingStringWithImage];
        [stringTimeMoving addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(1, 1)];
    }
    
    [string appendAttributedString:stringWaypoints];
    if (stringTimeMoving)
        [string appendAttributedString:stringTimeMoving];
    
    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];

    return string;
}

- (void)cancelPressed
{
    if (self.delegate)
        [self.delegate btnCancelPressed];
    
    [self closePointsController];
}

- (void)okPressed
{
    [PXAlertView showAlertWithTitle:OALocalizedString(@"gpx_cancel_route_q")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_no")
                         otherTitle:OALocalizedString(@"shared_string_yes")
                          otherDesc:nil
                         otherImage:nil
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                             {
                                 [self closePointsController];
                                 
                                 if (self.delegate)
                                     [self.delegate btnOkPressed];
                                 
                                 [_gpxRouter cancelRoute];
                             }
                         }];
}

- (BOOL)preHide
{
    [self closePointsController];
    return YES;
}

- (BOOL)supportFullMenu
{
    return _segmentType == kSegmentRouteWaypoints;
}

- (BOOL)supportFullScreen
{
    return _segmentType == kSegmentRouteWaypoints;
}

-(BOOL)supportEditing
{
    return NO;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

-(BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)shouldShowToolbar
{
    return YES;
}

- (BOOL)denyClose
{
    return YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (id)getTargetObj
{
    return _gpxRouter.gpx;
}

- (CGFloat)contentHeight
{
    if (_segmentType == kSegmentRoute)
        return 0.0;
    else
        return 160.0;
}

-(UIColor *)getNavBarColor
{
    return UIColorFromRGB(0x044b7f);
}

- (void)applyLocalization
{
    
    [self.segmentView setTitle:OALocalizedString(@"gpx_route") forSegmentAtIndex:0];
    [self.segmentView setTitle:OALocalizedString(@"gpx_waypoints") forSegmentAtIndex:1];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _dateTimeFormatter = [[NSDateFormatter alloc] init];
    _dateTimeFormatter.dateStyle = NSDateFormatterShortStyle;
    _dateTimeFormatter.timeStyle = NSDateFormatterMediumStyle;
    
    self.titleView.text = [_gpxRouter.gpx getNiceTitle];
    
    _waypointsController = [[OAGPXRouteWptListViewController alloc] init];
    _waypointsController.delegate = self;
    _waypointsController.allGroups = [self readGroups];
    
    _waypointsController.view.frame = self.view.frame;
    [_waypointsController doViewAppear];
    [self.contentView addSubview:_waypointsController.view];

    [self.segmentView setSelectedSegmentIndex:_segmentType];
    [self applySegmentType];

    [self addBadge];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (OATargetMenuViewControllerState *) getCurrentState
{
    OAGPXRouteViewControllerState *state = [[OAGPXRouteViewControllerState alloc] init];
    state.scrollPos = _waypointsController.tableView.contentOffset.y;
    state.segmentType = _segmentType;
    
    return state;
}

- (void)addBadge
{
    if (_badge)
    {
        [_badge removeFromSuperview];
        _badge = nil;
    }
    
    UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 50.0)];
    badgeLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    badgeLabel.text = [NSString stringWithFormat:@"%d", (int)_gpxRouter.routeDoc.locationMarks.count];
    badgeLabel.textColor = [self getNavBarColor];
    badgeLabel.textAlignment = NSTextAlignmentCenter;
    [badgeLabel sizeToFit];
    
    CGSize badgeSize = CGSizeMake(MAX(16.0, badgeLabel.bounds.size.width + 8.0), MAX(16.0, badgeLabel.bounds.size.height));
    badgeLabel.frame = CGRectMake(.5, .5, badgeSize.width, badgeSize.height);
    CGRect badgeFrame = CGRectMake(self.segmentView.bounds.size.width - badgeSize.width + 10.0, -4.0, badgeSize.width, badgeSize.height);
    _badge = [[UIView alloc] initWithFrame:badgeFrame];
    _badge.layer.cornerRadius = 8.0;
    _badge.layer.backgroundColor = [UIColor whiteColor].CGColor;
    
    [_badge addSubview:badgeLabel];
    
    [self.segmentViewContainer addSubview:_badge];
}

- (void)closePointsController
{
    if (_waypointsController)
    {
        [_waypointsController resetData];
        [_waypointsController doViewDisappear];
        _waypointsController = nil;
    }
}

- (void)applySegmentType
{
    switch (_segmentType)
    {
        case kSegmentRoute:
        {
            if (self.delegate)
                [self.delegate requestHeaderOnlyMode];
            
            break;
        }
        case kSegmentRouteWaypoints:
        {
            if (!_wasInit && _scrollPos != 0.0)
                [_waypointsController.tableView setContentOffset:CGPointMake(0.0, _scrollPos)];
            
            _waypointsController.view.frame = self.contentView.bounds;
            
            if (self.delegate)
                [self.delegate requestFullScreenMode];
            
            break;
        }
            
        default:
            break;
    }
    
    _wasInit = YES;
}

- (NSArray *)readGroups
{
    NSMutableSet *groups = [NSMutableSet set];
    for (OAGpxWpt *wptItem in _gpxRouter.routeDoc.locationMarks)
    {
        if (wptItem.type.length > 0)
            [groups addObject:wptItem.type];
    }
    return [groups allObjects];
}

-(CGFloat) getNavBarHeight
{
    return gpxItemNavBarHeight;
}

- (void)updateMap
{
    [[OARootViewController instance].mapPanel displayGpxOnMap:_gpxRouter.gpx];
}

- (IBAction)segmentClicked:(id)sender
{
    OAGpxRouteSegmentType newSegmentType = (OAGpxRouteSegmentType)self.segmentView.selectedSegmentIndex;
    if (_segmentType == newSegmentType)
        return;
    
    _segmentType = newSegmentType;
    
    [self applySegmentType];
}

#pragma mark - OAGPXRouteWptListViewControllerDelegate

-(void)routePointsChanged
{
    if (self.delegate)
        [self.delegate contentChanged];
}

@end
