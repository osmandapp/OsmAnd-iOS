//
//  OANextTurnInfoWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 02/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANextTurnWidget.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OATurnDrawable.h"
#import "OATurnDrawable+cpp.h"
#import "OARoutingHelper.h"
#import "OARouteDirectionInfo.h"
#import "OARouteCalculationResult.h"
#import "OAUtilities.h"
#import "OAVoiceRouter.h"
#import "OAAppSettings.h"
#import "OAOsmAndFormatter.h"
#import "GeneratedAssetSymbols.h"
#import "OACurrentStreetName.h"
#import "OARoutingHelperUtils.h"
#import "OARouteInfoView.h"
#import "OACurrentPositionHelper.h"
#import "OANativeUtilities.h"
#import "OAMapPresentationEnvironment.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAStreetNameWidgetParams.h"

#include <OsmAndCore/Map/MapPresentationEnvironment.h>
#include <OsmAndCore/Map/MapStyleEvaluator.h>
#include <OsmAndCore/Map/MapStyleEvaluationResult.h>
#include <OsmAndCore/Map/MapStyleBuiltinValueDefinitions.h>
#include <OsmAndCore/TextRasterizer.h>

#define kTopViewSide 72
#define kLeftViewSide 24

@interface OANextTurnWidget ()

@property (nonatomic) IBOutlet UIView *topView;
@property (nonatomic) IBOutlet UIView *leftView;
@property (nonatomic) IBOutlet UIView *shieldView;
@property (nonatomic) IBOutlet UIView *exitView;
@property (nonatomic) IBOutlet UIView *leftArrowView;
@property (nonatomic) IBOutlet UIImageView *shieldImage;
@property (nonatomic) IBOutlet OutlineLabel *exitLabel;
@property (nonatomic) IBOutlet OutlineLabel *distanceLabel;
@property (nonatomic) IBOutlet OutlineLabel *streetLabel;
@property (nonatomic) IBOutlet UIButton *showButton;
@property (nonatomic) IBOutlet UIStackView *shieldStackView;
@property (nonatomic) IBOutlet UIStackView *distanceStackView;
@property (nonatomic) IBOutlet UIStackView *streetStackView;
@property (nonatomic) IBOutlet UIStackView *infoStackView;
@property (nonatomic) IBOutlet UIStackView *mainStackView;
@property (nonatomic) IBOutlet NSLayoutConstraint *widgetHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *arrowSizeConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *firstLineHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *secondLineHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *shieldHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *shieldWidthConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *exitLabelViewHeightConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *exitLabelViewRightEqualConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *exitLabelViewRightGreaterConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *topArrowSpaceConstraint;
@property (nonatomic) IBOutlet NSLayoutConstraint *bottomArrowSpaceConstraint;

@end

@implementation OANextTurnWidget
{
    BOOL _horisontalMini;
    
    int _deviatedPath;
    int _nextTurnDistance;
    
    OATurnDrawable *_turnDrawable;
    OsmAndAppInstance _app;
    
    BOOL _nextNext;
    BOOL _isPanelVertical;
    OANextDirectionInfo *_calc1;
    UIView *_widgetView;
    NSArray<RoadShield *> *_cachedRoadShields;
    std::shared_ptr<const OsmAnd::TextRasterizer> _textRasterizer;
}

