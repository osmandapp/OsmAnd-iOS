//
//  OAQuickSearchViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAQuickSearchViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "OsmAndApp.h"
#import "OAMapLayers.h"
#import "OAPOILayer.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAPOIHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAUtilities.h"
#import "OAPOIFavType.h"
#import "OAFavoriteItem.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OAPOIHistoryType.h"
#import "OAAddressTableViewController.h"
#import "OACategoriesTableViewController.h"
#import "OAHistoryTableViewController.h"
#import "OACustomPOIViewController.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFilterViewController.h"
#import "OAQuickSearchListItem.h"
#import "OAQuickSearchMoreListItem.h"
#import "OAQuickSearchButtonListItem.h"
#import "OAQuickSearchHeaderListItem.h"
#import "OAQuickSearchEmptyResultListItem.h"
#import "OAPointDescription.h"
#import "OATargetPointsHelper.h"

#import "OASearchUICore.h"
#import "OASearchCoreFactory.h"
#import "OAQuickSearchHelper.h"
#import "OASearchWord.h"
#import "OASearchPhrase.h"
#import "OASearchResult.h"
#import "OASearchSettings.h"
#import "OAQuickSearchTableController.h"
#import "OASearchToolbarViewController.h"
#import "OADeleteCustomFiltersViewController.h"
#import "OARearrangeCustomFiltersViewController.h"
#import "QuadRect.h"

#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OADefaultFavorite.h"
#import "OANativeUtilities.h"

#import "Localization.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>

#define kMaxTypeRows 5
#define kInitialSearchToolbarHeight 44.0
#define kBarActionViewHeight 44.0
#define kTabsHeight 40.0

#define kCancelButtonY 5.0
#define kLeftImageButtonY -2.0

typedef NS_ENUM(NSInteger, QuickSearchTab)
{
    HISTORY = 0,
    CATEGORIES,
    ADDRESS,
};

typedef void(^OASearchStartedCallback)(OASearchPhrase *phrase);
typedef void(^OAPublishCallback)(OASearchResultCollection *res, BOOL append);
typedef BOOL(^OASearchFinishedCallback)(OASearchPhrase *phrase);


@interface OAQuickSearchViewController () <OAQuickSearchTableDelegate, UITextFieldDelegate, UIPageViewControllerDataSource, OACategoryTableDelegate, OAHistoryTableDelegate, UIGestureRecognizerDelegate, UIPageViewControllerDelegate, OAPOIFilterViewDelegate, OASearchToolbarViewControllerProtocol, OAAddressTableDelegate, OAPOIFiltersRemoveDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *leftImageButton;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;

@property (weak, nonatomic) IBOutlet UIView *searchNearCenterView;
@property (weak, nonatomic) IBOutlet UILabel *lbSearchNearCenter;
@property (weak, nonatomic) IBOutlet UIButton *btnMyLocation;

@property (weak, nonatomic) IBOutlet UIView *barActionView;
@property (weak, nonatomic) IBOutlet UIButton *barActionLeftImageButton;
@property (weak, nonatomic) IBOutlet UIImageView *barActionImageView;
@property (weak, nonatomic) IBOutlet UIButton *barActionTextButton;
@property (weak, nonatomic) IBOutlet UIButton *barActionImageButton;

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *bottomTextBtn;
@property (weak, nonatomic) IBOutlet UIButton *bottomImageBtn;

@property (weak, nonatomic) IBOutlet UISegmentedControl *tabs;


@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;
@property NSTimeInterval lastUpdate;

@property (strong, nonatomic) dispatch_queue_t searchDispatchQueue;
@property (strong, nonatomic) dispatch_queue_t updateDispatchQueue;

@property (nonatomic) BOOL paused;
@property (nonatomic) BOOL foundPartialLocation;
@property (nonatomic) BOOL interruptedSearch;
@property (nonatomic) BOOL searching;
@property (nonatomic) BOOL cancelPrev;
@property (nonatomic) BOOL runSearchFirstTime;
@property (nonatomic) BOOL poiFilterApplied;
@property (nonatomic) BOOL addressSearch;
@property (nonatomic) BOOL citiesLoaded;
@property (nonatomic) BOOL modalInput;
@property (nonatomic) QuadRect *citySearchedRect;
@property (nonatomic) CLLocation *storedOriginalLocation;

@property (nonatomic) OAQuickSearchHelper *searchHelper;
@property (nonatomic) OASearchUICore *searchUICore;
@property (nonatomic) CLLocationCoordinate2D searchLocation;


@end

@implementation OAQuickSearchViewController
{
    UIPanGestureRecognizer *_tblMove;

    UIImageView *_leftImgView;
    UIActivityIndicatorView *_activityIndicatorView;

    OAQuickSearchTableController *_tableController;

    UIPageViewController *_pageController;
    OAAddressTableViewController *_addressViewController;
    OACategoriesTableViewController *_categoriesViewController;
    OAHistoryTableViewController *_historyViewController;

    OASearchToolbarViewController *_searchToolbarViewController;

    BarActionType _barActionType;
    BOOL _historyEditing;

    BOOL _bottomViewVisible;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.searchQuery = @"";
    self.searchType = OAQuickSearchType::REGULAR;
    _runSearchFirstTime = YES;
}

-(void)applyLocalization
{
    [_btnCancel setTitle:OALocalizedString(@"poi_hide") forState:UIControlStateNormal];
    [_bottomTextBtn setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _tableController = [[OAQuickSearchTableController alloc] initWithTableView:self.tableView];
    _tableController.delegate = self;
    _tableController.searchType = self.searchType;
    if (_searchNearMapCenter)
        [_tableController setMapCenterCoordinate:_searchLocation];
    else
        [_tableController resetMapCenterSearch];

    // drop shadow
    [_bottomView.layer setShadowColor:[UIColor blackColor].CGColor];
    [_bottomView.layer setShadowOpacity:0.3];
    [_bottomView.layer setShadowRadius:3.0];
    [_bottomView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    _bottomView.hidden = YES;

    _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageController.dataSource = self;
    _pageController.delegate = self;
    _pageController.view.frame = _tableView.frame;
    _pageController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    _addressViewController = [[OAAddressTableViewController alloc] initWithFrame:_pageController.view.bounds];
    _addressViewController.delegate = self;
    _addressViewController.tableDelegate = self;
    _addressViewController.searchType = self.searchType;
    if (_searchNearMapCenter)
        [_addressViewController setMapCenterCoordinate:_searchLocation];
    else
        [_addressViewController resetMapCenterSearch];

    _categoriesViewController = [[OACategoriesTableViewController alloc] initWithFrame:_pageController.view.bounds];
    _categoriesViewController.delegate = self;
    _categoriesViewController.tableDelegate = self;
    _categoriesViewController.searchType = self.searchType;
    if (_searchNearMapCenter)
        [_categoriesViewController setMapCenterCoordinate:_searchLocation];
    else
        [_categoriesViewController resetMapCenterSearch];

    _historyViewController = [[OAHistoryTableViewController alloc] initWithFrame:_pageController.view.bounds];
    _historyViewController.delegate = self;
    _historyViewController.searchNearMapCenter = _searchNearMapCenter;
    _historyViewController.myLocation = _myLocation;
    _historyViewController.searchType = self.searchType;

    [_pageController setViewControllers:@[_historyViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];

    [_tabs setTitle:OALocalizedString(@"history") forSegmentAtIndex:0];
    [_tabs setTitle:OALocalizedString(@"categories") forSegmentAtIndex:1];
    [_tabs setTitle:OALocalizedString(@"shared_string_address") forSegmentAtIndex:2];
    [_tabs setSelectedSegmentIndex:0];

    _tblMove = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(moveGestureDetected:)];
    _tblMove.delegate = self;

    _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(4.0, 0.0, 24.0, _textField.bounds.size.height)];
    _textField.leftViewMode = UITextFieldViewModeAlways;

    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:_textField.leftView.frame];
    _activityIndicatorView.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;

    _leftImgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"search_icon"]];
    _leftImgView.contentMode = UIViewContentModeCenter;
    _leftImgView.frame = _textField.leftView.frame;

    [_textField.leftView addSubview:_leftImgView];
    [_textField.leftView addSubview:_activityIndicatorView];

    [self setupSearch];
    [self updateHint];

    [self showSearchIcon];
    [self updateSearchNearMapCenterLabel];
    [self showTabs];
    if ([_textField isDirectionRTL])
        _textField.textAlignment = NSTextAlignmentRight;
}

