//
//  OATargetMenuViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"

#import "OAFavoriteItem.h"
#import "OAFavoriteViewController.h"
#import "OATargetDestinationViewController.h"
#import "OATargetHistoryItemViewController.h"
#import "OAParkingViewController.h"
#import "OAPOIViewController.h"
#import "OAWikiMenuViewController.h"
#import "OAGPXItemViewController.h"
#import "OAGPXEditWptViewController.h"
#import "OAGPXWptViewController.h"
#import "OARouteTargetViewController.h"
#import "OARouteTargetSelectionViewController.h"
#import "OAImpassableRoadViewController.h"
#import "OAImpassableRoadSelectionViewController.h"
#import "OARouteDetailsViewController.h"
#import "OAMyLocationViewController.h"
#import "OATransportStopViewController.h"
#import "OATransportStopRoute.h"
#import "OATransportRouteController.h"
#import "OAOsmEditTargetViewController.h"
#import "OAOsmNotesOnlineTargetViewController.h"
#import "OARouteDetailsGraphViewController.h"
#import "OAChangePositionViewController.h"
#import "OATrsansportRouteDetailsViewController.h"
#import "OAMapDownloadController.h"
#import "OADownloadedRegionsLayer.h"
#import "OASizes.h"
#import "OAPointDescription.h"
#import "OAWorldRegion.h"
#import "OAManageResourcesViewController.h"
#import "OAResourcesUIHelper.h"
#import "Reachability.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OADownloadMapViewController.h"
#import "OAPlugin.h"
#import "OAWikipediaPlugin.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OATargetMenuViewControllerState

@end

@implementation OATargetMenuControlButton

@end

@interface OATargetMenuViewController ()

@property (nonatomic) OARepositoryResourceItem *localMapIndexItem;

@end

@implementation OATargetMenuViewController
{
    OsmAndAppInstance _app;
    
    
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
}