- (instancetype)initWithHorisontalMini:(BOOL)horisontalMini
                              nextNext:(BOOL)nextNext
                              customId:(NSString *)customId
                               appMode:(OAApplicationMode *)appMode
                          widgetParams:(NSDictionary *)widgetParams
{
    OAWidgetType *type;
    if (horisontalMini)
    {
        if (nextNext)
            type = OAWidgetType.secondNextTurn;
        else
            type = OAWidgetType.smallNextTurn;
    }
    else
    {
        type = OAWidgetType.nextTurn;
    }
    self = [super initWithType:type];
    if (self)
    {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        
        _app = [OsmAndApp instance];
        _horisontalMini = horisontalMini;
        _nextNext = nextNext;
        _calc1 = [[OANextDirectionInfo alloc] init];
        
        OAWidgetsPanel *panel = [type getPanel:customId ?: type.id appMode:appMode];
        _isPanelVertical = [panel isPanelVertical];
        
        _turnDrawable = [[OATurnDrawable alloc] initWithMini:!_isPanelVertical && horisontalMini themeColor:EOATurnDrawableThemeColorMap];
        _textRasterizer = OsmAnd::TextRasterizer::getDefault();
        
        if (_isPanelVertical)
        {
            [self layoutWidget];
            [self setVerticalTurnDrawable:_turnDrawable gone:NO];
            [self setTopTurnDrawable:nil];
            [self updateHeightConstraint:_widgetHeightConstraint];
            _showButton.menu = [self configureContextWidgetMenu];
        }
        else
        {
            _topView = [[UIView alloc] initWithFrame:CGRectMake(11., 6., kTopViewSide, kTopViewSide)];
            _leftView = [[UIView alloc] initWithFrame:CGRectMake(2., 84., kLeftViewSide, kLeftViewSide)];
            _leftView.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:_topView];
            [self addSubview:_leftView];
            
            [NSLayoutConstraint activateConstraints:@[
                [_leftView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:2],
                [_leftView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor constant:0],
                [_leftView.heightAnchor constraintEqualToConstant:kLeftViewSide],
                [_leftView.widthAnchor constraintEqualToConstant:kLeftViewSide]
            ]];
            
            if (horisontalMini)
            {
                [self setTurnDrawable:_turnDrawable gone:NO];
                [self setTopTurnDrawable:nil];
            }
            else
            {
                [self setTurnDrawable:nil gone:YES];
                [self setTopTurnDrawable:_turnDrawable];
            }
        }
        
        if (!_nextNext)
        {
            self.onClickFunction = ^(id sender) {
                OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
                if ([routingHelper isRouteCalculated] && ![OARoutingHelper isDeviatedFromRoute])
                {
                    [[routingHelper getVoiceRouter] announceCurrentDirection:nil];
                }

            };
        }
    }
    return self;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    if (_isPanelVertical && _turnDrawable.frame.size.width != _arrowSizeConstraint.constant)
        [self updateNextTurnInfo];
}

- (UIView *)widgetView
{
    if (!_widgetView)
    {
        NSArray *nibObjects = [[NSBundle mainBundle] loadNibNamed:@"OANextTurnWidget" owner:self options:nil];
        _widgetView = (UIView *)[nibObjects firstObject];
    }
    return _widgetView;
}

- (BOOL)hasEnoughWidth
{
    return self.frame.size.width > 250;
}

- (UIColor *)valueTextColor
{
    return self.isNightMode ? UIColor.whiteColor : UIColor.blackColor;
}

