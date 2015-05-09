//
//  OADebugActionsViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADebugActionsViewController.h"

#import <QuickDialog.h>

#import "OsmAndApp.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#include "Localization.h"
#include <OsmAndCore/Map/MapRendererDebugSettings.h>

#define _(name) OADebugActionsViewController__##name

@interface OADebugActionsViewController ()
@end

@implementation OADebugActionsViewController
{
    OsmAndAppInstance _app;

    QBooleanElement* _forcedRenderingElement;
    QBooleanElement* _hideStaticSymbolsElement;
    QBooleanElement* _forceDisplayDensityFactorElement;
    QFloatElement* _forcedDisplayDensityFactorElement;
    QDecimalElement* _forcedDisplayDensityFactorValueElement;

    QRadioSection* _forcedGpsAccuracySection;
    QRadioSection* _textureFilteringQualitySection;

    QRadioSection* _visualMetricsSection;

    QBooleanElement* _useRawSpeedAndAltitudeOnHUDElement;
    QBooleanElement* _setAllResourcesAsOutdatedElement;

    QBooleanElement* _debugStageEnabledElement;
    QBooleanElement* _excludeOnPathSymbolsFromProcessingElement;
    QBooleanElement* _excludeBillboardSymbolsFromProcessingElement;
    QBooleanElement* _excludeOnSurfaceSymbolsFromProcessingElement;
    QBooleanElement* _skipSymbolsIntersectionCheckElement;
    QBooleanElement* _showSymbolsBBoxesAcceptedByIntersectionCheckElement;
    QBooleanElement* _showSymbolsBBoxesRejectedByIntersectionCheckElement;
    QBooleanElement* _skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement;
    QBooleanElement* _showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement;
    QBooleanElement* _showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement;
    QBooleanElement* _skipSymbolsPresentationModeCheckElement;
    QBooleanElement* _showSymbolsBBoxesRejectedByPresentationModeElement;
    QBooleanElement* _showOnPathSymbolsRenderablesPathsElement;
    QBooleanElement* _showOnPath2dSymbolGlyphDetailsElement;
    QBooleanElement* _showOnPath3dSymbolGlyphDetailsElement;
    QBooleanElement* _allSymbolsTransparentForIntersectionLookupElement;
    QBooleanElement* _showTooShortOnPathSymbolsRenderablesPathsElement;
    QBooleanElement* _showAllPathsElement;
    QBooleanElement* _rasterLayersOverscaleForbiddenElement;
    QBooleanElement* _rasterLayersUnderscaleForbiddenElement;
    QBooleanElement* _mapLayersBatchingForbiddenElement;
    QBooleanElement* _disableJunkResourcesCleanupElement;
    QBooleanElement* _disableNeededResourcesRequestsElement;
    QBooleanElement* _disableSkyStageElement;
    QBooleanElement* _disableMapLayersStageElement;
    QBooleanElement* _disableSymbolsStageElement;

    OAMapViewController* __weak _mapViewController;
    OAMapRendererView* __weak _mapRendererView;
    
    std::shared_ptr<OsmAnd::MapRendererDebugSettings> _mapRendererDebugSettings;
}

