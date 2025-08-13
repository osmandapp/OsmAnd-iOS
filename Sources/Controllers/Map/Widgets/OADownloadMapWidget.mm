//
//  OADownloadMapWidget.m
//  OsmAnd Maps
//
//  Created by Paul on 20.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OADownloadMapWidget.h"
#import "OsmAndApp.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAutoObserverProxy.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OATextInfoWidget.h"
#import "OALocationConvert.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAToolbarViewController.h"
#import "OAResourcesUIHelper.h"
#import "OADownloadsManager.h"
#import "OAObservable.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/ResourcesManager.h>

#define ZOOM_MIN_TO_SHOW_DOWNLOAD_DIALOG 9
#define ZOOM_MAX_TO_SHOW_DOWNLOAD_DIALOG 11

#define DISTANCE_TO_REFRESH 35000

#define kBottomShadowOffset 13.0

@interface OADownloadMapWidget ()

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descrView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;

@end

@implementation OADownloadMapWidget
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapRendererView *_mapView;
    BOOL _cachedVisibiliy;
    
    OARepositoryResourceItem *_resourceItem;
    CLLocation *_cachedLocation;
    OsmAnd::ZoomLevel _cachedZoomLevel;
    NSString *_lastProcessedRegionName;
    
    OAAutoObserverProxy* _dayNightModeObserver;
}

- (instancetype) init
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADownloadMapWidget" owner:self options:nil];
    self = (OADownloadMapWidget *)[nib objectAtIndex:0];
    if (self)
        self.frame = CGRectMake(0, 0, DeviceScreenWidth, 150);
    
    [self commonInit];
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADownloadMapWidget" owner:self options:nil];
    self = (OADownloadMapWidget *)[nib objectAtIndex:0];
    if (self)
        self.frame = frame;
    
    [self commonInit];
    return self;
}

- (void) commonInit
{
    _settings = [OAAppSettings sharedManager];
    _app = [OsmAndApp instance];
    _mapView = OARootViewController.instance.mapPanel.mapViewController.mapView;
    _dayNightModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                      withHandler:@selector(onDayNightModeChanged)
                                                       andObserve:_app.dayNightModeObservable];
    
    self.hidden = YES;
    [self.closeButton setCornerRadius:9];
    [self.downloadButton setCornerRadius:9];
    [self applyLocalization];
    [self onDayNightModeChanged];
    [self updateInfo];

    self.descrView.font = [UIFont systemFontOfSize:15. weight:UIFontWeightBold];
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
    self.downloadButton.titleLabel.font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (void) applyLocalization
{
    [self.closeButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.downloadButton setTitle:OALocalizedString(@"shared_string_download") forState:UIControlStateNormal];
}

- (void) layoutSubviews
{
    self.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.2].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowRadius = 12.0;
    self.layer.shadowOffset = CGSizeMake(0.0, 12.0);
    self.layer.masksToBounds = NO;
}


- (CGFloat)shadowOffset
{
    return kBottomShadowOffset;
}

- (BOOL) isVisible
{
    return [_settings.showDownloadMapDialog get] && !_lastProcessedRegionName && _resourceItem && [self hasZoomForQuery];
}

- (BOOL) hasZoomForQuery
{
    return _mapView.zoomLevel >= ZOOM_MIN_TO_SHOW_DOWNLOAD_DIALOG && _mapView.zoomLevel <= ZOOM_MAX_TO_SHOW_DOWNLOAD_DIALOG;
}

