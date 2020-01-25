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
#import "OAGPXEditItemViewController.h"
#import "OAGPXEditWptViewController.h"
#import "OAGPXWptViewController.h"
#import "OARouteTargetViewController.h"
#import "OARouteTargetSelectionViewController.h"
#import "OAImpassableRoadViewController.h"
#import "OAImpassableRoadSelectionViewController.h"
#import "OARouteDetailsViewController.h"
#import "OAGPXRouteViewController.h"
#import "OAMyLocationViewController.h"
#import "OATransportStopViewController.h"
#import "OATransportStopRoute.h"
#import "OATransportRouteController.h"
#import "OAOsmEditTargetViewController.h"
#import "OAOsmNotesOnlineTargetViewController.h"
#import "OASizes.h"
#import "OAPointDescription.h"
#import "OAWorldRegion.h"
#import "OAManageResourcesViewController.h"
#import "OAResourcesBaseViewController.h"
#import "Reachability.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@implementation OATargetMenuViewControllerState

@end

@implementation OATargetMenuControlButton

@end

@interface OATargetMenuViewController ()

@end

@implementation OATargetMenuViewController
{
    OsmAndAppInstance _app;
    
    RepositoryResourceItem *_localMapIndexItem;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
}

+ (OATargetMenuViewController *) createMenuController:(OATargetPoint *)targetPoint activeTargetType:(OATargetPointType)activeTargetType activeViewControllerState:(OATargetMenuViewControllerState *)activeViewControllerState
{
    double lat = targetPoint.location.latitude;
    double lon = targetPoint.location.longitude;
    OATargetMenuViewController *controller = nil;
    switch (targetPoint.type)
    {
        case OATargetFavorite:
        {
            OAFavoriteItem *item = [[OAFavoriteItem alloc] init];
            for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
            {
                double favLon = OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x);
                double favLat = OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y);
                
                if ([OAUtilities isCoordEqual:lat srcLon:lon destLat:favLat destLon:favLon])
                {
                    item.favorite = favLoc;
                    break;
                }
            }
            
            if (item.favorite)
                controller = [[OAFavoriteViewController alloc] initWithItem:item];
            
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
                controller = [[OAParkingViewController alloc] initWithParking:targetPoint.targetObj];
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
            NSString *contentLocale = [[OAAppSettings sharedManager] settingPrefMapLanguage];
            if (!contentLocale)
                contentLocale = [OAUtilities currentLang];
            
            NSString *content = [targetPoint.localizedContent objectForKey:contentLocale];
            if (!content)
            {
                contentLocale = @"";
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            if (!content && targetPoint.localizedContent.count > 0)
            {
                contentLocale = targetPoint.localizedContent.allKeys[0];
                content = [targetPoint.localizedContent objectForKey:contentLocale];
            }
            
            if (content)
                controller = [[OAWikiMenuViewController alloc] initWithPOI:targetPoint.targetObj content:content];
            break;
        }
            
        case OATargetWpt:
        {
            if (activeTargetType == OATargetGPXEdit)
                controller = [[OAGPXEditWptViewController alloc] initWithItem:targetPoint.targetObj];
            else
                controller = [[OAGPXWptViewController alloc] initWithItem:targetPoint.targetObj];
            break;
        }
            
        case OATargetGPX:
        {
            OAGPXItemViewControllerState *state = activeViewControllerState ? (OAGPXItemViewControllerState *)activeViewControllerState : nil;
            
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
            break;
        }
            
        case OATargetGPXEdit:
        {
            OAGPXEditItemViewControllerState *state = activeViewControllerState ? (OAGPXEditItemViewControllerState *)activeViewControllerState : nil;
            if (targetPoint.targetObj)
            {
                if (state)
                {
                    if (state.showCurrentTrack)
                        controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem:state];
                    else
                        controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj ctrlState:state];
                }
                else
                {
                    controller = [[OAGPXEditItemViewController alloc] initWithGPXItem:targetPoint.targetObj];
                }
            }
            else
            {
                controller = [[OAGPXEditItemViewController alloc] initWithCurrentGPXItem];
                targetPoint.targetObj = ((OAGPXItemViewController *)controller).gpx;
            }
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
            NSNumber *roadId = targetPoint.targetObj;
            controller = [[OAImpassableRoadViewController alloc] initWithRoadId:roadId.unsignedLongLongValue];
            break;
        }
            
        case OATargetImpassableRoadSelection:
        {
            controller = [[OAImpassableRoadSelectionViewController alloc] init];
            break;
        }
            
        case OATargetRouteDetails:
        {
            controller = [[OARouteDetailsViewController alloc] init];
            break;
        }
            
        case OATargetGPXRoute:
        {
            OAGPXRouteViewControllerState *state = activeViewControllerState ? (OAGPXRouteViewControllerState *)activeViewControllerState : nil;
            OAGpxRouteSegmentType segmentType = (OAGpxRouteSegmentType)targetPoint.segmentIndex;
            if (state)
                controller = [[OAGPXRouteViewController alloc] initWithCtrlState:state];
            else
                controller = [[OAGPXRouteViewController alloc] initWithSegmentType:segmentType];
            
            break;
        }
            
        default:
        {
        }
    }
    if (targetPoint.type != OATargetImpassableRoad &&
        targetPoint.type != OATargetRouteFinishSelection &&
        targetPoint.type != OATargetRouteStartSelection &&
        targetPoint.type != OATargetRouteIntermediateSelection &&
        targetPoint.type != OATargetWorkSelection &&
        targetPoint.type != OATargetHomeSelection &&
        targetPoint.type != OATargetGPXEdit &&
        targetPoint.type != OATargetGPXRoute &&
        targetPoint.type != OATargetRouteDetails &&
        targetPoint.type != OATargetImpassableRoadSelection)
    {
        [controller requestMapDownloadInfo:targetPoint.location];
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
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    
    NSMutableAttributedString *stringGroup = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", group]];
    NSTextAttachment *groupAttachment = [[NSTextAttachment alloc] init];
    groupAttachment.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_small_group.png"] color:UIColorFromRGB(0x808080)];
    
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
    buttonFrame.origin.x = 5.0 + [OAUtilities getLeftMargin];
    buttonFrame.origin.y = [OAUtilities getStatusBarHeight];
    self.buttonBack.frame = buttonFrame;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) requestMapDownloadInfo:(CLLocationCoordinate2D) coordinate
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray<OAWorldRegion *> *mapRegions = [[_app.worldRegion queryAtLat:coordinate.latitude lon:coordinate.longitude] mutableCopy];
        NSArray<OAWorldRegion *> *copy = [NSArray arrayWithArray:mapRegions];
        OAWorldRegion *selectedRegion = nil;
        if (mapRegions.count > 0)
        {
            [copy enumerateObjectsUsingBlock:^(OAWorldRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![region contain:coordinate.latitude lon:coordinate.longitude])
                    [mapRegions removeObject:region];
            }];
            
            double smallestArea = DBL_MAX;
            for (OAWorldRegion *region : mapRegions)
            {
                BOOL isRegionMapDownload = NO;
                NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsyRegion:region];
                for (NSString *resourceId in ids)
                {
                    const auto resource = _app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                    if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                    {
                        if (_app.resourcesManager->isResourceInstalled(resource->id))
                        {
                            _localMapIndexItem = nil;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self createMapDownloadControls];
                            });
                            return;
                        }
                        isRegionMapDownload = YES;
                    }
                }
                
                double area = [region getArea];
                if (area < smallestArea && isRegionMapDownload)
                {
                    smallestArea = area;
                    selectedRegion = region;
                }
            }
        }
        
        if (selectedRegion)
        {
            NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsyRegion:selectedRegion];
            if (ids.count > 0)
            {
                for (NSString *resourceId in ids)
                {
                    const auto resource = _app.resourcesManager->getResourceInRepository(QString::fromNSString(resourceId));
                    if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                    {
                        BOOL isDownloading = [_app.downloadsManager.keysOfDownloadTasks containsObject:[NSString stringWithFormat:@"resource:%@", resource->id.toNSString()]];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (self.delegate && [self.delegate respondsToSelector:@selector(showProgressBar)] && isDownloading)
                                [self.delegate showProgressBar];
                            else if (self.delegate && [self.delegate respondsToSelector:@selector(hideProgressBar)])
                                [self.delegate hideProgressBar];
                        });
                        RepositoryResourceItem* item = [[RepositoryResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.resourceType = resource->type;
                        item.title = [OAResourcesBaseViewController titleOfResource:resource
                                                                           inRegion:selectedRegion
                                                                     withRegionName:YES
                                                                   withResourceType:NO];
                        item.resource = resource;
                        item.downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                        item.size = resource->size;
                        item.sizePkg = resource->packageSize;
                        item.worldRegion = selectedRegion;
                        if ((!_app.resourcesManager->isResourceInstalled(resource->id) &&
                            [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable) || isDownloading)
                        {
                            _localMapIndexItem = item;
                        }
                        break;
                    }
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self createMapDownloadControls];
        });
    });
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
        NSByteCountFormatter *f = [[NSByteCountFormatter alloc] init];
        f.includesUnit = NO;
        f.countStyle = NSByteCountFormatterCountStyleFile;
        
        if (_localMapIndexItem && [_localMapIndexItem.resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            NSMutableString *progressStr = [NSMutableString string];
            [progressStr appendString:[f stringFromByteCount:(_localMapIndexItem.size * [value floatValue])]];
            [progressStr appendString:@" "];
            [progressStr appendString:OALocalizedString(@"shared_string_of")];
            [progressStr appendString:@" "];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:_localMapIndexItem.size countStyle:NSByteCountFormatterCountStyleFile]];
            if (self.delegate && [self.delegate respondsToSelector:@selector(setDownloadProgress:text:)])
                [self.delegate setDownloadProgress:[value floatValue] text:progressStr];
        }
    });
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
        self.downloadControlButton.title = _localMapIndexItem.title;
        [self.delegate contentChanged];
    }
    else if (self.delegate && [self.delegate respondsToSelector:@selector(hideProgressBar)])
        [self.delegate hideProgressBar];
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

