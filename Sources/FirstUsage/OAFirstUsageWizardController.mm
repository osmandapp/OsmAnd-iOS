//
//  OAFirstUsageWizardController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/11/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAFirstUsageWizardController.h"
#import "OAManageResourcesViewController.h"
#import "OsmAndApp.h"
#import "OAResourcesUIHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAOcbfHelper.h"
#import "OAWorldRegion.h"
#import "Localization.h"

#import <Reachability.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

const static int PROGRESS_ON_MARGIN = 29;
const static int PROGRESS_OFF_MARGIN = 8;

typedef enum
{
    SEARCH_LOCATION,
    NO_INTERNET,
    NO_LOCATION,
    SEARCH_MAP,
    MAP_FOUND,
    MAP_DOWNLOAD,
} WizardType;

typedef enum
{
    ALERT_SKIP,
} AlertType;


@interface OAFirstUsageWizardController ()<UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnSkip;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progress1DivTopMarginConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progress2DivTopMarginConstraint;

@property (strong, nonatomic) IBOutlet UIView *viewLocationNotFound;
@property (weak, nonatomic) IBOutlet UILabel *lbLocationNotFound;
@property (weak, nonatomic) IBOutlet UIButton *btnSearchLocation;

@property (strong, nonatomic) IBOutlet UIView *viewNoInet;
@property (weak, nonatomic) IBOutlet UILabel *lbNoInet;
@property (weak, nonatomic) IBOutlet UILabel *lbNoInteDesc;
@property (weak, nonatomic) IBOutlet UIButton *btnTryAgain;

@property (strong, nonatomic) IBOutlet UIView *viewSearchingLocation;
@property (weak, nonatomic) IBOutlet UILabel *lbSearchingLocation;
@property (weak, nonatomic) IBOutlet UIButton *btnSearchingLocation;

@property (strong, nonatomic) IBOutlet UIView *viewSearchingMap;
@property (weak, nonatomic) IBOutlet UILabel *lbSearchingMap;
@property (weak, nonatomic) IBOutlet UIButton *btnSearchingMap;

@property (strong, nonatomic) IBOutlet UIView *viewDownloadMap;
@property (weak, nonatomic) IBOutlet UILabel *lbDownloadMapName;
@property (weak, nonatomic) IBOutlet UILabel *lbDownloadMapSize;
@property (weak, nonatomic) IBOutlet UIButton *btnDownload;
@property (weak, nonatomic) IBOutlet UIButton *btnSelectMap;

@property (strong, nonatomic) IBOutlet UIView *viewProgress;

@property (weak, nonatomic) IBOutlet UIImageView *imgMapIcon1;
@property (weak, nonatomic) IBOutlet UILabel *lbMapName1;
@property (weak, nonatomic) IBOutlet UILabel *lbMapSize1;
@property (weak, nonatomic) IBOutlet UIButton *btnRestart1;
@property (weak, nonatomic) IBOutlet UIProgressView *progress1;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel1;
@property (weak, nonatomic) IBOutlet UIView *viewDivider;

@property (weak, nonatomic) IBOutlet UIImageView *imgMapIcon2;
@property (weak, nonatomic) IBOutlet UILabel *lbMapName2;
@property (weak, nonatomic) IBOutlet UILabel *lbMapSize2;
@property (weak, nonatomic) IBOutlet UIButton *btnRestart2;
@property (weak, nonatomic) IBOutlet UIProgressView *progress2;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel2;
@property (weak, nonatomic) IBOutlet UIButton *btnGoToMap;

@end