-(void)viewWillAppear:(BOOL)animated
{
    self.paused = NO;

    [self setupView];

    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];

    [self registerForKeyboardNotifications];

    [super viewWillAppear:animated];

    if ([self getResultCollection])
    {
        [self updateSearchResult:[self getResultCollection] append:false];
        if (self.interruptedSearch || [self.searchUICore isSearchMoreAvailable:[self.searchUICore getPhrase]])
            [self addMoreButton];
    }
    if ([self.searchQuery length] > 0)
        [self updateTextField:_searchQuery];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self showSearchIcon];
    [self.textField becomeFirstResponder];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.paused = YES;

    if (self.locationServicesUpdateObserver)
    {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }

    [self unregisterKeyboardNotifications];
}

-(void)viewWillLayoutSubviews
{
    [self updateNavbar];
}

- (void) setupSearch
{
    // Setup search core
    NSString *locale = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    self.searchHelper = [OAQuickSearchHelper instance];
    self.searchUICore = [self.searchHelper getCore];

    [self stopAddressSearch];
    [self setResultCollection:nil];
    [self.searchUICore resetPhrase];

    OASearchSettings *settings = [[self.searchUICore getSearchSettings] setOriginalLocation:[[CLLocation alloc] initWithLatitude:_searchLocation.latitude longitude:_searchLocation.longitude]];
    settings = [settings setLang:locale ? locale : @"" transliterateIfMissing:transliterate];
    [self.searchUICore updateSettings:settings];

    __weak OAQuickSearchViewController *weakSelf = self;
    self.searchUICore.onSearchStart = ^void() {
        _cancelPrev = false;
    };
    self.searchUICore.onResultsComplete = ^void() {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.searching = false;
            if (!weakSelf.paused)
            {
                if ([weakSelf.searchUICore isSearchMoreAvailable:[weakSelf.searchUICore getPhrase]])
                    [weakSelf addMoreButton];

                [weakSelf updateBarActionView];
                [weakSelf showSearchIcon];
            }
        });
    };
}

- (void)setupBarActionView:(BarActionType)type title:(NSString *)title
{
    switch (type)
    {
        case BarActionSelectTarget:
        {
            _barActionLeftImageButton.hidden = YES;
            UIImage *mapImage = [UIImage templateImageNamed:@"ic_action_marker"];
            _barActionImageView.image = mapImage;
            _barActionImageView.hidden = NO;

            OASearchWord *word = [[self.searchUICore getPhrase] getLastSelectedWord];
            [UIView performWithoutAnimation:^{
                if (title)
                {
                    [_barActionTextButton setTitle:title forState:UIControlStateNormal];
                }
                else if (self.textField.text.length > 0)
                {
                    if (word && word.result)
                        [_barActionTextButton setTitle:[NSString stringWithFormat:@"%@ %@", OALocalizedString(@"shared_string_select"), word.result.localeName] forState:UIControlStateNormal];
                    else
                        [_barActionTextButton setTitle:OALocalizedString(@"shared_string_select") forState:UIControlStateNormal];
                }
                else
                {
                    [_barActionTextButton setTitle:OALocalizedString(@"shared_string_select") forState:UIControlStateNormal];
                }

                [_barActionTextButton layoutIfNeeded];
            }];
            _barActionTextButton.hidden = NO;
            _barActionTextButton.userInteractionEnabled = YES;
            _barActionImageButton.hidden = YES;

            break;
        }
        case BarActionShowOnMap:
        {
            _barActionLeftImageButton.hidden = YES;
            UIImage *mapImage = [UIImage templateImageNamed:@"waypoint_map_disable.png"];
            _barActionImageView.image = mapImage;
            _barActionImageView.hidden = NO;

            OASearchWord *word = [[self.searchUICore getPhrase] getLastSelectedWord];
            [UIView performWithoutAnimation:^{
                if (title)
                {
                    [_barActionTextButton setTitle:title forState:UIControlStateNormal];
                }
                else if (self.textField.text.length > 0)
                {
                    if (word && word.result)
                        [_barActionTextButton setTitle:[NSString stringWithFormat:OALocalizedString(@"show_something_on_map"), word.result.localeName] forState:UIControlStateNormal];
                    else
                        [_barActionTextButton setTitle:OALocalizedString(@"map_settings_show") forState:UIControlStateNormal];
                }
                else
                {
                    [_barActionTextButton setTitle:OALocalizedString(@"map_settings_show") forState:UIControlStateNormal];
                }

                [_barActionTextButton layoutIfNeeded];
            }];
            _barActionTextButton.hidden = NO;
            _barActionTextButton.userInteractionEnabled = YES;


            [_barActionImageButton setImage:[UIImage imageNamed:@"ic_search_filter.png"] forState:UIControlStateNormal];
            BOOL filterButtonVisible = word && word.getType == POI_TYPE;
            _barActionImageButton.hidden = !filterButtonVisible;

            break;
        }

        case BarActionEditHistory:
        {
            _barActionImageView.hidden = YES;
            [_barActionLeftImageButton setImage:[UIImage imageNamed:@"ic_close.png"] forState:UIControlStateNormal];
            _barActionLeftImageButton.hidden = NO;

            [UIView performWithoutAnimation:^{
                [_barActionTextButton setTitle:title forState:UIControlStateNormal];
                [_barActionTextButton layoutIfNeeded];
            }];
            _barActionTextButton.hidden = NO;
            _barActionTextButton.userInteractionEnabled = NO;

            [_barActionImageButton setImage:[UIImage imageNamed:@"icon_remove.png"] forState:UIControlStateNormal];
            _barActionImageButton.hidden = NO;

            break;
        }
        default:
            break;
    }
    _barActionType = type;
    [self.view setNeedsLayout];
}

- (void)updateTabsVisibility:(BOOL)show
{
    if (show && ![self tabsVisible])
        [self showTabs];
    else if (!show && [self tabsVisible])
        [self hideTabs];

    [self updateBarActionView];
}

- (BOOL)tabsVisible
{
    return _pageController.parentViewController != nil;
}

- (void)showTabs
{
    [self addChildViewController:_pageController];
    [self.view addSubview:_pageController.view];
    _pageController.view.frame = _tableView.frame;
    _tabs.hidden = NO;
    _tableView.hidden = YES;
    [_pageController didMoveToParentViewController:self];
}

- (void)hideTabs
{
    _tabs.hidden = YES;
    _tableView.hidden = NO;
    [_pageController.view removeFromSuperview];
    [_pageController removeFromParentViewController];
}