- (BOOL) updateInfo
{
    if (self.shouldUpdate)
    {
        if (![self hasZoomForQuery])
            return [self updateVisibility];
        const auto latLon = OsmAnd::LatLon(_cachedLocation.coordinate.latitude, _cachedLocation.coordinate.longitude);
        const auto externalMaps = [OAResourcesUIHelper getExternalMapFilesAt:OsmAnd::Utilities::convertLatLonTo31(latLon) routeData:NO];
        if (!externalMaps.empty())
        {
            _lastProcessedRegionName = externalMaps.first()->id.toNSString();
            [self updateVisibility];
        }
        else
        {
            [OAResourcesUIHelper requestMapDownloadInfo:_cachedLocation.coordinate resourceType:OsmAnd::ResourcesManager::ResourceType::MapRegion onComplete:^(NSArray<OAResourceItem *> *res) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (res.count > 0)
                    {
                        for (OAResourceItem * item in res)
                        {
                            if ([item isKindOfClass:OALocalResourceItem.class])
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    _lastProcessedRegionName = item.resourceId.toNSString();
                                    [self updateVisibility];
                                });
                                return;
                            }
                        }
                        OARepositoryResourceItem *item = (OARepositoryResourceItem *)res[0];
                        NSString *resId = item.resourceId.toNSString();
                        if ([_lastProcessedRegionName isEqualToString:resId])
                            return;
                        BOOL isDownloading = [[OsmAndApp instance].downloadsManager.keysOfDownloadTasks containsObject:[NSString stringWithFormat:@"resource:%@", resId]];
                        _lastProcessedRegionName = isDownloading ? resId : nil;
                        _resourceItem = isDownloading ? nil : item;
                        dispatch_async(dispatch_get_main_queue(), ^{
                            BOOL visible = self.isVisible;
                            if (visible)
                                [self updateWidgetInformation];
                            [self updateVisibility];
                        });
                    }
                });
            }];
        }
    }
    return YES;
}

- (void) updateWidgetInformation
{
    if (_resourceItem)
    {
        NSString *titleText = [NSString stringWithFormat:OALocalizedString(@"download_suggestion"), _resourceItem.title];
        NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:titleText attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17]}];
        NSRange range = [titleText rangeOfString:_resourceItem.title];
        [attrString addAttributes:@{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorActive], NSFontAttributeName : [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium]} range:range];
        
        _titleView.attributedText = attrString;
        _descrView.text = [NSByteCountFormatter stringFromByteCount:_resourceItem.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
    }
}

- (BOOL) shouldUpdate
{
    if (![_settings.showDownloadMapDialog get])
    {
        if (!self.isHidden)
            [self updateVisibility];
        return NO;
    }
    
    BOOL isFirstLaunch = _cachedLocation == nil;
    const auto target31 = _mapView.target31;
    const auto loc = OsmAnd::Utilities::convert31ToLatLon(target31);
    CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:loc.latitude longitude:loc.longitude];
    if (isFirstLaunch)
    {
        _cachedLocation = currentLocation;
        _cachedZoomLevel = _mapView.zoomLevel;
        return YES;
    }
    else
    {
        if ([_cachedLocation distanceFromLocation:currentLocation] > DISTANCE_TO_REFRESH || _cachedZoomLevel != _mapView.zoomLevel)
        {
            _cachedZoomLevel = _mapView.zoomLevel;
            _cachedLocation = currentLocation;
            return YES;
        }
        return NO;
    }
}

- (BOOL) updateVisibility
{
    BOOL visible = self.isVisible;
    if (visible != _cachedVisibiliy)
    {
        _cachedVisibiliy = visible;
        self.hidden = !visible;
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:self visible:visible];
        OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
        [mapPanel.hudViewController updateControlsLayout:YES];
        [mapPanel updateToolbar];
        
        return YES;
    }
    return NO;
}

- (void) onDayNightModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.overrideUserInterfaceStyle = OAAppSettings.sharedManager.nightMode ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
        [self updateColors];
        [self updateWidgetInformation];
    });
}

- (void) updateColors
{
    self.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    self.titleView.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    self.descrView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    self.closeButton.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
    [self.closeButton setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorSecondary] forState:UIControlStateNormal];
    self.downloadButton.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
    [self.downloadButton setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorPrimary] forState:UIControlStateNormal];
}

- (IBAction)closeButtonPressed:(id)sender
{
    _lastProcessedRegionName = _resourceItem.resourceId.toNSString();
    [self updateVisibility];
}

- (IBAction)downloadButtonPressed:(id)sender
{
    if (_resourceItem)
    {
        [OAResourcesUIHelper offerDownloadAndInstallOf:_resourceItem onTaskCreated:nil onTaskResumed:^(id<OADownloadTask> task) {
            _lastProcessedRegionName = _resourceItem.resourceId.toNSString();
            [self updateVisibility];
        }];
    }
}

@end
