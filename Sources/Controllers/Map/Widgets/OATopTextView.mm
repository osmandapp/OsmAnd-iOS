//
//  OATopTextView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATopTextView.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OALocationServices.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAWaypointHelper.h"
#import "OATurnDrawable.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OARouteInfoView.h"
#import "OARouteDirectionInfo.h"
#import "OACurrentPositionHelper.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATextInfoWidget.h"

@interface OATopTextView ()

@property (weak, nonatomic) IBOutlet UIView *turnView;
@property (weak, nonatomic) IBOutlet UILabel *addressText;
@property (weak, nonatomic) IBOutlet UILabel *addressTextShadow;
@property (weak, nonatomic) IBOutlet UIView *waypointInfoBar;

@end

@implementation OATopTextView
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
    //MapActivity map;
    OALocationServices *_locationProvider;
    OAMapViewTrackingUtilities *_trackingUtilities;
    OACurrentPositionHelper *_currentPositionHelper;
    OAWaypointHelper *_waypointHelper;
    //OALocationPointWrapper *_lastPoint;
    OATurnDrawable *_turnDrawable;
    UIImageView *_imageView;
    BOOL _showMarker;
    
    UIFont *_textFont;
    UIColor *_textColor;
    UIColor *_textShadowColor;
    float _shadowRadius;
    
    UIFont *_regularFont;
    UIFont *_boldFont;
    
    UIButton *_shadowButton;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATopTextView class]])
        {
            self = (OATopTextView *)v;
            break;
        }
    }
    
    if (self)
        self.frame = CGRectMake(0, 0, DeviceScreenWidth, 32);
    
    [self commonInit];
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    
    for (UIView *v in bundle)
    {
        if ([v isKindOfClass:[OATopTextView class]])
        {
            self = (OATopTextView *)v;
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
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];
    _locationProvider = _app.locationServices;
    _waypointHelper = [OAWaypointHelper sharedInstance];
    _trackingUtilities = [OAMapViewTrackingUtilities instance];
    _currentPositionHelper = [OACurrentPositionHelper instance];

    CGFloat radius = 3.0;
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = radius;
    
    // drop shadow
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.3;
    self.layer.shadowRadius = 2.0;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.0);

    _regularFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:23];
    _boldFont = [UIFont fontWithName:@"AvenirNextCondensed-Bold" size:23];
    _textFont = _regularFont;
    _textColor = [UIColor blackColor];
    _textShadowColor = nil;
    _shadowRadius = 0;
    
    _turnDrawable = [[OATurnDrawable alloc] initWithMini:YES];
    _turnDrawable.frame = _turnView.bounds;
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeCenter;
    _imageView.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_action_start_navigation"] color:UIColorFromRGB(color_myloc_distance)];
    _imageView.frame = _turnView.bounds;
    
    _shadowButton = [[UIButton alloc] initWithFrame:self.frame];
    _shadowButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_shadowButton addTarget:self action:@selector(onTopTextViewClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_shadowButton];

    [self updateVisibility:NO];
}

- (void) layoutSubviews
{
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    CGFloat margin = _turnView.subviews.count > 0 ? 4 + _turnView.bounds.size.width + 2 : 2;
    CGFloat maxTextWidth = w - margin * 2;
    CGSize size = [OAUtilities calculateTextBounds:_addressText.text width:maxTextWidth height:h font:_textFont];
    if (size.width > maxTextWidth)
        size.width = maxTextWidth;
    
    CGFloat x = w / 2 - size.width / 2;
    _addressText.frame = CGRectMake(w / 2 - size.width / 2, 0, w - x - 4, h);
    _addressTextShadow.frame = _addressText.frame;
    _turnView.center = CGPointMake(_addressText.frame.origin.x - 2 - _turnView.bounds.size.width / 2, h / 2);
}

- (BOOL) updateVisibility:(BOOL)visible
{
    BOOL updated = [self updateVisibility:self visible:visible];
    if (updated)
        [[OARootViewController instance].mapPanel setNeedsStatusBarAppearanceUpdate];

    return updated;
}

- (BOOL) updateVisibility:(UIView *)view visible:(BOOL)visible
{
    BOOL needUpdate = (visible && view.hidden) || (!visible && !view.hidden);
    if (needUpdate)
    {
        view.hidden = !visible;
        if (_delegate)
            [_delegate topTextViewVisibilityChanged:self visible:visible];
    }

    return needUpdate;
}

- (void) refreshLabel:(NSString *)text
{
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    //paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    NSMutableAttributedString *stringShadow = nil;

    NSRange valueRange = NSMakeRange(0, text.length);
    if (valueRange.length > 0)
    {
        [string addAttribute:NSFontAttributeName value:_textFont range:valueRange];
        [string addAttribute:NSForegroundColorAttributeName value:_textColor range:valueRange];
        if (_textShadowColor && _shadowRadius > 0)
        {
            stringShadow = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
            [stringShadow addAttribute:NSFontAttributeName value:_textFont range:valueRange];
            [stringShadow addAttribute:NSForegroundColorAttributeName value:_textShadowColor range:valueRange];
            [stringShadow addAttribute:NSStrokeColorAttributeName value:_textShadowColor range:valueRange];
            [stringShadow addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat: -_shadowRadius] range:valueRange];
        }
    }
    _addressTextShadow.attributedText = stringShadow;
    _addressText.attributedText = string;
    
    [self setNeedsLayout];
    if (_delegate)
        [_delegate topTextViewChanged:self];
}

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius nightMode:(BOOL)nightMode
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

    [self refreshLabel:_addressText.text];
}