@implementation OAFirstUsageWizardController
{
    OsmAndAppInstance _app;
    CLLocation *_location;
    BOOL _searchLocationByIp;
    OAAutoObserverProxy* _locationServicesUpdateFirstTimeObserver;
    OAAutoObserverProxy* _repositoryUpdatedObserver;

    //WorldRegion localDownloadRegion;
    OARepositoryResourceItem *_localMapIndexItem;
    OARepositoryResourceItem *_baseMapIndexItem;
    NSMutableArray<OARepositoryResourceItem *> *_indexItems;
    BOOL _firstMapDownloadCancelled;
    BOOL _secondMapDownloadCancelled;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    
    WizardType _wizardType;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _app = [OsmAndApp instance];

    _repositoryUpdatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onRepositoryUpdated:withKey:)
                                                            andObserve:_app.resourcesRepositoryUpdatedObservable];

    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];

    // Init wizard
    _lbTitle.text = OALocalizedString(@"download_map");
    _lbDescription.text = OALocalizedString(@"first_usage_wizard_desc");
    [_btnSkip setTitle:OALocalizedString(@"intro_skip") forState:UIControlStateNormal];
    
    // Init no location view
    _lbLocationNotFound.text = OALocalizedString(@"location_not_found");
    [_btnSearchLocation setTitle:OALocalizedString(@"search_my_location") forState:UIControlStateNormal];

    // Init no inet view
    _lbNoInet.text = OALocalizedString(@"no_inet_connection");
    _lbNoInteDesc.text = OALocalizedString(@"no_inet_connection_desc_map");
    [_btnTryAgain setTitle:OALocalizedString(@"try_again") forState:UIControlStateNormal];

    // Init searching location view
    _lbSearchingLocation.text = OALocalizedString(@"search_location");
    [_btnSearchingLocation setTitle:OALocalizedString(@"download") forState:UIControlStateNormal];

    // Init searching map view
    _lbSearchingMap.text = OALocalizedString(@"search_map");
    [_btnSearchingMap setTitle:OALocalizedString(@"download") forState:UIControlStateNormal];

    // Init download map view
    [self updateDownloadButtonLayer];
    [_btnDownload setTitle:OALocalizedString(@"download") forState:UIControlStateNormal];
    [_btnSelectMap setTitle:OALocalizedString(@"search_another_country") forState:UIControlStateNormal];

    // Init progress view
    _btnRestart1.hidden = YES;
    _btnRestart2.hidden = YES;
    [_btnGoToMap setTitle:OALocalizedString(@"show_region_on_map_go") forState:UIControlStateNormal];
    
    [self startWizard];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    if (_repositoryUpdatedObserver && [_repositoryUpdatedObserver isAttached])
        [_repositoryUpdatedObserver detach];
}

- (void) clearSubViews
{
    for (UIView *subview in _cardView.subviews)
        [subview removeFromSuperview];
}

- (void) showProgressView
{
    [self showCard:_viewProgress];
}

-(void)viewWillLayoutSubviews
{
    if (_cardView.subviews.count > 0)
    {
        [_cardView.subviews[0] layoutIfNeeded];
        [self resizeToFitSubviews:_cardView.subviews[0]];
        _heightConstraint.constant = _cardView.subviews[0].frame.size.height;
    }
}

- (void)updateDownloadButtonLayer
{
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_btnDownload.bounds byRoundingCorners:(UIRectCornerBottomLeft | UIRectCornerBottomRight) cornerRadii:CGSizeMake(4.0, 4.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.view.bounds;
    maskLayer.path  = maskPath.CGPath;
    _btnDownload.layer.mask = maskLayer;
}

- (void)showCard:(UIView *)cardView
{
    [self clearSubViews];
    [_cardView addSubview:cardView];
}

-(void)resizeToFitSubviews:(UIView *)source
{
    float h = 0;
    for (UIView *v in source.subviews)
    {
        float fh = v.frame.origin.y + v.frame.size.height;
        h = MAX(fh, h);
    }
    source.frame = CGRectMake(source.frame.origin.x, source.frame.origin.y, _cardView.frame.size.width, h);
    if (source == _viewDownloadMap)
        [self updateDownloadButtonLayer];
}

- (IBAction)skipPress:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"skip_map_downloading") message:OALocalizedString(@"skip_map_downloading_desc") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles:OALocalizedString(@"intro_skip"), OALocalizedString(@"shared_string_select"), nil];
    alert.tag = ALERT_SKIP;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag)
    {
        case ALERT_SKIP:
            if (buttonIndex != alertView.cancelButtonIndex)
            {
                if (buttonIndex == 1)
                {   // skip
                    [self closeWizard];
                }
                else
                {   // select
                    [self selectMapPress:nil];
                }
            }
            break;
            
        default:
            break;
    }
}

