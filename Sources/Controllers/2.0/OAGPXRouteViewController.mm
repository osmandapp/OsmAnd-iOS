//
//  OAGPXRouteViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteViewController.h"
#import "OAGPXDetailsTableViewCell.h"
#import "OAGPXElevationTableViewCell.h"
#import "OsmAndApp.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "PXAlertView.h"
#import "OAEditGroupViewController.h"
#import "OAEditColorViewController.h"
#import "OADefaultFavorite.h"

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
                                 [_gpxRouter cancelRoute];
                                 
                                 if (self.delegate)
                                     [self.delegate btnOkPressed];
                                 
                                 [self closePointsController];
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

-(BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;
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
    [self.buttonCancel setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [self.buttonCancel setImage:[UIImage imageNamed:@"menu_icon_back"] forState:UIControlStateNormal];
    [self.buttonCancel setTintColor:[UIColor whiteColor]];
    self.buttonCancel.titleEdgeInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 0.0);
    self.buttonCancel.imageEdgeInsets = UIEdgeInsetsMake(0.0, -12.0, 0.0, 0.0);
    
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

- (void)addBadge
{
    if (_badge)
    {
        [_badge removeFromSuperview];
        _badge = nil;
    }
    
    UILabel *badgeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 50.0)];
    badgeLabel.font = [UIFont fontWithName:@"AvenirNext-Medium" size:11.0];
    badgeLabel.text = [NSString stringWithFormat:@"%d", _gpxRouter.routeDoc.locationMarks.count];
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
