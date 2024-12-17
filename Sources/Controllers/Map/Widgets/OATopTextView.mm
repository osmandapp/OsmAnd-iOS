//
//  OATopTextView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATopTextView.h"
#import "OsmAndApp.h"
#import "OACurrentStreetName.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OALocationServices.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAWaypointHelper.h"
#import "OATurnDrawable.h"
#import "OATurnDrawable+cpp.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OARouteInfoView.h"
#import "OARouteDirectionInfo.h"
#import "OACurrentPositionHelper.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OATextInfoWidget.h"
#import "OAWaypointUIHelper.h"
#import "OAPointDescription.h"
#import "OALocationPointWrapper.h"
#import "OAOsmAndFormatter.h"
#import "OARouteCalculationResult.h"
#import "OARoutingHelperUtils.h"
#import "OAMapPresentationEnvironment.h"
#import "OANativeUtilities.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/MapStyleEvaluator.h>
#include <OsmAndCore/Map/MapStyleEvaluationResult.h>
#include <OsmAndCore/Map/MapStyleBuiltinValueDefinitions.h>
#include <OsmAndCore/TextRasterizer.h>
#include <binaryRead.h>

@interface OATopTextView ()

@property (weak, nonatomic) IBOutlet UIView *turnView;
@property (weak, nonatomic) IBOutlet UILabel *addressText;
@property (weak, nonatomic) IBOutlet UILabel *addressTextShadow;
@property (weak, nonatomic) IBOutlet UIView *exitRefTextContainer;
@property (weak, nonatomic) IBOutlet UILabel *exitRefText;
@property (weak, nonatomic) IBOutlet UIImageView *shieldIcon;

@property (weak, nonatomic) IBOutlet UIView *waypointInfoBar;
@property (weak, nonatomic) IBOutlet UIImageView *waypointImage;
@property (weak, nonatomic) IBOutlet UILabel *waypointDist;
@property (weak, nonatomic) IBOutlet UILabel *waypointText;
@property (weak, nonatomic) IBOutlet UILabel *waypointTextShadow;
@property (weak, nonatomic) IBOutlet UIButton *waypointButtonMore;
@property (weak, nonatomic) IBOutlet UIButton *waypointButtonRemove;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *exitRefTextContainerWidthConstraint;

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
    OALocationPointWrapper *_lastPoint;
    OATurnDrawable *_turnDrawable;
    UIImageView *_imageView;
    BOOL _showMarker;
    
    OANextDirectionInfo *_calc1;
    
    std::shared_ptr<const OsmAnd::TextRasterizer> _textRasterizer;
    OACurrentStreetName *_prevStreetName;
    NSArray<RoadShield *> *cachedRoadShields;
    NSString *_roadShieldName;
    
    UIFont *_textFont;
    UIFont *_textWaypointFont;
    UIColor *_textColor;
    UIColor *_textShadowColor;
    float _shadowRadius;
    
    UIFont *_regularFont;
    UIFont *_boldFont;
    UIFont *_regularWaypointFont;
    UIFont *_boldWaypointFont;

    UIButton *_shadowButton;
    UIButton *_shadowWaypointButton;
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
    self.widgetType = OAWidgetType.streetName;
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];
    _locationProvider = _app.locationServices;
    _waypointHelper = [OAWaypointHelper sharedInstance];
    _trackingUtilities = [OAMapViewTrackingUtilities instance];
    _currentPositionHelper = [OACurrentPositionHelper instance];
    _calc1 = [[OANextDirectionInfo alloc] init];
    
    _textRasterizer = OsmAnd::TextRasterizer::getDefault();
    
    BOOL isNight = OADayNightHelper.instance.isNightMode;

    CGFloat radius = 3.0;
    self.backgroundColor = isNight ? UIColorFromRGB(nav_bar_night) : UIColor.whiteColor;
    self.layer.cornerRadius = radius;

    _regularFont = [UIFont systemFontOfSize:23 weight:UIFontWeightSemibold];
    _boldFont = [UIFont systemFontOfSize:23 weight:UIFontWeightBold];
    _regularWaypointFont = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    _boldWaypointFont = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    _textFont = _regularFont;
    _textWaypointFont = _regularWaypointFont;
    _textColor = isNight ? UIColor.whiteColor : UIColor.blackColor;
    _textShadowColor = nil;
    _shadowRadius = 0;
    
    _turnDrawable = [[OATurnDrawable alloc] initWithMini:YES themeColor:EOATurnDrawableThemeColorMap];
    _turnDrawable.frame = _turnView.bounds;
    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeCenter;
    _imageView.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_action_start_navigation"] color:UIColorFromRGB(color_myloc_distance)];
    _imageView.frame = _turnView.bounds;
    
    _exitRefTextContainer.layer.cornerRadius = 6.;
    _shadowButton = [[UIButton alloc] initWithFrame:self.frame];
    _shadowButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_shadowButton addTarget:self action:@selector(onTopTextViewClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self insertSubview:_shadowButton belowSubview:_waypointInfoBar];

    _shadowWaypointButton = [[UIButton alloc] initWithFrame:self.frame];
    _shadowWaypointButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_shadowWaypointButton addTarget:self action:@selector(onWaypointViewClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_waypointInfoBar insertSubview:_shadowWaypointButton aboveSubview:_waypointText];

    [self updateVisibility:NO];
}