- (void) closeWizard
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void) startWizard
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
    {
        [self startNoInternetWizard];
    }
    else if (!_location)
    {
        [self findLocation:YES];
    }
    else
    {
        [self startSearchMapWizard];
    }
}

- (void) startSearchLocationWizard:(BOOL)searchByIp
{
    _searchLocationByIp = searchByIp;
    [self initWizard:SEARCH_LOCATION];
    [self startWizard:SEARCH_LOCATION];
}

- (void) startNoInternetWizard
{
    [self initWizard:NO_INTERNET];
    [self startWizard:NO_INTERNET];
}

- (void) startSearchMapWizard
{
    [self initWizard:SEARCH_MAP];
    [self startWizard:SEARCH_MAP];
}

- (void) startMapDownloadWizard
{
    [self initWizard:MAP_DOWNLOAD];
    [self startWizard:MAP_DOWNLOAD];
}

- (void) startNoLocationWizard
{
    [self initWizard:NO_LOCATION];
}

- (void) startMapFoundFragment
{
    [self initWizard:MAP_FOUND];
    [self startWizard:MAP_FOUND];
}

- (void) initWizard:(WizardType)wizardType
{
    _wizardType = wizardType;
    switch (wizardType)
    {
        case SEARCH_LOCATION:
        {
            [self showCard:_viewSearchingLocation];
            break;
        }
        case NO_INTERNET:
        {
            [self showCard:_viewNoInet];
            break;
        }
        case NO_LOCATION:
        {
            [self showCard:_viewLocationNotFound];
            break;
        }
        case SEARCH_MAP:
        {
            [self showCard:_viewSearchingMap];
            break;
        }
        case MAP_FOUND:
        {
            OARepositoryResourceItem *indexItem = _localMapIndexItem ? _localMapIndexItem : _baseMapIndexItem;
            if (indexItem)
            {
                _lbDownloadMapName.text = indexItem.title;
                _lbDownloadMapSize.text = [NSByteCountFormatter stringFromByteCount:indexItem.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
            }
            
            [self showCard:_viewDownloadMap];
            break;
        }
        case MAP_DOWNLOAD:
        {
            _indexItems = [NSMutableArray array];
            if (_localMapIndexItem)
                [_indexItems addObject:_localMapIndexItem];
            if (_baseMapIndexItem)
                [_indexItems addObject:_baseMapIndexItem];
            
            if (_indexItems.count > 0)
            {
                OARepositoryResourceItem *item = _indexItems[0];
                _lbMapName1.text = item.title;
                _lbMapSize1.text = [NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
                if (_firstMapDownloadCancelled)
                {
                    _progress1.hidden = YES;
                    _btnCancel1.hidden = YES;
                    _btnRestart1.hidden = _firstMapDownloadCancelled ? NO : YES;
                }
            }
            else
            {
                _imgMapIcon1.hidden = YES;
                _lbMapName1.hidden = YES;
                _lbMapSize1.hidden = YES;
                _progress1.hidden = YES;
                _btnCancel1.hidden = YES;
                _btnRestart1.hidden = YES;
                _viewDivider.hidden = YES;
            }
            if (_indexItems.count > 1)
            {
                OARepositoryResourceItem *item = _indexItems[1];
                _lbMapName2.text = item.title;
                _lbMapSize2.text = [NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
                if (_secondMapDownloadCancelled)
                {
                    _progress2.hidden = YES;
                    _btnCancel2.hidden = YES;
                    _btnRestart2.hidden = _secondMapDownloadCancelled ? NO : YES;
                }
            }
            else
            {
                _imgMapIcon2.hidden = YES;
                _lbMapName2.hidden = YES;
                _lbMapSize2.hidden = YES;
                _progress2.hidden = YES;
                _btnCancel2.hidden = YES;
                _btnRestart2.hidden = YES;
                _viewDivider.hidden = YES;
            }
            
            [self showCard:_viewProgress];
            break;
        }
    }
}

- (void) startWizard:(WizardType)wizardType
{
    switch (wizardType)
    {
        case SEARCH_LOCATION:
            if (_searchLocationByIp)
            {
                NSString *ver = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
                /*
                try {
                    pms.put("aid", Secure.getString(app.getContentResolver(), Secure.ANDROID_ID));
                } catch (Exception e) {
                    e.printStackTrace();
                 }
                 */
                
                NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://osmand.net/api/geo-ip?version=%@", ver]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

                    if (response)
                    {
                        try
                        {
                            NSMutableDictionary *map = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                            if (map)
                            {
                                double latitude = [[map objectForKey:@"latitude"] doubleValue];
                                double longitude = [[map objectForKey:@"longitude"] doubleValue];
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    if (latitude == 0 && longitude == 0)
                                    {
                                        [self startNoLocationWizard];
                                    }
                                    else
                                    {
                                        _location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                                        [self startSearchMapWizard];
                                    }
                                });
                            }
                            else
                            {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [self startNoLocationWizard];
                                });
                            }
                        }
                        catch (NSException *e)
                        {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [self startNoLocationWizard];
                            });
                        }
                    }
                    else
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [self startNoLocationWizard];
                        });
                    }
                }];
                
                [downloadTask resume];
            }
            else
            {
                if ([_app.locationServices allowed])
                {
                    _location = _app.locationServices.lastKnownLocation;
                    if (!_location)
                    {
                        _locationServicesUpdateFirstTimeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                                             withHandler:@selector(onLocationServicesFirstTimeUpdate)
                                                                                              andObserve:_app.locationServices.updateFirstTimeObserver];
                    }
                    else
                    {
                        [self onLocationServicesFirstTimeUpdate];
                    }
                    [self performSelector:@selector(onLocationNotFound) withObject:nil afterDelay:10.0];
                }
            }
            break;
        case NO_INTERNET:
            break;
        case NO_LOCATION:
            break;
        case SEARCH_MAP:
            if (!_app.resourcesManager->isRepositoryAvailable())
            {
                if (!_app.isRepositoryUpdating &&
                    [Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
                {
                    [self updateRepository];
                }
                else if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
                {
                    [self startNoInternetWizard];
                }
            }
            else
            {
                [self searchMap];
            }
            break;
        case MAP_FOUND:
            break;
        case MAP_DOWNLOAD:
            if (_indexItems.count > 0)
                [self startDownloadIndex:0];
            if (_indexItems.count > 1)
                [self startDownloadIndex:1];

            break;
    }
}