+ (OATargetMenuViewController *) createMenuController:(OATargetPoint *)targetPoint activeTargetType:(OATargetPointType)activeTargetType activeViewControllerState:(OATargetMenuViewControllerState *)activeViewControllerState headerOnly:(BOOL)headerOnly
{
    double lat = targetPoint.location.latitude;
    double lon = targetPoint.location.longitude;
    OATargetMenuViewController *controller = nil;
    switch (targetPoint.type)
    {
        case OATargetFavorite:
        {
            OAFavoriteItem *item;
            for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
            {
                double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
                double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
                
                if ([OAUtilities isCoordEqual:lat srcLon:lon destLat:favLat destLon:favLon])
                {
                    item = [[OAFavoriteItem alloc] initWithFavorite:favLoc];
                    break;
                }
            }
            
            if (item.favorite)
                controller = [[OAFavoriteViewController alloc] initWithItem:item headerOnly:headerOnly];
            
            break;
        }
            
        case OATargetDestination:
        {
            controller = [[OATargetDestinationViewController alloc] initWithDestination:targetPoint.targetObj];
            break;
        }
            
        case OATargetHistoryItem:
        {
            controller = [[OATargetHistoryItemViewController alloc] initWithHistoryItem:targetPoint.targetObj];
            break;
        }
            
        case OATargetParking:
        {
            if (targetPoint.targetObj)
                controller = [[OAParkingViewController alloc] initWithParking];
            else
                controller = [[OAParkingViewController alloc] initWithCoordinate:CLLocationCoordinate2DMake(lat, lon)];
            break;
        }
            
        case OATargetMyLocation:
        {
            controller = [[OAMyLocationViewController alloc] init];
            break;
        }
            
        case OATargetPOI:
        {
            controller = [[OAPOIViewController alloc] initWithPOI:targetPoint.targetObj];
            break;
        }
            
        case OATargetMapDownload:
        {
            controller = [[OAMapDownloadController alloc] initWithMapObject:targetPoint.targetObj];
            break;
        }

        case OATargetTransportStop:
        {
            controller = [[OATransportStopViewController alloc] initWithTransportStop:targetPoint.targetObj];
            break;
        }

        case OATargetTransportRoute:
        {
            controller = [[OATransportRouteController alloc] initWithTransportRoute:targetPoint.targetObj];
            break;
        }
        case OATargetOsmNote:
        case OATargetOsmEdit:
        {
            controller = [[OAOsmEditTargetViewController alloc] initWithOsmPoint:targetPoint.targetObj icon:targetPoint.icon];
            break;
        }
        case OATargetOsmOnlineNote:
        {
            controller = [[OAOsmNotesOnlineTargetViewController alloc] initWithNote:targetPoint.targetObj icon:nil];
            break;
        }
        case OATargetWiki:
        {
            if (targetPoint.localizedContent.count == 1)
            {
                controller = [[OAWikiMenuViewController alloc] initWithPOI:targetPoint.targetObj content:targetPoint.localizedContent.allValues.firstObject];
            }
            else
            {
                NSString *preferredMapLanguage = [[OAAppSettings sharedManager] settingPrefMapLanguage].get;
                if (!preferredMapLanguage || preferredMapLanguage.length == 0)
                    preferredMapLanguage = NSLocale.currentLocale.languageCode;

                NSString *locale = [OAPlugin onGetMapObjectsLocale:targetPoint.targetObj preferredLocale:preferredMapLanguage];
                if ([locale isEqualToString:@"en"])
                    locale = @"";

                NSString *content = targetPoint.localizedContent[locale];
                if (content)
                {
                    controller = [[OAWikiMenuViewController alloc] initWithPOI:targetPoint.targetObj content:content];
                }
                else
                {
                    NSArray *locales = targetPoint.localizedContent.allKeys;
                    for (NSString *langCode in [NSLocale preferredLanguages])
                    {
                        if ([langCode containsString:@"-"])
                            locale = [langCode substringToIndex:[langCode indexOf:@"-"]];
                        if ([locales containsObject:locale])
                        {
                            content = targetPoint.localizedContent[locale];
                            break;
                        }
                    }
                    if (!content)
                        content = targetPoint.localizedContent.allValues.firstObject;

                    controller = [[OAWikiMenuViewController alloc] initWithPOI:targetPoint.targetObj content:content];
                }
            }
            break;
        }
            
        case OATargetWpt:
        {
            controller = [[OAGPXWptViewController alloc] initWithItem:targetPoint.targetObj headerOnly:headerOnly];
            break;
        }
            
        case OATargetRouteStart:
        case OATargetRouteFinish:
        case OATargetRouteIntermediate:
        {
            controller = [[OARouteTargetViewController alloc] initWithTargetPoint:targetPoint.targetObj];
            break;
        }
            
        case OATargetRouteStartSelection:
        {
            controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetRouteStartSelection];
            break;
        }
            
        case OATargetRouteFinishSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetRouteFinishSelection];
            break;
        }
            
        case OATargetRouteIntermediateSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetRouteIntermediateSelection];
            break;
        }
        case OATargetHomeSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetHomeSelection];
            break;
        }
        case OATargetWorkSelection:
        {
            controller = controller = [[OARouteTargetSelectionViewController alloc] initWithTargetPointType:OATargetWorkSelection];
            break;
        }
        case OATargetImpassableRoad:
        {
            OAAvoidRoadInfo *roadInfo = targetPoint.targetObj;
            controller = [[OAImpassableRoadViewController alloc] initWithRoadInfo:roadInfo];
            break;
        }
            
        case OATargetImpassableRoadSelection:
        {
            controller = [[OAImpassableRoadSelectionViewController alloc] init];
            break;
        }
            
        case OATargetRouteDetails:
        {
            controller = [[OARouteDetailsViewController alloc] initWithGpxData:targetPoint.targetObj];
            break;
        }
            
        case OATargetRouteDetailsGraph:
        {
            controller = [[OARouteDetailsGraphViewController alloc] initWithGpxData:targetPoint.targetObj];
            break;
        }
        case OATargetChangePosition:
        {
            controller = [[OAChangePositionViewController alloc] initWithTargetPoint:targetPoint.targetObj];
            break;
        }
        case OATargetTransportRouteDetails:
        {
            controller = [[OATrsansportRouteDetailsViewController alloc] initWithRouteIndex:[targetPoint.targetObj integerValue]];
            break;
        }
        case OATargetDownloadMapSource:
        {
            controller = [[OADownloadMapViewController alloc] init];
            break;
        }
            
        default:
        {
        }
    }
    if (controller && [controller offerMapDownload])
    {
        const auto point31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(targetPoint.location.latitude, targetPoint.location.longitude));
        if (![OAResourcesUIHelper getExternalMapFilesAt:point31 routeData:NO].empty())
            return controller;
        
        [OAResourcesUIHelper requestMapDownloadInfo:targetPoint.location
                                       resourceType:OsmAnd::ResourcesManager::ResourceType::MapRegion
                                         onComplete:^(NSArray<OAResourceItem *>* res) {
            if (res.count > 0)
            {
                for (OAResourceItem * item in res)
                {
                    if ([item isKindOfClass:OALocalResourceItem.class])
                    {
                        controller.localMapIndexItem = nil;
                        [controller createMapDownloadControls];
                        return;
                    }
                }
                OARepositoryResourceItem *item = (OARepositoryResourceItem *)res[0];
                BOOL isDownloading = [[OsmAndApp instance].downloadsManager.keysOfDownloadTasks containsObject:[NSString stringWithFormat:@"resource:%@", item.resourceId.toNSString()]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (controller.delegate && [controller.delegate respondsToSelector:@selector(showProgressBar)] && isDownloading)
                        [controller.delegate showProgressBar];
                    else if (controller.delegate && [controller.delegate respondsToSelector:@selector(hideProgressBar)])
                        [controller.delegate hideProgressBar];
                });
                
                if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable || isDownloading)
                    controller.localMapIndexItem = item;
            }
            [controller createMapDownloadControls];
        }];
    }
    else if (controller && targetPoint.type == OATargetMapDownload)
    {
        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
        {
            OAResourceItem *item = ((OADownloadMapObject *)targetPoint.targetObj).indexItem;
            OARepositoryResourceItem *repoItem = nil;
            const auto& resourceManager = OsmAndApp.instance.resourcesManager;
            if (resourceManager->isInstalledResourceOutdated(item.resourceId))
            {
                repoItem = [[OARepositoryResourceItem alloc] init];
                repoItem.resourceId = item.resourceId;
                repoItem.resourceType = item.resourceType;
                repoItem.title = item.title;
                repoItem.resource = resourceManager->getResourceInRepository(item.resourceId);
                repoItem.downloadTask = [[OsmAndApp.instance.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]] firstObject];
                repoItem.size = repoItem.resource->size;
                repoItem.sizePkg = repoItem.resource->packageSize;
                repoItem.worldRegion = item.worldRegion;
                repoItem.date = item.date;
            }
            else if ([item isKindOfClass:OARepositoryResourceItem.class])
            {
                repoItem = (OARepositoryResourceItem *) item;
            }
            controller.localMapIndexItem = repoItem;
            BOOL isDownloading = [[OsmAndApp instance].downloadsManager.keysOfDownloadTasks containsObject:[NSString stringWithFormat:@"resource:%@", item.resourceId.toNSString()]];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (controller.delegate && [controller.delegate respondsToSelector:@selector(showProgressBar)] && isDownloading)
                    [controller.delegate showProgressBar];
                else if (controller.delegate && [controller.delegate respondsToSelector:@selector(hideProgressBar)])
                    [controller.delegate hideProgressBar];
                [controller createMapDownloadControls];
            });
        }
    }
    return controller;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _topToolbarType = ETopToolbarTypeFixed;
        _app = [OsmAndApp instance];
    }
    return self;
}