- (BOOL) updateWaypoint
{
    // TODO waypoints
    return NO;
}

- (BOOL) updateInfo
{
    NSString *text = nil;
    std::vector<std::shared_ptr<TurnType>> type(1);
    BOOL showNextTurn = false;
    BOOL showMarker = _showMarker;
    if ([_routingHelper isRouteCalculated] && ![OARoutingHelper isDeviatedFromRoute])
    {
        if ([_routingHelper isFollowingMode])
        {
            if ([_settings.showStreetName get])
            {
                text = [_routingHelper getCurrentName:type];
                if (!text)
                {
                    text = @"";
                }
                else
                {
                    if (type[0] == nullptr)
                        _showMarker = YES;
                    else
                        _turnDrawable.clr = UIColorFromRGB(color_nav_arrow);
                }
            }
        }
        else
        {
            int di = [OARouteInfoView getDirectionInfo];
            if (di >= 0 && [OARouteInfoView isVisible] && di < [_routingHelper getRouteDirections].count)
            {
                showNextTurn = YES;
                OARouteDirectionInfo *next = [_routingHelper getRouteDirections][di];
                type[0] = next.turnType;
                _turnDrawable.clr = UIColorFromRGB(color_nav_arrow_distant);
                text = [OARoutingHelper formatStreetName:next.streetName ref:next.ref destination:next.destinationName towards:@"»"];
                //                        if (next.distance > 0) {
                //                            text += " " + OsmAndFormatter.getFormattedDistance(next.distance, map.getMyApplication());
                //                        }
                if (!text)
                    text = @"";
            }
            else
            {
                text = nil;
            }
        }
    }
    else if ([_trackingUtilities isMapLinkedToLocation] && [_settings.showStreetName get])
    {
        CLLocation *lastKnownLocation = _locationProvider.lastKnownLocation;
        std::shared_ptr<const OsmAnd::Road> road = nullptr;
        if (lastKnownLocation)
        {
            road = [_currentPositionHelper getLastKnownRouteSegment:lastKnownLocation];
            if (road)
            {
                QString lang = QString::fromNSString([_settings settingPrefMapLanguage] ? [_settings settingPrefMapLanguage] : @"");
                bool transliterate = [_settings settingMapLanguageTranslit];

                QString qStreetName = road->getName(lang, transliterate);
                QString qRefName = road->getRef(lang, transliterate);
                QString qDestinationName = road->getDestinationName(lang, transliterate, true);
                
                NSString *streetName = qStreetName.isNull() ? nil : qStreetName.toNSString();
                NSString *refName = qRefName.isNull() ? nil : qRefName.toNSString();
                NSString *destinationName = qDestinationName.isNull() ? nil : qDestinationName.toNSString();

                text = [OARoutingHelper formatStreetName:streetName ref:refName destination:destinationName towards:@"»"];
            }
        }
        if (!text)
        {
            text = @"";
        }
        else
        {
            if (text.length > 0 && road)
            {
                double dist = [OACurrentPositionHelper getOrthogonalDistance:road loc:lastKnownLocation];
                if (dist < 50)
                    showMarker = YES;
                else
                    text = [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"shared_string_near"), text];
            }
        }
    }
    if ([[OARootViewController instance].mapPanel isTopToolbarActive])
    {
        [self updateVisibility:NO];
    }
    else if (!showNextTurn && [self updateWaypoint])
    {
        [self updateVisibility:YES];
        [self updateVisibility:_addressText visible:NO];
        [self updateVisibility:_addressTextShadow visible:NO];
    }
    else if (!text)
    {
        [self updateVisibility:NO];
    }
    else
    {
        [self updateVisibility:YES];
        [self updateVisibility:_waypointInfoBar visible:NO];
        [self updateVisibility:_addressText visible:YES];
        [self updateVisibility:_addressTextShadow visible:_shadowRadius > 0];
        BOOL update = [_turnDrawable setTurnType:type[0]] || showMarker != _showMarker;
        _showMarker = showMarker;
        if (update)
        {
            if (type[0] != nullptr)
            {
                [_imageView removeFromSuperview];
                [_turnView addSubview:_turnDrawable];
            }
            else if (showMarker)
            {
                [_turnDrawable removeFromSuperview];
                [_turnView addSubview:_imageView];
            }
            else
            {
                [_turnDrawable removeFromSuperview];
                [_imageView removeFromSuperview];
            }
        }
        if (![text isEqualToString:_addressText.text])
        {
            [self refreshLabel:text];
            return YES;
        }
    }
    return NO;
}

- (void) onTopTextViewClicked:(id)sender
{
    if (_delegate)
        [_delegate topTextViewClicked:self];
}

@end