- (BOOL) supportMapInteraction
{
    return NO; // override
}

- (BOOL) showNearestWiki;
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
        CGFloat backButtonAlpha = alpha;
        if (self.topToolbarType != ETopToolbarTypeFloating)
            backButtonAlpha = 0;
        
        if (self.buttonBack.alpha != backButtonAlpha)
            self.buttonBack.alpha = backButtonAlpha;
        
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
        if (_localMapIndexItem.resourceType == OsmAnd::ResourcesManager::ResourceType::MapRegion &&
            ![OAResourcesBaseViewController checkIfDownloadAvailable:_localMapIndexItem.worldRegion])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"res_free_exp") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
            [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        NSString *resourceName = [OAResourcesBaseViewController titleOfResource:_localMapIndexItem.resource
                                                                       inRegion:_localMapIndexItem.worldRegion
                                                                 withRegionName:YES
                                                               withResourceType:YES];
        
        if (![OAResourcesBaseViewController verifySpaceAvailableDownloadAndUnpackResource:_localMapIndexItem.resource
                                                      withResourceName:resourceName
                                                              asUpdate:YES])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"res_install_no_space") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
            [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        [OAResourcesBaseViewController startBackgroundDownloadOf:_localMapIndexItem.resource resourceName:resourceName];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(showProgressBar)])
            [self.delegate showProgressBar];
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

@end
