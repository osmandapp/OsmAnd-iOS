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
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAPOIHelper.h"
#import "OAPointDescCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAIconTextExTableViewCell.h"
#import "OASearchMoreCell.h"
#import "OAIconTextDescCell.h"
#import "OAAutoObserverProxy.h"
#import "OAUtilities.h"
#import "OAPOIFavType.h"
#import "OAFavoriteItem.h"
#import "OAHistoryItem.h"
#import "OAHistoryHelper.h"
#import "OAPOIHistoryType.h"
#import "OAPOISearchHelper.h"
#import "OACategoriesTableViewController.h"
#import "OAHistoryTableViewController.h"
#import "OACustomPOIViewController.h"
#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFilterViewController.h"
#import "OAQuickSearchListItem.h"
#import "OAQuickSearchMoreListItem.h"

#import "OASearchUICore.h"
#import "OASearchCoreFactory.h"
#import "OAQuickSearchHelper.h"
#import "OASearchWord.h"
#import "OASearchPhrase.h"
#import "OASearchResult.h"
#import "OASearchSettings.h"
#import "OAQuickSearchTableController.h"

#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OADefaultFavorite.h"
#import "OANativeUtilities.h"

#import "Localization.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/IFavoriteLocation.h>

#define kMaxTypeRows 5
#define kInitialSearchToolbarHeight 64.0
#define kBarActionViewHeight 44.0
#define kTabsHeight 40.0

typedef NS_ENUM(NSInteger, BarActionType)
{
    BarActionNone = 0,
    BarActionShowOnMap,
    BarActionEditHistory,
};

@interface OAQuickSearchViewController () <OAQuickSearchTableDelegate, UITextFieldDelegate, UIPageViewControllerDataSource, OACategoryTableDelegate, OAHistoryTableDelegate, UIGestureRecognizerDelegate, UIPageViewControllerDelegate, OACustomPOIViewDelegate, UIAlertViewDelegate, OAPOIFilterViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
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

@property (nonatomic) NSString* searchQuery;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;
@property NSTimeInterval lastUpdate;

@property (strong, nonatomic) dispatch_queue_t searchDispatchQueue;
@property (strong, nonatomic) dispatch_queue_t updateDispatchQueue;

@property (nonatomic) BOOL decelerating;
@property (nonatomic) BOOL paused;
@property (nonatomic) BOOL foundPartialLocation;
@property (nonatomic) BOOL interruptedSearch;
@property (nonatomic) BOOL searching;
@property (nonatomic) BOOL runSearchFirstTime;
@property (nonatomic) BOOL poiFilterApplied;

@property (nonatomic) OAQuickSearchHelper *searchHelper;
@property (nonatomic) OASearchUICore *searchUICore;
@property (nonatomic) CLLocationCoordinate2D searchLocation;


@end