- (IBAction)tabChanged:(id)sender
{
    [self moveGestureDetected:nil];
    switch (_tabs.selectedSegmentIndex)
    {
        case 0:
        {
            [_pageController setViewControllers:@[_historyViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
            break;
        }
        case 1:
        {
            [self.searchHelper refreshCustomPoiFilters];
            [_pageController setViewControllers:@[_categoriesViewController] direction: (_pageController.viewControllers[0] == _historyViewController ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse) animated:YES completion:nil];
            break;
        }
        case 2:
        {
            [_pageController setViewControllers:@[_addressViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            break;
        }
    }
    [self processTabChange];
}

- (void) processTabChange
{
    self.addressSearch = _tabs.selectedSegmentIndex == 2;
    [self updateHint];
    if (!(self.addressSearch && !self.citiesLoaded))
        [self restoreSearch];
}

- (IBAction)leftImgButtonPress:(id)sender
{
    [self restoreInputLayout];
    [self resetSearch];
    if (self.addressSearch && [self tabsVisible])
        [self reloadCities];
}

- (IBAction)barActionTextButtonPress:(id)sender
{
    switch (_barActionType)
    {
        case BarActionSelectTarget:
        case BarActionShowOnMap:
        {
            OASearchPhrase *searchPhrase = [self.searchUICore getPhrase];
            if ([searchPhrase isNoSelectedType] || [searchPhrase isLastWord:POI_TYPE])
            {
                OAPOIUIFilter *filter;
                if ([searchPhrase isNoSelectedType])
                {
                    OAPOIBaseType *unselectedPoiType = [self.searchUICore getUnselectedPoiType];
                    if (unselectedPoiType)
                    {
                        filter = [[OAPOIUIFilter alloc] initWithBasePoiType:unselectedPoiType idSuffix:@""];
                        NSString *customName = [self.searchUICore getCustomNameFilter];
                        if (customName.length > 0)
                            [filter setFilterByName:customName];
                    }
                    else
                    {
                        filter = [[OAPOIFiltersHelper sharedInstance] getSearchByNamePOIFilter];
                        if ([searchPhrase getFirstUnknownSearchWord].length > 0)
                        {
                            [filter setFilterByName:[searchPhrase getFirstUnknownSearchWord]];
                            [filter clearCurrentResults];
                        }
                    }
                }
                else if ([[searchPhrase getLastSelectedWord].result.object isKindOfClass:[OAPOIBaseType class]])
                {
                    if ([searchPhrase isNoSelectedType])
                    {
                        filter = [[OAPOIUIFilter alloc] initWithBasePoiType:nil idSuffix:@""];
                    }
                    else
                    {
                        OAPOIBaseType *abstractPoiType = (OAPOIBaseType *) [searchPhrase getLastSelectedWord].result.object;
                        filter = [[OAPOIUIFilter alloc] initWithBasePoiType:abstractPoiType idSuffix:@""];
                    }
                    if ([searchPhrase getFirstUnknownSearchWord].length > 0)
                        [filter setFilterByName:[searchPhrase getFirstUnknownSearchWord]];
                }
                else
                {
                    filter = (OAPOIUIFilter *) [searchPhrase getLastSelectedWord].result.object;
                }
                [[OAPOIFiltersHelper sharedInstance] clearSelectedPoiFilters];
                [[OAPOIFiltersHelper sharedInstance] addSelectedPoiFilter:filter];

                OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
                [mapVC updatePoiLayer];
                [self showToolbar];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else
            {
                OASearchWord *word = [searchPhrase getLastSelectedWord];
                if (word && [word getLocation])
                {
                    OASearchResult *searchResult = word.result;
                    [_tableController showOnMap:searchResult searchType:self.searchType delegate:self];
                }
            }
            break;
        }
        default:
            break;
    }
}

- (IBAction)barActionLeftImgButtonPress:(id)sender
{
    switch (_barActionType)
    {
        case BarActionEditHistory:
            [_historyViewController editDone];
            [self finishHistoryEditing];
            break;

        default:
            break;
    }
}

- (IBAction)barActionImgButtonPress:(id)sender
{
    switch (_barActionType)
    {
        case BarActionShowOnMap:
        {
            OASearchPhrase *searchPhrase = [self.searchUICore getPhrase];
            if ([searchPhrase isLastWord:POI_TYPE])
            {
                NSString *filterByName = [[searchPhrase getUnknownSearchPhrase] trim];
                NSObject *object = [searchPhrase getLastSelectedWord].result.object;
                if ([object isKindOfClass:[OAPOIUIFilter class]])
                {
                    OAPOIUIFilter *model = (OAPOIUIFilter *) object;
                    if (model.savedFilterByName.length > 0)
                        [model setFilterByName:model.savedFilterByName];

                    OAPOIFilterViewController *filterViewController = [[OAPOIFilterViewController alloc] initWithFilter:model filterByName:filterByName];
                    filterViewController.delegate = self;
                    [self.navigationController pushViewController:filterViewController animated:YES];
                }
                else if ([object isKindOfClass:[OAPOIBaseType class]])
                {
                    OAPOIBaseType *abstractPoiType = (OAPOIBaseType *)object;
                    OAPOIUIFilter *custom = [[OAPOIFiltersHelper sharedInstance] getFilterById:[STD_PREFIX stringByAppendingString:abstractPoiType.name]];
                    if (custom)
                    {
                        [custom setFilterByName:nil];
                        [custom clearFilter];
                        [custom updateTypesToAccept:abstractPoiType];

                        OAPOIFilterViewController *filterViewController = [[OAPOIFilterViewController alloc] initWithFilter:custom filterByName:filterByName];
                        filterViewController.delegate = self;
                        [self.navigationController pushViewController:filterViewController animated:YES];
                    }
                }
            }
            break;
        }
        case BarActionEditHistory:
        {
            [_historyViewController deleteSelected];
            break;
        }
        default:
            break;
    }
}

- (IBAction)bottomTextButtonPress:(id)sender
{
    OAPOIUIFilter *customFilter = [[OAPOIFiltersHelper sharedInstance] getCustomPOIFilter];
    if (customFilter)
        [self presentViewController:[self createSaveFilterDialog:customFilter customSaveAction:NO] animated:YES completion:nil];
}

- (IBAction)bottomImageButtonPress:(id)sender
{
    [self setBottomViewVisible:NO];
}

- (void)showToolbar
{
    [self showToolbar:nil];
}

- (void)showToolbar:(OAPOIUIFilter *)filter
{
    if (!_searchToolbarViewController)
    {
        _searchToolbarViewController = [[OASearchToolbarViewController alloc] initWithNibName:@"OASearchToolbarViewController" bundle:nil];
        _searchToolbarViewController.searchDelegate = self;
    }
    [_searchToolbarViewController setFilter:filter];
    _searchToolbarViewController.toolbarTitle = filter ? filter.name : [_textField.text trim];
    [[OARootViewController instance].mapPanel showToolbar:_searchToolbarViewController];
}

- (void) hideToolbar
{
    [[OARootViewController instance].mapPanel hideToolbar:_searchToolbarViewController];
}

- (void) resetSearch
{
    [self updateTextField:@""];
}

- (void) updateBarActionView
{
    if (!_historyEditing)
    {
        BOOL barActionButtonVisible = self.textField.text.length > 0;

        OASearchWord *word = [[self.searchUICore getPhrase] getLastSelectedWord];
        if (self.searchType == OAQuickSearchType::START_POINT || self.searchType == OAQuickSearchType::DESTINATION || self.searchType == OAQuickSearchType::INTERMEDIATE || self.searchType == OAQuickSearchType::HOME || self.searchType == OAQuickSearchType::WORK)
        {
            barActionButtonVisible = barActionButtonVisible && (word && word.result && word.getType != POI_TYPE);
        }
        if (barActionButtonVisible)
        {
            if (self.searchType == OAQuickSearchType::START_POINT || self.searchType == OAQuickSearchType::DESTINATION || self.searchType == OAQuickSearchType::INTERMEDIATE || self.searchType == OAQuickSearchType::HOME || self.searchType == OAQuickSearchType::WORK)
                [self setupBarActionView:BarActionSelectTarget title:nil];
            else
                [self setupBarActionView:BarActionShowOnMap title:nil];
        }
        else
        {
            [self setupBarActionView:BarActionNone title:nil];
        }
    }
}

- (void)setBottomViewVisible:(BOOL)visible
{
    if (visible)
    {
        if (!_bottomViewVisible)
        {
            _bottomView.frame = CGRectMake(0, self.view.bounds.size.height + 1, self.view.bounds.size.width, _bottomView.bounds.size.height);
            _bottomView.hidden = NO;
            CGRect tableFrame = _tableView.frame;
            tableFrame.size.height -= _bottomView.bounds.size.height;
            [UIView animateWithDuration:.25 animations:^{
                _tableView.frame = tableFrame;
                _bottomView.frame = CGRectMake(0, self.view.bounds.size.height - _bottomView.bounds.size.height, self.view.bounds.size.width, _bottomView.bounds.size.height);
            }];
        }
        _bottomViewVisible = YES;
    }
    else
    {
        if (_bottomViewVisible)
        {
            CGRect tableFrame = _tableView.frame;
            tableFrame.size.height = self.view.bounds.size.height - tableFrame.origin.y;
            [UIView animateWithDuration:.25 animations:^{
                _tableView.frame = tableFrame;
                _bottomView.frame = CGRectMake(0, self.view.bounds.size.height + 1, self.view.bounds.size.width, _bottomView.bounds.size.height);
            } completion:^(BOOL finished) {
                _bottomView.hidden = YES;
            }];
        }
        _bottomViewVisible = NO;
    }
}

- (void)finishHistoryEditing
{
    _historyEditing = NO;
    [self setupBarActionView:BarActionNone title:nil];
}

-(void)setSearchNearMapCenter:(BOOL)searchNearMapCenter
{
    _searchNearMapCenter = searchNearMapCenter;

    if (self.isViewLoaded)
    {
        if (searchNearMapCenter)
        {
            _historyViewController.myLocation = _myLocation;
            _historyViewController.searchNearMapCenter = searchNearMapCenter;
            [_addressViewController setMapCenterCoordinate:_searchLocation];
            [_categoriesViewController setMapCenterCoordinate:_searchLocation];
            [_tableController setMapCenterCoordinate:_searchLocation];
        }
        else
        {
            _historyViewController.searchNearMapCenter = searchNearMapCenter;
            [_addressViewController resetMapCenterSearch];
            [_categoriesViewController resetMapCenterSearch];
            [_tableController resetMapCenterSearch];
        }
        [self updateSearchNearMapCenterLabel];

        [self.view setNeedsLayout];
    }
}

-(void)setSearchType:(OAQuickSearchType)searchType
{
    _searchType = searchType;

    _historyViewController.searchType = searchType;
    _addressViewController.searchType = searchType;
    _categoriesViewController.searchType = searchType;
    _tableController.searchType = searchType;

    [self updateBarActionView];
}

- (void)setTabIndex:(NSInteger)tabIndex
{
    _tabIndex = tabIndex;
    if (self.isViewLoaded) {
        [self.tabs setSelectedSegmentIndex:tabIndex];
        [self tabChanged:nil];
    }
}

-(void)setMyLocation:(OsmAnd::PointI)myLocation
{
    _myLocation = myLocation;
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(myLocation);
    _searchLocation = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);

    OASearchSettings *settings = [[self.searchUICore getSearchSettings] setOriginalLocation:[[CLLocation alloc] initWithLatitude:_searchLocation.latitude longitude:_searchLocation.longitude]];
    [self.searchUICore updateSettings:settings];

    if (self.isViewLoaded)
        [self.view setNeedsLayout];
}

-(void)updateNavbar
{
    BOOL showBarActionView = _barActionType != BarActionNone && !_modalInput;
    BOOL showInputView = _barActionType != BarActionEditHistory;
    BOOL showMapCenterSearch = !showBarActionView && _searchNearMapCenter && self.searchQuery.length == 0 && _distanceFromMyLocation > 0;
    BOOL showTabs = [self tabsVisible] && _barActionType != BarActionEditHistory;
    CGRect frame = _topView.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    statusBarHeight = statusBarHeight == 0 ? 10.0 : statusBarHeight;
    frame.size.height = (showInputView ? kInitialSearchToolbarHeight + statusBarHeight : statusBarHeight) + (showMapCenterSearch || showBarActionView ? kBarActionViewHeight : 0.0)  + (showTabs ? kTabsHeight : 0.0);

    _textField.hidden = !showInputView;
    _btnCancel.hidden = !showInputView || _modalInput;
    _barActionView.hidden = !showBarActionView;
    _searchNearCenterView.hidden = !showMapCenterSearch;
    _tabs.hidden = !showTabs;

    _barActionView.frame = CGRectMake(0.0, showInputView ? 40.0 + statusBarHeight : statusBarHeight, _barActionView.bounds.size.width, _barActionView.bounds.size.height);
    [self adjustViewPosition:_searchNearCenterView byHeight:showInputView ? 40.0 : 0.0];

    [self adjustViewPosition:_btnCancel byHeight:kCancelButtonY];
    [self adjustViewPosition:_leftImageButton byHeight:kLeftImageButtonY];

    if (_modalInput)
    {
        self.leftImageButton.hidden = NO;
        self.textField.frame = CGRectMake(44, 5 + statusBarHeight, self.view.frame.size.width - 44 - 8, self.textField.frame.size.height);
    }
    else
    {
        self.leftImageButton.hidden = YES;
        self.textField.frame = CGRectMake(8, 5 + statusBarHeight, self.view.frame.size.width - 84 - 8, self.textField.frame.size.height);
    }

    _topView.frame = frame;
    _tableView.frame = CGRectMake(0.0, frame.size.height, frame.size.width, self.view.frame.size.height - frame.size.height - (_bottomViewVisible ? _bottomView.bounds.size.height : 0.0));
    _pageController.view.frame = _tableView.frame;
}

-(void)updateSearchNearMapCenterLabel
{
    _lbSearchNearCenter.text = [NSString stringWithFormat:@"%@ %@ %@", OALocalizedString(@"you_searching"), [[OsmAndApp instance] getFormattedDistance:self.distanceFromMyLocation], OALocalizedString(@"from_location")];
}

- (void) adjustViewPosition:(UIView *)view byHeight:(CGFloat)height
{
    CGRect frame = view.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight] == 0 ? 10.0 : [OAUtilities getStatusBarHeight];
    frame.origin.y = statusBarHeight + height;
    view.frame = frame;
}

-(void)showWaitingIndicator
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_leftImgView setHidden:YES];
        [_activityIndicatorView setHidden:NO];
        [_activityIndicatorView startAnimating];
    });
}

