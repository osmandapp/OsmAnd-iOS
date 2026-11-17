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
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAContextMenuLayer.h"
#import "OAMapLayers.h"
#import "OAUtilities.h"
#import "Localization.h"

#define kInfoViewLanscapeWidth 320.0
#define kOATargetPointViewCellHeight 60.0
#define kMaxRowCount 4

@interface OATargetMultiView ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OATargetMultiView
{
    NSObject *_hideAnimationToken;
    void (^_hideCompletion)(BOOL hidden);
}

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
    
    self.headerLabel.text = OALocalizedString(@"whats_here");
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (OAUtilities.isPortrait || OAUtilities.isIPad)
        [OAUtilities setMaskTo:self byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight];
    else
        self.layer.mask = nil;
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
    cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 60, 0., 0.);
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATargetPoint *targetPoint = self.targetPoints[indexPath.row];
    OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;

    if (![mapPanel processNavigationPointSelection:@[targetPoint]])
    {
        if (_selectedMapObjects && _selectedMapObjects.count > indexPath.row)
        {
            SelectedMapObject *selectedObject = _selectedMapObjects[indexPath.row];
            OAContextMenuLayer *contextLayer = [OARootViewController instance].mapPanel.mapViewController.mapLayers.contextMenuLayer;
            [contextLayer showContextMenu:selectedObject touchPointLatLon:_touchPoint];
        }
        else
        {
            [mapPanel showContextMenu:targetPoint];
        }
    }
}

-(void) setTargetPoints:(NSArray<OATargetPoint *> *)targetPoints
{
    _targetPoints = targetPoints;
    [self.tableView reloadData];
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
    [self.tableView reloadData];
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
        frame.size.height = (MIN(self.targetPoints.count, kMaxRowCount) + 1) * kOATargetPointViewCellHeight + [OAUtilities getBottomMargin];
        frame.size.width = DeviceScreenWidth;
        self.frame = frame;
        frame.origin.y = DeviceScreenHeight - frame.size.height;
    }
    return frame;
}

- (void) show:(BOOL)animated onComplete:(void (^)(void))onComplete
{
    [self cancelHide];
    [self.layer removeAllAnimations];
    //[self applyMapInteraction:self.frame.size.height];
    CGRect frame = [self getFrame];
    
    if (animated)
    {
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
        self.frame = frame;
        
        if (onComplete)
            onComplete();
        
        //if (!_showFullScreen && self.customController && [self.customController supportMapInteraction])
        //    [self.delegate targetViewEnableMapInteraction];
    }
}

- (void) hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [self hide:animated duration:duration completion:^(BOOL hidden) {
        if (hidden && onComplete)
            onComplete();
    }];
}

- (void)cancelHide
{
    _hideAnimationToken = nil;
    void (^completion)(BOOL) = _hideCompletion;
    _hideCompletion = nil;
    if (completion)
        completion(NO);
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration completion:(void (^)(BOOL hidden))completion
{
    [self cancelHide];
    if (self.superview)
    {
        CGRect frame = self.frame;
        if ([self isLandscape])
            frame.origin.x = -frame.size.width;
        else
            frame.origin.y = DeviceScreenHeight + 10.0;
        
        if (animated && duration > 0.0)
        {
            NSObject *hideAnimationToken = [NSObject new];
            _hideAnimationToken = hideAnimationToken;
            _hideCompletion = [completion copy];
            [UIView animateWithDuration:duration animations:^{
                
                self.frame = frame;
                
            } completion:^(BOOL finished) {
                // A newer show or hide supersedes this request, even if its animation completes later.
                if (_hideAnimationToken != hideAnimationToken)
                    return;

                _hideAnimationToken = nil;
                _hideCompletion = nil;
                [self removeFromSuperview];
                if (completion)
                    completion(YES);
            }];
        }
        else
        {
            self.frame = frame;
            
            [self removeFromSuperview];
            
            if (completion)
                completion(YES);
        }
    }
}

- (IBAction)onCloseButtonClicked:(id)sender {
    [[[OARootViewController instance] mapPanel] hideTargetPointMenu];
}

@end
