//
//  OATrackMenuViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuViewController.h"
#import "OAOverviewTrackMenuViewController.h"
#import "OASegmentsTrackMenuViewController.h"
#import "OARootViewController.h"
#import "OASaveTrackViewController.h"
#import "OAEditGPXColorViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OAMapRendererView.h"
#import "OATabBar.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDocument.h"
#import "OASelectedGPXHelper.h"
#import "OASavingTrackHelper.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAGPXDatabase.h"
#import "OANativeUtilities.h"
#import "OAGPXLayer.h"
#import "OAMapActions.h"
#import "OARouteProvider.h"

#define kOverviewPosition 0
#define kSegmentsPosition 1
#define kPointsPosition 2
#define kActionsPosition 3

@interface OATrackMenuViewController() <UIPageViewControllerDelegate, UITabBarDelegate, UIDocumentInteractionControllerDelegate, OATrackMenuViewControllerDelegate, OAEditGPXColorViewControllerDelegate, OASaveTrackViewControllerDelegate, OASegmentSelectionDelegate>

@end

@implementation OATrackMenuViewController
{
    UIPageViewController *_pageViewController;
    UIDocumentInteractionController *_exportController;
    OAOverviewTrackMenuViewController *_overviewViewController;
    OASegmentsTrackMenuViewController *_segmentsViewController;
    OAMapPanelViewController *_mapPanelViewController;
    OAMapViewController *_mapViewController;
    NSArray *_controllers;

    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASavingTrackHelper *_savingHelper;
    OAGPX *_gpx;
    OAGPXDocument *_doc;

    BOOL _isCurrentTrack;
    BOOL _isShown;
    NSString *_exportFileName;
    NSString *_exportFilePath;
    OAGPXTrackColorCollection *_gpxColorCollection;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        _gpx = gpx;
        _isCurrentTrack = _gpx.gpxFilePath.length == 0;
        _doc = _isCurrentTrack ? (OAGPXDocument *) _savingHelper.currentTrack
                : [[OAGPXDocument alloc] initWithGpxFile:[_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath]];
        _isShown = [_settings.mapSettingVisibleGpx.get containsObject:_gpx.gpxFilePath];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.interactivePopGestureRecognizer.enabled = NO;

    [self setupView];

    _mapPanelViewController = [OARootViewController instance].mapPanel;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    _gpxColorCollection = [[OAGPXTrackColorCollection alloc] initWithMapViewController:_mapViewController];

//    [_mapPanelViewController displayAreaOnMap:_gpx.bounds.topLeft bottomRight:_gpx.bounds.bottomRight zoom:10. bottomInset:!self.isLandscape ? DeviceScreenHeight - _overviewViewController.headerView.frame.size.height : 0 leftInset:self.isLandscape ? DeviceScreenHeight - _overviewViewController.headerView.frame.size.width : 0];
//    [_mapPanelViewController displayGpxOnMap:_gpx];
    OsmAnd::LatLon latLon(_gpx.bounds.topLeft.latitude, _gpx.bounds.bottomRight.longitude);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [_mapViewController goToPosition:point andZoom:_mapViewController.mapView.zoomLevel animated:NO];
}

//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    [self setupView];
//}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {

        if (self.delegate)
        {
            if (self.isLandscape)
                [self.delegate requestFullScreenMode];
            else
                [self.delegate requestFullMode];

            [self.delegate contentChanged];
        }
    } completion:nil];
}

- (void)setupView
{
    [self setupPageController];

    _overviewViewController = [[OAOverviewTrackMenuViewController alloc] initWithGpx:_gpx];
    _overviewViewController.delegate = self;
    _segmentsViewController = [[OASegmentsTrackMenuViewController alloc] initWithGpx:_gpx];
    _controllers = @[_overviewViewController, _segmentsViewController];

    [_pageViewController setViewControllers:@[_controllers.firstObject]
                                  direction:UIPageViewControllerNavigationDirectionForward
                                   animated:NO
                                 completion:nil];

    [self setupTabBar];
}