- (void) updateFrame
{
    CGRect f = self.frame;
    f.size.height = _waypointInfoBar.hidden ? 32 : 50;
    self.frame = f;
}

- (void) layoutSubviews
{
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    BOOL showShield = _shieldIcon.image && !_shieldIcon.isHidden;
    BOOL showTurn = !_turnView.isHidden && _turnView.subviews.count > 0;
    BOOL showExit = !_exitRefTextContainer.isHidden && _exitRefText.text.length > 0;
    BOOL showAddress = !_addressText.isHidden && _addressText.text.length > 0;
    CGRect shieldFrame = _shieldIcon.frame;
    if (showShield)
    {
        shieldFrame.size = _shieldIcon.image.size;
        CGFloat height = h - 4;
        CGFloat scaleFactor = height / shieldFrame.size.height;
        shieldFrame.size = CGSizeMake(shieldFrame.size.width * scaleFactor, height);
        _shieldIcon.frame = shieldFrame;
    }
    CGRect exitRefFrame = _exitRefTextContainer.frame;
    if (showExit)
    {
        CGSize size = [OAUtilities calculateTextBounds:_exitRefText.text width:w font:[UIFont systemFontOfSize:17 weight:UIFontWeightSemibold]];
        _exitRefText.adjustsFontSizeToFitWidth = YES;
        _exitRefText.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
        _exitRefText.textAlignment = NSTextAlignmentCenter;
        exitRefFrame.size = CGSizeMake(size.width + 6., h - 4);
        if (size.width > 40)
            self.exitRefTextContainerWidthConstraint.constant = size.width;
        else
            self.exitRefTextContainerWidthConstraint.constant = 40;
    }
    
    CGFloat margin = _turnView.subviews.count > 0 ? 4 + _turnView.bounds.size.width + 2 : 2;
    margin += _exitRefTextContainer.hidden ? 0 : _exitRefTextContainer.frame.size.width + 2;
    margin += showShield ? shieldFrame.size.width + 2 : 0;
    margin += showExit ? exitRefFrame.size.width + 2 : 0;
    CGFloat maxTextWidth = w - margin * 2;
    CGSize size = [OAUtilities calculateTextBounds:showAddress ? _addressText.text : @"" width:maxTextWidth height:h font:_textFont];
    if (size.width > maxTextWidth)
        size.width = maxTextWidth;
    
    CGFloat x = w / 2 - size.width / 2;
    
    CGFloat prevX = x;
    if (showShield)
    {
        prevX = _shieldIcon.frame.origin.x;
    }
    if (showTurn)
    {
        prevX = _turnView.frame.origin.x;
    }
    if (showExit)
    {
        [self applyCorrectPositionToView:_exitRefTextContainer prevX:prevX];
    }
    
    _waypointText.frame = CGRectMake(96, 0, w - 176, h);
    _waypointTextShadow.frame = _waypointText.frame;
}