- (instancetype)init
{
    OsmAndAppInstance app = [OsmAndApp instance];

    QRootElement* rootElement = [[QRootElement alloc] init];

    rootElement.title = OALocalizedString(@"Debug");
    rootElement.grouped = YES;
    rootElement.appearance.entryAlignment = NSTextAlignmentRight;

    // Header
    QSection* headerSection = [[QSection alloc] initWithTitle:OALocalizedString(@"")];
    [rootElement addSection:headerSection];
    
    QButtonElement* backButtonElement = [[QButtonElement alloc] initWithTitle:OALocalizedString(@"Close")];
    backButtonElement.controllerAction = NSStringFromSelector(@selector(onBackButtonClicked));
    [headerSection addElement:backButtonElement];

    // Renderer section
    QSection* rendererSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Renderer")];
    [rootElement addSection:rendererSection];

    QBooleanElement* forcedRenderingElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Forced rendering")
                                                                           BoolValue:NO];
    forcedRenderingElement.controllerAction = NSStringFromSelector(@selector(onForcedRenderingSettingChanged));
    [rendererSection addElement:forcedRenderingElement];

    QBooleanElement* hideStaticSymbolsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Hide static symbols")
                                                                           BoolValue:NO];
    hideStaticSymbolsElement.controllerAction = NSStringFromSelector(@selector(onHideStaticSymbolsSettingChanged));
    [rendererSection addElement:hideStaticSymbolsElement];

    QBooleanElement* forceDisplayDensityFactorElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Force display density factor")
                                                                                     BoolValue:NO];
    forceDisplayDensityFactorElement.controllerAction = NSStringFromSelector(@selector(onForceDisplayDensityFactorSettingChanged));
    [rendererSection addElement:forceDisplayDensityFactorElement];

    QFloatElement* forcedDisplayDensityFactorElement = [[QFloatElement alloc] initWithTitle:OALocalizedString(@"Display Density")
                                                                                      value:0.0f];
    forcedDisplayDensityFactorElement.minimumValue = 1.0f;
    forcedDisplayDensityFactorElement.maximumValue = 5.0f;
    forcedDisplayDensityFactorElement.onValueChanged = ^(QRootElement *){
        [self onForcedDisplayDensityFactorSettingChanged];
    };
    [rendererSection addElement:forcedDisplayDensityFactorElement];

    QDecimalElement* forcedDisplayDensityFactorValueElement = [[QDecimalElement alloc] initWithTitle:OALocalizedString(@"Display Density")
                                                                                               value:[NSNumber numberWithFloat:0.0f]];
    forcedDisplayDensityFactorValueElement.fractionDigits = 6;
    forcedDisplayDensityFactorValueElement.onValueChanged = ^(QRootElement *){
        [self onForcedDisplayDensityFactorValueSettingChanged];
    };
    [rendererSection addElement:forcedDisplayDensityFactorValueElement];


    // Forced GPS accuracy section
    QRadioSection* forcedGpsAccuracySection = [[QRadioSection alloc] initWithItems:@[OALocalizedString(@"None"),
                                                                                     OALocalizedString(@"Best"),
                                                                                     OALocalizedString(@"Best for Navigation")]
                                                                          selected:0
                                                                             title:OALocalizedString(@"Forced GPS accuracy")];
    forcedGpsAccuracySection.onSelected = ^(){
        [self onForcedGpsAccuracyChanged];
    };
    [rootElement addSection: forcedGpsAccuracySection];

    // Visual metrics section
    QRadioSection* visualMetricsSection = [[QRadioSection alloc] initWithItems:@[OALocalizedString(@"Off"),
                                                                                 OALocalizedString(@"Binary Map Data"),
                                                                                 OALocalizedString(@"Binary Map Primitives"),
                                                                                 OALocalizedString(@"Binary Map Rasterize")]
                                                                      selected:0
                                                                         title:OALocalizedString(@"Visual metrics")];
    visualMetricsSection.onSelected = ^(){
        [self onVisualMetricsSettingChanged];
    };
    [rootElement addSection: visualMetricsSection];

    // Texture Filtering Quality section
    QRadioSection* textureFilteringQualitySection = [[QRadioSection alloc] initWithItems:@[OALocalizedString(@"Normal"),
                                                                                     OALocalizedString(@"Good"),
                                                                                     OALocalizedString(@"Best")]
                                                                          selected:0
                                                                             title:OALocalizedString(@"Texture Filtering Quality")];
    textureFilteringQualitySection.onSelected = ^(){
        [self onTextureFilteringQualityChanged];
    };
    [rootElement addSection: textureFilteringQualitySection];
    
    // HUD section
    QSection* hudSection = [[QSection alloc] initWithTitle:OALocalizedString(@"HUD")];
    [rootElement addSection:hudSection];

    QBooleanElement* useRawSpeedAndAltitudeOnHUDElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Show raw speed/altritude")
                                                                                       BoolValue:NO];
    useRawSpeedAndAltitudeOnHUDElement.controllerAction = NSStringFromSelector(@selector(onUseRawSpeedAndAltitudeOnHUDSettingChanged));
    [hudSection addElement:useRawSpeedAndAltitudeOnHUDElement];

    
    
    // HUD section
    QSection* resourcesSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Resources")];
    [rootElement addSection:resourcesSection];
    
    QBooleanElement* setAllResourcesAsOutdatedElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"Set all resources as outdated")
                                                                                       BoolValue:NO];
    setAllResourcesAsOutdatedElement.controllerAction = NSStringFromSelector(@selector(onSetAllResourcesAsOutdated));
    [resourcesSection addElement:setAllResourcesAsOutdatedElement];
    
    
    
    // Map Renderer section
    QSection* mapRendererSection = [[QSection alloc] initWithTitle:OALocalizedString(@"Map Renderer")];
    [rootElement addSection:mapRendererSection];
    
    //bool debugStageEnabled;
    QBooleanElement* debugStageEnabledElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"debugStageEnabled") BoolValue:NO];
    debugStageEnabledElement.controllerAction = NSStringFromSelector(@selector(ondebugStageEnabledSettingChanged));
    [mapRendererSection addElement:debugStageEnabledElement];

    //bool excludeOnPathSymbolsFromProcessing;
    QBooleanElement* excludeOnPathSymbolsFromProcessingElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"excludeOnPathSymbolsFromProcessing") BoolValue:NO];
    excludeOnPathSymbolsFromProcessingElement.controllerAction = NSStringFromSelector(@selector(onexcludeOnPathSymbolsFromProcessingSettingChanged));
    [mapRendererSection addElement:excludeOnPathSymbolsFromProcessingElement];
    
    //bool excludeBillboardSymbolsFromProcessing;
    QBooleanElement* excludeBillboardSymbolsFromProcessingElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"excludeBillboardSymbolsFromProcessing") BoolValue:NO];
    excludeBillboardSymbolsFromProcessingElement.controllerAction = NSStringFromSelector(@selector(onexcludeBillboardSymbolsFromProcessingSettingChanged));
    [mapRendererSection addElement:excludeBillboardSymbolsFromProcessingElement];
    
    //bool excludeOnSurfaceSymbolsFromProcessing;
    QBooleanElement* excludeOnSurfaceSymbolsFromProcessingElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"excludeOnSurfaceSymbolsFromProcessing") BoolValue:NO];
    excludeOnSurfaceSymbolsFromProcessingElement.controllerAction = NSStringFromSelector(@selector(onexcludeOnSurfaceSymbolsFromProcessingSettingChanged));
    [mapRendererSection addElement:excludeOnSurfaceSymbolsFromProcessingElement];
    
    //bool skipSymbolsIntersectionCheck;
    QBooleanElement* skipSymbolsIntersectionCheckElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"skipSymbolsIntersectionCheck") BoolValue:NO];
    skipSymbolsIntersectionCheckElement.controllerAction = NSStringFromSelector(@selector(onskipSymbolsIntersectionCheckSettingChanged));
    [mapRendererSection addElement:skipSymbolsIntersectionCheckElement];
    
    //bool showSymbolsBBoxesAcceptedByIntersectionCheck;
    QBooleanElement* showSymbolsBBoxesAcceptedByIntersectionCheckElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showSymbolsBBoxesAcceptedByIntersectionCheck") BoolValue:NO];
    showSymbolsBBoxesAcceptedByIntersectionCheckElement.controllerAction = NSStringFromSelector(@selector(onshowSymbolsBBoxesAcceptedByIntersectionCheckSettingChanged));
    [mapRendererSection addElement:showSymbolsBBoxesAcceptedByIntersectionCheckElement];
    
    //bool showSymbolsBBoxesRejectedByIntersectionCheck;
    QBooleanElement* showSymbolsBBoxesRejectedByIntersectionCheckElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showSymbolsBBoxesRejectedByIntersectionCheck") BoolValue:NO];
    showSymbolsBBoxesRejectedByIntersectionCheckElement.controllerAction = NSStringFromSelector(@selector(onshowSymbolsBBoxesRejectedByIntersectionCheckSettingChanged));
    [mapRendererSection addElement:showSymbolsBBoxesRejectedByIntersectionCheckElement];
    
    //bool skipSymbolsMinDistanceToSameContentFromOtherSymbolCheck;
    QBooleanElement* skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"skipSymbolsMinDistanceToSameContentFromOtherSymbolCheck") BoolValue:NO];
    skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement.controllerAction = NSStringFromSelector(@selector(onskipSymbolsMinDistanceToSameContentFromOtherSymbolCheckSettingChanged));
    [mapRendererSection addElement:skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement];
    
    //bool showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck;
    QBooleanElement* showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck") BoolValue:NO];
    showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement.controllerAction = NSStringFromSelector(@selector(onshowSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckSettingChanged));
    [mapRendererSection addElement:showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement];
    
    //bool showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck;
    QBooleanElement* showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck") BoolValue:NO];
    showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement.controllerAction = NSStringFromSelector(@selector(onshowSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckSettingChanged));
    [mapRendererSection addElement:showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement];
    
    //bool skipSymbolsPresentationModeCheck;
    QBooleanElement* skipSymbolsPresentationModeCheckElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"skipSymbolsPresentationModeCheck") BoolValue:NO];
    skipSymbolsPresentationModeCheckElement.controllerAction = NSStringFromSelector(@selector(onskipSymbolsPresentationModeCheckSettingChanged));
    [mapRendererSection addElement:skipSymbolsPresentationModeCheckElement];
    
    //bool showSymbolsBBoxesRejectedByPresentationMode;
    QBooleanElement* showSymbolsBBoxesRejectedByPresentationModeElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showSymbolsBBoxesRejectedByPresentationMode") BoolValue:NO];
    showSymbolsBBoxesRejectedByPresentationModeElement.controllerAction = NSStringFromSelector(@selector(onshowSymbolsBBoxesRejectedByPresentationModeSettingChanged));
    [mapRendererSection addElement:showSymbolsBBoxesRejectedByPresentationModeElement];
    
    //bool showOnPathSymbolsRenderablesPaths;
    QBooleanElement* showOnPathSymbolsRenderablesPathsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showOnPathSymbolsRenderablesPaths") BoolValue:NO];
    showOnPathSymbolsRenderablesPathsElement.controllerAction = NSStringFromSelector(@selector(onshowOnPathSymbolsRenderablesPathsSettingChanged));
    [mapRendererSection addElement:showOnPathSymbolsRenderablesPathsElement];
    
    //bool showOnPath2dSymbolGlyphDetails;
    QBooleanElement* showOnPath2dSymbolGlyphDetailsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showOnPath2dSymbolGlyphDetails") BoolValue:NO];
    showOnPath2dSymbolGlyphDetailsElement.controllerAction = NSStringFromSelector(@selector(onshowOnPath2dSymbolGlyphDetailsSettingChanged));
    [mapRendererSection addElement:showOnPath2dSymbolGlyphDetailsElement];
    
    //bool showOnPath3dSymbolGlyphDetails;
    QBooleanElement* showOnPath3dSymbolGlyphDetailsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showOnPath3dSymbolGlyphDetails") BoolValue:NO];
    showOnPath3dSymbolGlyphDetailsElement.controllerAction = NSStringFromSelector(@selector(onshowOnPath3dSymbolGlyphDetailsSettingChanged));
    [mapRendererSection addElement:showOnPath3dSymbolGlyphDetailsElement];
    
    //bool allSymbolsTransparentForIntersectionLookup;
    QBooleanElement* allSymbolsTransparentForIntersectionLookupElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"allSymbolsTransparentForIntersectionLookup") BoolValue:NO];
    allSymbolsTransparentForIntersectionLookupElement.controllerAction = NSStringFromSelector(@selector(onallSymbolsTransparentForIntersectionLookupSettingChanged));
    [mapRendererSection addElement:allSymbolsTransparentForIntersectionLookupElement];
    
    //bool showTooShortOnPathSymbolsRenderablesPaths;
    QBooleanElement* showTooShortOnPathSymbolsRenderablesPathsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showTooShortOnPathSymbolsRenderablesPaths") BoolValue:NO];
    showTooShortOnPathSymbolsRenderablesPathsElement.controllerAction = NSStringFromSelector(@selector(onshowTooShortOnPathSymbolsRenderablesPathsSettingChanged));
    [mapRendererSection addElement:showTooShortOnPathSymbolsRenderablesPathsElement];
    
    //bool showAllPaths;
    QBooleanElement* showAllPathsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"showAllPaths") BoolValue:NO];
    showAllPathsElement.controllerAction = NSStringFromSelector(@selector(onshowAllPathsSettingChanged));
    [mapRendererSection addElement:showAllPathsElement];
    
    //bool rasterLayersOverscaleForbidden;
    QBooleanElement* rasterLayersOverscaleForbiddenElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"rasterLayersOverscaleForbidden") BoolValue:NO];
    rasterLayersOverscaleForbiddenElement.controllerAction = NSStringFromSelector(@selector(onrasterLayersOverscaleForbiddenSettingChanged));
    [mapRendererSection addElement:rasterLayersOverscaleForbiddenElement];
    
    //bool rasterLayersUnderscaleForbidden;
    QBooleanElement* rasterLayersUnderscaleForbiddenElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"rasterLayersUnderscaleForbidden") BoolValue:NO];
    rasterLayersUnderscaleForbiddenElement.controllerAction = NSStringFromSelector(@selector(onrasterLayersUnderscaleForbiddenSettingChanged));
    [mapRendererSection addElement:rasterLayersUnderscaleForbiddenElement];
    
    //bool mapLayersBatchingForbidden;
    QBooleanElement* mapLayersBatchingForbiddenElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"mapLayersBatchingForbidden") BoolValue:NO];
    mapLayersBatchingForbiddenElement.controllerAction = NSStringFromSelector(@selector(onmapLayersBatchingForbiddenSettingChanged));
    [mapRendererSection addElement:mapLayersBatchingForbiddenElement];
    
    //bool disableJunkResourcesCleanup;
    QBooleanElement* disableJunkResourcesCleanupElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"disableJunkResourcesCleanup") BoolValue:NO];
    disableJunkResourcesCleanupElement.controllerAction = NSStringFromSelector(@selector(ondisableJunkResourcesCleanupSettingChanged));
    [mapRendererSection addElement:disableJunkResourcesCleanupElement];
    
    //bool disableNeededResourcesRequests;
    QBooleanElement* disableNeededResourcesRequestsElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"disableNeededResourcesRequests") BoolValue:NO];
    disableNeededResourcesRequestsElement.controllerAction = NSStringFromSelector(@selector(ondisableNeededResourcesRequestsSettingChanged));
    [mapRendererSection addElement:disableNeededResourcesRequestsElement];
    
    //bool disableSkyStage;
    QBooleanElement* disableSkyStageElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"disableSkyStage") BoolValue:NO];
    disableSkyStageElement.controllerAction = NSStringFromSelector(@selector(ondisableSkyStageSettingChanged));
    [mapRendererSection addElement:disableSkyStageElement];

    //bool disableMapLayersStage;
    QBooleanElement* disableMapLayersStageElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"disableMapLayersStage") BoolValue:NO];
    disableMapLayersStageElement.controllerAction = NSStringFromSelector(@selector(ondisableMapLayersStageSettingChanged));
    [mapRendererSection addElement:disableMapLayersStageElement];

    //bool disableSymbolsStage;
    QBooleanElement* disableSymbolsStageElement = [[QBooleanElement alloc] initWithTitle:OALocalizedString(@"disableSymbolsStage") BoolValue:NO];
    disableSymbolsStageElement.controllerAction = NSStringFromSelector(@selector(ondisableSymbolsStageSettingChanged));
    [mapRendererSection addElement:disableSymbolsStageElement];

    self = [super initWithRoot:rootElement];
    if (self) {
        _app = app;

        _forcedRenderingElement = forcedRenderingElement;
        _hideStaticSymbolsElement = hideStaticSymbolsElement;
        _forceDisplayDensityFactorElement = forceDisplayDensityFactorElement;
        _forcedDisplayDensityFactorElement = forcedDisplayDensityFactorElement;
        _forcedDisplayDensityFactorValueElement = forcedDisplayDensityFactorValueElement;
        
        _forcedGpsAccuracySection = forcedGpsAccuracySection;
        _textureFilteringQualitySection = textureFilteringQualitySection;

        _visualMetricsSection = visualMetricsSection;

        _useRawSpeedAndAltitudeOnHUDElement = useRawSpeedAndAltitudeOnHUDElement;
        _setAllResourcesAsOutdatedElement = setAllResourcesAsOutdatedElement;
        
        _debugStageEnabledElement = debugStageEnabledElement;
        _excludeOnPathSymbolsFromProcessingElement = excludeOnPathSymbolsFromProcessingElement;
        _excludeBillboardSymbolsFromProcessingElement = excludeBillboardSymbolsFromProcessingElement;
        _excludeOnSurfaceSymbolsFromProcessingElement = excludeOnSurfaceSymbolsFromProcessingElement;
        _skipSymbolsIntersectionCheckElement = skipSymbolsIntersectionCheckElement;
        _showSymbolsBBoxesAcceptedByIntersectionCheckElement = showSymbolsBBoxesAcceptedByIntersectionCheckElement;
        _showSymbolsBBoxesRejectedByIntersectionCheckElement = showSymbolsBBoxesRejectedByIntersectionCheckElement;
        _skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement = skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement;
        _showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement = showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement;
        _showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement = showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement;
        _skipSymbolsPresentationModeCheckElement = skipSymbolsPresentationModeCheckElement;
        _showSymbolsBBoxesRejectedByPresentationModeElement = showSymbolsBBoxesRejectedByPresentationModeElement;
        _showOnPathSymbolsRenderablesPathsElement = showOnPathSymbolsRenderablesPathsElement;
        _showOnPath2dSymbolGlyphDetailsElement = showOnPath2dSymbolGlyphDetailsElement;
        _showOnPath3dSymbolGlyphDetailsElement = showOnPath3dSymbolGlyphDetailsElement;
        _allSymbolsTransparentForIntersectionLookupElement = allSymbolsTransparentForIntersectionLookupElement;
        _showTooShortOnPathSymbolsRenderablesPathsElement = showTooShortOnPathSymbolsRenderablesPathsElement;
        _showAllPathsElement = showAllPathsElement;
        _rasterLayersOverscaleForbiddenElement = rasterLayersOverscaleForbiddenElement;
        _rasterLayersUnderscaleForbiddenElement = rasterLayersUnderscaleForbiddenElement;
        _mapLayersBatchingForbiddenElement = mapLayersBatchingForbiddenElement;
        _disableJunkResourcesCleanupElement = disableJunkResourcesCleanupElement;
        _disableNeededResourcesRequestsElement = disableNeededResourcesRequestsElement;
        _disableSkyStageElement = disableSkyStageElement;
        _disableMapLayersStageElement = disableMapLayersStageElement;
        _disableSymbolsStageElement = disableSymbolsStageElement;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    _mapViewController = mapVC;
    if ([mapVC isViewLoaded])
        _mapRendererView = (OAMapRendererView*)mapVC.view;

    _mapRendererDebugSettings = [_mapRendererView getMapDebugSettings];
    
    _forcedRenderingElement.boolValue = _mapRendererView.forceRenderingOnEachFrame;
    _hideStaticSymbolsElement.boolValue = _mapViewController.hideStaticSymbols;
    _forceDisplayDensityFactorElement.boolValue = _mapViewController.forceDisplayDensityFactor;
    _forcedDisplayDensityFactorElement.floatValue = _mapViewController.forcedDisplayDensityFactor;
    _forcedDisplayDensityFactorValueElement.numberValue = [NSNumber numberWithFloat:_mapViewController.forcedDisplayDensityFactor];

    _forcedGpsAccuracySection.selected = _app.locationServices.forceAccuracy;
    _textureFilteringQualitySection.selected = _app.debugSettings.textureFilteringQuality;

    _visualMetricsSection.selected = _mapViewController.visualMetricsMode;

    _useRawSpeedAndAltitudeOnHUDElement.boolValue = _app.debugSettings.useRawSpeedAndAltitudeOnHUD;
    _setAllResourcesAsOutdatedElement.boolValue = _app.debugSettings.setAllResourcesAsOutdated;
    
    
    _debugStageEnabledElement.boolValue = _mapRendererDebugSettings->debugStageEnabled;
    _excludeOnPathSymbolsFromProcessingElement.boolValue = _mapRendererDebugSettings->excludeOnPathSymbolsFromProcessing;
    _excludeBillboardSymbolsFromProcessingElement.boolValue = _mapRendererDebugSettings->excludeBillboardSymbolsFromProcessing;
    _excludeOnSurfaceSymbolsFromProcessingElement.boolValue = _mapRendererDebugSettings->excludeOnSurfaceSymbolsFromProcessing;
    _skipSymbolsIntersectionCheckElement.boolValue = _mapRendererDebugSettings->skipSymbolsIntersectionCheck;
    _showSymbolsBBoxesAcceptedByIntersectionCheckElement.boolValue = _mapRendererDebugSettings->showSymbolsBBoxesAcceptedByIntersectionCheck;
    _showSymbolsBBoxesRejectedByIntersectionCheckElement.boolValue = _mapRendererDebugSettings->showSymbolsBBoxesRejectedByIntersectionCheck;
    _skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement.boolValue = _mapRendererDebugSettings->skipSymbolsMinDistanceToSameContentFromOtherSymbolCheck;
    _showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement.boolValue = _mapRendererDebugSettings->showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck;
    _showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement.boolValue = _mapRendererDebugSettings->showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck;
    _skipSymbolsPresentationModeCheckElement.boolValue = _mapRendererDebugSettings->skipSymbolsPresentationModeCheck;
    _showSymbolsBBoxesRejectedByPresentationModeElement.boolValue = _mapRendererDebugSettings->showSymbolsBBoxesRejectedByPresentationMode;
    _showOnPathSymbolsRenderablesPathsElement.boolValue = _mapRendererDebugSettings->showOnPathSymbolsRenderablesPaths;
    _showOnPath2dSymbolGlyphDetailsElement.boolValue = _mapRendererDebugSettings->showOnPath2dSymbolGlyphDetails;
    _showOnPath3dSymbolGlyphDetailsElement.boolValue = _mapRendererDebugSettings->showOnPath3dSymbolGlyphDetails;
    _allSymbolsTransparentForIntersectionLookupElement.boolValue = _mapRendererDebugSettings->allSymbolsTransparentForIntersectionLookup;
    _showTooShortOnPathSymbolsRenderablesPathsElement.boolValue = _mapRendererDebugSettings->showTooShortOnPathSymbolsRenderablesPaths;
    _showAllPathsElement.boolValue = _mapRendererDebugSettings->showAllPaths;
    _rasterLayersOverscaleForbiddenElement.boolValue = _mapRendererDebugSettings->rasterLayersOverscaleForbidden;
    _rasterLayersUnderscaleForbiddenElement.boolValue = _mapRendererDebugSettings->rasterLayersUnderscaleForbidden;
    _mapLayersBatchingForbiddenElement.boolValue = _mapRendererDebugSettings->mapLayersBatchingForbidden;
    _disableJunkResourcesCleanupElement.boolValue = _mapRendererDebugSettings->disableJunkResourcesCleanup;
    _disableNeededResourcesRequestsElement.boolValue = _mapRendererDebugSettings->disableNeededResourcesRequests;
    _disableSkyStageElement.boolValue = _mapRendererDebugSettings->disableSkyStage;
    _disableMapLayersStageElement.boolValue = _mapRendererDebugSettings->disableMapLayersStage;
    _disableSymbolsStageElement.boolValue = _mapRendererDebugSettings->disableSymbolsStage;
}