- (BOOL) startDownloadIndex:(int)itemIndex
{
    BOOL downloadStarted = NO;
    if (itemIndex == 0 && _indexItems.count > 0)
    {
        OARepositoryResourceItem *item = _indexItems[0];
        if ([_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]].count == 0 && !_firstMapDownloadCancelled)
        {
            [self startDownload:item];
            downloadStarted = YES;
        }
    }
    else if (itemIndex == 1 && _indexItems.count > 1)
    {
        OARepositoryResourceItem *item = _indexItems[1];
        if ([_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]].count == 0 && !_secondMapDownloadCancelled)
        {
            [self startDownload:item];
            downloadStarted = YES;
        }
    }
    return downloadStarted;
}

- (void)onLocationServicesFirstTimeUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSThread cancelPreviousPerformRequestsWithTarget:self selector:@selector(startNoLocationWizard) object:nil];
        if (!_location)
            _location = _app.locationServices.lastKnownLocation;
        if (_location)
            [self startSearchMapWizard];
    });
}

- (void)onLocationNotFound
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_locationServicesUpdateFirstTimeObserver && [_locationServicesUpdateFirstTimeObserver isAttached])
            [_locationServicesUpdateFirstTimeObserver detach];
        
        [self startNoLocationWizard];
    });
}