- (void) setLocation:(CLLocationCoordinate2D)location
{
    _location = location;
    _formattedCoords = [OAPointDescription getLocationName:location.latitude lon:location.longitude sh:YES];
}

- (UIImage *) getIcon
{
    return nil;
}

- (BOOL) needAddress
{
    return YES;
}

-(UIView *) getTopView
{
    return _navBar;
}

-(UIView *) getMiddleView
{
    return _contentView;
}

-(CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}

- (NSString *) getTypeStr
{
    return [self getCommonTypeStr];
}

- (NSString *) getCommonTypeStr
{
    return OALocalizedString(@"sett_arr_loc");
}

- (NSAttributedString *) getAttributedTypeStr
{
    return nil;
}

- (NSAttributedString *) getAttributedCommonTypeStr
{
    return nil;
}

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group
{
    return [self getAttributedTypeStr:group color:nil];
}

- (NSAttributedString *) getAttributedTypeStr:(NSString *)group color:(UIColor *)color
{
    UIColor *iconColor = color ? color : UIColorFromRGB(0x808080);
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont systemFontOfSize:15.0];
    
    NSMutableAttributedString *stringGroup = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", group]];
    NSTextAttachment *groupAttachment = [[NSTextAttachment alloc] init];
    groupAttachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_small_group.png"] color:iconColor];
    
    NSAttributedString *groupStringWithImage = [NSAttributedString attributedStringWithAttachment:groupAttachment];
    [stringGroup replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:groupStringWithImage];
    [stringGroup addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
    
    [string appendAttributedString:stringGroup];
    
    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
    
    return string;
}