- (void)onBackButtonClicked
{
    [self popToPreviousRootElement];
}

- (void)onForcedRenderingSettingChanged
{
    _mapRendererView.forceRenderingOnEachFrame = _forcedRenderingElement.boolValue;
}

- (void)onHideStaticSymbolsSettingChanged
{
    _mapViewController.hideStaticSymbols = _hideStaticSymbolsElement.boolValue;
}

- (void)onForceDisplayDensityFactorSettingChanged
{
    _mapViewController.forceDisplayDensityFactor = _forceDisplayDensityFactorElement.boolValue;
}

- (void)onForcedDisplayDensityFactorSettingChanged
{
    _mapViewController.forcedDisplayDensityFactor = _forcedDisplayDensityFactorElement.floatValue;
    _forcedDisplayDensityFactorValueElement.numberValue = [NSNumber numberWithFloat:_mapViewController.forcedDisplayDensityFactor];
    [self.quickDialogTableView reloadCellForElements:_forcedDisplayDensityFactorValueElement, nil];
}

- (void)onForcedDisplayDensityFactorValueSettingChanged
{
    _mapViewController.forcedDisplayDensityFactor = [_forcedDisplayDensityFactorValueElement.numberValue floatValue];
    _forcedDisplayDensityFactorElement.floatValue = _mapViewController.forcedDisplayDensityFactor;
    [self.quickDialogTableView reloadCellForElements:_forcedDisplayDensityFactorElement, nil];
}