- (void)layoutWidget
{
    self.widgetView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.widgetView];

    [NSLayoutConstraint activateConstraints:@[
        [self.widgetView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.widgetView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.widgetView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.widgetView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
}

- (void)setStreetName:(OACurrentStreetName *)streetName
{
    if (!streetName)
    {
        [_shieldStackView setHidden:YES];
        [_exitView setHidden:YES];
        return;
    }
    
    if (streetName.text.length == 0)
        streetName.text = [self removeSymbol:streetName.text];
    
    streetName.text = [self removeRoundaboutSubstring:streetName.text];
    
    NSArray<RoadShield *> *shields = streetName.shields;
    
    if (shields.count != 0)
    {
        BOOL isShieldsEqual = [shields isEqualToArray:_cachedRoadShields];
        if (!isShieldsEqual)
            [self setRoadShield:_shieldImage shields:shields];
        else
            [_shieldStackView setHidden:!isShieldsEqual];
        _cachedRoadShields = shields;
    }
    else
    {
        [_shieldStackView setHidden:YES];
        _cachedRoadShields = nil;
    }
    
    [self setExit:streetName];
    
    _streetLabel.text = streetName.text.length == 0 ? @"" : streetName.text;
    [self applyOutlineIfNeededToLabel:_streetLabel];
}

- (CGFloat)getWidthFor:(UIImage *)image
{
    if (!image)
        return 0;
    
    CGFloat sizeRatio = _shieldHeightConstraint.constant / image.size.height;
    return sizeRatio * image.size.width;
}

- (NSString *)removeSymbol:(NSString *)input
{
    return [self removePrefix:@"» " from:input];
}

- (NSString *)removeRoundaboutSubstring:(NSString *)input
{
    return [self removePrefix:@"Roundabout: " from:input];
}

- (NSString *)removePrefix:(NSString *)prefix from:(NSString *)input
{
    return [input hasPrefix:prefix] ? [input stringByReplacingOccurrencesOfString:prefix withString:@""] : input;
}

- (void)checkShieldOverflow
{
    if (_isPanelVertical && self.widgetSizeStyle == EOAWidgetSizeStyleSmall)
    {
        CGFloat containerWidth = self.frame.size.width - _leftArrowView.frame.size.width - _mainStackView.spacing;
        CGFloat usedWidth = 0;
        int addedCount = 0;
        
        for (NSInteger i = 0; i < _shieldStackView.subviews.count; i++)
        {
            UIView *shieldView = _shieldStackView.subviews[i];
            UIImageView *view = shieldView.subviews.firstObject;
            
            if (![view isKindOfClass:[UIImageView class]])
                continue;
            
            CGFloat totalWidth = 0;
            CGFloat width = [self getWidthFor:view.image];
            
            totalWidth += width;
            if (i < _shieldStackView.subviews.count - 1)
                totalWidth += _shieldStackView.spacing;
            
            if (usedWidth + totalWidth <= containerWidth - 3 * width)
            {
                shieldView.hidden = NO;
                usedWidth += totalWidth;
                addedCount++;
            }
            else
            {
                shieldView.hidden = YES;
            }
        }
        
        [_shieldStackView setHidden:addedCount == 0];
    }
}

- (void)setExit:(OACurrentStreetName *)streetName
{
    NSString *exitNumber = nil;
    const auto& turnType = [self getTurnType];
    
    if (turnType && turnType->getExitOut() > 0)
        exitNumber = [NSString stringWithFormat:@"%d", turnType->getExitOut()];
    else if (streetName.exitRef.length > 0)
        exitNumber = streetName.exitRef;
    
    if (exitNumber.length > 0)
    {
        NSString *exitViewText = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_space"), OALocalizedString(@"shared_string_road_exit"), exitNumber];
        _exitLabel.text = exitViewText;
        [self applyOutlineIfNeededToLabel:_exitLabel];
        [_exitView setHidden:NO];
    }
    else
    {
        [_exitView setHidden:YES];
    }
}

- (void)setRoadShield:(UIImageView *)view shields:(NSArray<RoadShield *> *)shields
{
    BOOL isShieldSet = NO;
    if (shields.count != 0)
    {
        NSInteger maxShields = MIN(shields.count, MAX_SHIELDS_QUANTITY);
        
        if (_shieldStackView.subviews.count > 1)
        {
            for (NSInteger i = 1; i < _shieldStackView.subviews.count; i++)
                [_shieldStackView.subviews[i] removeFromSuperview];
        }
        
        for (NSInteger i = 0; i < maxShields; i++)
        {
            RoadShield *shield = shields[i];
            
            if (i > 0)
            {
                UIImageView *shieldImageView = [[UIImageView alloc] init];
                UIView *shieldView = [[UIView alloc] initWithFrame:CGRectZero];
                [shieldView addSubview:shieldImageView];
                [_shieldStackView addArrangedSubview:shieldView];
                shieldImageView.translatesAutoresizingMaskIntoConstraints = NO;
                shieldImageView.contentMode = UIViewContentModeScaleAspectFit;
                shieldImageView.clipsToBounds = YES;
                [shieldImageView setContentHuggingPriority:[_shieldImage contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal] forAxis:UILayoutConstraintAxisHorizontal];
                [shieldView setContentHuggingPriority:[_shieldView contentHuggingPriorityForAxis:UILayoutConstraintAxisHorizontal] forAxis:UILayoutConstraintAxisHorizontal];
                [NSLayoutConstraint activateConstraints:@[
                    [shieldImageView.heightAnchor constraintEqualToConstant:_shieldHeightConstraint.constant],
                    [shieldImageView.leadingAnchor constraintEqualToAnchor:shieldView.leadingAnchor],
                    [shieldImageView.trailingAnchor constraintEqualToAnchor:shieldView.trailingAnchor],
                    [shieldImageView.centerYAnchor constraintEqualToAnchor:shieldView.centerYAnchor]
                ]];
                isShieldSet |= [self setRoadShield:shieldImageView shield:shield];
                NSLayoutConstraint *widthConstraint = [shieldImageView.widthAnchor constraintEqualToConstant:[self getWidthFor:shieldImageView.image]];
                widthConstraint.active = YES;
            }
            else
            {
                isShieldSet |= [self setRoadShield:view shield:shield];
                _shieldWidthConstraint.constant = [self getWidthFor:view.image];
            }
        }
    }
    [_shieldStackView setHidden:!isShieldSet];
    [self checkShieldOverflow];
}

- (BOOL) setRoadShield:(UIImageView *)view shield:(RoadShield *)shield
{
    const auto& object = shield.rdo;
    const auto& tps = object->types;
    NSString *nameTag = shield.tag;
    NSString *name = shield.value;
    NSMutableString *additional = [shield.additional mutableCopy];
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
        return YES;
    }

    return NO;
}

- (void)setVerticalTurnDrawable:(OATurnDrawable *)turnDrawable gone:(BOOL)gone
{
    if (turnDrawable)
    {
        [self setSubview:self.leftView subview:turnDrawable];
        self.leftView.hidden = NO;
    }
    else
    {
        self.leftView.hidden = gone;
    }
}

- (void) setTurnDrawable:(OATurnDrawable *)turnDrawable gone:(BOOL)gone
{
    if (turnDrawable)
    {
        [self setSubview:self.leftView subview:turnDrawable];
        self.leftView.hidden = NO;
        [self setImageHidden:NO];
    }
    else
    {
        self.leftView.hidden = gone;
        [self setImageHidden:gone];
    }
}

- (void) setTopTurnDrawable:(OATurnDrawable *)turnDrawable
{
    if (turnDrawable)
    {
        [self setSubview:self.topView subview:turnDrawable];
        self.topView.hidden = NO;
    }
    else
    {
        self.topView.hidden = YES;
    }
}

- (void) setSubview:(UIView *)view subview:(UIView *)subview
{
    for (UIView *v in view.subviews)
        [v removeFromSuperview];
    
    subview.frame = view.bounds;
    [view addSubview:subview];
}

- (CGFloat) getWidgetHeight
{
    return _horisontalMini ? [super getWidgetHeight] : kNextTurnInfoWidgetHeight;
}

- (BOOL) distChanged:(CLLocationDistance)oldDist dist:(CLLocationDistance)dist
{
    return oldDist == 0 || ABS(oldDist - dist) > 10;
}

- (std::shared_ptr<TurnType>) getTurnType
{
    return _turnDrawable.turnType;
}

- (void) setTurnType:(std::shared_ptr<TurnType>)turnType
{
    BOOL vis = [self updateVisibility:turnType != nullptr];
    if ([_turnDrawable setTurnType:turnType]
        || (_isPanelVertical && _turnDrawable.frame.size.width != _arrowSizeConstraint.constant)
        || vis)
    {
        if (_isPanelVertical)
        {
            [self setVerticalTurnDrawable:_turnDrawable gone:NO];
        }
        else
        {
            _turnDrawable.textFont = self.primaryFont;
            if (_horisontalMini)
                [self setTurnDrawable:_turnDrawable gone:false];
            else
                [self setTopTurnDrawable:_turnDrawable];
        }  
    }
}

- (void) setTurnImminent:(int)turnImminent deviatedFromRoute:(BOOL)deviatedFromRoute
{
    if (_turnDrawable.turnImminent != turnImminent || _turnDrawable.deviatedFromRoute != deviatedFromRoute)
        [_turnDrawable setTurnImminent:turnImminent deviatedFromRoute:deviatedFromRoute];
}

- (void) setDeviatePath:(int)deviatePath
{
    if ([self distChanged:deviatePath dist:_deviatedPath])
    {
        _deviatedPath = deviatePath;
        [self updateDistance];
    }
}

- (void) setTurnDistance:(int)nextTurnDistance
{
    if ([self distChanged:nextTurnDistance dist:_nextTurnDistance])
    {
        _nextTurnDistance = nextTurnDistance;
        [self updateDistance];
    }
}

- (void) adjustViewSize
{
    [super adjustViewSize];
    self.topTextAnchor.constant = _horisontalMini ? 5 : self.topView.frame.size.height + 5;
    CGRect rect = self.frame;
    rect.size.height += self.textView.frame.origin.y - 5;
    self.frame = rect;
}

- (BOOL)isEnabledTextInfoComponents
{
    return !_isPanelVertical;
}

- (BOOL)isEnabledShowIconSwitchWith:(OAWidgetsPanel *)widgetsPanel widgetConfigurationParams:(NSDictionary<NSString *,id> *)widgetConfigurationParams
{
    return false;
}

- (void) setTextNoUpdateVisibility:(NSString *)text subtext:(NSString *)subtext
{
    if (_isPanelVertical)
    {
        if (text.length == 0 && subtext.length == 0)
        {
            _distanceLabel.text = self.isSimpleLayout ? nil : @"";
        }
        else
        {
            _distanceLabel.text = [NSString stringWithFormat:@"%@ %@", text, subtext];
            
            NSString *text = [_distanceLabel.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (self.widgetSizeStyle == EOAWidgetSizeStyleSmall && (!_exitView.hidden || _streetLabel.text.length != 0 || !_shieldStackView.hidden))
                _distanceLabel.text = [text stringByAppendingString:@","];
        }
        
        [self applyOutlineIfNeededToLabel:_distanceLabel];
    }
    else
    {
        [super setTextNoUpdateVisibility:text subtext:subtext];
    }
}

- (void) updateDistance
{
    int deviatePath = _turnDrawable.deviatedFromRoute ? _deviatedPath : _nextTurnDistance;
    NSString *ds = [OAOsmAndFormatter getFormattedDistance:deviatePath withParams:[OsmAndFormatterParams useLowerBounds]];
    
    if (ds)
    {
        auto turnType = [self getTurnType];
        OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
        if (turnType && routingHelper)
            [self setContentDescription:[NSString stringWithFormat:@"%@ %@", ds, [OARouteCalculationResult toString:turnType shortName:NO]]];
        else
            [self setContentDescription:ds];
    }
    
    int ls = [ds indexOf:@" "];
    if (ls == -1)
        [self setTextNoUpdateVisibility:ds subtext:nil];
    else
        [self setTextNoUpdateVisibility:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
}

- (void)updateColors:(OATextState *)textState
{
    [super updateColors:textState];
    UIColor *valueTextColor = self.valueTextColor;
    UIColor *textColorSecondary = [UIColor colorNamed:ACColorNameTextColorSecondary];
    UIColor *borderColor = [UIColor colorNamed:ACColorNameWidgetSeparatorColor];
    _distanceLabel.textColor = valueTextColor;
    _exitLabel.textColor = valueTextColor;
    _exitLabel.borderColor = self.isNightMode ? borderColor.dark : borderColor.light;
    _streetLabel.textColor = self.isNightMode ? textColorSecondary.dark : textColorSecondary.light;
    [self updateTextWitState:textState];
    [self applyOutlineIfNeededToLabel:_distanceLabel];
    [self applyOutlineIfNeededToLabel:_exitLabel];
    [self applyOutlineIfNeededToLabel:_streetLabel];
}

- (BOOL) updateInfo
{
    [self updateNextTurnInfo];
    return YES;
}

- (void)updateNextTurnInfo
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL followingMode = [routingHelper isFollowingMode]/* || app.getLocationProvider().getLocationSimulation().isRouteAnimating()*/;
    std::shared_ptr<TurnType> turnType = nullptr;
    BOOL deviatedFromRoute = false;
    int turnImminent = 0;
    int nextTurnDistance = 0;
    OACurrentStreetName *streetName = nil;
    
    if (_isPanelVertical)
    {
        OAStreetNameWidgetParams *params = [[OAStreetNameWidgetParams alloc] initWithTurnDrawable:_turnDrawable calc1:_calc1];
        streetName = params.streetName;
    }
    
    if (routingHelper && [routingHelper isRouteCalculated] && followingMode)
    {
        deviatedFromRoute = [OARoutingHelper isDeviatedFromRoute];
        if (!_nextNext)
        {
            if (deviatedFromRoute)
            {
                turnImminent = 0;
                turnType = TurnType::ptrValueOf(TurnType::OFFR, [OADrivingRegion isLeftHandDriving:[settings.drivingRegion get]]);
                [self setDeviatePath:(int) [routingHelper getRouteDeviation]];
            }
            else
            {
                OANextDirectionInfo *info = [routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:true];
                if (info && info.distanceTo >= 0 && info.directionInfo)
                {
                    streetName = [[OACurrentStreetName alloc] initWithStreetName:info useDestination:true];
                    if (_isPanelVertical && streetName.text.length == 0)
                        streetName.text = [info.directionInfo getDescriptionRoutePart];
                    turnType = info.directionInfo.turnType;
                    nextTurnDistance = info.distanceTo;
                    turnImminent = info.imminent;
                }
            }
        }
        else
        {
            OANextDirectionInfo *info = [routingHelper getNextRouteDirectionInfo:_calc1 toSpeak:true];
            if (!deviatedFromRoute)
            {
                if (info)
                    info = [routingHelper getNextRouteDirectionInfoAfter:info to:_calc1 toSpeak:true];
            }
            if (info && info.distanceTo > 0 && info.directionInfo)
            {
                streetName = [[OACurrentStreetName alloc] initWithStreetName:info useDestination:true];
                if (_isPanelVertical && streetName.text.length == 0)
                    streetName.text = [info.directionInfo getDescriptionRoutePart];
                turnType = info.directionInfo.turnType;
                nextTurnDistance = info.distanceTo;
                turnImminent = info.imminent;
            }
        }
    }
    
    if (_isPanelVertical)
    {
        [self setStreetName:streetName];
        if (streetName.shields.count != 0)
            [self checkShieldOverflow];
        [self applySuitableTextFont];
        [self applySuitableLayout];
        [self replaceComponentsIfNeeded];
        [self updateHeightConstraintWithRelation:NSLayoutRelationEqual constant:[OAWidgetSizeStyleObjWrapper getMaxWidgetHeightForType:self.widgetSizeStyle] priority:UILayoutPriorityDefaultHigh];
        [self refreshLayout];
    }
    
    [self setTurnType:turnType];
    [self setTurnImminent:turnImminent deviatedFromRoute:deviatedFromRoute];
    [self setTurnDistance:nextTurnDistance];
}

- (void)applySuitableTextFont
{
    UIFontWeight typefaceStyle = UIFontWeightSemibold;
    _distanceLabel.font = [UIFont scaledSystemFontOfSize:self.distanceFont weight:typefaceStyle];
    _exitLabel.font = [UIFont scaledSystemFontOfSize:self.exitFont weight:typefaceStyle];
    _streetLabel.font = [UIFont scaledSystemFontOfSize:self.streetFont weight:typefaceStyle];
}

- (void)applySuitableLayout
{
    [_distanceLabel setContentHuggingPriority:self.widgetSizeStyle == EOAWidgetSizeStyleSmall ? 252 : UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    [_mainStackView setSpacing:!self.hasEnoughWidth ? 6 : 12];
    [_exitLabelViewRightGreaterConstraint setActive:self.widgetSizeStyle == EOAWidgetSizeStyleSmall];
    [_exitLabelViewRightEqualConstraint setActive:self.widgetSizeStyle != EOAWidgetSizeStyleSmall];
    _arrowSizeConstraint.constant = !self.hasEnoughWidth ? self.halfScreenArrowSize : self.arrowSize;
    _exitLabelViewHeightConstraint.constant = !self.hasEnoughWidth ? self.halfScreenExitLabelViewHeight : self.exitLabelViewHeight;
    _topArrowSpaceConstraint.constant = _bottomArrowSpaceConstraint.constant = self.hasEnoughWidth && self.widgetSizeStyle != EOAWidgetSizeStyleSmall ? 6 : 0;
    _firstLineHeightConstraint.constant = self.firstLineHeight;
    _secondLineHeightConstraint.constant = self.secondLineHeight;
}

- (void)replaceComponentsIfNeeded
{
    if (self.widgetSizeStyle == EOAWidgetSizeStyleSmall)
        [self moveView:_streetStackView toStackView:_distanceStackView];
    else
    {
        if (!self.hasEnoughWidth)
        {
            [self moveView:_exitView toStackView:_streetStackView];
            [self moveView:_exitView toIndex:0 inStackView:_streetStackView];
            [self moveView:_leftArrowView toStackView:_distanceStackView];
            [self moveView:_leftArrowView toIndex:0 inStackView:_distanceStackView];
        }
        else
        {
            [self moveView:_exitView toStackView:_distanceStackView];
            [self moveView:_leftArrowView toStackView:_mainStackView];
            [self moveView:_leftArrowView toIndex:0 inStackView:_mainStackView];
        }
        [self moveView:_streetStackView toStackView:_infoStackView];
    }
}

- (void)moveView:(UIView *)view toStackView:(UIStackView *)stackView
{
    if ([stackView.subviews containsObject:view])
        return;
    
    [stackView addArrangedSubview:view];
}

- (void)moveView:(UIView *)view toIndex:(NSInteger)newIndex inStackView:(UIStackView *)stackView
{
    NSMutableArray<UIView *> *views = [stackView.arrangedSubviews mutableCopy];
    
    if (![views containsObject:view])
        return;
    
    NSInteger currentIndex = [views indexOfObject:view];
    if (currentIndex == NSNotFound || newIndex == currentIndex || newIndex < 0 || newIndex >= views.count)
        return;
    
    [views removeObjectAtIndex:currentIndex];
    
    if (newIndex > currentIndex)
        newIndex -= 1;

    [views insertObject:view atIndex:newIndex];

    for (UIView *v in stackView.arrangedSubviews)
    {
        [stackView removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    for (UIView *v in views)
        [stackView addArrangedSubview:v];
}

@end