- (void)updateRepository
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [OAOcbfHelper downloadOcbfIfUpdated];
        [_app loadWorldRegions];
        [_app startRepositoryUpdateAsync:NO];
    });
}

- (void)onRepositoryUpdated:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_wizardType == SEARCH_MAP)
            [self searchMap];
    });
}

- (IBAction)searchLocation:(id)sender
{
    [self findLocation:NO];
}

- (IBAction)tryAgainPress:(id)sender
{
    [self startWizard];
}

- (void) searchMap
{
    if (_location)
    {
        if ([OAManageResourcesViewController lackOfResources])
            [OAManageResourcesViewController prepareData];

        CLLocationCoordinate2D latLon = _location.coordinate;
        const auto rm = _app.resourcesManager;
        NSMutableArray<OAWorldRegion *> *mapRegions = [[_app.worldRegion queryAtLat:latLon.latitude lon:latLon.longitude] mutableCopy];
        
        OAWorldRegion *selectedRegion = nil;
        if (mapRegions.count > 0)
        {
            [mapRegions enumerateObjectsUsingBlock:^(OAWorldRegion * _Nonnull region, NSUInteger idx, BOOL * _Nonnull stop) {
                if (![region contain:latLon.latitude lon:latLon.longitude])
                    [mapRegions removeObject:region];
            }];
            
            double smallestArea = DBL_MAX;
            for (OAWorldRegion *region : mapRegions)
            {
                double area = [region getArea];
                if (area < smallestArea)
                {
                    smallestArea = area;
                    selectedRegion = region;
                }
            }
        }
        
        if (selectedRegion)
        {
            NSArray<NSString *> *ids = [OAManageResourcesViewController getResourcesInRepositoryIdsByRegion:selectedRegion];
            if (ids.count > 0)
            {
                for (NSString *resourceId in ids)
                {
                    const auto resource = rm->getResourceInRepository(QString::fromNSString(resourceId));
                    if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                    {
                        OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
                        item.resourceId = resource->id;
                        item.resourceType = resource->type;
                        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                                 inRegion:selectedRegion
                                                           withRegionName:YES
                                                         withResourceType:NO];
                        item.resource = resource;
                        item.downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
                        item.size = resource->size;
                        item.sizePkg = resource->packageSize;
                        item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];
                        item.worldRegion = selectedRegion;
                        item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];
                        _localMapIndexItem = item;
                        break;
                    }
                }
            }
        }
        
        const auto resource = _app.resourcesManager->getResourceInRepository(kWorldBasemapKey);
        OARepositoryResourceItem* item = [[OARepositoryResourceItem alloc] init];
        item.resourceId = resource->id;
        item.resourceType = resource->type;
        item.title = [OAResourcesUIHelper titleOfResource:resource
                                                 inRegion:_app.worldRegion
                                           withRegionName:YES
                                         withResourceType:NO];
        item.resource = resource;
        item.downloadTask = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:resource->id.toNSString()]] firstObject];
        item.size = resource->size;
        item.sizePkg = resource->packageSize;
        item.worldRegion = _app.worldRegion;
        item.date = [NSDate dateWithTimeIntervalSince1970:(resource->timestamp / 1000)];

        _baseMapIndexItem = item;
        
        if (_localMapIndexItem || _baseMapIndexItem)
            [self startMapFoundFragment];
        else
            [self closeWizard];
    }
    else
    {
        [self startNoLocationWizard];
    }
}