- (void) applyCorrectPositionToView:(UIView *)view prevX:(CGFloat)prevX
{
    CGFloat h = self.bounds.size.height;
    view.center = CGPointMake(prevX - 2 - view.bounds.size.width / 2, h / 2);
}

- (BOOL)isTopText
{
    return YES;
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
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:self visible:visible];
    }

    return needUpdate;
}

- (void) refreshLabel:(NSString *)text
{
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
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

    [self refreshLayout];
}

- (void) updateTextColor:(UIColor *)textColor textShadowColor:(UIColor *)textShadowColor bold:(BOOL)bold shadowRadius:(float)shadowRadius nightMode:(BOOL)nightMode
{
    if (bold)
    {
        _textFont = _boldFont;
        _textWaypointFont = _boldWaypointFont;
    }
    else
    {
        _textFont = _regularFont;
        _textWaypointFont = _regularWaypointFont;
    }
    
    _textColor = textColor;
    _textShadowColor = textShadowColor;
    _shadowRadius = shadowRadius;

    [self refreshLabel:_addressText.text];
}

- (BOOL) updateWaypoint
{
    OALocationPointWrapper *pnt = [_waypointHelper getMostImportantLocationPoint:nil];
    BOOL changed = _lastPoint != pnt;
    BOOL updated = NO;
    BOOL res = NO;
    _lastPoint = pnt;
    if (!pnt)
    {
        [self updateVisibility:_waypointInfoBar visible:NO];
        res = NO;
    }
    else
    {
        [self updateVisibility:_turnView visible:NO];
        [self updateVisibility:_addressText visible:NO];
        [self updateVisibility:_addressTextShadow visible:NO];

        updated = [self updateVisibility:_waypointInfoBar visible:YES];
        [self updateVisibility:_waypointTextShadow visible:_shadowRadius > 0];

        id<OALocationPoint> point = pnt.point;
        _waypointImage.image = [pnt getImage:NO];
        
        NSString *descr = @"";
        
        if (pnt && [pnt.point isKindOfClass:[OASWptPt class]])
        {
            OASWptPt *wpt = (OASWptPt *)pnt.point;
            OAPointDescription *pd = [[OAPointDescription alloc] initWithType:POINT_TYPE_WPT name:wpt.name];
            if (pd.name && pd.name.length > 0)
                descr = pd.name;
            else if (pd.typeName && pd.typeName.length > 0)
                descr = pd.typeName;
        }

        NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
        attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:descr attributes:attributes];
        NSMutableAttributedString *stringShadow = nil;
        
        NSRange valueRange = NSMakeRange(0, descr.length);
        if (valueRange.length > 0 && _textWaypointFont && _textColor)
        {
            [string addAttribute:NSFontAttributeName value:_textWaypointFont range:valueRange];
            [string addAttribute:NSForegroundColorAttributeName value:_textColor range:valueRange];
            if (_textShadowColor && _shadowRadius > 0)
            {
                stringShadow = [[NSMutableAttributedString alloc] initWithString:descr attributes:attributes];
                [stringShadow addAttribute:NSFontAttributeName value:_textWaypointFont range:valueRange];
                [stringShadow addAttribute:NSForegroundColorAttributeName value:_textShadowColor range:valueRange];
                [stringShadow addAttribute:NSStrokeColorAttributeName value:_textShadowColor range:valueRange];
                [stringShadow addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat: -_shadowRadius] range:valueRange];
            }
        }
        _waypointTextShadow.attributedText = stringShadow;
        _waypointText.attributedText = string;
        
        int dist = -1;
        if (![_waypointHelper isRouteCalculated])
        {
            [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
            dist = [[[CLLocation alloc] initWithLatitude:[point getLatitude] longitude:[point getLongitude]] distanceFromLocation:[[OARootViewController instance].mapPanel.mapViewController getMapLocation]];
        }
        else
        {
            dist = [_waypointHelper getRouteDistance:pnt];
        }
        
        NSString *distStr = nil;
        if (dist > 0)
            distStr = [OAOsmAndFormatter getFormattedDistance:dist];
        
        NSString *deviationStr = nil;
        UIImage *deviationImg = nil;
        if (dist > 0 && pnt.deviationDistance > 0) {
            deviationStr = [OAOsmAndFormatter getFormattedDistance:pnt.deviationDistance];
            UIColor *color = UIColorFromRGB(color_osmand_orange);
            if (pnt.deviationDirectionRight)
                deviationImg = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_small_turn_right"] color:color];
            else
                deviationImg = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_small_turn_left"] color:color];
        }
        
        NSMutableAttributedString *distAttrStr = nil;
        if (distStr)
        {
            distAttrStr = [[NSMutableAttributedString alloc] initWithString:distStr];
            UIColor *color = UIColorFromRGB(color_myloc_distance);
            [distAttrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, distStr.length)];
        }
        NSMutableAttributedString *deviationAttrStr = nil;
        if (deviationStr)
        {
            deviationAttrStr = [[NSMutableAttributedString alloc] initWithString:deviationStr];
            if (deviationImg)
            {
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                attachment.image = deviationImg;
                NSAttributedString *strWithImage = [NSAttributedString attributedStringWithAttachment:attachment];
                [deviationAttrStr replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:strWithImage];
                [deviationAttrStr addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
            }
        }
        
        NSMutableAttributedString *descAttrStr = [[NSMutableAttributedString alloc] init];
        if (distAttrStr)
            [descAttrStr appendAttributedString:distAttrStr];
        if (deviationAttrStr)
        {
            if (descAttrStr.length > 0)
                [descAttrStr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            
            [descAttrStr appendAttributedString:deviationAttrStr];
        }
        if (descAttrStr.length > 0)
        {
            UIColor *color = UIColorFromRGB(color_osmand_orange);
            [descAttrStr addAttribute:NSForegroundColorAttributeName value:color range:NSMakeRange(0, descAttrStr.length)];
            UIFont *font = [UIFont systemFontOfSize:12 weight:UIFontWeightSemibold];
            if (font)
                [descAttrStr addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, descAttrStr.length)];
        }
        _waypointDist.attributedText = descAttrStr;
        
        res = YES;
    }
    
    if (changed || updated)
        [self refreshLayout];
    
    return res;
}