- (UIColor *) getAdditionalInfoColor
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (UIImage *) getAdditionalInfoImage
{
    return nil;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
    
    _navBar.hidden = YES;
    _actionButtonPressed = NO;
    
    if ([self hasTopToolbarShadow])
    {
        // drop shadow
        [self.navBar.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.navBar.layer setShadowOpacity:0.3];
        [self.navBar.layer setShadowRadius:3.0];
        [self.navBar.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    }
    [self applySafeAreaMargins];
    [self adjustBackButtonPosition];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self applySafeAreaMargins];
        [self adjustBackButtonPosition];
        // Refresh the offset on iPads to avoid broken animations
        if (self.delegate && OAUtilities.isIPad)
            [self.delegate contentChanged];
    } completion:nil];
}

-(void) adjustBackButtonPosition
{
    CGRect buttonFrame = self.buttonBack.frame;
    buttonFrame.origin.x = 16.0 + [OAUtilities getLeftMargin];
    buttonFrame.origin.y = [[OARootViewController instance].mapPanel.hudViewController getHudMinTopOffset];
    self.buttonBack.frame = buttonFrame;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"] || task.state != OADownloadTaskStateRunning)
        return;
    
    if (!task.silentInstall)
        task.silentInstall = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_localMapIndexItem && [_localMapIndexItem.resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            NSMutableString *progressStr = [NSMutableString string];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:(_localMapIndexItem.sizePkg * [value floatValue]) countStyle:NSByteCountFormatterCountStyleFile]];
            [progressStr appendString:@" "];
            [progressStr appendString:OALocalizedString(@"shared_string_of")];
            [progressStr appendString:@" "];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:_localMapIndexItem.sizePkg countStyle:NSByteCountFormatterCountStyleFile]];
            if (self.delegate && [self.delegate respondsToSelector:@selector(setDownloadProgress:text:)])
                [self.delegate setDownloadProgress:[value floatValue] text:progressStr];
        }
    });
}

- (void) onDownloadCancelled
{
    if (_localMapIndexItem)
    {
        [OAResourcesUIHelper offerCancelDownloadOf:_localMapIndexItem onTaskStop:^(id<OADownloadTask>  _Nonnull task) {
            if ([[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""] isEqualToString:_localMapIndexItem.resourceId.toNSString()])
            {
                [self.delegate hideProgressBar];
                _localMapIndexItem = nil;
                
                if ([self.getTargetObj isKindOfClass:OADownloadMapObject.class])
                {
                    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
                    {
                        OAResourceItem *item = ((OADownloadMapObject *) self.getTargetObj).indexItem;
                        self.localMapIndexItem = [item isKindOfClass:OARepositoryResourceItem.class] ? (OARepositoryResourceItem *) item : nil;
                    }
                }
                else
                {
                    [OAResourcesUIHelper requestMapDownloadInfo:self.location
                                                   resourceType:OsmAnd::ResourcesManager::ResourceType::MapRegion
                                                     onComplete:^(NSArray<OAResourceItem *>* res) {
                        OARepositoryResourceItem *item = (OARepositoryResourceItem *)res[0];
                        if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable && item)
                            self.localMapIndexItem = item;
                    }];
                }
            }
        }];
    }
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
            {
                if (self.delegate && [self.delegate respondsToSelector:@selector(showProgressBar)])
                    [self.delegate showProgressBar];
            }
        }
        else if (_localMapIndexItem && [_localMapIndexItem.resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            _localMapIndexItem = nil;
            _downloadControlButton = nil;
            if (self.delegate && [self.delegate respondsToSelector:@selector(hideProgressBar)])
                [self.delegate hideProgressBar];
        }
    });
}

- (void) createMapDownloadControls
{
    if (_localMapIndexItem)
    {
        self.downloadControlButton = [[OATargetMenuControlButton alloc] init];
        if ([self showRegionNameOnDownloadButton])
            self.downloadControlButton.title = _localMapIndexItem.title;
        else
            self.downloadControlButton.title = OALocalizedString(@"download");
        [self.delegate contentChanged];
    }
    else if (self.delegate && [self.delegate respondsToSelector:@selector(hideProgressBar)])
        [self.delegate hideProgressBar];
}

- (BOOL) showRegionNameOnDownloadButton
{
    return YES; //override
}

- (BOOL) showDetailsButton
{
    return NO; //override
}