- (IBAction)downloadPress:(id)sender
{
    uint64_t spaceNeededForLocal = _localMapIndexItem.sizePkg + _localMapIndexItem.size;
    uint64_t spaceNeededForBase = _baseMapIndexItem.sizePkg + _baseMapIndexItem.size;

    BOOL spaceEnoughForBoth = _app.freeSpaceAvailableOnDevice >= spaceNeededForLocal + spaceNeededForBase;
    BOOL spaceEnoughForLocal = _app.freeSpaceAvailableOnDevice >= spaceNeededForLocal;
    if (!spaceEnoughForBoth)
    {
        _baseMapIndexItem = nil;
    }
    if (spaceEnoughForLocal)
    {
        [self startMapDownloadWizard];
    }
    else
    {
        NSString *resourceName = [OAResourcesUIHelper titleOfResource:_localMapIndexItem.resource
                                                             inRegion:_localMapIndexItem.worldRegion
                                                       withRegionName:YES
                                                     withResourceType:YES];
        [OAResourcesUIHelper showNotEnoughSpaceAlertFor:resourceName withSize:spaceEnoughForLocal asUpdate:NO];
    }
}

- (IBAction)selectMapPress:(id)sender
{
    OAManageResourcesViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    resourcesViewController.openFromSplash = YES;
    [self.navigationController pushViewController:resourcesViewController animated:YES];
}

- (IBAction)restart1Press:(id)sender
{
    if (_indexItems.count > 0)
    {
        OARepositoryResourceItem *item = _indexItems[0];
        if (item && [_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]].count == 0 && _firstMapDownloadCancelled)
        {
            _progress1.hidden = NO;
            _btnCancel1.hidden = NO;
            _btnRestart1.hidden = YES;
            [self startDownload:item];
            _firstMapDownloadCancelled = NO;
            _progress1DivTopMarginConstraint.constant = PROGRESS_ON_MARGIN;
            [self.view setNeedsLayout];
        }
    }
}

- (IBAction)cancel1Press:(id)sender
{
    if (_indexItems.count > 0)
    {
        OARepositoryResourceItem *item = _indexItems[0];
        id<OADownloadTask> task = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]] firstObject];
        if (task)
            [task stop];

        _firstMapDownloadCancelled = YES;
        _lbMapSize1.text = [NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
        _progress1.hidden = YES;
        _progress1.progress = 0;
        _btnCancel1.hidden = YES;
        _btnRestart1.hidden = NO;
        _progress1DivTopMarginConstraint.constant = PROGRESS_OFF_MARGIN;
        [self.view setNeedsLayout];
    }
}

- (IBAction)restart2Press:(id)sender
{
    if (_indexItems.count > 1)
    {
        OARepositoryResourceItem *item = _indexItems[1];
        if (item && [_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]].count == 0 && _secondMapDownloadCancelled)
        {
            _progress2.hidden = NO;
            _btnCancel2.hidden = NO;
            _btnRestart2.hidden = YES;
            [self startDownload:item];
            _secondMapDownloadCancelled = NO;
            _progress2DivTopMarginConstraint.constant = PROGRESS_ON_MARGIN;
            [self.view setNeedsLayout];
        }
    }
}

- (IBAction)cancel2Press:(id)sender
{
    if (_indexItems.count > 1)
    {
        OARepositoryResourceItem *item = _indexItems[1];
        id<OADownloadTask> task = [[_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]] firstObject];
        if (task)
            [task stop];

        _secondMapDownloadCancelled = YES;
        _lbMapSize2.text = [NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile];
        _progress2.hidden = YES;
        _progress2.progress = 0;
        _btnCancel2.hidden = YES;
        _btnRestart2.hidden = NO;
        _progress2DivTopMarginConstraint.constant = PROGRESS_OFF_MARGIN;
        [self.view setNeedsLayout];
    }
}