- (void)onForcedGpsAccuracyChanged
{
    _app.locationServices.forceAccuracy = (OALocationServicesForcedAccuracy)_forcedGpsAccuracySection.selected;
}

- (void)onVisualMetricsSettingChanged
{
    _mapViewController.visualMetricsMode = (OAVisualMetricsMode)_visualMetricsSection.selected;
}

- (void)onUseRawSpeedAndAltitudeOnHUDSettingChanged
{
    _app.debugSettings.useRawSpeedAndAltitudeOnHUD = _useRawSpeedAndAltitudeOnHUDElement.boolValue;
}

- (void)onSetAllResourcesAsOutdated
{
    _app.debugSettings.setAllResourcesAsOutdated = _setAllResourcesAsOutdatedElement.boolValue;
}

- (void)onTextureFilteringQualityChanged
{
    _app.debugSettings.textureFilteringQuality = _textureFilteringQualitySection.selected;
}


- (void)applyMapRenderDebugSettings
{
    [_mapRendererView setMapDebugSettings:_mapRendererDebugSettings];
}

- (void)ondebugStageEnabledSettingChanged
{
    _mapRendererDebugSettings->debugStageEnabled = _debugStageEnabledElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onexcludeOnPathSymbolsFromProcessingSettingChanged
{
    _mapRendererDebugSettings->excludeOnPathSymbolsFromProcessing = _excludeOnPathSymbolsFromProcessingElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onexcludeBillboardSymbolsFromProcessingSettingChanged
{
    _mapRendererDebugSettings->excludeBillboardSymbolsFromProcessing = _excludeBillboardSymbolsFromProcessingElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onexcludeOnSurfaceSymbolsFromProcessingSettingChanged
{
    _mapRendererDebugSettings->excludeOnSurfaceSymbolsFromProcessing = _excludeOnSurfaceSymbolsFromProcessingElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onskipSymbolsIntersectionCheckSettingChanged
{
    _mapRendererDebugSettings->skipSymbolsIntersectionCheck = _skipSymbolsIntersectionCheckElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowSymbolsBBoxesAcceptedByIntersectionCheckSettingChanged
{
    _mapRendererDebugSettings->showSymbolsBBoxesAcceptedByIntersectionCheck = _showSymbolsBBoxesAcceptedByIntersectionCheckElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowSymbolsBBoxesRejectedByIntersectionCheckSettingChanged
{
    _mapRendererDebugSettings->showSymbolsBBoxesRejectedByIntersectionCheck = _showSymbolsBBoxesRejectedByIntersectionCheckElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onskipSymbolsMinDistanceToSameContentFromOtherSymbolCheckSettingChanged
{
    _mapRendererDebugSettings->skipSymbolsMinDistanceToSameContentFromOtherSymbolCheck = _skipSymbolsMinDistanceToSameContentFromOtherSymbolCheckElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckSettingChanged
{
    _mapRendererDebugSettings->showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck = _showSymbolsBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckSettingChanged
{
    _mapRendererDebugSettings->showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheck = _showSymbolsCheckBBoxesRejectedByMinDistanceToSameContentFromOtherSymbolCheckElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onskipSymbolsPresentationModeCheckSettingChanged
{
    _mapRendererDebugSettings->skipSymbolsPresentationModeCheck = _skipSymbolsPresentationModeCheckElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowSymbolsBBoxesRejectedByPresentationModeSettingChanged
{
    _mapRendererDebugSettings->showSymbolsBBoxesRejectedByPresentationMode = _showSymbolsBBoxesRejectedByPresentationModeElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowOnPathSymbolsRenderablesPathsSettingChanged
{
    _mapRendererDebugSettings->showOnPathSymbolsRenderablesPaths = _showOnPathSymbolsRenderablesPathsElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowOnPath2dSymbolGlyphDetailsSettingChanged
{
    _mapRendererDebugSettings->showOnPath2dSymbolGlyphDetails = _showOnPath2dSymbolGlyphDetailsElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowOnPath3dSymbolGlyphDetailsSettingChanged
{
    _mapRendererDebugSettings->showOnPath3dSymbolGlyphDetails = _showOnPath3dSymbolGlyphDetailsElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onallSymbolsTransparentForIntersectionLookupSettingChanged
{
    _mapRendererDebugSettings->allSymbolsTransparentForIntersectionLookup = _allSymbolsTransparentForIntersectionLookupElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowTooShortOnPathSymbolsRenderablesPathsSettingChanged
{
    _mapRendererDebugSettings->showTooShortOnPathSymbolsRenderablesPaths = _showTooShortOnPathSymbolsRenderablesPathsElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onshowAllPathsSettingChanged
{
    _mapRendererDebugSettings->showAllPaths = _showAllPathsElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onrasterLayersOverscaleForbiddenSettingChanged
{
    _mapRendererDebugSettings->rasterLayersOverscaleForbidden = _rasterLayersOverscaleForbiddenElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onrasterLayersUnderscaleForbiddenSettingChanged
{
    _mapRendererDebugSettings->rasterLayersUnderscaleForbidden = _rasterLayersUnderscaleForbiddenElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)onmapLayersBatchingForbiddenSettingChanged
{
    _mapRendererDebugSettings->mapLayersBatchingForbidden = _mapLayersBatchingForbiddenElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)ondisableJunkResourcesCleanupSettingChanged
{
    _mapRendererDebugSettings->disableJunkResourcesCleanup = _disableJunkResourcesCleanupElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)ondisableNeededResourcesRequestsSettingChanged
{
    _mapRendererDebugSettings->disableNeededResourcesRequests = _disableNeededResourcesRequestsElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)ondisableSkyStageSettingChanged
{
    _mapRendererDebugSettings->disableSkyStage = _disableSkyStageElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)ondisableMapLayersStageSettingChanged
{
    _mapRendererDebugSettings->disableMapLayersStage = _disableMapLayersStageElement.boolValue;
    [self applyMapRenderDebugSettings];
}

- (void)ondisableSymbolsStageSettingChanged
{
    _mapRendererDebugSettings->disableSymbolsStage = _disableSymbolsStageElement.boolValue;
    [self applyMapRenderDebugSettings];
}

@end
