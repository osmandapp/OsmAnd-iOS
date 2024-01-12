//
//  OANetworkRouteDrawable.m
//  OsmAnd Maps
//
//  Created by Paul on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OANetworkRouteDrawable.h"
#import "OARouteKey.h"
#import "OADayNightHelper.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererEnvironment.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/Map/MapStyleEvaluator.h>
#include <OsmAndCore/Map/MapStyleEvaluationResult.h>
#include <OsmAndCore/Map/MapStyleBuiltinValueDefinitions.h>
#include <OsmAndCore/TextRasterizer.h>

@implementation OANetworkRouteDrawable
{
    OARouteKey *_routeKey;
    BOOL _isNight;
    OAMapRendererEnvironment *_env;
}

- (instancetype)initWithRouteKey:(OARouteKey *)routeKey
{
    self = [super init];
    if (self) {
        _routeKey = routeKey;
        _isNight = OADayNightHelper.instance.isNightMode;
        _env = OARootViewController.instance.mapPanel.mapViewController.mapRendererEnv;
    }
    return self;
}

- (UIImage *)getIcon
{
    const auto tag = QStringLiteral("route_") + _routeKey.routeKey.getTag();
    const auto text = _routeKey.routeKey.getValue(QStringLiteral("osmc_text"));
    const auto &env = _env.mapPresentationEnvironment;
    OsmAnd::MapStyleEvaluator textEvaluator(env->mapStyle, _env.mapPresentationEnvironment->displayDensityFactor);
    env->applyTo(textEvaluator);
    OsmAnd::MapStyleEvaluationResult evaluationResult(env->mapStyle->getValueDefinitionsCount());

    if (text.length() > 0)
    {
        const auto color = _routeKey.routeKey.getValue(QStringLiteral("osmc_textcolor"));
        textEvaluator.setStringValue(env->styleBuiltinValueDefs->id_INPUT_TAG, tag);
        textEvaluator.setStringValue(env->styleBuiltinValueDefs->id_INPUT_VALUE, QStringLiteral(""));
        textEvaluator.setIntegerValue(env->styleBuiltinValueDefs->id_INPUT_MINZOOM, 14);
        textEvaluator.setIntegerValue(env->styleBuiltinValueDefs->id_INPUT_MAXZOOM, 14);
        textEvaluator.setIntegerValue(env->styleBuiltinValueDefs->id_INPUT_TEXT_LENGTH, (unsigned int) text.length());
        textEvaluator.setStringValue(env->styleBuiltinValueDefs->id_INPUT_NAME_TAG, tag + QStringLiteral("_1_osmc_text"));
        textEvaluator.setStringValue(env->styleBuiltinValueDefs->id_INPUT_ADDITIONAL, tag + QStringLiteral("_1_osmc_textcolor=") + color);
    }
    textEvaluator.evaluate(nullptr, OsmAnd::MapStyleRulesetType::Text, &evaluationResult);

    OsmAnd::TextRasterizer::Style textStyle;
    QList<sk_sp<const SkImage>> layers;
    const auto background = _routeKey.routeKey.getValue(QStringLiteral("osmc_background"));
    if (!background.isEmpty())
    {
        QString shieldName = QStringLiteral("osmc_") + background + QStringLiteral("_bg");
        sk_sp<const SkImage> shield;
        env->obtainTextShield(shieldName, 1.0f, shield);
        if (shield)
            layers << shield;
    }
    
    const auto foreground = _routeKey.routeKey.getValue(QStringLiteral("osmc_foreground"));
    if (!foreground.isEmpty())
    {
        QString shieldName = QStringLiteral("osmc_") + foreground;
        sk_sp<const SkImage> shield;
        env->obtainMapIcon(shieldName, 1.0f, shield);
        if (shield)
            layers << shield;
    }
    
    textStyle.backgroundImage = OsmAnd::SkiaUtilities::mergeImages(layers);

    int textColor = 0xff000000;
    evaluationResult.getIntegerValue(env->styleBuiltinValueDefs->id_OUTPUT_TEXT_COLOR, textColor);
    textStyle.setColor(OsmAnd::ColorARGB(textColor));
    
    bool bold = false;
    evaluationResult.getBooleanValue(env->styleBuiltinValueDefs->id_OUTPUT_TEXT_BOLD, bold);
    textStyle.setBold(bold);

    float textSize = 12;
    evaluationResult.getFloatValue(env->styleBuiltinValueDefs->id_OUTPUT_TEXT_SIZE, textSize);
    textStyle.setSize(textSize);

    const auto rasterizer = OsmAnd::TextRasterizer::getDefault();
    const auto textImage = rasterizer->rasterize(text, textStyle);
    if (textImage)
    {
        return [OANativeUtilities skImageToUIImage:textImage];
    }
    return nil;
}

@end
