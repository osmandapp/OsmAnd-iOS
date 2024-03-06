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
#import "OsmAnd_Maps-Swift.h"
#import "SafariServices/SafariServices.h"
#import "GeneratedAssetSymbols.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "OACloudIntroductionViewController.h"
#import "OACloudBackupViewController.h"
#import "GeneratedAssetSymbols.h"

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

@interface OAFirstUsageWizardController () <UITextViewDelegate, SFSafariViewControllerDelegate, UIDocumentPickerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *lbTitle;
@property (weak, nonatomic) IBOutlet UIButton *btnSkip;
@property (weak, nonatomic) IBOutlet UIButton *navBarMenuButton;
@property (weak, nonatomic) IBOutlet UILabel *lbDescription;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIView *cardView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *heightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *progress1DivTopMarginConstraint;

@property (strong, nonatomic) IBOutlet UIView *viewLocationNotFound;
@property (weak, nonatomic) IBOutlet UILabel *lbLocationNotFound;
@property (weak, nonatomic) IBOutlet UIButton *btnSearchLocation;

@property (strong, nonatomic) IBOutlet UIView *viewNoInet;
@property (weak, nonatomic) IBOutlet UILabel *lbNoInet;
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

@property (strong, nonatomic) IBOutlet UIView *viewProgress;

@property (weak, nonatomic) IBOutlet UIImageView *imgMapIcon1;
@property (weak, nonatomic) IBOutlet UILabel *lbMapName1;
@property (weak, nonatomic) IBOutlet UIProgressView *progress1;
@property (weak, nonatomic) IBOutlet UIView *viewDivider;

@property (weak, nonatomic) IBOutlet UIButton *btnGoToMap;
@property (weak, nonatomic) IBOutlet UITextView *bottomTextView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *logoHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *logoWidthConstraint;
@property (weak, nonatomic) IBOutlet UIStackView *logoTitleStackView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoTitleStackViewTopConstraint;
@property (weak, nonatomic) IBOutlet UIButton *userLocationButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cardViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *privacyPolicyLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLeadingConstraint;
@property (nonatomic, strong) NSByteCountFormatter *byteCountFormatter;

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
    NSMutableArray<OARepositoryResourceItem *> *_indexItems;
    BOOL _mapDownloadCancelled;
    
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
    _lbTitle.text = OALocalizedString(@"shared_string_download_map");
    _lbDescription.text = OALocalizedString(@"first_usage_wizard_desc");
    _lbDescription.font = [UIFont scaledSystemFontOfSize:14.];
    [_btnSkip setTitle:OALocalizedString(@"skip_download") forState:UIControlStateNormal];
    _btnSkip.titleLabel.font = [UIFont scaledSystemFontOfSize:14.];
    
    // Init no location view
    _lbLocationNotFound.text = OALocalizedString(@"location_not_found");
    [_btnSearchLocation setTitle:OALocalizedString(@"search_my_location") forState:UIControlStateNormal];

    // Init no inet view
    _lbNoInet.text = OALocalizedString(@"no_inet_connection");
    [_btnTryAgain setTitle:OALocalizedString(@"try_again") forState:UIControlStateNormal];

    // Init searching location view
    _lbSearchingLocation.text = OALocalizedString(@"search_location");
    [_btnSearchingLocation setTitle:OALocalizedString(@"shared_string_download") forState:UIControlStateNormal];

    // Init searching map view
    _lbSearchingMap.text = OALocalizedString(@"search_map");
    [_btnSearchingMap setTitle:OALocalizedString(@"shared_string_download") forState:UIControlStateNormal];

    // Init download map view;
    [_btnDownload setTitle:OALocalizedString(@"shared_string_download") forState:UIControlStateNormal];

    // Init progress view
    [_btnGoToMap setTitle:OALocalizedString(@"show_region_on_map_go") forState:UIControlStateNormal];
    
    _bottomTextView.textContainerInset = UIEdgeInsetsZero;
    _bottomTextView.textContainer.lineFragmentPadding = 0;
    _bottomTextView.textContainer.maximumNumberOfLines = 0;
    _bottomTextView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    _bottomTextView.userInteractionEnabled = YES;
    _bottomTextView.editable = NO;
    _bottomTextView.delegate = self;
    
    NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithData:[OALocalizedString(@"map_download_privacy_descr") dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                             NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                        documentAttributes:nil error:nil];
    [titleStr addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] range:NSMakeRange(0, titleStr.length)];
    [titleStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorSecondary] range:NSMakeRange(0, titleStr.length)];
    [titleStr enumerateAttributesInRange:NSMakeRange(0, titleStr.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        if (attrs[@"NSLink"])
        {
            NSString *link = attrs[@"NSLink"];
            [titleStr removeAttribute:attrs[@"NSLink"] range:range];
            [titleStr addAttribute:NSLinkAttributeName value:link  range:range];
            [titleStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorActive] range:range];
        }
    }];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentNatural;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    [titleStr addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, titleStr.length)];
    NSDictionary *linkAttributes = @{NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorActive],
                                     NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline],
                                     NSUnderlineStyleAttributeName: @(NSUnderlineStyleNone)
    };
    _bottomTextView.linkTextAttributes = linkAttributes;
    _bottomTextView.attributedText = titleStr;
    
    self.navBarMenuButton.showsMenuAsPrimaryAction = YES;
    self.navBarMenuButton.menu = [self rightNavButtonMenuItems];
    
    [self startWizard];
    [self configureToolbar];
    [self configureUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)configureUI
{
    BOOL isLandscape = OAUtilities.isLandscape;
    [self.navigationController setToolbarHidden:isLandscape];
    [self.btnSkip setHidden:!isLandscape];
    
    self.logoHeightConstraint.constant = isLandscape ? 48 : 60;
    self.logoWidthConstraint.constant = self.logoHeightConstraint.constant;
    _lbTitle.font = [UIFont scaledSystemFontOfSize:isLandscape ? 28 : 34];
    if (isLandscape)
    {
        self.privacyPolicyLeadingConstraint.constant = 40;
        self.logoTitleStackView.axis = UILayoutConstraintAxisHorizontal;
        self.logoTitleStackView.alignment = UIStackViewAlignmentCenter;
        self.logoTitleStackViewTopConstraint.constant = 16;
        self.cardViewTopConstraint.constant = 0;
    }
    else
    {
        self.privacyPolicyLeadingConstraint.constant = 20;
        self.cardViewTopConstraint.constant = 20;
        self.logoTitleStackViewTopConstraint.constant = 0;
        self.logoTitleStackView.axis = UILayoutConstraintAxisVertical;
        self.logoTitleStackView.alignment = UIStackViewAlignmentLeading;
    }
    self.descriptionLeadingConstraint.constant = self.privacyPolicyLeadingConstraint.constant;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self configureUI];
    } completion:nil];
}