- (IBAction)goToMapPress:(id)sender
{
    if (_location)
    {
        OsmAnd::PointI locationI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_location.coordinate.latitude, _location.coordinate.longitude));
        Point31 point31;
        point31.x = locationI.x;
        point31.y = locationI.y;
        _app.data.mapLastViewedState.target31 = point31;
        _app.data.mapLastViewedState.zoom = 13.0;

        [self closeWizard];
    }
}

- (void) startDownload:(OARepositoryResourceItem *)item
{
    NSString *resourceName = [OAResourcesUIHelper titleOfResource:item.resource
                                                         inRegion:item.worldRegion
                                                   withRegionName:YES
                                                 withResourceType:YES];
    
    [OAResourcesUIHelper startBackgroundDownloadOf:item.resource resourceName:resourceName];
}

- (void) findLocation:(BOOL)searchLocationByIp
{
    if (searchLocationByIp)
    {
        [self startSearchLocationWizard:YES];
    }
    else if (!_app.locationServices.denied)
    {
        CLLocation *loc = _app.locationServices.lastKnownLocation;
        if (loc)
        {
            [self startSearchLocationWizard:NO];
        }
        else
        {
            _location = loc;
            [self startSearchMapWizard];
        }
    }
    else
    {
        [self startSearchLocationWizard:NO];
    }
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

        if (_indexItems.count > 0 && [_indexItems[0].resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            NSMutableString *progressStr = [NSMutableString string];
            [progressStr appendString:[f stringFromByteCount:(_indexItems[0].size * [value floatValue])]];
            [progressStr appendString:@" "];
            [progressStr appendString:OALocalizedString(@"shared_string_of")];
            [progressStr appendString:@" "];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:_indexItems[0].size countStyle:NSByteCountFormatterCountStyleFile]];
            _lbMapSize1.text = progressStr;
            [_progress1 setProgress:[value floatValue]];
        }
        if (_indexItems.count > 1 && [_indexItems[1].resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            NSMutableString *progressStr = [NSMutableString string];
            [progressStr appendString:[f stringFromByteCount:(_indexItems[1].size * [value floatValue])]];
            [progressStr appendString:@" "];
            [progressStr appendString:OALocalizedString(@"shared_string_of")];
            [progressStr appendString:@" "];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:_indexItems[1].size countStyle:NSByteCountFormatterCountStyleFile]];
            _lbMapSize2.text = progressStr;
            [_progress2 setProgress:[value floatValue]];
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
        
        if (_indexItems.count > 0)
        {
            _lbMapSize1.text = [NSByteCountFormatter stringFromByteCount:_indexItems[0].size countStyle:NSByteCountFormatterCountStyleFile];
        }
        if (_indexItems.count > 1)
        {
            _lbMapSize2.text = [NSByteCountFormatter stringFromByteCount:_indexItems[1].size countStyle:NSByteCountFormatterCountStyleFile];
        }

        if (task.progressCompleted < 1.0)
        {
            if ([_app.downloadsManager.keysOfDownloadTasks count] > 0)
            {
                id<OADownloadTask> nextTask = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks firstObject]];
                [nextTask resume];
            }
        }
        else
        {
            if (_indexItems.count > 0 && [_indexItems[0].resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
            {
                _progress1.hidden = YES;
                _btnCancel1.hidden = YES;
                _btnRestart1.hidden = YES;
                _progress1DivTopMarginConstraint.constant = PROGRESS_OFF_MARGIN;
                [self.view setNeedsLayout];
            }
            if (_indexItems.count > 1 && [_indexItems[1].resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
            {
                _progress2.hidden = YES;
                _btnCancel2.hidden = YES;
                _btnRestart2.hidden = YES;
                _progress2DivTopMarginConstraint.constant = PROGRESS_OFF_MARGIN;
                [self.view setNeedsLayout];
            }
        }
        
    });
}

@end