-(void)showSearchIcon
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_activityIndicatorView setHidden:YES];
        [_leftImgView setHidden:NO];
    });
}

-(void)moveGestureDetected:(id)sender
{
    [self.textField resignFirstResponder];
}

// keyboard notifications register+process
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view addGestureRecognizer:_tblMove];
    });
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.view removeGestureRecognizer:_tblMove];
    });
}


- (void)updateDistanceAndDirection
{
    if (_paused || _cancelPrev || _searchNearMapCenter || [[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.lastUpdate = [[NSDate date] timeIntervalSince1970];
        [_tableController updateDistanceAndDirection];
        [_historyViewController updateDistanceAndDirection];
        [_addressViewController updateDistanceAndDirection];
    });
}

- (void) updateHint
{
    if (self.addressSearch)
        self.textField.placeholder = OALocalizedString(@"type_address");
    else
        self.textField.placeholder = OALocalizedString(@"search_poi_category_hint");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) enterModalInputLayout
{
    self.modalInput = YES;
    [self updateNavbar];
}

- (void) restoreInputLayout
{
    self.modalInput = NO;
    [self updateNavbar];
}

- (void) restoreSearch
{
    if (self.addressSearch)
        [self startAddressSearch];
    else
        [self stopAddressSearch];

    if (self.storedOriginalLocation)
    {
        // Restore previous search location
        [self.searchUICore updateSettings:[[self.searchUICore getSearchSettings] setOriginalLocation:self.storedOriginalLocation]];
        self.storedOriginalLocation = nil;
    }
    [self restoreInputLayout];
}

- (void) startAddressSearch
{
    OASearchSettings *settings = [[[[[[self.searchUICore getSearchSettings]
                                      setEmptyQueryAllowed:true]
                                     setAddressSearch:true]
                                    setSortByName:false]
                                   setSearchTypes:@[[OAObjectType withType:CITY], [OAObjectType withType:VILLAGE], [OAObjectType withType:POSTCODE], [OAObjectType withType:HOUSE], [OAObjectType withType:STREET_INTERSECTION], [OAObjectType withType:STREET],[OAObjectType withType:LOCATION], [OAObjectType withType:PARTIAL_LOCATION]]]
                                  setRadiusLevel:1];

    [self.searchUICore updateSettings:settings];
}

- (void) startCitySearch
{
    OASearchSettings *settings = [[[[[[self.searchUICore getSearchSettings]
                                      setEmptyQueryAllowed:true]
                                     setAddressSearch:true]
                                    setSortByName:true]
                                   setSearchTypes:@[[OAObjectType withType:CITY], [OAObjectType withType:VILLAGE]]]
                                  setRadiusLevel:1];

    [self.searchUICore updateSettings:settings];
    [self enterModalInputLayout];
}

- (void) startNearestCitySearch
{
    OASearchSettings *settings = [[[[[[self.searchUICore getSearchSettings]
                                      setEmptyQueryAllowed:true]
                                     setAddressSearch:true]
                                    setSortByName:false]
                                   setSearchTypes:@[[OAObjectType withType:CITY]]]
                                  setRadiusLevel:1];

    [self.searchUICore updateSettings:settings];
}

- (void) startLastCitySearch:(CLLocation *)latLon
{
    OASearchSettings *settings = [self.searchUICore getSearchSettings];
    self.storedOriginalLocation = [settings getOriginalLocation];
    settings = [[[[[[settings setEmptyQueryAllowed:true]
                    setAddressSearch:true]
                   setSortByName:false]
                  setSearchTypes:@[[OAObjectType withType:CITY]]]
                 setOriginalLocation:latLon]
                setRadiusLevel:1];

    [self.searchUICore updateSettings:settings];
}

- (void) startPostcodeSearch
{
    OASearchSettings *settings = [[[[[[self.searchUICore getSearchSettings]
                                      setSearchTypes:@[[OAObjectType withType:POSTCODE]]]
                                     setEmptyQueryAllowed:false]
                                    setAddressSearch:true]
                                   setSortByName:true]
                                  setRadiusLevel:1];

    [self.searchUICore updateSettings:settings];
    [self enterModalInputLayout];
}

- (void) stopAddressSearch
{
    OASearchSettings *settings = [[[[[[self.searchUICore getSearchSettings]
                                      resetSearchTypes]
                                     setEmptyQueryAllowed:false]
                                    setSortByName:false]
                                   setAddressSearch:false]
                                  setRadiusLevel:1];

    [self.searchUICore updateSettings:settings];
}

- (void) reloadCities
{
    if (self.citySearchedRect)
    {
        CLLocation *loc = [[self.searchUICore getSearchSettings] getOriginalLocation];
        if (loc)
        {
            OsmAnd::PointI loc31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(loc.coordinate.latitude, loc.coordinate.longitude));
            if ([self.citySearchedRect contains:loc31.x top:loc31.y right:loc31.x bottom:loc31.y])
                return;
        }
    }
    [self startNearestCitySearch];
    [self runCoreSearch:@"" updateResult:NO searchMore:NO onSearchStarted:nil onPublish:nil onSearchFinished:^BOOL(OASearchPhrase *phrase) {

        OASearchResultCollection *res = [self getResultCollection];

        OAAppSettings *settings = [OAAppSettings sharedManager];
        NSMutableArray<NSMutableArray<OAQuickSearchListItem *> *> *data = [NSMutableArray array];

        self.citySearchedRect = [phrase getRadiusBBoxToSearch:1000];
        OASearchResult *lastCity = nil;
        if (res)
        {
            self.citiesLoaded = [res getCurrentSearchResults].count > 0;
            unsigned long long lastCityId = settings.lastSearchedCity;
            for (OASearchResult *sr in [res getCurrentSearchResults])
            {
                if (sr.objectType == CITY && ((OACity *) sr.object).addrId == lastCityId) {
                    lastCity = sr;
                    break;
                }
            }
        }
        NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];

        NSString *lastCityName = (!lastCity ? settings.lastSearchedCityName : lastCity.localeName);
        if (lastCityName.length > 0)
        {
            NSString *selectStreets = OALocalizedString(@"select_street");
            NSString *inCityName = [NSString stringWithFormat:OALocalizedString(@"shared_string_in_name"), lastCityName];
            NSMutableAttributedString *selectStreetsInCityAttr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", selectStreets, inCityName]];
            [selectStreetsInCityAttr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x2f7af5) range:NSMakeRange(0, selectStreets.length)];
            [selectStreetsInCityAttr addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0x727272) range:NSMakeRange(selectStreets.length + 1, inCityName.length)];

            [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_action_street_name"] attributedText:selectStreetsInCityAttr onClickFunction:^(id sender) {
                if (!lastCity)
                {
                    unsigned long long lastCityId = settings.lastSearchedCity;
                    CLLocation *lastCityPoint = settings.lastSearchedPoint;
                    if (lastCityId != -1 && lastCityPoint)
                    {
                        [self startLastCitySearch:lastCityPoint];
                        BOOL __block cityFound = NO;
                        [self runCoreSearch:@"" updateResult:NO searchMore:NO onSearchStarted:^(OASearchPhrase *phrase) {
                            //
                        } onPublish:^(OASearchResultCollection *res, BOOL append) {
                            if (res) {
                                for (OASearchResult *sr in [res getCurrentSearchResults])
                                {
                                    if (sr.objectType == CITY && ((OACity *) sr.object).addrId == lastCityId)
                                    {
                                        cityFound = YES;
                                        [self completeQueryWithObject:sr];
                                        break;
                                    }
                                }
                            }
                        } onSearchFinished:^BOOL(OASearchPhrase *phrase) {
                            if (!cityFound)
                                [self replaceQueryWithText:[lastCityName stringByAppendingString:@" "]];

                            return NO;
                        }];
                        [self restoreSearch];
                    }
                    else
                    {
                        [self replaceQueryWithText:[lastCityName stringByAppendingString:@" "]];
                    }
                }
                else
                {
                    [self completeQueryWithObject:lastCity];
                }
                [self.textField becomeFirstResponder];
            }]];
        }

        [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_action_building_number"] text:OALocalizedString(@"select_city") onClickFunction:^(id sender) {
            self.textField.placeholder = OALocalizedString(@"type_city_town");
            [self startCitySearch];
            [self updateTabsVisibility:NO];
            [self runCoreSearch:@"" updateResult:NO searchMore:NO];
            [self.textField becomeFirstResponder];
        }]];

        [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_action_postcode"] text:OALocalizedString(@"select_postcode") onClickFunction:^(id sender) {
            self.textField.placeholder = OALocalizedString(@"type_postcode");
            [self startPostcodeSearch];
            [self updateData:[NSMutableArray<OAQuickSearchListItem *> array] append:NO];
            [self updateTabsVisibility:NO];
            [self.textField becomeFirstResponder];
        }]];

        /*
        [rows addObject:[[OAQuickSearchButtonListItem alloc] initWithIcon:[UIImage imageNamed:@"ic_action_marker_dark"] text:OALocalizedString(@"coords_search") onClickFunction:^(id sender) {
            CLLocation *latLon = [[self.searchUICore getSearchSettings] getOriginalLocation];
            QuickSearchCoordinatesFragment.showDialog(QuickSearchDialogFragment.this,
                                                      latLon.getLatitude(), latLon.getLongitude());
        }]];
         */

        [data addObject:rows];

        if (res)
        {
            NSArray<OASearchResult *> *currentSearchResults = [res getCurrentSearchResults];
            if (currentSearchResults.count > 0)
            {
                NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];
                [rows addObject:[[OAQuickSearchHeaderListItem alloc] initWithName:OALocalizedString(@"nearest_cities")]];
                int limit = 15;
                for (OASearchResult *sr in currentSearchResults)
                {
                    if (limit > 0)
                        [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];
                    else
                        break;

                    limit--;
                }
                [data addObject:rows];
            }
        }
        [_addressViewController setData:data];
        return YES;
    }];
    [self restoreSearch];
}