@implementation OAQuickSearchViewController
{
    UIPanGestureRecognizer *_tblMove;
    
    UIImageView *_leftImgView;
    UIActivityIndicatorView *_activityIndicatorView;
    
    OAPOIUIFilter *_filter;
    OAPOIUIFilter *_filterToSave;

    OAQuickSearchTableController *_tableController;

    UIPageViewController *_pageController;
    OACategoriesTableViewController *_categoriesViewController;
    OAHistoryTableViewController *_historyViewController;
    
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
    self.tableView.dataSource = _tableController;
    self.tableView.delegate = _tableController;
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
    
    _categoriesViewController = [[OACategoriesTableViewController alloc] initWithFrame:_pageController.view.bounds];
    _categoriesViewController.delegate = self;
    if (_searchNearMapCenter)
        [_categoriesViewController setMapCenterCoordinate:_searchLocation];
    else
        [_categoriesViewController resetMapCenterSearch];
    
    _historyViewController = [[OAHistoryTableViewController alloc] initWithFrame:_pageController.view.bounds];
    _historyViewController.delegate = self;
    _historyViewController.searchNearMapCenter = _searchNearMapCenter;
    _historyViewController.myLocation = _myLocation;
    
    [_pageController setViewControllers:@[_historyViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [_tabs setTitle:OALocalizedString(@"history") forSegmentAtIndex:0];
    [_tabs setTitle:OALocalizedString(@"categories") forSegmentAtIndex:1];
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

    [self showSearchIcon];
    [self updateSearchNearMapCenterLabel];
    [self showTabs];
}

-(void)viewWillAppear:(BOOL)animated
{
    self.decelerating = NO;
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

- (void)appplicationIsActive:(NSNotification *)notification
{
    [self showSearchIcon];
}

-(void)viewWillLayoutSubviews
{
    [self updateNavbar];
}

- (void) setupSearch
{
    // Setup search core
    NSString *locale = [OAAppSettings sharedManager].settingPrefMapLanguage;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit;
    self.searchHelper = [OAQuickSearchHelper instance];
    self.searchUICore = [self.searchHelper getCore];

    [self setResultCollection:nil];
    [self.searchUICore resetPhrase];
    
    OASearchSettings *settings = [[self.searchUICore getSearchSettings] setOriginalLocation:[[CLLocation alloc] initWithLatitude:_searchLocation.latitude longitude:_searchLocation.longitude]];
    settings = [settings setLang:locale transliterateIfMissing:transliterate];
    [self.searchUICore updateSettings:settings];
    
    __weak OAQuickSearchViewController *weakSelf = self;
    self.searchUICore.onResultsComplete = ^void() {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.searching = false;
            if (!weakSelf.paused)
            {
                [weakSelf showSearchIcon];
                if ([weakSelf.searchUICore isSearchMoreAvailable:[weakSelf.searchUICore getPhrase]])
                    [weakSelf addMoreButton];
            }
        });
    };
}

- (void)setupBarActionView:(BarActionType)type title:(NSString *)title
{
    if (_barActionType == type)
        return;
    
    switch (type)
    {
        case BarActionShowOnMap:
        {
            _barActionLeftImageButton.hidden = YES;
            UIImage *mapImage = [UIImage imageNamed:@"waypoint_map_disable.png"];
            mapImage = [mapImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
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
                        [_barActionTextButton setTitle:OALocalizedString(@"show_something_on_map", word.result.localeName) forState:UIControlStateNormal];
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
}

- (void)updateTabsVisibility:(BOOL)show
{
    if (show && ![self tabsVisible])
        [self showTabs];
    else if (!show && [self tabsVisible])
        [self hideTabs];
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
    if (_tabs.selectedSegmentIndex == 0)
    {
        [_pageController setViewControllers:@[_historyViewController] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:nil];
    }
    else
    {
        [_pageController setViewControllers:@[_categoriesViewController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
    }
}

- (IBAction)barActionTextButtonPress:(id)sender
{
    switch (_barActionType)
    {
        case BarActionShowOnMap:
        {
            OASearchPhrase *searchPhrase = [self.searchUICore getPhrase];
            if ([searchPhrase isNoSelectedType] || [searchPhrase isLastWord:POI_TYPE])
            {
                OAPOIUIFilter *filter;
                if ([searchPhrase isNoSelectedType])
                {
                    filter = [[OAPOIFiltersHelper sharedInstance] getSearchByNamePOIFilter];
                    if ([searchPhrase getUnknownSearchWord].length > 0)
                    {
                        [filter setFilterByName:[searchPhrase getUnknownSearchWord]];
                        [filter clearCurrentResults];
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
                    if ([searchPhrase getUnknownSearchWord].length > 0)
                        [filter setFilterByName:[searchPhrase getUnknownSearchWord]];
                }
                else
                {
                    filter = (OAPOIUIFilter *) [searchPhrase getLastSelectedWord].result.object;
                }
                [[OAPOIFiltersHelper sharedInstance] clearSelectedPoiFilters];
                [[OAPOIFiltersHelper sharedInstance] addSelectedPoiFilter:filter];
                
                OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
                [mapVC showPoiOnMap:filter keyword:[[searchPhrase getUnknownSearchPhrase] trim]];
                [self dismissViewControllerAnimated:YES completion:nil];

                //mapActivity.getContextMenu().closeActiveToolbar();
                //showToolbar();
                //getMapActivity().refreshMap();
                //hide();
            }
            else
            {
                OASearchWord *word = [searchPhrase getLastSelectedWord];
                if (word && [word getLocation])
                {
                    OASearchResult *searchResult = word.result;
                    [OAQuickSearchTableController showOnMap:searchResult delegate:self];

                    //[self addHistoryItem:item type:OAHistoryType];
                    //hideToolbar();
                    //reloadHistory();
                    //hide();
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
    if (_filter)
        [self doSaveFilter:_filter];
}

- (IBAction)bottomImageButtonPress:(id)sender
{
    [self setBottomViewVisible:NO];
}

- (void) updateBarActionView
{
    if (!_historyEditing)
    {
        if (self.textField.text.length > 0)
            [self setupBarActionView:BarActionShowOnMap title:nil];
        else
            [self setupBarActionView:BarActionNone title:nil];
        [self.view setNeedsLayout];
    }
}

- (void) doSaveFilter:(OAPOIUIFilter *)filter
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:OALocalizedString(@"enter_name") message:OALocalizedString(@"new_filter_desc") delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") otherButtonTitles: OALocalizedString(@"shared_string_save"), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [alert textFieldAtIndex:0].text = filter.name;
    _filterToSave = filter;
    [alert show];
}

- (void) setFilter:(OAPOIUIFilter *)filter
{
    _filter = filter;
    [self setBottomViewVisible:_filter && ![_filter isEmpty] && _filter == [[OAPOIFiltersHelper sharedInstance] getCustomPOIFilter]];
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
    [self.view setNeedsLayout];
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
            [_categoriesViewController setMapCenterCoordinate:_searchLocation];
            [_tableController setMapCenterCoordinate:_searchLocation];
        }
        else
        {
            _historyViewController.searchNearMapCenter = searchNearMapCenter;
            [_categoriesViewController resetMapCenterSearch];
            [_tableController resetMapCenterSearch];
        }
        [self updateSearchNearMapCenterLabel];
        
        [self.view setNeedsLayout];
    }
}

-(void)setMyLocation:(OsmAnd::PointI)myLocation
{
    _myLocation = myLocation;
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(myLocation);
    _searchLocation = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    
    if (self.isViewLoaded)
        [self.view setNeedsLayout];
}

-(void)updateNavbar
{
    BOOL showBarActionView = _barActionType != BarActionNone;
    BOOL showInputView = _barActionType != BarActionEditHistory;
    BOOL showMapCenterSearch = !showBarActionView && _searchNearMapCenter && self.searchQuery.length == 0;
    BOOL showTabs = [self tabsVisible] && _barActionType != BarActionEditHistory;
    CGRect frame = _topView.frame;
    frame.size.height = (showInputView ? kInitialSearchToolbarHeight : 20.0) + (showMapCenterSearch || showBarActionView ? kBarActionViewHeight : 0.0)  + (showTabs ? kTabsHeight : 0.0);
    
    _textField.hidden = !showInputView;
    _btnCancel.hidden = !showInputView;
    _barActionView.hidden = !showBarActionView;
    _searchNearCenterView.hidden = !showMapCenterSearch;
    _tabs.hidden = !showTabs;
    
    _barActionView.frame = CGRectMake(0.0, showInputView ? 60.0 : 20.0, _barActionView.bounds.size.width, _barActionView.bounds.size.height);
    
    _topView.frame = frame;
    _tableView.frame = CGRectMake(0.0, frame.size.height, frame.size.width, DeviceScreenHeight - frame.size.height - (_bottomViewVisible ? _bottomView.bounds.size.height : 0.0));
    _pageController.view.frame = _tableView.frame;
}

-(void)updateSearchNearMapCenterLabel
{
    _lbSearchNearCenter.text = [NSString stringWithFormat:@"%@ %@ %@", OALocalizedString(@"you_searching"), [[OsmAndApp instance] getFormattedDistance:self.distanceFromMyLocation], OALocalizedString(@"from_location")];
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
    if (self.decelerating || [[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3)
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        self.lastUpdate = [[NSDate date] timeIntervalSince1970];
        [self refreshVisibleRows];
        [_historyViewController updateDistanceAndDirection];
    });
}

- (void)refreshVisibleRows
{
    [_tableView reloadData];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    [mapVC hidePoi];
}

-(void)updateData:(NSMutableArray<OAQuickSearchListItem *> *)dataArray append:(BOOL)append
{
    [_tableController updateData:dataArray append:append];
}

-(void)updateTextField:(NSString *)text
{
    NSString *t = (text ? text : @"");
    _textField.text = t;
    
    [self.view setNeedsLayout];
}

-(void)setupView
{
}

- (void)addHistoryItem:(OAPOI *)poi type:(OAHistoryType)type
{
    OAHistoryItem *h = [[OAHistoryItem alloc] init];
    h.name = poi.nameLocalized;
    h.latitude = poi.latitude;
    h.longitude = poi.longitude;
    h.date = [NSDate date];
    h.iconName = [poi.type iconName];
    h.typeName = poi.type.nameLocalized;
    h.hType = type;
    
    [[OAHistoryHelper sharedInstance] addPoint:h];
}

- (IBAction)btnCancelClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btnMyLocationClicked:(id)sender
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
            //[self generateData];
        }];
    }
}

- (IBAction)textFieldValueChanged:(id)sender
{
    NSString *newQueryText = _textField.text;
    //updateClearButtonAndHint();
    //updateClearButtonVisibility(true);
    BOOL textEmpty = newQueryText.length == 0;
    [self updateTabsVisibility:textEmpty];
    if (textEmpty && self.poiFilterApplied)
    {
        self.poiFilterApplied = NO;
        [self reloadCategories];
    }
    if ([self.searchQuery localizedCaseInsensitiveCompare:newQueryText] != NSOrderedSame)
    {
        self.searchQuery = newQueryText;
        if (self.searchQuery.length == 0)
            [self.searchUICore resetPhrase];
        else
            [self runSearch];
        
    }
    else if (self.runSearchFirstTime)
    {
        self.runSearchFirstTime = NO;
        [self runSearch];
    }

    [self.view setNeedsLayout];
}

- (void)goToPoint:(double)latitude longitude:(double)longitude
{
    OAPOI *poi = [[OAPOI alloc] init];
    poi.latitude = latitude;
    poi.longitude = longitude;
    poi.nameLocalized = @"";
    
    [self goToPoint:poi];
}

- (void)goToPoint:(OAPOI *)poi
{
    const OsmAnd::LatLon latLon(poi.latitude, poi.longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    Point31 pos = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [mapVC goToPosition:pos andZoom:kDefaultFavoriteZoomOnShow animated:YES];
    [mapVC showContextPinMarker:poi.latitude longitude:poi.longitude animated:NO];
    
    CGPoint touchPoint = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    touchPoint.x *= mapRendererView.contentScaleFactor;
    touchPoint.y *= mapRendererView.contentScaleFactor;
    
    OAMapSymbol *symbol = [OAMapViewController getMapSymbol:poi];
    symbol.touchPoint = CGPointMake(touchPoint.x, touchPoint.y);
    symbol.centerMap = YES;
    [OAMapViewController postTargetNotification:symbol];
    
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

-(void)runSearch
{
    [self runSearch:self.searchQuery];
}

- (void) runSearch:(NSString *)text
{
    [self showSearchIcon];
    OASearchSettings *settings = [[self.searchUICore getPhrase] getSettings];
    if ([settings getRadiusLevel] != 1)
        [self.searchUICore updateSettings:[settings setRadiusLevel:1]];
    
    [self runCoreSearch:text updateResult:YES searchMore:NO];
}

- (void) runCoreSearch:(NSString *)text updateResult:(BOOL)updateResult searchMore:(BOOL)searchMore
{
    self.foundPartialLocation = false;
    [self updateBarActionView];
    self.interruptedSearch = false;
    self.searching = true;
    
    OASearchResultCollection __block *regionResultCollection;
    OASearchCoreAPI __block *regionResultApi;
    NSMutableArray<OASearchResult *> __block *results = [NSMutableArray array];

    OASearchResultCollection *c = [self.searchUICore search:text matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
        
        if (self.paused)
        {
            if (results.count > 0)
                [[self getResultCollection] addSearchResults:results resortAll:YES removeDuplicates:YES];
            
            return NO;
        }
        OASearchResult *obj = *object;
        switch (obj.objectType)
        {
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
                [self showApiResults:apiResults phrase:phrase hasRegionCollection:hasRegionCollection];
                break;
            }
            case SEARCH_API_REGION_FINISHED:
            {
                regionResultApi = (OASearchCoreAPI *) obj.object;
                OASearchPhrase *regionPhrase = obj.requiredSearchPhrase;
                regionResultCollection = [[[OASearchResultCollection alloc] initWithPhrase:regionPhrase] addSearchResults:results resortAll:YES removeDuplicates:YES];
                [self showRegionResults:regionResultCollection];
                break;
            }
            case PARTIAL_LOCATION:
            {
                //[self showLocationToolbar];
                break;
            }
            default:
            {
                [results addObject:obj];
            }
        }
        
        return false;

    } cancelledFunc:^BOOL {
        
        return self.paused;
    }]];
    
    if (!searchMore)
    {
        [self setResultCollection:nil];
        if (!updateResult)
            [self updateSearchResult:nil append:NO];
    }
    if (updateResult)
        [self updateSearchResult:c append:NO];
}

- (void) showApiResults:(NSArray<OASearchResult *> *)apiResults phrase:(OASearchPhrase *)phrase hasRegionCollection:(BOOL)hasRegionCollection
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!_paused)
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
            if (!hasRegionCollection)
                [self updateSearchResult:[self getResultCollection] append:append];
        }
    });
}