- (void) refreshLayout
{
    [self updateFrame];
    [self setNeedsLayout];
    if (self.delegate)
        [self.delegate widgetChanged:self];
}

- (BOOL) updateInfo
{
    OACurrentStreetName *streetName = nil;
    BOOL showClosestWaypointFirstInAddress = YES;
    if ([_routingHelper isRouteCalculated] && ![OARoutingHelper isDeviatedFromRoute])
    {
        if ([_routingHelper isFollowingMode])
        {
            OANextDirectionInfo *nextDirInfo = [_routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:YES];
            streetName = [_routingHelper getCurrentName:nextDirInfo];
            _turnDrawable.clr = [UIColor colorNamed:ACColorNameNavArrowColor].currentMapThemeColor;
        }
        else
        {
            int di = [OARouteInfoView getDirectionInfo];
            if (di >= 0 && [OARouteInfoView isVisible] && di < [_routingHelper getRouteDirections].count)
            {
                showClosestWaypointFirstInAddress = NO;
                streetName = [_routingHelper getCurrentName:[_routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:YES]];
                _turnDrawable.clr = [UIColor colorNamed:ACColorNameNavArrowDistantColor].currentMapThemeColor;
            }
        }
    }
    else if ([_trackingUtilities isMapLinkedToLocation])
    {
        streetName = [[OACurrentStreetName alloc] init];
        CLLocation *lastKnownLocation = _locationProvider.lastKnownLocation;
        std::shared_ptr<RouteDataObject> road;
        if (lastKnownLocation)
        {
            road = [_currentPositionHelper getLastKnownRouteSegment:lastKnownLocation];
            if (road)
            {
                string lang = _settings.settingPrefMapLanguage.get ? _settings.settingPrefMapLanguage.get.UTF8String : "";
                bool transliterate = _settings.settingMapLanguageTranslit.get;

                string rStreetName = road->getName(lang, transliterate);
                string rRefName = road->getRef(lang, transliterate, road->bearingVsRouteDirection(lastKnownLocation.course));
                string rDestinationName = road->getDestinationName(lang, transliterate, true);
                
                NSString *strtName = [NSString stringWithUTF8String:rStreetName.c_str()];
                NSString *refName = [NSString stringWithUTF8String:rRefName.c_str()];
                NSString *destinationName = [NSString stringWithUTF8String:rDestinationName.c_str()];

                streetName.text = [OARoutingHelperUtils formatStreetName:strtName ref:refName destination:destinationName towards:@"»"];
            }
            if (streetName.text.length > 0 && road)
            {
                double dist = [OACurrentPositionHelper getOrthogonalDistance:road loc:lastKnownLocation];
                if (dist < 50)
                    streetName.showMarker = YES;
                else
                    streetName.text = [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"shared_string_near"), streetName.text];
            }
        }
    }
    
    //Change several shields to one
    if (streetName.shields.count > 1)
    {
        NSMutableArray<RoadShield *> *oneShield = [NSMutableArray arrayWithObject:streetName.shields.firstObject];
        NSMutableString * other = [streetName.text mutableCopy];
        for (int i = 1; i < 4 && i < streetName.shields.count; i++)
        {
            RoadShield *shield = [streetName.shields objectAtIndex:i];
            if (other.length == 0)
                [other appendString:shield.value];
            else
                [other appendString:[NSString stringWithFormat:@", %@", shield.value]];
        }
        streetName.text = other;
        streetName.shields = oneShield;
    }
    
    _shadowButton.accessibilityLabel =  OALocalizedString(@"map_widget_top_text");
    _shadowButton.accessibilityValue = streetName.text;
    
    if ([[OARootViewController instance].mapPanel isTopToolbarActive])
    {
        [self updateVisibility:NO];
    }
    else if (showClosestWaypointFirstInAddress && [self updateWaypoint])
    {
        [self updateVisibility:YES];
        [self updateVisibility:_turnView visible:NO];
        [self updateVisibility:_addressText visible:NO];
        [self updateVisibility:_addressTextShadow visible:NO];
        [self updateVisibility:_shieldIcon visible:NO];
        [self updateVisibility:_exitRefTextContainer visible:NO];
    }
    else if (!streetName)
    {
        [self updateVisibility:NO];
    }
    else
    {
        if ([streetName isEqual:_prevStreetName])
            return YES;

        [self updateVisibility:YES];
        [self updateVisibility:_waypointInfoBar visible:NO];
        [self updateVisibility:_addressText visible:YES];
        [self updateVisibility:_addressTextShadow visible:_shadowRadius > 0];
        _prevStreetName = streetName;
        NSArray<RoadShield *> *shields = streetName.shields;
        if (shields.count != 0 && ![shields isEqual:cachedRoadShields])
        {
            if([self setRoadShield:_shieldIcon shields:shields])
            {
                _shieldIcon.hidden = NO;
                int idx = [streetName.text indexOf:@"»"];
                if (idx > 0)
                    streetName.text = [streetName.text substringFromIndex:idx];
            }
            cachedRoadShields = shields;
        }
        else
        {
            _shieldIcon.hidden = YES;
            cachedRoadShields = nil;
        }
        if (streetName.exitRef.length > 0)
        {
            _exitRefText.text = streetName.exitRef;
            _exitRefTextContainer.hidden = NO;
        }
        else
        {
            _exitRefTextContainer.hidden = YES;
        }
        if ([_turnDrawable setTurnType:streetName.turnType] || streetName.showMarker != _showMarker)
        {
            _showMarker = streetName.showMarker;
            if (streetName.turnType)
            {
                [_imageView removeFromSuperview];
                _turnDrawable.translatesAutoresizingMaskIntoConstraints = NO;
                [_turnView addSubview:_turnDrawable];
                
                [NSLayoutConstraint activateConstraints:@[
                    [_turnDrawable.topAnchor constraintEqualToAnchor:_turnView.topAnchor],
                    [_turnDrawable.leadingAnchor constraintEqualToAnchor:_turnView.leadingAnchor],
                    [_turnDrawable.bottomAnchor constraintEqualToAnchor:_turnView.bottomAnchor],
                    [_turnDrawable.trailingAnchor constraintEqualToAnchor:_turnView.trailingAnchor]
                ]];
            }
            else if (_showMarker)
            {
                [_turnDrawable removeFromSuperview];
                _imageView.translatesAutoresizingMaskIntoConstraints = NO;
                [_turnView addSubview:_imageView];
                
                [NSLayoutConstraint activateConstraints:@[
                    [_imageView.topAnchor constraintEqualToAnchor:_turnView.topAnchor],
                    [_imageView.leadingAnchor constraintEqualToAnchor:_turnView.leadingAnchor],
                    [_imageView.bottomAnchor constraintEqualToAnchor:_turnView.bottomAnchor],
                    [_imageView.trailingAnchor constraintEqualToAnchor:_turnView.trailingAnchor]
                ]];
            }
            else
            {
                [_turnDrawable removeFromSuperview];
                [_imageView removeFromSuperview];
            }
        }
        if (streetName.text.length == 0)
        {
            _addressTextShadow.text = @"";
            _addressText.text = @"";

            [self refreshLayout];
        }
        else if (![streetName.text isEqualToString:_addressText.text])
        {
            [self refreshLabel:streetName.text];
            return YES;
        }
    }
    return NO;
}



