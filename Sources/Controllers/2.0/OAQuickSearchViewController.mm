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

#import "OASearchUICore.h"
#import "OASearchCoreFactory.h"
#import "OAQuickSearchHelper.h"
#import "OASearchWord.h"
#import "OASearchPhrase.h"
#import "OASearchResult.h"
#import "OASearchSettings.h"

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
    BarActionShownMap,
    BarActionEditHistory,
};

@interface OAQuickSearchViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIPageViewControllerDataSource, OACategoryTableDelegate, OAHistoryTableDelegate, UIGestureRecognizerDelegate, UIPageViewControllerDelegate, OACustomPOIViewDelegate, UIAlertViewDelegate, OAPOIFilterViewDelegate>

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


@property (nonatomic) NSMutableArray* dataArray;
@property (nonatomic) NSMutableArray* dataArrayTemp;
@property (nonatomic) NSMutableArray* dataPoiArray;
@property (nonatomic) NSMutableArray* searchPoiArray;

@property (nonatomic) NSString* searchString;
@property (nonatomic) NSString* searchStringPrev;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;
@property NSTimeInterval lastUpdate;

@property (strong, nonatomic) dispatch_queue_t searchDispatchQueue;
@property (strong, nonatomic) dispatch_queue_t updateDispatchQueue;

@end