- (void)setupPageController
{
    _pageViewController = [[UIPageViewController alloc]
            initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
              navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                            options:nil];
    _pageViewController.delegate = self;
    CGRect frame = CGRectMake(0., 0., self.contentView.frame.size.width, self.contentView.frame.size.height);
    _pageViewController.view.frame = frame;
    _pageViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self.parentViewController addChildViewController:_pageViewController];
    [self.contentView addSubview:_pageViewController.view];
    [_pageViewController didMoveToParentViewController:self.parentViewController];
    [self.contentView sendSubviewToBack:_pageViewController.view];
}

- (void)setupTabBar
{
    UIColor *unselectedColor = UIColorFromRGB(color_dialog_buttons_dark);
    [self.tabBarView setItems:@[
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"rendering_value_browse_map_name")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_overview"]
                                                                    color:unselectedColor]
                                      tag:kOverviewPosition],
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"track")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_trip"]
                                                                    color:unselectedColor]
                                      tag:kSegmentsPosition],
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"shared_string_gpx_points")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_waypoint"]
                                                                    color:unselectedColor]
                                      tag:kPointsPosition],
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"actions")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_overflow_menu"]
                                                                    color:unselectedColor]
                                      tag:kActionsPosition]
            ]
                          animated:YES];

    self.tabBarView.selectedItem = self.tabBarView.items[0];
    self.tabBarView.itemWidth = (!self.isLandscape ? DeviceScreenWidth : DeviceScreenHeight < DeviceScreenWidth / 2 ? DeviceScreenHeight : DeviceScreenWidth / 2) / self.tabBarView.items.count;
    self.tabBarView.delegate = self;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (BOOL)hasBottomToolbar
{
    return YES;
}

- (BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)hasControlButtons
{
    return NO;
}

- (BOOL)needsLayoutOnModeChange
{
    return NO;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)hideButtons
{
    return YES;
}

- (UIView *)bottomToolBarView
{
    return self.tabBarView;
}

- (UIView *)navBar
{
    return self.navBarView;
}

- (NSString *)getTypeStr
{
    return nil;
}

- (id)getTargetObj
{
    return _gpx;
}

- (BOOL)offerMapDownload
{
    return NO;
}

-(CGFloat)getNavBarHeight
{
    return self.navBarView.frame.size.height;
}

- (CGFloat)getToolBarHeight
{
    CGFloat height = 0;
    if (_pageViewController.viewControllers[0] == _overviewViewController)
        height = [_overviewViewController getToolBarHeight];
    else if (_pageViewController.viewControllers[0] == _segmentsViewController)
        height = [_segmentsViewController getToolBarHeight];

    return height + self.tabBarView.layer.frame.size.height;
}

- (CGFloat)getHeaderHeight
{
    CGFloat height = 0;
    if (_pageViewController.viewControllers[0] == _overviewViewController)
        height = [_overviewViewController getHeaderHeight];
    else if (_pageViewController.viewControllers[0] == _segmentsViewController)
        height = [_segmentsViewController getHeaderHeight];

    return height + self.tabBarView.layer.frame.size.height;
}

- (BOOL)preHide
{
    [_mapViewController keepTempGpxTrackVisible];
    [[_app updateGpxTracksOnMapObservable] notifyEvent];
    return YES;
}

