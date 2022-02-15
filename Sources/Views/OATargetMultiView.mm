//
//  OATargetMultiView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetMultiView.h"
#import "OATargetPoint.h"
#import "OATargetPointViewCell.h"
#import "OARootViewController.h"
#import "OATargetPointsHelper.h"

#define kInfoViewLanscapeWidth 320.0
#define kOATargetPointViewCellHeight 60.0
#define kMaxRowCount 4

@interface OATargetMultiView ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OATargetMultiView

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATargetMultiView class]])
            self = (OATargetMultiView *)v;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATargetMultiView class]])
            self = (OATargetMultiView *)v;
    }
    
    if (self)
        self.frame = frame;
    
    return self;
}

-(void) awakeFromNib
{
    // drop shadow
    [self.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.layer setShadowOpacity:0.3];
    [self.layer setShadowRadius:3.0];
    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
}

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kOATargetPointViewCellHeight;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.targetPoints.count;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATargetPoint *targetPoint = self.targetPoints[indexPath.row];
    OATargetPointViewCell* cell;
    cell = (OATargetPointViewCell *)[tableView dequeueReusableCellWithIdentifier:[OATargetPointViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATargetPointViewCell getCellIdentifier] owner:self options:nil];
        cell = (OATargetPointViewCell *)[nib objectAtIndex:0];
    }
    cell.targetPoint = targetPoint;
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATargetPoint *targetPoint = self.targetPoints[indexPath.row];
    if (_activeTargetType == OATargetRouteIntermediateSelection)
    {
        [[OATargetPointsHelper sharedInstance] navigateToPoint:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude] updateRoute:YES intermediate:(_activeTargetType != OATargetRouteIntermediateSelection ? -1 : (int)[[OATargetPointsHelper sharedInstance] getIntermediatePoints].count) historyName:targetPoint.pointDescription];
        [self hide:YES duration:0.2 onComplete:^{
            [[[OARootViewController instance] mapPanel] showRouteInfo];
        }];
    }
    else
    {
        [[[OARootViewController instance] mapPanel] showContextMenu:targetPoint];
    }
}

-(void) setTargetPoints:(NSArray<OATargetPoint *> *)targetPoints
{
    _targetPoints = targetPoints;
    [self.tableView reloadData];
}

-(void) setActiveTargetType:(OATargetPointType)activeTargetType
{
    _activeTargetType = activeTargetType;
}

- (BOOL) isLandscapeSupported
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (BOOL) isLandscape
{
    return DeviceScreenWidth > 470.0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
}

- (void) transitionToSize
{
    self.frame = [self getFrame];
}

- (CGRect)getFrame {
    CGRect frame = self.frame;
    if ([self isLandscape])
    {
        frame.size.height = DeviceScreenHeight;
        frame.size.width = kInfoViewLanscapeWidth;
        frame.origin.x = -self.bounds.size.width;
        frame.origin.y = 0.0;
        self.frame = frame;
        frame.origin.x = 0.0;
    }
    else
    {
        frame.origin.x = 0.0;
        frame.origin.y = DeviceScreenHeight + 10.0;
        frame.size.height = MIN(self.targetPoints.count, kMaxRowCount) * kOATargetPointViewCellHeight + [OAUtilities getBottomMargin];
        frame.size.width = DeviceScreenWidth;
        self.frame = frame;
        frame.origin.y = DeviceScreenHeight - frame.size.height;
    }
    return frame;
}

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    //[self applyMapInteraction:self.frame.size.height];
    
    if (animated)
    {
        CGRect frame = [self getFrame];
        
        [UIView animateWithDuration:0.3 animations:^{

            self.frame = frame;
            
        } completion:^(BOOL finished) {
            if (onComplete)
                onComplete();
            
            //if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
            //    [self.delegate targetViewEnableMapInteraction];
        }];
    }
    else
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
        {
            frame.size.height = DeviceScreenHeight;
            frame.size.width = kInfoViewLanscapeWidth;
            frame.origin.y = 0.0;
        }
        else
        {
            frame.size.height = MIN(self.targetPoints.count, kMaxRowCount) * kOATargetPointViewCellHeight;
            frame.size.width = DeviceScreenWidth;
            frame.origin.y = DeviceScreenHeight - frame.size.height;
        }
        
        self.frame = frame;
        
        if (onComplete)
            onComplete();
        
        //if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
        //    [self.delegate targetViewEnableMapInteraction];
    }
}

- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    if (self.superview)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.x = -frame.size.width;
        else
            frame.origin.y = DeviceScreenHeight + 10.0;
        
        if (animated && duration > 0.0)
        {
            [UIView animateWithDuration:duration animations:^{
                
                self.frame = frame;
                
            } completion:^(BOOL finished) {
                
                [self removeFromSuperview];
                
                if (onComplete)
                    onComplete();
            }];
        }
        else
        {
            self.frame = frame;
            
            [self removeFromSuperview];
            
            if (onComplete)
                onComplete();
        }
    }
}

@end