- (void)configureToolbar
{
    NSMutableArray *items = [NSMutableArray new];

    UIBarButtonItem *flexibleSpaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [items addObject:flexibleSpaceItem];
    
    UIBarButtonItem *skipDownloadButtonItem = [[UIBarButtonItem alloc] initWithTitle:OALocalizedString(@"skip_download") style:UIBarButtonItemStylePlain target:self action:@selector(closeWizard)];
    [skipDownloadButtonItem setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: [UIColor colorNamed:ACColorNameTextColorActive], NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
    [items addObject:skipDownloadButtonItem];

    [self setToolbarItems:items];
}

# pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction
{
    [self openSafariWithURL:URL.absoluteString];
    return NO;
}

# pragma mark - SFSafariViewControllerDelegate

- (void)openSafariWithURL:(NSString *)url
{
    SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
    [self presentViewController:safariViewController animated:YES completion:nil];
}

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
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

- (void)showCard:(UIView *)cardView
{
    [self clearSubViews];
    [_cardView addSubview:cardView];
}

- (void)resizeToFitSubviews:(UIView *)source
{
    source.frame = CGRectMake(source.frame.origin.x, source.frame.origin.y, _cardView.frame.size.width, 130);
}

- (UIMenu *)rightNavButtonMenuItems {
    __weak OAFirstUsageWizardController *weakSelf = self;
    UIAction *restoreCloudAction = [UIAction actionWithTitle:OALocalizedString(@"restore_from_osmand_cloud")
                                                       image:[UIImage imageNamed:@"ic_custom_restore"]
                                                  identifier:nil
                                                     handler:^(__kindof UIAction * _Nonnull action) {
        UIViewController *controller = OABackupHelper.sharedInstance.isRegistered
        ? [OACloudBackupViewController new]
        : [OACloudIntroductionViewController new];
        [weakSelf.navigationController pushViewController:controller animated:YES];
    }];
    UIAction *restoreFileAction = [UIAction actionWithTitle:OALocalizedString(@"restore_from_file")
                                                      image:[UIImage imageNamed:@"ic_custom_import_outlined"]
                                                 identifier:nil
                                                    handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf onRestoreFromFilePressed];
    }];
    
    return [UIMenu menuWithTitle:@""
                           image:nil
                      identifier:nil
                         options:UIMenuOptionsDisplayInline children:@[restoreCloudAction, restoreFileAction]];;
}

- (void)onRestoreFromFilePressed
{
    NSArray<UTType *> *contentTypes = @[[UTType importedTypeWithIdentifier:@"net.osmand.osf" conformingToType:UTTypeArchive]];
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:YES];
    documentPickerVC.allowsMultipleSelection = NO;
    documentPickerVC.delegate = self;
    [self presentViewController:documentPickerVC animated:YES completion:nil];
}