- (NSString *) getUniqueFileName:(NSString *)fileName inFolderPath:(NSString *)folderPath
{
    NSString *name = [fileName stringByDeletingPathExtension];
    NSString *newName = name;
    int i = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:[[folderPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"gpx"]])
    {
        newName = [NSString stringWithFormat:@"%@ %i", name, i++];
    }
    return [newName stringByAppendingPathExtension:@"gpx"];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
{
    NSString *oldPath = _gpx.gpxFilePath;
    NSString *oldName = _gpx.gpxFileName;
    NSString *sourcePath = [_app.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [_app.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = newFileName ? newFileName : oldName;
    newName = [self getUniqueFileName:newName inFolderPath:newFolderPath];
    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];

    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        [gpxDatabase updateGPXFolderName:newStoringPath oldFilePath:oldPath];
        [gpxDatabase save];
        [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];

        self.titleView.text = [newName stringByDeletingPathExtension];
        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
    }
    else
    {
        OAGPXDocument *gpxDoc = [[OAGPXDocument alloc] initWithGpxFile:sourcePath];
        OAGPXTrackAnalysis *analysis = [gpxDoc getAnalysis:0];
        [gpxDatabase addGpxItem:[newFolder stringByAppendingPathComponent:newName]
                                     title:newName
                                      desc:gpxDoc.metadata.desc
                                    bounds:gpxDoc.bounds
                                  analysis:analysis];

        if ([_settings.mapSettingVisibleGpx.get containsObject:oldPath])
            [_settings showGpx:@[newStoringPath]];
    }

    if (self.delegate)
        [self.delegate contentChanged];
}

#pragma mark - UIPageViewControllerDelegate

- (void)pageViewController:(UIPageViewController *)pageViewController
        didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
       transitionCompleted:(BOOL)completed
{
    if (pageViewController.viewControllers[0] == _overviewViewController)
        self.tabBarView.selectedItem = self.tabBarView.items[kOverviewPosition];
    else if (pageViewController.viewControllers[0] == _segmentsViewController)
        self.tabBarView.selectedItem = self.tabBarView.items[kSegmentsPosition];
    /*else if (pageViewController.viewControllers[0] == _pointsController)
        self.tabBarView.selectedItem = self.tabBarView.items[kPointsPosition];
    else if (pageViewController.viewControllers[0] == _actionsController)
        self.tabBarView.selectedItem = self.tabBarView.items[kActionsPosition];*/
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSInteger selectedTag = tabBar.selectedItem.tag;
    NSLog(@"%ld",(long) selectedTag);

    if ([_controllers indexOfObject:_pageViewController.viewControllers[0]] == kOverviewPosition)
    {
        if (item.tag > kOverviewPosition)
            [_pageViewController setViewControllers:@[_segmentsViewController]
                                          direction:UIPageViewControllerNavigationDirectionForward
                                           animated:YES
                                         completion:nil];
    }
    else if ([_controllers indexOfObject:_pageViewController.viewControllers[0]] == kSegmentsPosition)
    {
        [_pageViewController setViewControllers:@[item.tag > kSegmentsPosition ? _segmentsViewController : _overviewViewController] direction:item.tag > kSegmentsPosition ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
            didEndSendingToApplication:(NSString *)application
{
    if (_isCurrentTrack && _exportFilePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:_exportFilePath error:nil];
        _exportFilePath = nil;
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    if ([application isEqualToString:@"net.osmand.maps"])
    {
        [_exportController dismissMenuAnimated:YES];
        _exportFilePath = nil;
        _exportController = nil;

        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
                initWithFileName:_gpx.gpxFilePath.lastPathComponent.stringByDeletingPathExtension
                        filePath:_gpx.gpxFilePath
                       showOnMap:YES
                 simplifiedTrack:YES];

        saveTrackViewController.delegate = self;
        [OARootViewController.instance presentViewController:saveTrackViewController animated:YES completion:nil];
    }
}

#pragma mark - OAOverviewTrackMenuViewControllerDelegate

- (void)overviewContentChanged
{
    if (self.delegate)
        [self.delegate contentChanged];
}

- (BOOL)onShowHidePressed
{
    if (_isShown)
        [_settings hideGpx:@[_gpx.gpxFilePath] update:YES];
    else
        [_settings showGpx:@[_gpx.gpxFilePath] update:YES];

    return _isShown = [_settings.mapSettingVisibleGpx.get containsObject:_gpx.gpxFilePath];
}

- (void)onColorPressed
{
    OAEditGPXColorViewController *trackColorViewController =
            [[OAEditGPXColorViewController alloc] initWithColorValue:_gpx.color
                                                    colorsCollection:_gpxColorCollection];
    trackColorViewController.delegate = self;
    [self.navController pushViewController:trackColorViewController animated:YES];
}

- (void)onExportPressed
{
    if (_isCurrentTrack)
    {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];

        NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
        [simpleFormat setDateFormat:@"HH-mm_EEE"];

        _exportFileName = [NSString stringWithFormat:@"%@_%@",
                [fmt stringFromDate:[NSDate date]],
                [simpleFormat stringFromDate:[NSDate date]]];
        _exportFilePath = [NSString stringWithFormat:@"%@/%@.gpx",
                NSTemporaryDirectory(),
                _exportFileName];

        [_savingHelper saveCurrentTrack:_exportFilePath];
    }
    else
    {
        _exportFileName = _gpx.gpxFileName;
        _exportFilePath = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath];
    }

    _exportController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:_exportFilePath]];
    _exportController.UTI = @"com.topografix.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero
                                           inView:self.navController.view
                                         animated:YES];
}