- (void) reloadCategories
{
    [_categoriesViewController reloadData];
}

- (void) reloadHistory
{
    [_historyViewController reloadData];
}

- (void) hidePoi
{
    [OAPOIFiltersHelper.sharedInstance hidePoiFilters];
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    [mapVC updatePoiLayer];
}

-(void) updateData:(NSMutableArray<OAQuickSearchListItem *> *)dataArray append:(BOOL)append
{
    [_tableController updateData:@[dataArray] append:append];
}

-(void) updateTextField:(NSString *)text
{
    NSString *t = (text ? text : @"");
    _textField.text = t;
    [self textFieldValueChanged:_textField];
}

-(void) setupView
{
    NSString *locale = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    OASearchSettings *settings = [[self.searchUICore getSearchSettings] setLang:locale ? locale : @"" transliterateIfMissing:transliterate];
    [self.searchUICore updateSettings:settings];
}

- (void) addHistoryItem:(OASearchResult *)searchResult
{
    if (searchResult.location)
    {
        OAHistoryItem *h = [[OAHistoryItem alloc] init];
        h.name = [OAQuickSearchListItem getName:searchResult];
        h.latitude = searchResult.location.coordinate.latitude;
        h.longitude = searchResult.location.coordinate.longitude;
        h.date = [NSDate date];
        h.iconName = [OAQuickSearchListItem getIconName:searchResult];
        h.typeName = [OAQuickSearchListItem getTypeName:searchResult];

        switch (searchResult.objectType)
        {
            case POI:
                h.hType = OAHistoryTypePOI;
                break;

            case FAVORITE:
                h.hType = OAHistoryTypeFavorite;
                break;

            case WPT:
                h.hType = OAHistoryTypeWpt;
                break;

            case LOCATION:
                h.hType = OAHistoryTypeLocation;
                break;

            case CITY:
            case VILLAGE:
            case POSTCODE:
            case STREET:
            case HOUSE:
            case STREET_INTERSECTION:
                h.hType = OAHistoryTypeAddress;
                break;

            default:
                h.hType = OAHistoryTypeUnknown;
                break;
        }

        [[OAHistoryHelper sharedInstance] addPoint:h];
    }
}

