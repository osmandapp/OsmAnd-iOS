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
#import "OAUtilities.h"
#import "OAColors.h"
#import "OARouteInfoView.h"
#import "OARouteDirectionInfo.h"
#import "OACurrentPositionHelper.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OATextInfoWidget.h"
#import "OAWaypointUIHelper.h"
#import "OAPointDescription.h"
#import "OALocationPointWrapper.h"
#import "OAOsmAndFormatter.h"
#import "OARouteCalculationResult.h"
#import "OARoutingHelperUtils.h"

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
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];
    _locationProvider = _app.locationServices;
    _waypointHelper = [OAWaypointHelper sharedInstance];
    _trackingUtilities = [OAMapViewTrackingUtilities instance];
    _currentPositionHelper = [OACurrentPositionHelper instance];
    _calc1 = [[OANextDirectionInfo alloc] init];

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
    _regularWaypointFont = [UIFont fontWithName:@"AvenirNext-Medium" size:17];
    _boldWaypointFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:17];
    _textFont = _regularFont;
    _textWaypointFont = _regularWaypointFont;
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
    BOOL showShield = _shieldIcon.image && !_shieldIcon.hidden;
    CGRect shieldFrame = _shieldIcon.frame;
    if (showShield)
    {
        shieldFrame.size = _shieldIcon.image.size;
        _shieldIcon.frame = shieldFrame;
    }
    
    CGFloat margin = _turnView.subviews.count > 0 ? 4 + _turnView.bounds.size.width + 2 : 2;
    margin += _exitRefTextContainer.hidden ? 0 : _exitRefTextContainer.frame.size.width + 2;
    margin += showShield && _shieldIcon.image ? shieldFrame.size.width + 2 : 0;
    CGFloat maxTextWidth = w - margin * 2;
    CGSize size = [OAUtilities calculateTextBounds:_addressText.text width:maxTextWidth height:h font:_textFont];
    if (size.width > maxTextWidth)
        size.width = maxTextWidth;
    
    CGFloat x = w / 2 - size.width / 2;
    _addressText.frame = CGRectMake(w / 2 - size.width / 2, 0, w - x - 4, h);
    _addressTextShadow.frame = _addressText.frame;
    _turnView.center = CGPointMake(_addressText.frame.origin.x - 2 - _turnView.bounds.size.width / 2, h / 2);
    
    if (showShield)
        _shieldIcon.center = CGPointMake(_turnView.frame.origin.x - 2 - _shieldIcon.bounds.size.width / 2, h / 2);
    
    if (!_exitRefTextContainer.hidden)
        _exitRefTextContainer.center = CGPointMake(_shieldIcon.frame.origin.x - 2 - _exitRefTextContainer.bounds.size.width / 2, h / 2);
    
    _waypointText.frame = CGRectMake(96, 0, w - 176, h);
    _waypointTextShadow.frame = _waypointText.frame;
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
    
    [self updateFrame];
    [self setNeedsLayout];
    if (self.delegate)
        [self.delegate widgetChanged:self];
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
    
    self.layer.shadowOpacity = shadowRadius > 0 ? 0.0 : 0.3;
    [OATextInfoWidget turnLayerBorder:self on:shadowRadius > 0];

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
        OAPointDescription *pd = [point getPointDescription];
        if (pd.name && pd.name.length > 0)
            descr = pd.name;
        else if (pd.typeName && pd.typeName.length > 0)
            descr = pd.typeName;
        
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
            UIFont *font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:12];
            if (font)
                [descAttrStr addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, descAttrStr.length)];
        }
        _waypointDist.attributedText = descAttrStr;
        
        res = YES;
    }
    
    if (changed || updated)
    {
        [self updateFrame];
        [self setNeedsLayout];
        if (self.delegate)
            [self.delegate widgetChanged:self];
    }
    
    return res;
}