@implementation OAQuickSearchViewController
{
    BOOL isDecelerating;
    BOOL _isSearching;
    BOOL _paused;
    
    UIPanGestureRecognizer *_tblMove;
    
    UIImageView *_leftImgView;
    UIActivityIndicatorView *_activityIndicatorView;
    
    int _searchRadiusIndex;
    int _searchRadiusIndexMax;

    OAPOIBaseType *_poiBaseType;
    OAPOIUIFilter *_filter;
    OAPOIUIFilter *_filterToSave;

    UIPageViewController *_pageController;
    OACategoriesTableViewController *_categoriesViewController;
    OAHistoryTableViewController *_historyViewController;
    
    BarActionType _barActionType;
    BOOL _historyEditing;
    
    BOOL _bottomViewVisible;
    BOOL _showTopList;
    BOOL _dataInvalidated;

    OAQuickSearchHelper *_searchHelper;
    OASearchUICore *_searchUICore;
}
/*
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
    _searchHelper = [OAQuickSearchHelper instance];
    _searchUICore = [_searchHelper getCore];
    
    _searchRadiusIndexMax = (sizeof kSearchRadiusKm) / (sizeof kSearchRadiusKm[0]) - 1;
    _showTopList = YES;
}

-(void)applyLocalization
{
    [_btnCancel setTitle:OALocalizedString(@"poi_hide") forState:UIControlStateNormal];
    [_bottomTextBtn setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    _categoriesViewController.searchNearMapCenter = _searchNearMapCenter;
    
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
    
    [self showSearchIcon];
    [self generateData];
    
    [self updateSearchNearMapCenterLabel];
    
    [self showTabs];
}

-(void)viewWillAppear:(BOOL)animated
{
    isDecelerating = NO;
    _paused = NO;
    
    [self setupView];
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];
    
    [self registerForKeyboardNotifications];
    
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showSearchIcon];
    [self.textField becomeFirstResponder];
    
    if (_dataInvalidated)
    {
        if (!self.searchString && _currentScope == EPOIScopeUndefined && !_showTopList)
            _showTopList = YES;
        
        [self generateData];
    }
    else if (!self.searchString && _currentScope == EPOIScopeUndefined && !_showTopList)
    {
        _showTopList = YES;
        [self generateData];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    _paused = YES;
 
    if (self.locationServicesUpdateObserver) {
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

- (void)setupBarActionView:(BarActionType)type title:(NSString *)title
{
    if (_barActionType == type)
        return;
    
    switch (type)
    {
        case BarActionShownMap:
        {
            _barActionLeftImageButton.hidden = YES;
            UIImage *mapImage = [UIImage imageNamed:@"waypoint_map_disable.png"];
            mapImage = [mapImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _barActionImageView.image = mapImage;
            _barActionImageView.hidden = NO;
            
            [UIView performWithoutAnimation:^{
                if (title)
                    [_barActionTextButton setTitle:title forState:UIControlStateNormal];
                else
                    [_barActionTextButton setTitle:OALocalizedString(@"map_settings_show") forState:UIControlStateNormal];
                
                [_barActionTextButton layoutIfNeeded];
            }];
            _barActionTextButton.hidden = NO;
            _barActionTextButton.userInteractionEnabled = YES;
            
            [_barActionImageButton setImage:[UIImage imageNamed:@"ic_search_filter.png"] forState:UIControlStateNormal];
            _barActionImageButton.hidden = NO;
            
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

- (void)updateTabsVisibility
{
    if (_showTopList && ![self tabsVisible])
    {
        [self showTabs];
    }
    else if (!_showTopList && [self tabsVisible])
    {
        [self hideTabs];
    }
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
        case BarActionShownMap:
        {
            OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
            NSString *str = [[self nextToken:self.searchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (_currentScope == EPOIScopeUIFilter && _filter)
                [mapVC showPoiOnMap:_filter keyword:str];
            else
                [mapVC showPoiOnMap:_currentScopeCategoryName type:_currentScopePoiTypeName filter:_currentScopeFilterName keyword:str];
            [self dismissViewControllerAnimated:YES completion:nil];
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
        case BarActionShownMap:
        {
            if (_currentScope == EPOIScopeUIFilter)
            {
                NSString *nextStr = [[self nextToken:self.searchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                OAPOIFilterViewController *filterViewController = [[OAPOIFilterViewController alloc] initWithFilter:_filter filterByName:nextStr];
                filterViewController.delegate = self;
                [self.navigationController pushViewController:filterViewController animated:YES];
            }
            else if (_poiBaseType)
            {
                OAPOIUIFilter *custom = [[OAPOIFiltersHelper sharedInstance] getFilterById:[STD_PREFIX stringByAppendingString:_poiBaseType.name]];
                if (custom)
                {
                    [custom setFilterByName:nil];
                    [custom clearFilter];
                    [custom updateTypesToAccept:_poiBaseType];
                    
                    NSString *nextStr = [[self nextToken:self.searchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    OAPOIFilterViewController *filterViewController = [[OAPOIFilterViewController alloc] initWithFilter:custom filterByName:nextStr];
                    filterViewController.delegate = self;
                    [self.navigationController pushViewController:filterViewController animated:YES];
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
    _coreFoundScopeUIFilterName = nil;
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
        _historyViewController.searchNearMapCenter = searchNearMapCenter;
        _categoriesViewController.searchNearMapCenter = searchNearMapCenter;
        [self updateSearchNearMapCenterLabel];
        
        _dataInvalidated = YES;
        [self.view setNeedsLayout];
    }
}

-(void)setMyLocation:(OsmAnd::PointI)myLocation
{
    _myLocation = myLocation;
    
    if (self.isViewLoaded)
    {
        _historyViewController.myLocation = myLocation;
        _dataInvalidated = YES;
        [self.view setNeedsLayout];
    }
}

-(void)updateNavbar
{
    BOOL showBarActionView = _barActionType != BarActionNone;
    BOOL showInputView = _barActionType != BarActionEditHistory;
    BOOL showMapCenterSearch = !showBarActionView && _searchNearMapCenter && self.searchString.length == 0;
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
    if (!_poiInList)
        return;
    
    if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !_initData)
        return;
    self.lastUpdate = [[NSDate date] timeIntervalSince1970];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDistancesAndSort];
        [_historyViewController updateDistanceAndDirection];
    });
}

-(void)updateDistancesAndSort
{
    OsmAndAppInstance app = [OsmAndApp instance];
    // Obtain fresh location and heading
    CLLocation* newLocation = app.locationServices.lastKnownLocation;
    if (_searchNearMapCenter)
    {
        OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(_myLocation);
        newLocation = [[CLLocation alloc] initWithLatitude:latLon.latitude longitude:latLon.longitude];
    }
    if (!newLocation)
    {
        return;
    }
    CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection =
    (newLocation.speed >= 1 && newLocation.course >= 0.0f)
    ? newLocation.course
    : newHeading;
    
    NSMutableArray *arr = [NSMutableArray array];
    double radius = kSearchRadiusKm[_searchRadiusIndex] * 1000.0;
    
    [_dataPoiArray enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
        
        if ([item isKindOfClass:[OAPOI class]])
        {
            OAPOI *itemData = item;
            const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                              newLocation.coordinate.latitude,
                                                              itemData.longitude, itemData.latitude);
            
            itemData.distance = [app getFormattedDistance:distance];
            itemData.distanceMeters = distance;
            CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:itemData.latitude longitude:itemData.longitude]];
            itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
            
            if (_currentScope == EPOIScopeUndefined || distance <= radius)
                [arr addObject:item];
        }
        else
        {
            [arr addObject:item];
        }
        
    }];
    
    if ([arr count] > 0)
    {
        NSArray *sortedArray = [arr sortedArrayUsingComparator:^NSComparisonResult(OAPOI *obj1, OAPOI *obj2)
                                {
                                    double distance1 = obj1.distanceMeters;
                                    double distance2 = obj2.distanceMeters;
                                    
                                    return distance1 > distance2 ? NSOrderedDescending : distance1 < distance2 ? NSOrderedAscending : NSOrderedSame;
                                }];
        
        [_dataPoiArray setArray:sortedArray];
    }
    else
    {
        [_dataPoiArray setArray:arr];
    }
    
    if (isDecelerating)
        return;
    
    [_tableView reloadData];
    if (_initData && _dataPoiArray.count > 0)
    {
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
    _initData = NO;
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

-(void)generateData
{
    // hide poi
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    [mapVC hidePoi];
    
    if (_currentScope == EPOIScopeUndefined)
        [self setupBarActionView:BarActionNone title:nil];
    
    NSString *searchStr = [self.searchString copy];
    if (!searchStr || _showTopList)
        _searchRadiusIndex = 0;
    
    if (searchStr)
    {
        if ([searchStr isEqualToString:self.searchStringPrev] && !_dataInvalidated)
            return;
        else
            self.searchStringPrev = [searchStr copy];
        
        _dataInvalidated = NO;
        [self startCoreSearch];
    }
    else
    {
        dispatch_async(self.updateDispatchQueue, ^{
            
            self.searchStringPrev = nil;
            
            OASearchResultCollection *res = [_searchUICore shallowSearch:[OASearchAmenityTypesAPI class] text:@"" matcher:nil];
            NSMutableArray<OAQuickSearchListItem *> rows = [NSMutableArray array];
            if (res)
            {
                for (OASearchResult *sr in [res getCurrentSearchResults])
                    [rows addObject:[[OAQuickSearchListItem alloc] initWithSearchResult:sr]];
 
                rows.add(new CustomSearchButton(app, new OnClickListener() {
                    @Override
                    public void onClick(View v) {
                        PoiUIFilter filter = app.getPoiFilters().getCustomPOIFilter();
                        filter.clearFilter();
                        QuickSearchCustomPoiFragment.showDialog(
                                                                QuickSearchDialogFragment.this, filter.getFilterId());
                    }
                }));
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showSearchIcon];

                _categoriesViewController.dataArray = rows;
                [_categoriesViewController.tableView reloadData];
                if (_categoriesViewController.dataArray.count > 0)
                    [_categoriesViewController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                
                [_historyViewController reloadData];
                self.dataArray = [NSMutableArray array];
                
                self.dataPoiArray = [NSMutableArray array];
                [self refreshTable];
            });
        });
    }
}

-(void)refreshTable
{
    [_tableView reloadData];
    if (_dataArray.count > 0 || _dataPoiArray.count > 0)
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

-(void)updateTextField:(NSString *)text
{
    NSString *t = (text ? text : @"");
    _textField.text = t;
    
    [self.view setNeedsLayout];
    [self generateData];
    [self updateTabsVisibility];
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
        OsmAnd::PointI myLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(newLocation.coordinate.latitude, newLocation.coordinate.longitude));
        
        _poiInList = NO;
        [_searchPoiArray removeAllObjects];
        _searchRadiusIndex = 0;
        self.myLocation = myLocation;
        _historyViewController.myLocation = myLocation;
        
        [self setSearchNearMapCenter:NO];
        [UIView animateWithDuration:.25 animations:^{
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            [self generateData];
        }];
    }
}

- (IBAction)textFieldValueChanged:(id)sender
{
    if (_textField.text.length > 0)
    {
        self.searchString = _textField.text;
        _showTopList = NO;
    }
    else
    {
        _showTopList = YES;
        [self setFilter:nil];
        self.searchString = nil;
    }
    
    [self.view setNeedsLayout];
    [self generateData];
    [self updateTabsVisibility];
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
    [_searchHelper setResultCollection:resultCollection];
}

- (OASearchResultCollection *) getResultCollection
{
    return [_searchHelper getResultCollection];
}

-(void)runSearch
{
    [self runSearch:self.searchString];
}

- (void) runSearch:(NSString *)text
{
    [self showSearchIcon];
    OASearchSettings *settings = [[_searchUICore getPhrase] getSettings];
    if ([settings getRadiusLevel] != 1)
        [_searchUICore updateSettings:[settings setRadiusLevel:1]];
    
    [self runCoreSearch:text, true, false];
}

- (void) runCoreSearch:(NSString *)text updateResult:(BOOL)updateResult searchMore:(BOOL)searchMore
{
    foundPartialLocation = false;
    //updateToolbarButton();
    interruptedSearch = false;
    searching = true;
    cancelPrev = true;
    
    OASearchResultCollection *regionResultCollection;
    OASearchCoreAPI *regionResultApi;
    NSMutableArray<OASearchResult *> *results = [NSMutableArray array];

    OASearchResultCollection *c = [_searchUICore search:text matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
        
        if (_paused)
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
                    apiResults = [regionCollection getCurrentSearchResults];
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
        
        return _paused;
    }]];
    
    if (!searchMore)
    {
        [self setResultCollection:nil];
        if (!updateResult)
            [self updateSearchResult:nil NO];
    }
    if (updateResult)
        [self updateSearchResult:c NO];
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

#pragma mark - OACategoryTableDelegate

-(void)didSelectCategoryItem:(id)obj
{
    if (!obj)
    {
        if (_currentScope == EPOIScopeUndefined && _showTopList)
        {
            _showTopList = NO;
            [self generateData];
            [self updateTabsVisibility];
        }
    }
    else if ([obj isKindOfClass:[OAPOIFilter class]])
    {
        OAPOIFilter* item = obj;
        self.searchString = [item.nameLocalized stringByAppendingString:@" "];
        _enteringScope = YES;
        _showTopList = NO;
        [self updateTextField:self.searchString];
    }
    else if ([obj isKindOfClass:[OAPOICategory class]])
    {
        OAPOICategory* item = obj;
        self.searchString = [item.nameLocalized stringByAppendingString:@" "];
        _enteringScope = YES;
        _showTopList = NO;
        [self updateTextField:self.searchString];
    }
    else if ([obj isKindOfClass:[OAPOIUIFilter class]])
    {
        [self searchByUIFilter:(OAPOIUIFilter *)obj nameFilter:@""];
    }
}

-(void)createPOIUIFilter
{
    OAPOIUIFilter *filter = [[OAPOIFiltersHelper sharedInstance] getCustomPOIFilter];
    [filter clearFilter];
    OACustomPOIViewController *customPOI = [[OACustomPOIViewController alloc] initWithFilter:filter];
    customPOI.delegate = self;
    [self.navigationController pushViewController:customPOI animated:YES];
}

-(void)editPOIUIFilter:(id)item
{
    
}

#pragma mark - OAHistoryTableDelegate

-(void)didSelectHistoryItem:(OAHistoryItem *)item
{
    if (item.hType == OAHistoryTypeFavorite)
    {
        BOOL foundFav = NO;
        for (const auto& favLoc : [OsmAndApp instance].favoritesCollection->getFavoriteLocations()) {
            
            if ([OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LongitudeX(favLoc->getPosition31().x) destination:item.longitude]
                && [OAUtilities doublesEqualUpToDigits:5 source:OsmAnd::Utilities::get31LatitudeY(favLoc->getPosition31().y) destination:item.latitude]
                && [item.name isEqualToString:favLoc->getTitle().toNSString()])
            {
                UIColor* color = [UIColor colorWithRed:favLoc->getColor().r/255.0 green:favLoc->getColor().g/255.0 blue:favLoc->getColor().b/255.0 alpha:1.0];
                OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
                
                if ([item.iconName isEqualToString:favCol.iconName])
                {
                    foundFav = YES;
                    [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item.latitude longitude:item.longitude caption:item.name icon:item.icon pushed:NO];
                    break;
                }
            }
        }
        
        if (!foundFav)
            [[OARootViewController instance].mapPanel openTargetViewWithHistoryItem:item pushed:NO];
    }
    else if (item.hType == OAHistoryTypePOI)
    {
        OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(item.latitude, item.longitude));
        NSArray<OAPOI *> *pois = [OAPOIHelper findPOIsByTagName:nil name:item.name location:locI categoryName:nil poiTypeName:nil radius:10];
        
        if (pois.count > 0)
            [self goToPoint:pois[0]];
        else
            [[OARootViewController instance].mapPanel openTargetViewWithHistoryItem:item pushed:NO];
    }
    else
    {
        [[OARootViewController instance].mapPanel openTargetViewWithHistoryItem:item pushed:NO];
    }
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

-(void)searchByUIFilter:(OAPOIUIFilter *)filter nameFilter:(NSString *)nameFilter
{
    [self setFilter:filter];
    self.searchString = [NSString stringWithFormat:@"%@ %@", filter.name, nameFilter.length > 0 && [filter isStandardFilter] ? [nameFilter stringByAppendingString:@" "] : @""];
    _dataInvalidated = YES;
    _currentScope = EPOIScopeUndefined;
    _enteringScope = YES;
    _showTopList = NO;
    [self updateTextField:self.searchString];
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
                //app.getSearchUICore().refreshCustomPoiFilters();
                [self searchByUIFilter:nFilter nameFilter:@""];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }
    }
}

#pragma mark - OAPOIFilterViewDelegate

- (BOOL) updateFilter:(OAPOIUIFilter *)filter nameFilter:(NSString *)nameFilter
{
    //app.getSearchUICore().refreshCustomPoiFilters();
    [self searchByUIFilter:filter nameFilter:nameFilter];
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
        //app.getSearchUICore().refreshCustomPoiFilters();
        
        [self setFilter:nil];
        self.searchString = nil;
        _enteringScope = YES;
        _showTopList = YES;
        [self updateTextField:self.searchString];
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForHeader];
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [OAPOISearchHelper getNumberOfRows:_dataArray dataPoiArray:_dataPoiArray currentScope:_currentScope showCoordinates:_showCoordinates showTopList:_showTopList poiInList:_poiInList searchRadiusIndex:_searchRadiusIndex searchRadiusIndexMax:_searchRadiusIndexMax];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OAPOISearchHelper getCellForRowAtIndexPath:indexPath tableView:tableView dataArray:_dataArray dataPoiArray:_dataPoiArray currentScope:_currentScope poiInList:_poiInList showCoordinates:_showCoordinates foundCoords:_foundCoords showTopList:_showTopList searchRadiusIndex:_searchRadiusIndex searchRadiusIndexMax:_searchRadiusIndexMax searchNearMapCenter:_searchNearMapCenter];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isDecelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        isDecelerating = NO;
        //[self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
    //[self refreshVisibleRows];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OAPOISearchHelper getHeightForRowAtIndexPath:indexPath tableView:tableView dataArray:_dataArray dataPoiArray:_dataPoiArray showCoordinates:_showCoordinates];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSInteger row = indexPath.row;
    
    if (_showCoordinates)
    {
        if (row == 0)
        {
            if (_foundCoords.count > 1)
            {
                double lat = [_foundCoords[0] doubleValue];
                double lon = [_foundCoords[1] doubleValue];
                [self goToPoint:lat longitude:lon];
                return;
            }
        }
        else
        {
            row--;
        }
    }
    
    if (row >= _dataArray.count + _dataPoiArray.count)
    {
        if (_currentScope == EPOIScopeUndefined && _showTopList)
        {
            _showTopList = NO;
            [self generateData];
            return;
        }
        else if (_searchRadiusIndex < _searchRadiusIndexMax)
        {
            _searchRadiusIndex++;
            _ignoreSearchResult = NO;
            _increasingSearchRadius = YES;
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               [self startCoreSearch];
                           });
        }
        return;
    }
    
    id obj;
    if (row >= _dataArray.count)
        obj = _dataPoiArray[row - _dataArray.count];
    else
        obj = _dataArray[row];
    
    if ([obj isKindOfClass:[OAPOI class]])
    {
        OAPOI* item = obj;
        
        if ([item.type isKindOfClass:[OAPOIFavType class]])
        {
            [self addHistoryItem:item type:OAHistoryTypeFavorite];
            
            [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item.latitude longitude:item.longitude caption:item.nameLocalized icon:[item icon] pushed:NO];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if ([item.type isKindOfClass:[OAPOIHistoryType class]])
        {
            OAHistoryItem *hist = [[OAHistoryItem alloc] init];
            hist.name = item.name;
            hist.latitude = item.latitude;
            hist.longitude = item.longitude;
            hist.hType = ((OAPOIHistoryType *)item.type).hType;
            [[OARootViewController instance].mapPanel openTargetViewWithHistoryItem:hist pushed:NO];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self addHistoryItem:item type:OAHistoryTypePOI];
            
            NSString *name = item.nameLocalized;
            if (!name)
                name = item.type.nameLocalized;
            
            [self goToPoint:item];
        }
    }
    else if ([obj isKindOfClass:[OAPOIType class]])
    {
        OAPOIType* item = obj;
        self.searchString = [item.nameLocalized stringByAppendingString:@" "];
        _enteringScope = YES;
        [self updateTextField:self.searchString];
    }
    else if ([obj isKindOfClass:[OAPOIFilter class]])
    {
        OAPOIFilter* item = obj;
        self.searchString = [item.nameLocalized stringByAppendingString:@" "];
        _enteringScope = YES;
        [self updateTextField:self.searchString];
    }
    else if ([obj isKindOfClass:[OAPOICategory class]])
    {
        OAPOICategory* item = obj;
        self.searchString = [item.nameLocalized stringByAppendingString:@" "];
        _enteringScope = YES;
        [self updateTextField:self.searchString];
    }
}

*/
@end