- (CGFloat) detailsButtonHeight
{
    return 50.; //override
}

- (IBAction) buttonBackPressed:(id)sender
{
    if (self.topToolbarType == ETopToolbarTypeFloating)
    {
        if (self.delegate)
            [self.delegate requestHeaderOnlyMode];
    }

    [self backPressed];
}

- (IBAction) buttonOKPressed:(id)sender
{
    _actionButtonPressed = YES;
    [self okPressed];
}

- (IBAction) buttonCancelPressed:(id)sender
{
    _actionButtonPressed = YES;
    if (self.topToolbarType == ETopToolbarTypeFloating)
    {
        if (self.delegate)
            [self.delegate requestHeaderOnlyMode];
    }
    [self cancelPressed];
}

- (void) backPressed
{
    // override
}

- (void) okPressed
{
    // override
}

- (void) cancelPressed
{
    // override
}

- (BOOL) hasContent
{
    return YES; // override
}

- (CGFloat) contentHeight
{
    return 0.0; // override
}

- (CGFloat) contentHeight:(CGFloat)width
{
    return [self contentHeight];
}

- (void) setContentBackgroundColor:(UIColor *)color
{
    _contentView.backgroundColor = color;
}

- (BOOL) hasInfoView
{
    return [self hasInfoButton] || [self hasRouteButton];
}

- (BOOL) hasInfoButton
{
    return [self hasContent] && ![self isLandscape];
}

- (BOOL) hasRouteButton
{
    return YES;
}

- (BOOL) showTopControls
{
    if (self.delegate)
        return ![self.delegate isInFullMode] && ![self.delegate isInFullScreenMode] && self.topToolbarType != ETopToolbarTypeFixed;
    else
        return NO;
}

- (BOOL) shouldEnterContextModeManually
{
    return NO; // override
}

- (BOOL) supportMapInteraction
{
    return NO; // override
}

- (BOOL) supportsForceClose
{
    return NO; // override
}

- (BOOL) showNearestWiki;
{
    return NO; // override
}

- (BOOL) showNearestPoi;
{
    return NO; // override
}

- (BOOL) supportFullMenu
{
    return YES; // override
}

- (BOOL) supportFullScreen
{
    return YES; // override
}

- (void) goHeaderOnly
{
    // override
}

- (void) goFull
{
    // override
}

- (void) goFullScreen
{
    // override
}

- (BOOL) hasTopToolbar
{
    return NO; // override
}

- (BOOL) shouldShowToolbar
{
    return NO; // override
}

- (BOOL) hasTopToolbarShadow
{
    return YES;
}

- (BOOL) hasBottomToolbar
{
    return NO; // override
}

- (BOOL) needsAdditionalBottomMargin
{
    return YES; // override
}

- (BOOL) needsMapRuler
{
    return NO; // override
}

- (CGFloat) additionalContentOffset
{
    return 0.0; // override
}

- (BOOL) needsLayoutOnModeChange
{
    return YES; // override
}

- (void) setTopToolbarType:(ETopToolbarType)topToolbarType
{
    _topToolbarType = topToolbarType;
}

- (void) applyTopToolbarTargetTitle
{
    if (self.delegate)
        self.titleView.text = [self.delegate getTargetTitle];
}

- (void) setTopToolbarAlpha:(CGFloat)alpha
{
    if ([self hasTopToolbar])
    {
        switch (self.topToolbarType)
        {
            case ETopToolbarTypeFloating:
            case ETopToolbarTypeMiddleFixed:
            case ETopToolbarTypeFloatingFixedButton:
                if (self.navBar.alpha != alpha)
                    self.navBar.alpha = alpha;
                break;
                
            case ETopToolbarTypeFixed:
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeFixed alpha:alpha];
                self.navBar.alpha = 1.0;
                break;

            default:
                break;
        }
    }
}