- (BOOL) updateInfo
{
    OACurrentStreetName *streetName = nil;
    BOOL showClosestWaypointFirstInAddress = YES;
    if ([_routingHelper isRouteCalculated] && ![OARoutingHelper isDeviatedFromRoute])
    {
        if ([_routingHelper isFollowingMode])
        {
            if ([_settings.showStreetName get])
            {
                OANextDirectionInfo *nextDirInfo = [_routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:YES];
                streetName = [_routingHelper getCurrentName:nextDirInfo];
                _turnDrawable.clr = UIColorFromRGB(color_nav_arrow);
            }
        }
        else
        {
            int di = [OARouteInfoView getDirectionInfo];
            if (di >= 0 && [OARouteInfoView isVisible] && di < [_routingHelper getRouteDirections].count)
            {
                showClosestWaypointFirstInAddress = NO;
                streetName = [_routingHelper getCurrentName:[_routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:YES]];
                _turnDrawable.clr = UIColorFromRGB(color_nav_arrow_distant);
            }
        }
    }
    else if ([_trackingUtilities isMapLinkedToLocation] && [_settings.showStreetName get])
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
        [self updateVisibility:YES];
        [self updateVisibility:_waypointInfoBar visible:NO];
        [self updateVisibility:_addressText visible:YES];
        [self updateVisibility:_addressTextShadow visible:_shadowRadius > 0];
        
        if (streetName.shieldObject && !streetName.shieldObject->namesIds.empty())
        
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

- (BOOL) setRoadShield:(UIImageView *)view object:(std::shared_ptr<RouteDataObject> &)object
{
    NSMutableString *additional = [NSMutableString string];
    for (NSInteger i = 0; i < object->namesIds.size(); i++)
    {
        NSString *key = [NSString stringWithUTF8String:object->region->quickGetEncodingRule(object->namesIds[i].first).getTag().c_str()];
        NSString *val = [NSString stringWithUTF8String:object->names[object->namesIds[i].first].c_str()];
        if (![key hasSuffix:@"_ref"] && ![key hasPrefix:@"route_road"])
            [additional appendFormat:@"%@=%@;", key, val];
    }
    for (NSInteger i = 0; i < object->namesIds.size(); i++)
    {
        NSString *key = [NSString stringWithUTF8String:object->region->quickGetEncodingRule(object->namesIds[i].first).getTag().c_str()];
        NSString *val = [NSString stringWithUTF8String:object->names[object->namesIds[i].first].c_str()];
        if ([key hasPrefix:@"route_road"] && [key hasSuffix:@"_ref"])
        {
            BOOL visible = [self setRoadShield:view object:object nameTag:key name:val additional:additional];
            if (visible)
                return YES;
        }
    }
    return NO;
}

- (BOOL) setRoadShield:(UIImageView *)view object:(std::shared_ptr<RouteDataObject> &)object nameTag:(NSString *)nameTag name:(NSString *)name additional:(NSMutableString *)additional
{
    const auto& tps = object->types;
//    RenderingRulesStorage storage = app.getRendererRegistry().getCurrentSelectedRenderer();
    BOOL nightMode = OAAppSettings.sharedManager.nightMode;
//    RenderingRuleSearchRequest rreq = map.getMyApplication().getResourceManager()
//        .getRenderer().getSearchRequestWithAppliedCustomRules(storage, nightMode);
    
    for (int i : tps) {
        const auto& tp = object->region->quickGetEncodingRule(i);
        if (tp.getTag() == "highway" || tp.getTag() == "route")
        {
            rreq.setInitialTagValueZoom(tp.getTag(), tp.getValue(), 13, null);
        }
        else
        {
            [additional appendFormat:@"%s=%s;", tp.getTag().c_str(), tp.getValue().c_str()];
        }
    }
    
    rreq.setIntFilter(rreq.ALL.R_TEXT_LENGTH, name.length());
    rreq.setStringFilter(rreq.ALL.R_NAME_TAG, nameTag);
    rreq.setStringFilter(rreq.ALL.R_ADDITIONAL, additional.toString());
    rreq.search(RenderingRulesStorage.TEXT_RULES);
    
    OsmandRenderer.RenderingContext rc = new OsmandRenderer.RenderingContext(context);
    
    TextRenderer textRenderer = new TextRenderer(context);
    TextRenderer.TextDrawInfo text = new TextRenderer.TextDrawInfo(name);
    
    
    Paint p = textRenderer.getPaintText();
    p.setTypeface(Typeface.create("Droid Serif", Typeface.BOLD));
    
    int shieldRes = -1;
    
    if (rreq.isSpecified(rreq.ALL.R_TEXT_SHIELD)) {
        text.setShieldResIcon(rreq.getStringPropertyValue(rreq.ALL.R_TEXT_SHIELD));
        shieldRes = app.getResources().getIdentifier("h_" + text.getShieldResIcon(),
                                                     "drawable", app.getPackageName());
    }
    
    if (rreq.isSpecified(rreq.ALL.R_TEXT_COLOR)) {
        p.setColor(rreq.getIntPropertyValue(rreq.ALL.R_TEXT_COLOR));
    }
    
    if (rreq.isSpecified(rreq.ALL.R_TEXT_SIZE)) {
        float ts = rreq.getFloatPropertyValue(rreq.ALL.R_TEXT_SIZE);
        textRenderer.getPaintText().setTextSize(
                                                TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, ts,
                                                                          app.getResources().getDisplayMetrics()));
    }
    
    if (shieldRes != -1) {
        Drawable shield = AppCompatResources.getDrawable(view.getContext(), shieldRes);
        if (shield == null) {
            return false;
        }
        float xSize = shield.getIntrinsicWidth();
        float ySize = shield.getIntrinsicHeight();
        float xyRatio = xSize / ySize;
        //setting view propotions (height is fixed by toolbar size - 48dp);
        int viewHeightPx = AndroidUtils.dpToPx(context, 48);
        int viewWidthPx = (int) (viewHeightPx * xyRatio);
        
        ViewGroup.LayoutParams params = view.getLayoutParams();
        params.width = viewWidthPx;
        view.setLayoutParams(params);
        
        //creating bitmap according to size of resource
        Bitmap bitmap = Bitmap.createBitmap((int) xSize, (int) ySize, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        text.fillProperties(rc, rreq, xSize / 2f, ySize / 2f - p.getFontMetrics().ascent / 2f);
        textRenderer.drawShieldIcon(rc, canvas, text, text.getShieldResIcon());
        textRenderer.drawWrappedText(canvas, text, 20f);
        
        view.setImageBitmap(bitmap);
        return true;
    }
    return false;
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
    [[OARootViewController instance].mapPanel showWaypoints];
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
