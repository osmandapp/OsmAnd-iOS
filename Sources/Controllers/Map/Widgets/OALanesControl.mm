//
//  OALanesControl.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OALanesControl.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OALanesDrawable.h"
#import "OAMapViewTrackingUtilities.h"
#import "OALocationServices.h"
#import "OARouteCalculationResult.h"
#import "OACurrentPositionHelper.h"
#import "OARouteInfoView.h"
#import "OARouteDirectionInfo.h"
#import "OAUtilities.h"
#import "OATextInfoWidget.h"
#import "OAOsmAndFormatter.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <turnType.h>
#include <binaryRead.h>
#include <routingContext.h>
#include <routeResultPreparation.h>

#define kBorder 6.0
#define kLanesViewHeight 36.0
#define kTextViewHeight 20.0
#define kMinWidth 60.0

@interface OALanesControl ()

@property (weak, nonatomic) IBOutlet UIView *lanesView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *textShadowView;

@end

@implementation OALanesControl
{
    OAMapViewTrackingUtilities *_trackingUtilities;
    OALocationServices *_locationProvider;
    OACurrentPositionHelper *_currentPositionHelper;
    OARoutingHelper *_rh;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    int _dist;
    OALanesDrawable *_lanesDrawable;
    
    UIFont *_textFont;
    UIColor *_textColor;
    UIColor *_textShadowColor;
    float _shadowRadius;
    
    UIFont *_regularFont;
    UIFont *_boldFont;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OALanesControl class]])
        {
            self = (OALanesControl *)v;
            break;
        }
    }
    
    if (self)
        self.frame = CGRectMake(0, 0, 94, 112);
    
    [self commonInit];
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OALanesControl class]])
        {
            self = (OALanesControl *)v;
            break;
        }
    }
    
    if (self)
        self.frame = frame;
    
    [self commonInit];
    
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _rh = [OARoutingHelper sharedInstance];
    _app = [OsmAndApp instance];
    _trackingUtilities = [OAMapViewTrackingUtilities instance];
    _locationProvider = _app.locationServices;
    _currentPositionHelper = [OACurrentPositionHelper instance];

    self.hidden = YES;

    CGFloat radius = 3.0;
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = radius;
    
    // drop shadow
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.3;
    self.layer.shadowRadius = 2.0;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    
    _regularFont = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    _boldFont = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    _textFont = _regularFont;
    _textColor = [UIColor blackColor];
    _textShadowColor = nil;
    _shadowRadius = 0;
    
    _lanesDrawable = [[OALanesDrawable alloc] initWithScaleCoefficient:1];
    [_lanesView addSubview:_lanesDrawable];
}

- (void) refreshLabel:(NSString *)text
{
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    NSMutableAttributedString *shadowString = nil;
    
    NSRange valueRange = NSMakeRange(0, text.length);
    if (valueRange.length > 0)
    {
        [string addAttribute:NSFontAttributeName value:_textFont range:valueRange];
        [string addAttribute:NSForegroundColorAttributeName value:_textColor range:valueRange];
        if (_textShadowColor && _shadowRadius > 0)
        {
            shadowString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
            [shadowString addAttribute:NSFontAttributeName value:_textFont range:valueRange];
            [shadowString addAttribute:NSForegroundColorAttributeName value:_textColor range:valueRange];
            [shadowString addAttribute:NSStrokeColorAttributeName value:_textShadowColor range:valueRange];
            [shadowString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat: -_shadowRadius] range:valueRange];
        }
    }
    _textShadowView.attributedText = shadowString;
    _textView.attributedText = string;
}

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius
{
    if (bold)
        _textFont = _boldFont;
    else
        _textFont = _regularFont;
    
    _textColor = textColor;
    _textShadowColor = textShadowColor;
    _shadowRadius = shadowRadius;

    self.layer.shadowOpacity = shadowRadius > 0 ? 0.0 : 0.3;
    [OATextInfoWidget turnLayerBorder:self on:shadowRadius > 0];

    [self refreshLabel:_textView.text];
}