- (void) showRegionResults:(OASearchResultCollection *)regionResultCollection
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!_paused)
        {
            if ([self getResultCollection])
            {
                OASearchResultCollection *resCollection = [[self getResultCollection] combineWithCollection:regionResultCollection resort:YES removeDuplicates:YES];
                [self updateSearchResult:resCollection append:YES];
            }
            else
            {
                [self updateSearchResult:regionResultCollection append:NO];
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
    NSString *txt = [[self.searchUICore getPhrase] getText:YES];
    self.searchQuery = txt;
    [self updateTextField:txt];
    [self updateBarActionView];
    OASearchSettings *settings = [[self.searchUICore getPhrase] getSettings];
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
        [self updateBarActionView];
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
            OASearchSettings *settings = [[self.searchUICore getPhrase] getSettings];
            [self.searchUICore updateSettings:[settings setRadiusLevel:[settings getRadiusLevel] + 1]];
        }
        [self runCoreSearch:self.searchQuery updateResult:NO searchMore:YES];
    }];

    if (!_paused)
        [_tableController addItem:moreListItem];
}

- (void) updateSearchResult:(OASearchResultCollection *)res append:(BOOL)append
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
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
    else
        return _historyViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if (viewController == _categoriesViewController)
        return nil;
    else
        return _categoriesViewController;
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (pageViewController.viewControllers[0] == _historyViewController)
        _tabs.selectedSegmentIndex = 0;
    else
        _tabs.selectedSegmentIndex = 1;
}

