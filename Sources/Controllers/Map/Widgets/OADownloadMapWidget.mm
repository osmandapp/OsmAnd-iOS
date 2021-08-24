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
#import "OAAutoObserverProxy.h"
#import "OAAppSettings.h"
#import "OAUtilities.h"
#import "OATextInfoWidget.h"
#import "OALocationConvert.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAToolbarViewController.h"
#import "OAResourcesUIHelper.h"
#import "Localization.h"

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
    BOOL _nightMode;
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
    [self updateInfo];
    [self updateColors];
}

- (void) applyLocalization
{
    [self.closeButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.downloadButton setTitle:OALocalizedString(@"download") forState:UIControlStateNormal];
}

- (void) layoutSubviews
{
    if (self.delegate)
        [self.delegate widgetChanged:nil];
    
    self.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.4].CGColor;
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
                if (res.count > 0)
                {
                    for (OAResourceItem * item in res)
                    {
                        if ([item isKindOfClass:OALocalResourceItem.class])
                        {
                            _lastProcessedRegionName = item.resourceId.toNSString();
                            [self updateVisibility];
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
        [attrString addAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(_nightMode ? color_chart_orange : color_primary_purple), NSFontAttributeName : [UIFont systemFontOfSize:17.0 weight:UIFontWeightMedium]} range:range];
        
        _titleView.attributedText = attrString;
        _descrView.text = [NSByteCountFormatter stringFromByteCount:_resourceItem.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
    }
}

- (BOOL) shouldUpdate
{
    if (![_settings.showDownloadMapDialog get])
        return NO;
    
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
        [mapPanel.hudViewController updateToolbarLayout:YES];
        [mapPanel updateToolbar];
        
        return YES;
    }
    return NO;
}

- (void) onDayNightModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _nightMode = OAAppSettings.sharedManager.nightMode;
        [self updateColors];
    });
}

- (void) updateColors
{
    if (!_nightMode)
    {
        self.backgroundColor = UIColor.whiteColor;
        self.titleView.textColor = UIColor.blackColor;
        self.descrView.textColor = UIColorFromRGB(color_text_footer);
        self.closeButton.backgroundColor = UIColorFromRGB(color_route_button_inactive);
        [self.closeButton setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
        self.downloadButton.backgroundColor = UIColorFromRGB(color_primary_purple);
    }
    else
    {
        self.backgroundColor = UIColorFromRGB(nav_bar_night);
        self.titleView.textColor = UIColorFromRGB(text_primary_night);
        self.descrView.textColor = UIColorFromRGB(text_secondary_night);
        self.closeButton.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary_night);
        [self.closeButton setTitleColor:UIColorFromRGB(color_chart_orange) forState:UIControlStateNormal];
        self.downloadButton.backgroundColor = UIColorFromRGB(color_button_active_night);
    }
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