- (BOOL) updateInfo
{
    BOOL visible = false;
    int locimminent = -1;
    vector<int> loclanes;
    int dist = 0;
    // TurnType primary = null;
    if ((![_rh isFollowingMode] || [OARoutingHelper isDeviatedFromRoute] || [_rh getCurrentGPXRoute]) && [_trackingUtilities isMapLinkedToLocation] && [_settings.showLanes get])
    {
        CLLocation *lp = _locationProvider.lastKnownLocation;
        std::shared_ptr<RouteDataObject> ro = nullptr;
        if (lp)
        {
            ro = [_currentPositionHelper getLastKnownRouteSegment:lp];
            if (ro)
            {
                float degree = !lp || (lp.course < 0 ? 0 : lp.course);
                loclanes = parseTurnLanes(ro, degree / 180 * M_PI);
                if (loclanes.empty())
                    loclanes = parseLanes(ro, degree / 180 * M_PI);
            }
        }
    }
    else if ([_rh isRouteCalculated])
    {
        if ([_rh isFollowingMode] && [_settings.showLanes get])
        {
            OANextDirectionInfo *r = [_rh getNextRouteDirectionInfo:[[OANextDirectionInfo alloc] init] toSpeak:false];
            if (r && r.directionInfo && r.directionInfo.turnType)
            {
                loclanes = r.directionInfo.turnType->getLanes();
                // primary = r.directionInfo.getTurnType();
                locimminent = r.imminent;
                // Do not show too far
                if ((r.distanceTo > 800 && r.directionInfo.turnType->isSkipToSpeak()) || r.distanceTo > 1200)
                    loclanes.clear();
                
                dist = r.distanceTo;
            }
        }
        else
        {
            int di = [OARouteInfoView getDirectionInfo];
            if (di >= 0 && [OARouteInfoView isVisible] && di < [_rh getRouteDirections].count)
            {
                OARouteDirectionInfo *next = [_rh getRouteDirections][di];
                if (next)
                {
                    loclanes = next.turnType->getLanes();
                    // primary = next.getTurnType();
                }
            }
            else
            {
                loclanes.clear();
            }
        }
    }
    visible = !loclanes.empty();
    if (visible)
    {
        BOOL needFrameUpdate = NO;
        //[_lanesDrawable setLanes:vector<int>()]; // TEST
        auto& drawableLanes = [_lanesDrawable getLanes];
        if (drawableLanes.size() != loclanes.size() || (drawableLanes.size() > 0 && !std::equal(drawableLanes.begin(), drawableLanes.end(), loclanes.begin())) || (locimminent == 0) != _lanesDrawable.imminent)
        {
            _lanesDrawable.imminent = locimminent == 0;
            [_lanesDrawable setLanes:loclanes];
            [_lanesDrawable updateBounds];
            needFrameUpdate = YES;
        }

        if ([self distChanged:dist dist:_dist])
        {
            _dist = dist;
            if (dist == 0)
                [self refreshLabel:@""];
            else
                [self refreshLabel:[OAOsmAndFormatter getFormattedDistance:dist]];
            
            _textView.hidden = _textView.text.length == 0;
            needFrameUpdate = YES;
        }
        
        if (needFrameUpdate)
        {
            BOOL hasText = _textView.text.length > 0;
            CGRect parentFrame = self.superview.frame;
            CGFloat minWidth = MAX(kMinWidth, [OAUtilities calculateTextBounds:_textView.text width:1000 font:_textFont].width);
            CGSize newSize = CGSizeMake(MAX(minWidth, _lanesDrawable.width + kBorder * 2), _lanesDrawable.height + kBorder * 2 + (hasText ? kTextViewHeight : 0));
            self.frame = (CGRect) { parentFrame.size.width / 2 - newSize.width / 2, self.frame.origin.y, newSize };
            _lanesDrawable.frame = CGRectMake(_lanesView.bounds.size.width / 2 - _lanesDrawable.width / 2, 0, _lanesDrawable.width, _lanesDrawable.height);
            [_lanesDrawable setNeedsDisplay];
        }
    }
    [self updateVisibility:visible];
    
    return YES;
}

- (BOOL) distChanged:(int)oldDist dist:(int)dist
{
    return oldDist == 0 || ABS(oldDist - dist) > 10;
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:nil visible:visible];
        
        return YES;
    }
    return NO;
}

@end