#pragma mark - OAQuickSearchTableController

- (void) didSelectResult:(OASearchResult *)result
{
    [self completeQueryWithObject:result];
}

- (void) didShowOnMap:(OASearchResult *)result
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - OACategoryTableDelegate

-(void) createPOIUIFIlter
{
    OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getCustomPOIFilter];
    [filter clearFilter];
    OACustomPOIViewController *customPOI = [[OACustomPOIViewController alloc] initWithFilter:filter];
    customPOI.delegate = self;
    [self.navigationController pushViewController:customPOI animated:YES];    
}

#pragma mark - OAHistoryTableDelegate

-(void)didSelectHistoryItem:(OAHistoryItem *)item
{
    NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage;
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit;
    [OAQuickSearchTableController showHistoryItemOnMap:item lang:lang transliterate:transliterate];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)enterHistoryEditingMode
{
    _historyEditing = YES;
    [self setupBarActionView:BarActionEditHistory title:@""];
    [self.view setNeedsLayout];
}

- (void)exitHistoryEditingMode
{
    [self finishHistoryEditing];
}

- (void)historyItemsSelected:(int)count
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - OACustomPOIViewDelegate

-(void)searchByUIFilter:(OAPOIUIFilter *)filter
{
    /*
    [self setFilter:filter];
    self.searchQuery = [NSString stringWithFormat:@"%@ %@", filter.name, nameFilter.length > 0 && [filter isStandardFilter] ? [nameFilter stringByAppendingString:@" "] : @""];
    [self updateTextField:self.searchQuery];
     */
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        NSString* newName = [[alertView textFieldAtIndex:0].text trim];
        if (newName.length > 0)
        {
            OAPOIUIFilter *nFilter = [[OAPOIUIFilter alloc] initWithName:newName filterId:nil acceptedTypes:[_filterToSave getAcceptedTypes]];
            if (_filterToSave.filterByName.length > 0)
                [nFilter setSavedFilterByName:_filterToSave.filterByName];
            
            if ([[OAPOIFiltersHelper sharedInstance] createPoiFilter:nFilter])
            {
                [self.searchHelper refreshCustomPoiFilters];
                [self searchByUIFilter:nFilter];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }
    }
}

#pragma mark - OAPOIFilterViewDelegate

- (BOOL) updateFilter:(OAPOIUIFilter *)filter nameFilter:(NSString *)nameFilter
{
    [self.searchHelper refreshCustomPoiFilters];
    [self searchByUIFilter:filter];
    return YES;
}

- (BOOL) saveFilter:(OAPOIUIFilter *)filter
{
    [self doSaveFilter:filter];
    return NO;
}

- (BOOL) removeFilter:(OAPOIUIFilter *)filter
{
    if ([[OAPOIFiltersHelper sharedInstance] removePoiFilter:filter])
    {
        [self.searchHelper refreshCustomPoiFilters];
        
        [self setFilter:nil];
        self.searchQuery = nil;
        [self updateTextField:self.searchQuery];
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.decelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self.decelerating = NO;
        //[self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.decelerating = NO;
    //[self refreshVisibleRows];
}


@end