- (void)onNavigationPressed
{
    if ([_doc getNonEmptySegmentsCount] > 1)
    {
        OATrackSegmentsViewController *trackSegmentViewController = [[OATrackSegmentsViewController alloc] initWithFile:_doc];
        trackSegmentViewController.delegate = self;
        [OARootViewController.instance presentViewController:trackSegmentViewController animated:YES completion:nil];
    }
    else
    {
        if (![[OARoutingHelper sharedInstance] isFollowingMode])
            [_mapPanelViewController.mapActions stopNavigationWithoutConfirm];

        [_mapPanelViewController.mapActions enterRoutePlanningModeGivenGpx:_gpx
                                                                      from:nil
                                                                  fromName:nil
                                            useIntermediatePointsByDefault:YES
                                                                showDialog:YES];
        [_mapPanelViewController hideTargetPointMenu];
    }
}

#pragma mark - OAEditGPXColorViewControllerDelegate

-(void)trackColorChanged:(NSInteger)colorIndex
{
    OAGPXTrackColor *gpxColor = [_gpxColorCollection getAvailableGPXColors][colorIndex];
    _gpx.color = gpxColor.colorValue;
    [[OAGPXDatabase sharedDb] save];
    [[_app mapSettingsChangeObservable] notifyEvent];
}

#pragma mark - OASaveTrackViewControllerDelegate

- (void)onSaveAsNewTrack:(NSString *)fileName
               showOnMap:(BOOL)showOnMap
         simplifiedTrack:(BOOL)simplifiedTrack
{
    [self copyGPXToNewFolder:fileName.stringByDeletingLastPathComponent
             renameToNewName:[fileName.lastPathComponent
                     stringByAppendingPathExtension:@"gpx"]
          deleteOriginalFile:NO];
}

#pragma mark - OASegmentSelectionDelegate

- (void)onSegmentSelected:(NSInteger)position gpx:(OAGPXDocument *)gpx
{
    [OAAppSettings.sharedManager.gpxRouteSegment set:position];

    [[OARootViewController instance].mapPanel.mapActions setGPXRouteParamsWithDocument:_doc path:_doc.path];
    [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
    [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];

    OAGPXRouteParamsBuilder *paramsBuilder = OARoutingHelper.sharedInstance.getCurrentGPXRoute;
    if (paramsBuilder)
    {
        [paramsBuilder setSelectedSegment:position];
        NSArray<CLLocation *> *ps = [paramsBuilder getPoints];
        if (ps.count > 0)
        {
            OATargetPointsHelper *tg = [OATargetPointsHelper sharedInstance];
            [tg clearStartPoint:NO];
            CLLocation *loc = ps.lastObject;
            [tg navigateToPoint:loc updateRoute:YES intermediate:-1];
        }
    }

    [[OARootViewController instance].mapPanel.mapActions stopNavigationWithoutConfirm];
    [[OARootViewController instance].mapPanel.mapActions enterRoutePlanningModeGivenGpx:_doc path:_gpx.gpxFilePath from:nil fromName:nil useIntermediatePointsByDefault:YES showDialog:YES];
    [[OARootViewController instance].mapPanel hideTargetPointMenu];
}

@end
