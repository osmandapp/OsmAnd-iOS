//
//  OAPOISearchViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPOISearchViewController.h"
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

@interface OAPOISearchViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIPageViewControllerDataSource, OAPOISearchDelegate, OACategoryTableDelegate, OAHistoryTableDelegate, UIGestureRecognizerDelegate, UIPageViewControllerDelegate, OACustomPOIViewDelegate, UIAlertViewDelegate,
    OAPOIFilterViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
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

@implementation OAPOISearchViewController
{
    BOOL isDecelerating;
    BOOL _isSearching;
    BOOL _poiInList;
    
    UIPanGestureRecognizer *_tblMove;
    
    UIImageView *_leftImgView;
    UIActivityIndicatorView *_activityIndicatorView;
    
    BOOL _needRestartSearch;
    BOOL _ignoreSearchResult;
    BOOL _increasingSearchRadius;
    BOOL _initData;
    BOOL _enteringScope;
    
    int _searchRadiusIndex;
    int _searchRadiusIndexMax;
    
    EPOIScope _currentScope;
    NSString *_currentScopePoiTypeName;
    NSString *_currentScopePoiTypeNameLoc;
    NSString *_currentScopeCategoryName;
    NSString *_currentScopeCategoryNameLoc;
    NSString *_currentScopeFilterName;
    NSString *_currentScopeFilterNameLoc;
    NSString *_currentScopeUIFilterName;
    NSString *_currentScopeUIFilterNameLoc;

    EPOIScope _coreFoundScope;
    NSString *_coreFoundScopePoiTypeName;
    NSString *_coreFoundScopeCategoryName;
    NSString *_coreFoundScopeFilterName;
    NSString *_coreFoundScopeUIFilterName;
    
    OAPOIBaseType *_poiBaseType;
    OAPOIUIFilter *_filter;
    OAPOIUIFilter *_filterToSave;

    BOOL _dataInvalidated;

    BOOL _showTopList;

    BOOL _showCoordinates;
    NSArray *_foundCoords;
    
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
    if (self) {
        [self commonInit];
    }
    return self;
}

- (dispatch_queue_t)searchDispatchQueue
{
    if (_searchDispatchQueue == nil) {
        _searchDispatchQueue = dispatch_queue_create("searchDispatchQueue", NULL);
    }
    return _searchDispatchQueue;
}

- (dispatch_queue_t)updateDispatchQueue
{
    if (_updateDispatchQueue == nil) {
        _updateDispatchQueue = dispatch_queue_create("updateDispatchQueue", NULL);
    }
    return _updateDispatchQueue;
}

- (void)commonInit
{
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
    
    [OAPOIHelper sharedInstance].delegate = self;
    
    [self showSearchIcon];
    [self generateData];
    
    [self updateSearchNearMapCenterLabel];

    [self showTabs];
}