- (IBAction) btnCancelClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) btnMyLocationClicked:(id)sender
{
    if (!_searchNearMapCenter)
        return;

    CLLocation* newLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    if (newLocation)
    {
        self.myLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(newLocation.coordinate.latitude, newLocation.coordinate.longitude));
        [self setSearchNearMapCenter:NO];

        [UIView animateWithDuration:.25 animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            if (self.addressSearch && [self tabsVisible])
                [self reloadCities];
        }];
    }
}

- (IBAction) textFieldValueChanged:(id)sender
{
    // hide poi
    [self hidePoi];
    [self hideToolbar];
    [self updateHint];

    NSString *newQueryText = _textField.text;
    BOOL textEmpty = newQueryText.length == 0;
    [self updateTabsVisibility:textEmpty];
    [self showSearchIcon];
    if (textEmpty && self.addressSearch) {
        [self startAddressSearch];
    }
    if (textEmpty && self.poiFilterApplied)
    {
        self.poiFilterApplied = NO;
        [self reloadCategories];
    }
    if ([self.searchQuery localizedCaseInsensitiveCompare:newQueryText] != NSOrderedSame)
    {
        self.searchQuery = newQueryText;
        if (self.searchQuery.length == 0)
        {
            [self restoreInputLayout];
            [self.searchUICore resetPhrase];
            [self.searchUICore cancelSearch];
        }
        else
        {
            [self runSearch];
        }
    }
    else if (self.runSearchFirstTime)
    {
        self.runSearchFirstTime = NO;
        [self runSearch];
    }

    [self.view setNeedsLayout];
}

- (void) goToPoint:(double)latitude longitude:(double)longitude
{
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = latitude;
    poi.longitude = longitude;
    poi.nameLocalized = @"";

    [self goToPoint:poi];
}

- (void) goToPoint:(OAPOI *)poi
{
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OATargetPoint *targetPoint = [mapVC.mapLayers.poiLayer getTargetPoint:poi];
    targetPoint.centerMap = YES;
    [[OARootViewController instance].mapPanel showContextMenu:targetPoint];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) setResultCollection:(OASearchResultCollection *)resultCollection
{
    [self.searchHelper setResultCollection:resultCollection];
}

- (OASearchResultCollection *) getResultCollection
{
    return [self.searchHelper getResultCollection];
}

-(void) runSearch
{
    [self runSearch:self.searchQuery];
}

- (void) runSearch:(NSString *)text
{
    [self showWaitingIndicator];
    OASearchSettings *settings = [self.searchUICore getSearchSettings];
    if ([settings getRadiusLevel] != 1)
        [self.searchUICore updateSettings:[settings setRadiusLevel:1]];

    [self runCoreSearch:text updateResult:YES searchMore:NO];
}

- (void) runCoreSearch:(NSString *)text updateResult:(BOOL)updateResult searchMore:(BOOL)searchMore
{
    [self showWaitingIndicator];
    [self runCoreSearch:text updateResult:updateResult searchMore:searchMore onSearchStarted:nil onPublish:^(OASearchResultCollection *res, BOOL append) {
        [self updateSearchResult:res append:append];
    } onSearchFinished:^BOOL(OASearchPhrase *phrase) {
        OASearchWord *lastSelectedWord = [phrase getLastSelectedWord];
        BOOL isEmptyResult = ![self getResultCollection] || [[self getResultCollection] getCurrentSearchResults].count == 0;
        if (_tableController && [_tableController isShowResult] && isEmptyResult && lastSelectedWord) {
            [_tableController showOnMap:lastSelectedWord.result searchType:self.searchType delegate:self];
        }
        return YES;
    }];
}

- (void) runCoreSearch:(NSString *)text updateResult:(BOOL)updateResult searchMore:(BOOL)searchMore onSearchStarted:(OASearchStartedCallback)onSearchStarted onPublish:(OAPublishCallback)onPublish onSearchFinished:(OASearchFinishedCallback)onSearchFinished
{
    self.foundPartialLocation = false;
    [self updateBarActionView];
    self.interruptedSearch = false;
    self.searching = true;
    self.cancelPrev = true;

    OASearchResultCollection __block *regionResultCollection;
    OASearchCoreAPI __block *regionResultApi;
    NSMutableArray<OASearchResult *> __block *results = [NSMutableArray array];

    [self.searchUICore search:text delayedExecution:updateResult matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {

        OASearchResult *obj = *object;
        if (obj.objectType == SEARCH_STARTED)
            self.cancelPrev = false;

        if (self.paused || self.cancelPrev)
        {
            if (results.count > 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[self getResultCollection] addSearchResults:results resortAll:YES removeDuplicates:YES];
                });
            }
            return NO;
        }
        switch (obj.objectType)
        {
            case SEARCH_STARTED:
            {
                if (onSearchStarted)
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        onSearchStarted(obj.requiredSearchPhrase);
                    });
                }
                break;
            }
            case FILTER_FINISHED:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateSearchResult:[self.searchUICore getCurrentSearchResult] append:NO];
                });
                break;
            }
            case SEARCH_FINISHED:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.paused)
                        return;

                    self.searching = false;
                    if (!onSearchFinished || onSearchFinished(obj.requiredSearchPhrase))
                    {
                        [self showSearchIcon];
                        if (![self getResultCollection] || [[self getResultCollection] getCurrentSearchResults].count == 0)
                        {
                            [self addEmptyResult];
                        }
                        if ([self.searchUICore isSearchMoreAvailable:obj.requiredSearchPhrase])
                        {
                            [self addMoreButton];
                        }
                        else if (onPublish && (![self getResultCollection] || [[self getResultCollection] getCurrentSearchResults].count == 0))
                        {
                            onPublish([self getResultCollection], false);
                            [self addEmptyResult];
                        }
                    }
                });
                break;
            }
            case SEARCH_API_FINISHED:
            {
                OASearchCoreAPI *searchApi = (OASearchCoreAPI *) obj.object;
                NSMutableArray<OASearchResult *> *apiResults;
                OASearchPhrase *phrase = obj.requiredSearchPhrase;
                OASearchCoreAPI *regionApi = regionResultApi;
                OASearchResultCollection *regionCollection = regionResultCollection;
                BOOL hasRegionCollection = (searchApi == regionApi && regionCollection);
                if (hasRegionCollection)
                    apiResults = [NSMutableArray arrayWithArray:[regionCollection getCurrentSearchResults]];
                else
                    apiResults = results;

                regionResultApi = nil;
                regionResultCollection = nil;
                results = [NSMutableArray array];
                [self showApiResults:apiResults phrase:phrase hasRegionCollection:hasRegionCollection onPublish:onPublish];
                break;
            }
            case SEARCH_API_REGION_FINISHED:
            {
                regionResultApi = (OASearchCoreAPI *) obj.object;
                OASearchPhrase *regionPhrase = obj.requiredSearchPhrase;
                regionResultCollection = [[[OASearchResultCollection alloc] initWithPhrase:regionPhrase] addSearchResults:results resortAll:YES removeDuplicates:YES];
                [self showRegionResults:regionResultCollection onPublish:onPublish];
                break;
            }
            case PARTIAL_LOCATION:
            {
                // do not show
                break;
            }
            default:
            {
                [results addObject:obj];
            }
        }

        return true;

    } cancelledFunc:^BOOL {

        return self.paused || self.cancelPrev;
    }]];

    if (!searchMore)
    {
        [self setResultCollection:nil];
        if (!updateResult)
            [self updateSearchResult:nil append:NO];
    }
}