- (void) setMiddleToolbarAlpha:(CGFloat)alpha
{
    if ([self hasTopToolbar])
    {
        CGFloat backButtonAlpha = alpha * 2;
        backButtonAlpha = backButtonAlpha > 1 ? 1 : backButtonAlpha;
        
        if (self.topToolbarType != ETopToolbarTypeFloating)
            backButtonAlpha = 0;
        if (self.topToolbarType == ETopToolbarTypeFloatingFixedButton)
            backButtonAlpha = 1;
        
        if (self.buttonBack.alpha != backButtonAlpha)
        {
            self.buttonBack.alpha = backButtonAlpha;
            if (!OAUtilities.isLandscape)
                [OARootViewController.instance.mapPanel.hudViewController setTopControlsAlpha:1 - backButtonAlpha];
        }
        
        if (self.topToolbarType == ETopToolbarTypeMiddleFixed)
        {
            if (alpha < 1)
            {
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeMiddleFixed alpha:1.0];
                self.navBar.alpha = alpha;
            }
            else
            {
                [self applyGradient:self.topToolbarGradient topToolbarType:ETopToolbarTypeFixed alpha:alpha - 1.0];
                self.navBar.alpha = 1.0;
            }
        }
    }
    
    if (self.navBar.alpha > 0)
        self.buttonBack.alpha = 1 - self.navBar.alpha;
}

- (void) applyGradient:(BOOL)gradient alpha:(CGFloat)alpha
{
    [self applyGradient:gradient topToolbarType:self.topToolbarType alpha:alpha];
}

- (void) applyGradient:(BOOL)gradient topToolbarType:(ETopToolbarType)topToolbarType alpha:(CGFloat)alpha
{
    if (self.titleGradient && gradient)
    {
        _topToolbarGradient = YES;
        switch (topToolbarType)
        {
            case ETopToolbarTypeFixed:
                self.titleGradient.alpha = 1.0 - alpha;
                self.navBarBackground.alpha = alpha;
                self.titleGradient.hidden = NO;
                self.navBarBackground.hidden = NO;
                break;
                
            case ETopToolbarTypeMiddleFixed:
                self.titleGradient.alpha = alpha;
                self.navBarBackground.alpha = 0;
                self.titleGradient.hidden = NO;
                self.navBarBackground.hidden = YES;
                break;
                
            default:
                break;
        }
    }
    else
    {
        _topToolbarGradient = NO;
        self.titleGradient.alpha = 0.0;
        self.titleGradient.hidden = YES;
        self.navBarBackground.alpha = 1.0;
        self.navBarBackground.hidden = NO;
    }
}

- (BOOL) disablePanWhileEditing
{
    return NO; // override
}

- (BOOL) disableScroll
{
    return NO; // override
}

- (BOOL) supportEditing
{
    return NO; // override
}

- (void) activateEditing
{
    // override
}

- (BOOL) commitChangesAndExit
{
    return YES; // override
}

- (BOOL) preHide
{
    return YES; // override
}

- (id) getTargetObj
{
    return nil; // override
}

- (OATargetMenuViewControllerState *)getCurrentState
{
    return nil; // override
}

- (BOOL) isLandscape
{
    return OAUtilities.isLandscape;
}

- (BOOL) hasControlButtons
{
    return self.leftControlButton || self.rightControlButton;
}

- (void) leftControlButtonPressed;
{
    // override
}

- (void) rightControlButtonPressed;
{
    // override
}

- (void) downloadControlButtonPressed
{
    if (_localMapIndexItem)
    {
        [OAResourcesUIHelper offerDownloadAndInstallOf:_localMapIndexItem onTaskCreated:^(id<OADownloadTask> task) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(showProgressBar)])
                [self.delegate showProgressBar];
            _localMapIndexItem.downloadTask = task;
        } onTaskResumed:nil];
    }
}

- (void) onMenuSwipedOff
{
    // override
}
- (void) onMenuDismissed
{
    // override
}

- (void) onMenuShown
{
    // override
}

- (void) setupToolBarButtonsWithWidth:(CGFloat)width
{
    // override
}

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    return @[];
}

- (NSArray<OATransportStopRoute *> *) getLocalTransportStopRoutes
{
    return [self getSubTransportStopRoutes:false];
}

- (NSArray<OATransportStopRoute *> *) getNearbyTransportStopRoutes
{
    return [self getSubTransportStopRoutes:true];
}

- (void)refreshContent
{
}

- (BOOL) isBottomsControlVisible
{
    return YES; // override
}

- (BOOL) isMapFrameNeeded
{
    return NO;
}

- (void) addMapFrameLayer:(CGRect)mapFrame view:(UIView *)view
{
    // override
}

- (void) removeMapFrameLayer:(UIView *)view
{
    // override
}

- (CGFloat) mapHeightKoef
{
    return 0; // override
}

- (BOOL)denyClose
{
    return NO;
}

- (BOOL)hideButtons
{
    return NO;
}

- (BOOL)hasDismissButton
{
    return NO;
}

- (BOOL) offerMapDownload
{
    return YES;
}

@end