- (IBAction)userLocationButtonPress:(id)sender
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:OALocalizedString(@"Location") message:@"" preferredStyle:UIAlertControllerStyleActionSheet];

    [actionSheet addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"search_another_country") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self selectMapPress:nil];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"determine_location") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        OALocationServices *locationServices = [OsmAndApp instance].locationServices;
        if (locationServices.denied)
        {
            [OALocationServices showDeniedAlert];
            return;
        }
      
        if (!locationServices.allowed)
            [locationServices start];
    }]];
    [actionSheet addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:actionSheet animated:YES completion:nil];
}

- (void)closeWizard
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (void) startWizard
{
   // [self showCard:_viewDownloadMap];
   // [self showCard:_viewSearchingLocation];
   // [self showCard:_viewNoInet];
   // [self showCard:_viewLocationNotFound];
   // [self showCard:_viewSearchingMap];

    if (!AFNetworkReachabilityManager.sharedManager.isReachable)
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
            OARepositoryResourceItem *indexItem = _localMapIndexItem;
            if (indexItem)
            {
                _lbDownloadMapName.text = indexItem.title;
                
                [_btnDownload setTitle:[OALocalizedString(@"shared_string_download") stringByAppendingFormat:@" %@", [NSByteCountFormatter stringFromByteCount:indexItem.sizePkg countStyle:NSByteCountFormatterCountStyleFile]] forState:UIControlStateNormal];
            }
            
            [self showCard:_viewDownloadMap];
            break;
        }
        case MAP_DOWNLOAD:
        {
            _indexItems = [NSMutableArray array];
            if (_localMapIndexItem)
                [_indexItems addObject:_localMapIndexItem];
            
            if (_indexItems.count > 0)
            {
                OARepositoryResourceItem *item = _indexItems[0];
                _lbMapName1.text = item.title;
                
                [_btnGoToMap setTitle:[OALocalizedString(@"downloading") stringByAppendingFormat:@" %@", [NSByteCountFormatter stringFromByteCount:item.sizePkg countStyle:NSByteCountFormatterCountStyleFile]] forState:UIControlStateNormal];

                if (_mapDownloadCancelled)
                {
                    _progress1.hidden = YES;
                }
            }
            else
            {
                _imgMapIcon1.hidden = YES;
                _lbMapName1.hidden = YES;
                _progress1.hidden = YES;
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
                
                NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://osmand.net/api/geo-ip?version=%@", ver]] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {

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
                    AFNetworkReachabilityManager.sharedManager.isReachable)
                {
                    [self updateRepository];
                }
                else if (!AFNetworkReachabilityManager.sharedManager.isReachable)
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

            break;
    }
}

- (BOOL) startDownloadIndex:(int)itemIndex
{
    BOOL downloadStarted = NO;
    if (itemIndex == 0 && _indexItems.count > 0)
    {
        OARepositoryResourceItem *item = _indexItems[0];
        if ([_app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:item.resourceId.toNSString()]].count == 0 && !_mapDownloadCancelled)
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
        [OAOcbfHelper downloadOcbfIfUpdated:^{
            [_app loadWorldRegions];
            [_app startRepositoryUpdateAsync:NO];
        }];
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
        
        if (_localMapIndexItem)
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

    BOOL spaceEnoughForLocal = _app.freeSpaceAvailableOnDevice >= spaceNeededForLocal;
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

- (NSByteCountFormatter *)byteCountFormatter
{
    if (!_byteCountFormatter) {
        _byteCountFormatter = [[NSByteCountFormatter alloc] init];
        _byteCountFormatter.includesUnit = NO;
        _byteCountFormatter.countStyle = NSByteCountFormatterCountStyleFile;
    }
    return _byteCountFormatter;
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
        if (_indexItems.count > 0 && [_indexItems[0].resourceId.toNSString() isEqualToString:[task.key stringByReplacingOccurrencesOfString:@"resource:" withString:@""]])
        {
            NSMutableString *progressStr = [NSMutableString string];
            uint64_t size = _indexItems[0].size;
            [progressStr appendString:[self.byteCountFormatter stringFromByteCount:(size * [value floatValue])]];
            [progressStr appendString:@"/"];
            [progressStr appendString:[NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile]];
            [_btnGoToMap setTitle:[OALocalizedString(@"downloading") stringByAppendingFormat:@" %@", progressStr] forState:UIControlStateNormal];
            [_progress1 setProgress:[value floatValue]];
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
            [_btnGoToMap setTitle:OALocalizedString(@"show_region_on_map_go") forState:UIControlStateNormal];
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
                _progress1DivTopMarginConstraint.constant = PROGRESS_OFF_MARGIN;
                [self.view setNeedsLayout];
            }
        }
        
    });
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller
didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (urls.count == 0)
        return;
    
    NSString *path = urls[0].path;
    NSString *extension = [[path pathExtension] lowercaseString];
    if ([extension caseInsensitiveCompare:@"osf"] == NSOrderedSame)
        [OASettingsHelper.sharedInstance collectSettings:urls[0].path latestChanges:@"" version:1];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark
    ? UIStatusBarStyleLightContent
    : UIStatusBarStyleDarkContent;
}

@end