- (void) showApiResults:(NSArray<OASearchResult *> *)apiResults phrase:(OASearchPhrase *)phrase hasRegionCollection:(BOOL)hasRegionCollection onPublish:(OAPublishCallback)onPublish
{
    dispatch_async(dispatch_get_main_queue(), ^{

        if (!_paused && !_cancelPrev)
        {
            BOOL append = [self getResultCollection] != nil;
            if (append)
            {
                [[self getResultCollection] addSearchResults:apiResults resortAll:YES removeDuplicates:YES];
            }
            else
            {
                OASearchResultCollection *resCollection = [[OASearchResultCollection alloc] initWithPhrase:phrase];
                [resCollection addSearchResults:apiResults resortAll:YES removeDuplicates:YES];
                [self setResultCollection:resCollection];
            }
            if (!hasRegionCollection && onPublish)
                onPublish([self getResultCollection], append);
        }
    });
}

- (void) showRegionResults:(OASearchResultCollection *)regionResultCollection onPublish:(OAPublishCallback)onPublish
{
    dispatch_async(dispatch_get_main_queue(), ^{

        if (!_paused && !_cancelPrev)
        {
            if ([self getResultCollection])
            {
                OASearchResultCollection *resCollection = [[self getResultCollection] combineWithCollection:regionResultCollection resort:YES removeDuplicates:YES];
                if (onPublish)
                    onPublish(resCollection, YES);
            }
            else if (onPublish)
            {
                onPublish(regionResultCollection, NO);
            }
        }
    });
}

- (void) completeQueryWithObject:(OASearchResult *)sr
{
    if ([sr.object isKindOfClass:[OAPOIType class]] && [((OAPOIType *) sr.object) isAdditional])
    {
        OAPOIType *additional = (OAPOIType *) sr.object;
        OAPOIBaseType *parent = additional.parentType;
        if (parent)
        {
            OAPOIUIFilter *custom = [[OAPOIFiltersHelper sharedInstance] getFilterById:[NSString stringWithFormat:@"%@%@", STD_PREFIX, parent.name]];
            if (custom)
            {
                [custom clearFilter];
                [custom updateTypesToAccept:parent];
                [custom setFilterByName:[[additional.name stringByReplacingOccurrencesOfString:@"_" withString:@":"] lowerCase]];

                OASearchPhrase *phrase = [self.searchUICore getPhrase];
                sr = [[OASearchResult alloc] initWithPhrase:phrase];
                sr.localeName = custom.name;
                sr.object = custom;
                sr.priority = SEARCH_AMENITY_TYPE_PRIORITY;
                sr.priorityDistance = 0;
                sr.objectType = POI_TYPE;
            }
        }
    }
    [self.searchUICore selectSearchResult:sr];
    if (self.addressSearch)
    {
        [self startAddressSearch];
        if (sr.objectType == CITY)
        {
            OAAppSettings *settings = [OAAppSettings sharedManager];
            OACity *city = (OACity *) sr.object;
            settings.lastSearchedCity = city.addrId;
            settings.lastSearchedCityName = sr.localeName;
            settings.lastSearchedPoint = [[CLLocation alloc] initWithLatitude:city.latitude longitude:city.longitude];
        }
    }
    NSString *txt = [[self.searchUICore getPhrase] getText:YES];
    self.searchQuery = txt;
    [self updateTextField:txt];
    OASearchSettings *settings = [self.searchUICore getSearchSettings];
    if ([settings getRadiusLevel] != 1)
        [self.searchUICore updateSettings:[settings setRadiusLevel:1]];

    [self runCoreSearch:txt updateResult:NO searchMore:NO];
}

- (void) replaceQueryWithText:(NSString *)txt
{
    self.searchQuery = txt;
    [self updateTextField:txt];
    OASearchSettings *settings = [self.searchUICore getSearchSettings];
    if ([settings getRadiusLevel] != 1)
        [self.searchUICore updateSettings:[settings setRadiusLevel:1]];

    [self runCoreSearch:txt updateResult:NO searchMore:NO];
}

- (void) replaceQueryWithUiFilter:(OAPOIUIFilter *)filter nameFilter:(NSString *)nameFilter
{
    OASearchPhrase *searchPhrase = [self.searchUICore getPhrase];
    if ([searchPhrase isLastWord:POI_TYPE])
    {
        self.poiFilterApplied = YES;
        OASearchResult *sr = [searchPhrase getLastSelectedWord].result;
        sr.object = filter;
        sr.localeName = [filter getName];
        [[self.searchUICore getPhrase] syncWordsWithResults];
        NSString *txt = [[filter getName] stringByAppendingString:(nameFilter.length > 0 && [filter isStandardFilter] ? [@" " stringByAppendingString:nameFilter] : @" ")];
        self.searchQuery = txt;
        [self updateTextField:txt];
        [self runCoreSearch:txt updateResult:NO searchMore:NO];
    }
}

- (void) clearLastWord
{
    if (self.textField.text.length > 0)
    {
        NSString *newText = [[self.searchUICore getPhrase] getTextWithoutLastWord];
        [self updateTextField:newText];
    }
}

- (void) addMoreButton
{
    OAQuickSearchMoreListItem *moreListItem = [[OAQuickSearchMoreListItem alloc] initWithName:OALocalizedString(@"search_POI_level_btn") onClickFunction:^(id sender) {

        if (!self.interruptedSearch)
        {
            OASearchSettings *settings = [self.searchUICore getSearchSettings];
            [self.searchUICore updateSettings:[settings setRadiusLevel:[settings getRadiusLevel] + 1]];
        }
        [self runCoreSearch:self.searchQuery updateResult:NO searchMore:YES];
    }];

    if (!_paused && !_cancelPrev)
    {
        [_tableController addItem:moreListItem groupIndex:0];
        [_tableController reloadData];
    }
}

- (void) addEmptyResult
{
    OAQuickSearchEmptyResultListItem *item = [[OAQuickSearchEmptyResultListItem alloc] init];
    int minimalSearchRadius = [self.searchUICore getMinimalSearchRadius:self.searchUICore.getPhrase];
    if ([self.searchUICore isSearchMoreAvailable:self.searchUICore.getPhrase] && minimalSearchRadius != INT_MAX)
    {
        double rd = [OsmAndApp.instance calculateRoundedDist:minimalSearchRadius];
        item.title = [NSString stringWithFormat:OALocalizedString(@"nothing_found"), [OsmAndApp.instance getFormattedDistance:rd]];
    }

    if (!_paused && !_cancelPrev)
    {
        [_tableController addItem:item groupIndex:0];
        [_tableController reloadData];
    }
}

- (void)updateSearchResult:(OASearchResultCollection *)res append:(BOOL)append
{
    if (!_paused)
    {
        NSMutableArray<OAQuickSearchListItem *> *rows = [NSMutableArray array];
        if (res && [res getCurrentSearchResults].count > 0)
            for (OASearchResult *sr in [res getCurrentSearchResults])
                [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];

        [self updateData:rows append:append];
    }
}