- (BOOL)setRoadShield:(UIImageView *)view shields:(NSArray<RoadShield *> *)shields {
    if (shields.count != 0) 
    {
        BOOL isShieldSet = NO;
        NSInteger maxShields = MIN(shields.count, MAX_SHIELDS_QUANTITY);
        
        for (NSInteger i = 0; i < maxShields; i++) 
        {
            RoadShield * shield = shields[i];
            isShieldSet |= [self setRoadShield:view shield:shield];
        }
        
        return isShieldSet;
    }
    return NO;
}

- (BOOL) setRoadShield:(UIImageView *)view shield:(RoadShield *)shield
{
    const auto& object = shield.rdo;
    const auto& tps = object->types;
    NSString* nameTag = shield.tag;
    NSString* name = shield.value;
    NSMutableString * additional = [shield.additional mutableCopy];
    OAMapPresentationEnvironment *mapPres = OARootViewController.instance.mapPanel.mapViewController.mapPresentationEnv;
    const auto& env = mapPres.mapPresentationEnvironment;
    if (!env)
        return NO;
    OsmAnd::MapStyleEvaluator textEvaluator(env->mapStyle, env->displayDensityFactor);
    env->applyTo(textEvaluator);
    OsmAnd::MapStyleEvaluationResult evaluationResult(env->mapStyle->getValueDefinitionsCount());
    
    for (int i : tps) {
        const auto& tp = object->region->quickGetEncodingRule(i);
        if (tp.getTag() == "highway" || tp.getTag() == "route")
        {
            textEvaluator.setIntegerValue(env->styleBuiltinValueDefs->id_INPUT_MINZOOM, 13);
            textEvaluator.setIntegerValue(env->styleBuiltinValueDefs->id_INPUT_MAXZOOM, 13);
            textEvaluator.setStringValue(env->styleBuiltinValueDefs->id_INPUT_TAG, QString::fromStdString(tp.getTag()));
            textEvaluator.setStringValue(env->styleBuiltinValueDefs->id_INPUT_VALUE, QString::fromStdString(tp.getValue()));
        }
        else
        {
            [additional appendFormat:@"%s=%s;", tp.getTag().c_str(), tp.getValue().c_str()];
        }
    }
    
    textEvaluator.setIntegerValue(env->styleBuiltinValueDefs->id_INPUT_TEXT_LENGTH, (unsigned int) name.length);
    textEvaluator.setStringValue(env->styleBuiltinValueDefs->id_INPUT_NAME_TAG, QString::fromNSString(nameTag));
    auto mapObj = std::make_shared<OsmAnd::MapObject>();
    auto additionals = std::make_shared<OsmAnd::MapObject::AttributeMapping>();
    uint32_t idx = 0;
    for (NSString *str : [additional componentsSeparatedByString:@";"])
    {
        NSArray<NSString *> *tagValue = [str componentsSeparatedByString:@"="];
        if (tagValue.count == 2)
        {
            mapObj->additionalAttributeIds.push_back(idx);
            additionals->registerMapping(idx++, QString::fromNSString(tagValue.firstObject), QString::fromNSString(tagValue.lastObject));
        }
    }
    mapObj->attributeMapping = additionals;
    
    textEvaluator.evaluate(mapObj, OsmAnd::MapStyleRulesetType::Text, &evaluationResult);
    
    OsmAnd::TextRasterizer::Style textStyle;
    textStyle.setBold(true);
    
    QString shieldName;
    evaluationResult.getStringValue(env->styleBuiltinValueDefs->id_OUTPUT_TEXT_SHIELD, shieldName);
    if (!shieldName.isNull() && !shieldName.isEmpty())
    {
        sk_sp<const SkImage> shield;
        env->obtainShaderOrShield(shieldName, 1.0f, shield);

        if (shield)
            textStyle.setBackgroundImage(shield);
    }
    
    int textColor = -1;
    evaluationResult.getIntegerValue(env->styleBuiltinValueDefs->id_OUTPUT_TEXT_COLOR, textColor);
    if (textColor != -1)
        textStyle.setColor(OsmAnd::ColorARGB(textColor));
    
    float textSize = -1;
    evaluationResult.getFloatValue(env->styleBuiltinValueDefs->id_OUTPUT_TEXT_SIZE, textSize);
    if (textSize != -1)
        textStyle.setSize(textSize);
    
    
    const auto textImage = _textRasterizer->rasterize(QString::fromNSString(name), textStyle);
    if (textImage)
    {
        view.image = [OANativeUtilities skImageToUIImage:textImage];
        _roadShieldName = name;
        return YES;
    }

    _roadShieldName = nil;
    return NO;
}

- (void) onTopTextViewClicked:(id)sender
{
    if (self.delegate)
        [self.delegate widgetClicked:self];
}

- (void) onWaypointViewClicked:(id)sender
{
    [OAWaypointUIHelper showOnMap:_lastPoint];

    if (self.delegate)
        [self.delegate widgetClicked:self];
}

- (IBAction) onMoreButtonClicked:(id)sender
{
    [[OARootViewController instance].mapPanel showWaypoints:YES];
}

- (IBAction) onRemoveButtonClicked:(id)sender
{
    if (_lastPoint)
    {
        [_waypointHelper removeVisibleLocationPoint:_lastPoint];
        [[OARootViewController instance].mapPanel refreshMap];
    }
}

@end