-(void)viewWillAppear:(BOOL)animated
{
    isDecelerating = NO;
    
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
    (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
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
    //NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    //[self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)isCoreSearchResultActual
{
    return _currentScope == _coreFoundScope &&
    (_currentScopeCategoryName ?
        [_currentScopeCategoryName isEqualToString:_coreFoundScopeCategoryName] : _coreFoundScopeCategoryName == nil) &&
    (_currentScopeFilterName ?
        [_currentScopeFilterName isEqualToString:_coreFoundScopeFilterName] : _coreFoundScopeFilterName == nil) &&
    (_currentScopeUIFilterName ?
        [_currentScopeUIFilterName isEqualToString:_coreFoundScopeUIFilterName] : _coreFoundScopeUIFilterName == nil) &&
    (_currentScopePoiTypeName ?
        [_currentScopePoiTypeName isEqualToString:_coreFoundScopePoiTypeName] : _coreFoundScopePoiTypeName == nil);
}

-(void)generateData
{
    // hide poi
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    [mapVC hidePoi];
    
    [self acquireCurrentScope];
    
    //if (_currentScope != EPOIScopeUndefined && ![self isCoreSearchResultActual])
    //    _searchRadiusIndex = 0;
    
    if (_currentScope == EPOIScopeUndefined)
        [self setupBarActionView:BarActionNone title:nil];

    NSString *searchStr = [self.searchString copy];

    if (![searchStr isEqualToString:self.searchStringPrev] || _dataInvalidated)
    {
        // Stop active core search
        [[OAPOIHelper sharedInstance] breakSearch];
    }

    if (!searchStr || _showTopList)
        _searchRadiusIndex = 0;

    if (searchStr)
    {
        dispatch_async(self.updateDispatchQueue, ^{
    
            if ([searchStr isEqualToString:self.searchStringPrev] && !_dataInvalidated)
                return;
            else
                self.searchStringPrev = [searchStr copy];

            _dataInvalidated = NO;
            
            if (_currentScope == EPOIScopeUndefined)
            {
                _foundCoords = [OAUtilities splitCoordinates:searchStr];
                _showCoordinates = (_foundCoords.count > 0);
            }
            else
            {
                _foundCoords = nil;
                _showCoordinates = NO;
            }
            
            // Build category/filter/type items array
            [self updateSearchResults];

            // Generate POIs (search via core or using the previous core search result)
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.dataArray = [NSMutableArray arrayWithArray:self.dataArrayTemp];

                NSString *str = searchStr;
                if (_currentScope != EPOIScopeUndefined)
                    str = [[self nextToken:str] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

                _ignoreSearchResult = (str.length == 0 && _currentScope == EPOIScopeUndefined);
                if (!_ignoreSearchResult)
                {
                    if (_searchPoiArray.count > 0 && _currentScope != EPOIScopeUndefined && [self isCoreSearchResultActual])
                    {
                        //NSLog(@"build");
                        [self buildPoiArray];
                        _initData = YES;
                        _poiInList = YES;
                        [self updateDistanceAndDirection];
                        if (_currentScope != EPOIScopeUndefined)
                            [self setupBarActionView:BarActionShownMap title:nil];
                        [self updateNavbar];
                    }
                    else
                    {
                        //NSLog(@"core");
                        [self startCoreSearch];
                    }
                }
                else
                {
                    [self refreshTable];
                }
            });
        });
    }
    else
    {
        dispatch_async(self.updateDispatchQueue, ^{
            
            _showCoordinates = NO;
            _ignoreSearchResult = YES;
            _poiInList = NO;

            // Stop active core search
            [[OAPOIHelper sharedInstance] breakSearch];

            self.searchStringPrev = nil;
            
            OAPOIFiltersHelper *filtersHelper = [OAPOIFiltersHelper sharedInstance];
            NSMutableArray *arr = [NSMutableArray array];
            NSArray *categories = [OAPOIHelper sharedInstance].poiCategories;
            if (_showTopList)
            {
                NSArray *filters = [OAPOIHelper sharedInstance].poiFilters;
                for (OAPOICategory *c in categories)
                    if (c.top)
                        [arr addObject:c];
                for (OAPOIFilter *f in filters)
                    if (f.top)
                        [arr addObject:f];

                NSArray<OAPOIUIFilter *> *uiFilters = [filtersHelper getUserDefinedPoiFilters];
                [arr addObjectsFromArray:uiFilters];
            }
            else
            {
                for (OAPOICategory *c in categories)
                    [arr addObject:c];
            }
            
            NSArray *sortedArrayItems = [arr sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                
                NSString *str1;
                NSString *str2;
                
                if ([obj1 isKindOfClass:[OAPOICategory class]])
                    str1 = ((OAPOICategory *)obj1).nameLocalized;
                else if ([obj1 isKindOfClass:[OAPOIFilter class]])
                    str1 = ((OAPOIFilter *)obj1).nameLocalized;
                else if ([obj1 isKindOfClass:[OAPOIUIFilter class]])
                    str1 = ((OAPOIUIFilter *)obj1).name;

                if ([obj2 isKindOfClass:[OAPOICategory class]])
                    str2 = ((OAPOICategory *)obj2).nameLocalized;
                else if ([obj2 isKindOfClass:[OAPOIFilter class]])
                    str2 = ((OAPOIFilter *)obj2).nameLocalized;
                else if ([obj2 isKindOfClass:[OAPOIUIFilter class]])
                    str2 = ((OAPOIUIFilter *)obj2).name;

                return [str1 localizedCaseInsensitiveCompare:str2];
            }];
            
            if (_showTopList)
            {
                if ([filtersHelper getLocalWikiPOIFilter])
                    sortedArrayItems = [sortedArrayItems arrayByAddingObject:[filtersHelper getLocalWikiPOIFilter]];
                sortedArrayItems = [sortedArrayItems arrayByAddingObject:[filtersHelper getShowAllPOIFilter]];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showSearchIcon];
                if (_showTopList)
                {
                    _categoriesViewController.dataArray = [NSMutableArray arrayWithArray:sortedArrayItems];
                    [_categoriesViewController.tableView reloadData];
                    if (_categoriesViewController.dataArray.count > 0)
                        [_categoriesViewController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                    
                    [_historyViewController reloadData];
                    self.dataArray = [NSMutableArray array];
                }
                else
                {
                    self.dataArray = [NSMutableArray arrayWithArray:sortedArrayItems];
                }
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

-(void)updateTextField:(NSString *)text
{
    NSString *t = (text ? text : @"");
    _textField.text = t;
    
    [self.view setNeedsLayout];
    [self generateData];
    [self updateTabsVisibility];
}

-(NSString *)currentScopeNameLoc
{
    switch (_currentScope) {
        case EPOIScopeCategory:
            return _currentScopeCategoryNameLoc;
        case EPOIScopeFilter:
            return _currentScopeFilterNameLoc;
        case EPOIScopeType:
            return _currentScopePoiTypeNameLoc;
        case EPOIScopeUIFilter:
            return _currentScopeUIFilterNameLoc;
            
        default:
            break;
    }
    return nil;
}

-(NSString *)currentScopeName
{
    switch (_currentScope) {
        case EPOIScopeCategory:
            return _currentScopeCategoryName;
        case EPOIScopeFilter:
            return _currentScopeFilterName;
        case EPOIScopeType:
            return _currentScopePoiTypeName;
        case EPOIScopeUIFilter:
            return _currentScopeUIFilterName;
            
        default:
            break;
    }
    return nil;
}

-(BOOL)firstTokenScoped:(NSString *)text scopeName:(NSString *)scopeName result:(NSString **)result
{
    if ([self beginWith:scopeName text:text] && (text.length == scopeName.length || [text characterAtIndex:scopeName.length] == ' '))
    {
        if (text.length > scopeName.length)
        {
            *result = [text substringToIndex:scopeName.length + 1];
            return YES;
        }
        else
        {
            *result = text;
            return YES;
        }
    }
    return NO;
}

-(BOOL)nextTokenScoped:(NSString *)text scopeName:(NSString *)scopeName result:(NSString **)result
{
    if ([self beginWith:scopeName text:text])
    {
        if (text.length > scopeName.length + 1)
        {
            NSString *res = [text substringFromIndex:scopeName.length + 1];
            *result = (res.length == 0 ? nil : res);
            return YES;
        }
        else
        {
            *result = nil;
            return YES;
        }
    }
    return NO;
}

-(NSString *)firstToken:(NSString *)text
{
    if (!text || text.length == 0)
        return nil;
    
    if (_enteringScope)
    {
        _enteringScope = NO;
        return text;
    }
    
    if (_currentScope != EPOIScopeUndefined)
    {
        NSString *ret;
        if ([self firstTokenScoped:text scopeName:[self currentScopeNameLoc] result:&ret])
            return ret;
        if ([self firstTokenScoped:text scopeName:[self currentScopeName] result:&ret])
            return ret;
    }
    
    NSRange r = [text rangeOfString:@" "];
    if (r.length == 0)
        return text;
    else
        return [text substringToIndex:r.location + 1];
    
}

-(NSString *)nextToken:(NSString *)text
{
    if (!text || text.length == 0)
        return nil;
    
    if (_currentScope != EPOIScopeUndefined)
    {
        NSString *ret;
        if ([self nextTokenScoped:text scopeName:[self currentScopeNameLoc] result:&ret])
            return ret;
        if ([self nextTokenScoped:text scopeName:[self currentScopeName] result:&ret])
            return ret;
    }
    
    NSRange r = [text rangeOfString:@" "];
    if (r.length == 0)
        return nil;
    else if (text.length > r.location + 1)
        return [text substringFromIndex:r.location + 1];
    else
        return nil;
}

-(void)acquireCurrentScope
{
    NSString *firstToken = [self firstToken:self.searchString];
    if (!firstToken)
    {
        _currentScope = EPOIScopeUndefined;
        return;
    }
    
    BOOL trailingSpace = [[firstToken substringFromIndex:firstToken.length - 1] isEqualToString:@" "];
    
    NSString *nextStr = [[self nextToken:self.searchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *currentScopeNameLoc = [self currentScopeNameLoc];
    
    if (_currentScope != EPOIScopeUndefined && [firstToken isEqualToString:(trailingSpace ? [currentScopeNameLoc stringByAppendingString:@" "] : currentScopeNameLoc)]) {
        
        if (_currentScope == EPOIScopeCategory && nextStr) {
            NSArray* searchableContent = [OAPOIHelper sharedInstance].poiTypes;
            for (OAPOIType *poi in searchableContent) {
                
                if ([nextStr localizedCaseInsensitiveCompare:poi.nameLocalized] == NSOrderedSame &&
                    [_currentScopeCategoryName isEqualToString:poi.category.name])
                {
                    _currentScope = EPOIScopeType;
                    _currentScopePoiTypeName = poi.name;
                    _currentScopePoiTypeNameLoc = poi.nameLocalized;
                    _currentScopeFilterName = poi.filter.name;
                    _currentScopeFilterNameLoc = poi.filter.nameLocalized;
                    _currentScopeCategoryName = poi.category.name;
                    _currentScopeCategoryNameLoc = poi.category.nameLocalized;
                    
                    _poiBaseType = poi;
                    return;
                }
            }
            searchableContent = [OAPOIHelper sharedInstance].poiFilters;
            for (OAPOIFilter *filter in searchableContent) {
                
                if ([nextStr localizedCaseInsensitiveCompare:filter.nameLocalized] == NSOrderedSame &&
                    [_currentScopeCategoryName isEqualToString:filter.category.name])
                {
                    _currentScope = EPOIScopeFilter;
                    _currentScopePoiTypeName = nil;
                    _currentScopePoiTypeNameLoc = nil;
                    _currentScopeFilterName = filter.name;
                    _currentScopeFilterNameLoc = filter.nameLocalized;
                    _currentScopeCategoryName = filter.category.name;
                    _currentScopeCategoryNameLoc = filter.category.nameLocalized;
                    
                    _poiBaseType = filter;
                    return;
                }
            }
        }
        return;
    }
    
    if (_currentScope == EPOIScopeUndefined && _filter && [firstToken hasPrefix:_filter.name])
    {
        _currentScope = EPOIScopeUIFilter;
        _currentScopePoiTypeName = nil;
        _currentScopePoiTypeNameLoc = nil;
        _currentScopeFilterName = nil;
        _currentScopeFilterNameLoc = nil;
        _currentScopeCategoryName = nil;
        _currentScopeCategoryNameLoc = nil;
        _poiBaseType = nil;
        _currentScopeUIFilterName = _filter.filterId;
        _currentScopeUIFilterNameLoc = _filter.name;
        return;
    }
    else if (_currentScope == EPOIScopeUIFilter && (!_filter || ![firstToken hasPrefix:_filter.name]))
    {
        _currentScope = EPOIScopeUndefined;
        _currentScopeUIFilterName = nil;
        _currentScopeUIFilterNameLoc = nil;
    }

    BOOL found = NO;
    
    NSString *str = [firstToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray* searchableContent = [OAPOIHelper sharedInstance].poiTypes;
    for (OAPOIType *poi in searchableContent)
    {
        if ([str localizedCaseInsensitiveCompare:poi.nameLocalized] == NSOrderedSame)
        {
            found = YES;
            _currentScope = EPOIScopeType;
            _currentScopePoiTypeName = poi.name;
            _currentScopePoiTypeNameLoc = poi.nameLocalized;
            _currentScopeFilterName = poi.filter.name;
            _currentScopeFilterNameLoc = poi.filter.nameLocalized;
            _currentScopeCategoryName = poi.category.name;
            _currentScopeCategoryNameLoc = poi.category.nameLocalized;
            
            _poiBaseType = poi;
            break;
        }
        else if ([str localizedCaseInsensitiveCompare:poi.filter.nameLocalized] == NSOrderedSame)
        {
            found = YES;
            _currentScope = EPOIScopeFilter;
            _currentScopePoiTypeName = nil;
            _currentScopePoiTypeNameLoc = nil;
            _currentScopeFilterName = poi.filter.name;
            _currentScopeFilterNameLoc = poi.filter.nameLocalized;
            _currentScopeCategoryName = poi.category.name;
            _currentScopeCategoryNameLoc = poi.category.nameLocalized;
            
            _poiBaseType = poi.filter;
            break;
        }
        else if ([str localizedCaseInsensitiveCompare:poi.category.nameLocalized] == NSOrderedSame)
        {
            found = YES;
            _currentScope = EPOIScopeCategory;
            _currentScopePoiTypeName = nil;
            _currentScopePoiTypeNameLoc = nil;
            _currentScopeFilterName = nil;
            _currentScopeFilterNameLoc = nil;
            _currentScopeCategoryName = poi.category.name;
            _currentScopeCategoryNameLoc = poi.category.nameLocalized;
            
            _poiBaseType = poi.category;
            break;
        }
    }
    
    if (!found)
    {
        NSArray* searchableContent = [OAPOIHelper sharedInstance].poiCategories;
        for (OAPOICategory *category in searchableContent)
        {
            if ([str localizedCaseInsensitiveCompare:category.nameLocalized] == NSOrderedSame)
            {
                found = YES;
                _currentScope = EPOIScopeCategory;
                _currentScopePoiTypeName = nil;
                _currentScopePoiTypeNameLoc = nil;
                _currentScopeFilterName = nil;
                _currentScopeFilterNameLoc = nil;
                _currentScopeCategoryName = category.name;
                _currentScopeCategoryNameLoc = category.nameLocalized;
                
                _poiBaseType = category;
                break;
            }
        }
    }
    
    if (!found)
    {
        _currentScope = EPOIScopeUndefined;
        _currentScopePoiTypeName = nil;
        _currentScopePoiTypeNameLoc = nil;
        _currentScopeFilterName = nil;
        _currentScopeFilterNameLoc = nil;
        _currentScopeCategoryName = nil;
        _currentScopeCategoryNameLoc = nil;
        _currentScopeUIFilterName = nil;
        _currentScopeUIFilterNameLoc = nil;
        _poiBaseType = nil;
    }
}

- (void)updateSearchResults
{
    [self performSearch:[_searchString copy]];
}

- (void)performSearch:(NSString*)searchString
{
    self.dataArrayTemp = [NSMutableArray array];
    
    // If case searchString is empty, there are no results
    if (searchString == nil || [searchString length] == 0 || _currentScope == EPOIScopeUIFilter)
        return;
    
    // In case searchString has only spaces, also nothing to do here
    if ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
        return;
    
    // Select where to look
    NSArray* searchableContent = [OAPOIHelper sharedInstance].poiTypes;
    
    NSComparator typeComparator = ^NSComparisonResult(id obj1, id obj2)
    {
        OAPOIType *item1 = obj1;
        OAPOIType *item2 = obj2;
        
        return [item1.nameLocalized localizedCaseInsensitiveCompare:item2.nameLocalized];
    };
    
    NSString *str = searchString;
    if (_currentScope != EPOIScopeUndefined)
        str = [[self nextToken:str] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (_currentScope == EPOIScopeUndefined)
    {
        NSArray *sortedCategories = [[OAPOIHelper sharedInstance].poiCategories sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
            return [obj1.nameLocalized localizedCaseInsensitiveCompare:obj2.nameLocalized];
        }];
        
        for (OAPOICategory *c in sortedCategories)
            if ([self beginWithOrAfterSpace:str text:c.nameLocalized] || [self beginWithOrAfterSpace:str text:c.name])
                [_dataArrayTemp addObject:c];

        NSArray *sortedFilters = [[OAPOIHelper sharedInstance].poiFilters sortedArrayUsingComparator:^NSComparisonResult(OAPOIFilter* obj1, OAPOIFilter* obj2) {
            return [obj1.nameLocalized localizedCaseInsensitiveCompare:obj2.nameLocalized];
        }];
        
        for (OAPOIFilter *f in sortedFilters)
            if ([self beginWithOrAfterSpace:str text:f.nameLocalized] || [self beginWithOrAfterSpace:str text:f.name])
                [_dataArrayTemp addObject:f];
    }
    
    if (_currentScope == EPOIScopeCategory)
    {
        NSArray *sortedFilters = [[[OAPOIHelper sharedInstance] poiFiltersForCategory:_currentScopeCategoryName] sortedArrayUsingComparator:^NSComparisonResult(OAPOIFilter* obj1, OAPOIFilter* obj2) {
            return [obj1.nameLocalized localizedCaseInsensitiveCompare:obj2.nameLocalized];
        }];
        
        for (OAPOIFilter *f in sortedFilters)
            if (!str || [self beginWithOrAfterSpace:str text:f.nameLocalized] || [self beginWithOrAfterSpace:str text:f.name])
                [_dataArrayTemp addObject:f];
    }
    
    if (_currentScope != EPOIScopeType)
    {
        NSMutableArray *typesStrictArray = [NSMutableArray array];
        NSMutableArray *typesOthersArray = [NSMutableArray array];
        for (OAPOIType *poi in searchableContent)
        {
            if ((!poi.category && !poi.filter) || poi.mapOnly)
                continue;
            
            if (_currentScopeCategoryName && ![poi.category.name isEqualToString:_currentScopeCategoryName])
                continue;
            if (_currentScopeFilterName && ![poi.filter.name isEqualToString:_currentScopeFilterName])
                continue;
            if (_currentScopePoiTypeName && ![poi.name isEqualToString:_currentScopePoiTypeName])
                continue;
            
            if (_currentScope == EPOIScopeUndefined && poi.reference)
                continue;
            
            if (!str)
            {
                // remove POI Types if search string is empty
                //if (!poi.filter || _currentScope == EPOIScopeFilter)
                //    [typesOthersArray addObject:poi];
            }
            else if ([self beginWithOrAfterSpace:str text:poi.nameLocalized] || [self beginWithOrAfterSpace:str text:poi.name])
            {
                if ([self containsWord:str inText:poi.nameLocalized] || [self containsWord:str inText:poi.name])
                    [typesStrictArray addObject:poi];
                else
                    [typesOthersArray addObject:poi];
            }
            else if ([self beginWithOrAfterSpace:str text:poi.filter.nameLocalized] || [self beginWithOrAfterSpace:str text:poi.filter.name])
            {
                [typesOthersArray addObject:poi];
            }
        }
        
        if (!str)
        {
            [typesOthersArray sortUsingComparator:typeComparator];
            self.dataArrayTemp = [[_dataArrayTemp arrayByAddingObjectsFromArray:typesOthersArray] mutableCopy];
        }
        else
        {
            [typesStrictArray sortUsingComparator:typeComparator];
            
            int rowsForOthers = kMaxTypeRows - (int)typesStrictArray.count;
            if (rowsForOthers > 0)
            {
                [typesOthersArray sortUsingComparator:typeComparator];
                if (typesOthersArray.count > rowsForOthers)
                    [typesOthersArray removeObjectsInRange:NSMakeRange(rowsForOthers, typesOthersArray.count - rowsForOthers)];
                
                typesStrictArray = [[typesStrictArray arrayByAddingObjectsFromArray:typesOthersArray] mutableCopy];
            }
            
            self.dataArrayTemp = [[_dataArrayTemp arrayByAddingObjectsFromArray:typesStrictArray] mutableCopy];
        }
    }
}

- (BOOL)containsWord:(NSString *)str inText:(NSString *)text
{
    NSString *src = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSArray *tokens = [text componentsSeparatedByString:@" "];
    
    for (NSString *t in tokens)
        if ([t localizedCaseInsensitiveCompare:src] == NSOrderedSame)
            return YES;
    
    return NO;
}

- (BOOL)beginWithOrAfterSpace:(NSString *)str text:(NSString *)text
{
    return [self beginWith:str text:text] || [self beginWithAfterSpace:str text:text];
}

- (BOOL)beginWith:(NSString *)str text:(NSString *)text
{
    return [[text lowercaseStringWithLocale:[NSLocale currentLocale]] hasPrefix:[str lowercaseStringWithLocale:[NSLocale currentLocale]]];
}

- (BOOL)beginWithAfterSpace:(NSString *)str text:(NSString *)text
{
    NSRange r = [text rangeOfString:@" "];
    if (r.length == 0 || r.location + 1 >= text.length)
        return NO;
    
    NSString *s = [text substringFromIndex:r.location + 1];
    return [[s lowercaseStringWithLocale:[NSLocale currentLocale]] hasPrefix:[str lowercaseStringWithLocale:[NSLocale currentLocale]]];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    return YES;
}

-(void)startCoreSearch
{
    _coreFoundScope = EPOIScopeUndefined;
    _coreFoundScopeCategoryName = nil;
    _coreFoundScopeFilterName = nil;
    _coreFoundScopeUIFilterName = nil;
    _coreFoundScopePoiTypeName = nil;

    _needRestartSearch = YES;
    
    if (![[OAPOIHelper sharedInstance] breakSearch])
        _needRestartSearch = NO;
    else
        return;
    
    
    dispatch_async(self.searchDispatchQueue, ^{
    
        if (_ignoreSearchResult) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showSearchIcon];
            });
            _poiInList = NO;
            return;
        }
        
        self.searchPoiArray = [NSMutableArray array];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showWaitingIndicator];
        });
        
        OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
        
        OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
        OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
        [poiHelper setVisibleScreenDimensions:[mapRendererView getVisibleBBox31] zoomLevel:mapRendererView.zoomLevel];
        poiHelper.myLocation = self.myLocation;
        
        if (_currentScope == EPOIScopeUIFilter)
            [poiHelper findPOIsByFilter:_filter radiusIndex:&_searchRadiusIndex];
        else if (_currentScope == EPOIScopeUndefined)
            [poiHelper findPOIsByKeyword:self.searchString];
        else
            [poiHelper findPOIsByKeyword:self.searchString categoryName:_currentScopeCategoryName poiTypeName:_currentScopePoiTypeName radiusIndex:&_searchRadiusIndex];
    });
}

#pragma mark - OAPOISearchDelegate

-(void)poiFound:(OAPOI *)poi
{
    if (_currentScope == EPOIScopeFilter && ![poi.type.filter.name isEqualToString:_currentScopeFilterName])
        return;

    [_searchPoiArray addObject:poi];
}

-(void)searchDone:(BOOL)wasInterrupted
{
    if (!wasInterrupted && !_needRestartSearch)
    {
        if (_ignoreSearchResult)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showSearchIcon];
            });
            _poiInList = NO;
            [_searchPoiArray removeAllObjects];
            return;
        }
        
        if (_searchPoiArray.count > 0)
        {
            NSArray *sortedArray = [self.searchPoiArray sortedArrayUsingComparator:^NSComparisonResult(OAPOI *obj1, OAPOI *obj2)
                                    {
                                        double distance1 = obj1.distanceMeters;
                                        double distance2 = obj2.distanceMeters;
                                        
                                        return distance1 > distance2 ? NSOrderedDescending : distance1 < distance2 ? NSOrderedAscending : NSOrderedSame;
                                    }];
            
            //if (sortedArray.count > kSearchLimit)
            //    [_searchPoiArray setArray:[sortedArray subarrayWithRange:NSMakeRange(0, kSearchLimit)]];
            //else
            [_searchPoiArray setArray:sortedArray];
        }

        // add favorites to array
        if (_currentScope == EPOIScopeUndefined)
        {
            NSString *keyword = [[self firstToken:self.searchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            const auto allFavorites = [OsmAndApp instance].favoritesCollection->getFavoriteLocations();
            
            // create favorite groups
            for(const auto& favorite : allFavorites)
            {
                OAPOI *poi = [[OAPOI alloc] init];
                poi.name = favorite->getTitle().toNSString();
                poi.nameLocalized = favorite->getTitle().toNSString();
                OsmAnd::LatLon latLon = favorite->getLatLon();
                poi.latitude = latLon.latitude;
                poi.longitude = latLon.longitude;
                
                OAPOIFavType *favType = [[OAPOIFavType alloc] initWithName:OALocalizedString(@"favorite")];
                favType.nameLocalized = OALocalizedString(@"favorite");
                poi.type = favType;
                
                if (keyword.length == 0 || [self beginWith:keyword text:poi.nameLocalized] || [self beginWithAfterSpace:keyword text:poi.nameLocalized] || [self beginWith:keyword text:poi.name] || [self beginWithAfterSpace:keyword text:poi.name])
                {
                    [_searchPoiArray insertObject:poi atIndex:0];
                }
            }
            
            // create history groups
            for(OAHistoryItem *item in [[OAHistoryHelper sharedInstance] getSearchHistoryPoints:0])
            {
                OAPOI *poi = [[OAPOI alloc] init];
                poi.name = item.name;
                poi.nameLocalized = item.name;
                poi.latitude = item.latitude;
                poi.longitude = item.longitude;
                
                OAPOIHistoryType *historyType = [[OAPOIHistoryType alloc] initWithName:OALocalizedString(@"history")];
                historyType.nameLocalized = OALocalizedString(@"history");
                historyType.hType = item.hType;
                poi.type = historyType;
                
                if (keyword.length == 0 || [self beginWith:keyword text:poi.nameLocalized] || [self beginWithAfterSpace:keyword text:poi.nameLocalized] || [self beginWith:keyword text:poi.name] || [self beginWithAfterSpace:keyword text:poi.name])
                {
                    [_searchPoiArray insertObject:poi atIndex:0];
                }
            }
        }
        
        _coreFoundScope = _currentScope;
        _coreFoundScopeCategoryName = _currentScopeCategoryName;
        _coreFoundScopeFilterName = _currentScopeFilterName;
        _coreFoundScopeUIFilterName = _currentScopeUIFilterName;
        _coreFoundScopePoiTypeName = _currentScopePoiTypeName;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            _poiInList = _searchPoiArray.count > 0;
            
            [self buildPoiArray];
            
            if (_poiInList)
            {
                _initData = !_increasingSearchRadius;
                [self updateDistanceAndDirection];
                _increasingSearchRadius = NO;
            }
            else
            {
                [_tableView reloadData];
            }

            if (_currentScope != EPOIScopeUndefined)
                [self setupBarActionView:BarActionShownMap title:nil];
            [self showSearchIcon];
            [self updateNavbar];
        });
    }
    else if (_needRestartSearch)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startCoreSearch];
        });
    }
}

-(void)buildPoiArray
{
    NSMutableArray *arr = [NSMutableArray array];
    NSString *nextStr = [[self nextToken:self.searchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    for (OAPOI *poi in self.searchPoiArray)
    {
        if (nextStr.length == 0 || [self beginWith:nextStr text:poi.nameLocalized] || [self beginWithAfterSpace:nextStr text:poi.nameLocalized] || [self beginWith:nextStr text:poi.name] || [self beginWithAfterSpace:nextStr text:poi.name])
        {
            [arr addObject:poi];
            if (arr.count > kSearchLimit)
                break;
        }
    }

    self.dataPoiArray = [arr mutableCopy];
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

@end