- (void)createAndRefreshCustomFilter:(OAPOIUIFilter *)newFilter newName:(NSString *)newName
{
    if (newName.length > 0)
    {
        OAPOIUIFilter *filterToSave = [[OAPOIUIFilter alloc] initWithName:newName filterId:nil acceptedTypes:[newFilter getAcceptedTypes]];
        if (newFilter.filterByName.length > 0)
            [filterToSave setSavedFilterByName:newFilter.filterByName];

        if ([[OAPOIFiltersHelper sharedInstance] createPoiFilter:filterToSave])
        {
            [self.searchHelper refreshCustomPoiFilters];
            [self replaceQueryWithUiFilter:filterToSave nameFilter:@""];
            [self reloadCategories];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if (textField.text.length > 0)
    {
        NSString *newText = [[self.searchUICore getPhrase] getTextWithoutLastWord];
        [self updateTextField:newText];
        return NO;
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    return YES;
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (viewController == _historyViewController)
        return nil;
    else if (viewController == _addressViewController)
        return _categoriesViewController;
    else
        return _historyViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if (viewController == _addressViewController)
        return nil;
    else if (viewController == _categoriesViewController)
        return _addressViewController;
    else
        return _categoriesViewController;
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    NSInteger prevTabIndex = _tabs.selectedSegmentIndex;
    if (pageViewController.viewControllers[0] == _historyViewController)
        _tabs.selectedSegmentIndex = 0;
    else if (pageViewController.viewControllers[0] == _categoriesViewController)
        _tabs.selectedSegmentIndex = 1;
    else
        _tabs.selectedSegmentIndex = 2;

    if (prevTabIndex != _tabs.selectedSegmentIndex)
        [self processTabChange];
}

#pragma mark - OAQuickSearchTableController

- (void) didSelectResult:(OASearchResult *)result
{
    [self completeQueryWithObject:result];
}

- (void) didShowOnMap:(OASearchResult *)searchResult
{
    [self hideToolbar];
    [self addHistoryItem:searchResult];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OAAddressTableDelegate

- (void) reloadAddressData
{
    [self reloadCities];
}

#pragma mark - OACategoryTableDelegate

- (void)showCreateFilterScreen
{
    OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getCustomPOIFilter];
    [filter clearFilter];
    OACustomPOIViewController *customPOIScreen = [[OACustomPOIViewController alloc] initWithFilter:filter];
    customPOIScreen.delegate = self;
    [self.navigationController pushViewController:customPOIScreen animated:YES];

}

- (void)showDeleteFiltersScreen:(NSArray<OAPOIUIFilter *> *)filters
{
    OADeleteCustomFiltersViewController *removeFiltersScreen = [[OADeleteCustomFiltersViewController alloc] initWithFilters:filters];
    removeFiltersScreen.delegate = self;
    [self.navigationController pushViewController:removeFiltersScreen animated:YES];

}

- (void)showRearrangeFiltersScreen:(NSArray<OAPOIUIFilter *> *)filters
{
    OARearrangeCustomFiltersViewController *rearrangeCategoriesScreen = [[OARearrangeCustomFiltersViewController alloc] initWithFilters:filters];
    [self.navigationController pushViewController:rearrangeCategoriesScreen animated:YES];

}

- (NSArray<OAPOIUIFilter *> *)getCustomFilters
{
    return [[OAPOIFiltersHelper sharedInstance] getUserDefinedPoiFilters:NO];
}

- (NSArray<OAPOIUIFilter *> *)getSortedFiltersIncludeInactive
{
    return [[OAPOIFiltersHelper sharedInstance] getSortedPoiFilters:NO];
}

#pragma mark - OAHistoryTableDelegate

- (void) didSelectHistoryItem:(OAHistoryItem *)item
{
    if (self.searchType == OAQuickSearchType::REGULAR)
    {
        NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
        BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
        [OAQuickSearchTableController showHistoryItemOnMap:item lang:lang ? lang : @"" transliterate:transliterate];
    }
    else if (self.searchType == OAQuickSearchType::START_POINT || self.searchType == OAQuickSearchType::DESTINATION || self.searchType == OAQuickSearchType::INTERMEDIATE || self.searchType == OAQuickSearchType::HOME || self.searchType == OAQuickSearchType::WORK)
    {
        double latitude = item.latitude;
        double longitude = item.longitude;
        OAPointDescription *pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION typeName:item.typeName name:item.name];

        if (self.searchType == OAQuickSearchType::START_POINT || self.searchType == OAQuickSearchType::DESTINATION || self.searchType == OAQuickSearchType::INTERMEDIATE)
        {
            [[OARootViewController instance].mapPanel setRouteTargetPoint:self.searchType == OAQuickSearchType::DESTINATION intermediate:self.searchType == OAQuickSearchType::INTERMEDIATE latitude:latitude longitude:longitude pointDescription:pointDescription];
        }
        else if (self.searchType == OAQuickSearchType::HOME)
        {
            [[OATargetPointsHelper sharedInstance] setHomePoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:pointDescription];
        }
        else if(self.searchType == OAQuickSearchType::WORK)
        {
            [[OATargetPointsHelper sharedInstance] setWorkPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] description:pointDescription];
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) enterHistoryEditingMode
{
    _historyEditing = YES;
    [self setupBarActionView:BarActionEditHistory title:@""];
}

- (void) exitHistoryEditingMode
{
    [self finishHistoryEditing];
}

- (void) historyItemsSelected:(int)count
{
    [UIView performWithoutAnimation:^{
        if (count > 0)
            [_barActionTextButton setTitle:[NSString stringWithFormat:OALocalizedString(@"items_selected"), count] forState:UIControlStateNormal];
        else
            [_barActionTextButton setTitle:@"" forState:UIControlStateNormal];

        [_barActionTextButton layoutIfNeeded];
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - OAPOIFilterViewDelegate

- (BOOL)updateFilter:(OAPOIUIFilter *)filter nameFilter:(NSString *)nameFilter
{
    [self.searchHelper refreshCustomPoiFilters];
    [self replaceQueryWithUiFilter:filter nameFilter:nameFilter];
    return YES;
}

- (BOOL)removeFilter:(OAPOIUIFilter *)filter
{
    if ([[OAPOIFiltersHelper sharedInstance] removePoiFilter:filter])
    {
        [self.searchHelper refreshCustomPoiFilters];
        [self reloadCategories];
        [self clearLastWord];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (UIAlertController *)createSaveFilterDialog:(OAPOIUIFilter *)filter customSaveAction:(BOOL)customSaveAction
{
    UIAlertController *saveDialog = [UIAlertController alertControllerWithTitle:OALocalizedString(@"enter_name") message:OALocalizedString(@"new_filter_desc") preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* actionCancel = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil];
    [saveDialog addAction:actionCancel];

    if (!customSaveAction) {
        UIAlertAction *actionSave = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_save") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self searchByUIFilter:filter newName:saveDialog.textFields[0].text willSaved:YES];
        }];
        [saveDialog addAction:actionSave];
    }

    [saveDialog addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = filter.name;
    }];

    return saveDialog;
}

- (void)searchByUIFilter:(OAPOIUIFilter *)filter newName:(NSString *)newName willSaved:(BOOL)willSaved
{
    OASearchResult *sr = [[OASearchResult alloc] initWithPhrase:[_searchUICore getPhrase]];
    sr.localeName = [filter getName];
    sr.object = filter;
    sr.priority = 0;
    sr.objectType = POI_TYPE;
    [_searchUICore selectSearchResult:sr];

    NSString *txt = [[filter getName] stringByAppendingString:@" "];
    self.searchQuery = txt;
    [self updateTextField:txt];
    OASearchSettings *settings = [[_searchUICore getPhrase] getSettings];
    if ([settings getRadiusLevel] != 1)
        [_searchUICore updateSettings:[settings setRadiusLevel:1]];

    [self runCoreSearch:txt updateResult:NO searchMore:NO];

    [self setBottomViewVisible:!willSaved];
    if (willSaved)
        [self createAndRefreshCustomFilter:filter newName:newName];
}

#pragma mark - OASearchToolbarViewControllerProtocol

- (void)searchToolbarOpenSearch:(OAPOIUIFilter *)filter
{
    if (filter)
    {
        [[OARootViewController instance].mapPanel hideToolbar:_searchToolbarViewController];
        [[OARootViewController instance].mapPanel openSearch:filter location:[[CLLocation alloc] initWithLatitude:_searchLocation.latitude longitude:_searchLocation.longitude]];
    }
    else
    {
        [[OARootViewController instance].mapPanel openSearch];
    }
}

- (void)searchToolbarClose
{
    [self resetSearch];
    [[OAPOIFiltersHelper sharedInstance] clearSelectedPoiFilters];
    [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];
    [[OARootViewController instance].mapPanel hideToolbar:_searchToolbarViewController];
}

#pragma mark - OAPOIFiltersRemoveDelegate

- (BOOL)removeFilters:(NSArray<OAPOIUIFilter *> *)filters
{
    OAPOIFiltersHelper *filtersHelper = [OAPOIFiltersHelper sharedInstance];
    BOOL removed = YES;
    for (OAPOIUIFilter *filter in filters)
        if (![filtersHelper removePoiFilter:filter])
            removed = NO;
    [self.searchHelper refreshCustomPoiFilters];
    [self reloadCategories];
    return removed;
}

@end
