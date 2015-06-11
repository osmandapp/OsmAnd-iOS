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

#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OADefaultFavorite.h"
#import "OANativeUtilities.h"

#import "Localization.h"

#include <OsmAndCore/Utilities.h>

#define kMaxTypeRows 5
#define kMapCenterSearchToolbarHeight 108.0

typedef enum
{
    EPOIScopeUndefined = 0,
    EPOIScopeCategory,
    EPOIScopeFilter,
    EPOIScopeType,
    
} EPOIScope;

@interface OAPOISearchViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, OAPOISearchDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UILabel *lbSearchNearCenter;
@property (weak, nonatomic) IBOutlet UIButton *btnMyLocation;

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

@implementation OAPOISearchViewController {
    
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

    EPOIScope _coreFoundScope;
    NSString *_coreFoundScopePoiTypeName;
    NSString *_coreFoundScopeCategoryName;
    NSString *_coreFoundScopeFilterName;

    BOOL _dataInvalidated;

    BOOL _showTopList;

    BOOL _showCoordinates;
    NSArray *_foundCoords;
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
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _tblMove = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                       action:@selector(moveGestureDetected:)];
    
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
}

-(void)viewWillAppear:(BOOL)animated {
    
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

- (void)appplicationIsActive:(NSNotification *)notification {
    [self showSearchIcon];
}

-(void)viewWillLayoutSubviews
{
    if (_searchNearMapCenter)
    {
        CGRect frame = _topView.frame;
        frame.size.height = kMapCenterSearchToolbarHeight;
        _topView.frame = frame;
        _tableView.frame = CGRectMake(0.0, frame.size.height, frame.size.width, DeviceScreenHeight - frame.size.height);
    }
    else
    {
        CGRect frame = _topView.frame;
        frame.size.height = 64.0;
        _topView.frame = frame;
        _tableView.frame = CGRectMake(0.0, frame.size.height, frame.size.width, DeviceScreenHeight - frame.size.height);
    }
}

-(void)setSearchNearMapCenter:(BOOL)searchNearMapCenter
{
    BOOL prevValue = _searchNearMapCenter;
    _searchNearMapCenter = searchNearMapCenter;
    
    if (searchNearMapCenter)
        _lbSearchNearCenter.text = [NSString stringWithFormat:@"%@ %@ %@", OALocalizedString(@"you_searching"), [[OsmAndApp instance] getFormattedDistance:self.distanceFromMyLocation], OALocalizedString(@"from_location")];

    if (prevValue != _searchNearMapCenter && self.isViewLoaded)
    {
        _dataInvalidated = YES;
        [self.view setNeedsLayout];
    }
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
        [self.tableView addGestureRecognizer:_tblMove];
    });
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView removeGestureRecognizer:_tblMove];
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


- (void)didReceiveMemoryWarning {
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
    (_currentScopePoiTypeName ?
        [_currentScopePoiTypeName isEqualToString:_coreFoundScopePoiTypeName] : _coreFoundScopePoiTypeName == nil);
}

-(void)generateData {
    
    [self acquireCurrentScope];
    
    if (_currentScope != EPOIScopeUndefined && ![self isCoreSearchResultActual])
        _searchRadiusIndex = 0;
    
    NSString *searchStr = [self.searchString copy];

    if (![searchStr isEqualToString:self.searchStringPrev] || _dataInvalidated)
    {
        // Stop active core search
        [[OAPOIHelper sharedInstance] breakSearch];
    }

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
            
            NSMutableArray *arr = [NSMutableArray array];
            NSArray *categories = [OAPOIHelper sharedInstance].poiCategories.allKeys;
            if (_showTopList)
            {
                NSArray *filters = [OAPOIHelper sharedInstance].poiFilters.allKeys;
                
                for (OAPOICategory *c in categories)
                    if (c.top)
                        [arr addObject:c];
                
                for (OAPOIFilter *f in filters)
                    if (f.top)
                        [arr addObject:f];
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

                if ([obj2 isKindOfClass:[OAPOICategory class]])
                    str2 = ((OAPOICategory *)obj2).nameLocalized;
                else if ([obj2 isKindOfClass:[OAPOIFilter class]])
                    str2 = ((OAPOIFilter *)obj2).nameLocalized;

                return [str1 localizedCaseInsensitiveCompare:str2];
            }];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                [self showSearchIcon];
                self.dataArray = [NSMutableArray arrayWithArray:sortedArrayItems];
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


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count + _dataPoiArray.count + (_currentScope != EPOIScopeUndefined && _searchRadiusIndex <= _searchRadiusIndexMax ? 1 : 0) + (_currentScope == EPOIScopeUndefined && _showTopList ? 1 : 0) + (_showCoordinates ? 1 : 0);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    NSInteger row = indexPath.row;

    if (_showCoordinates)
    {
        if (row == 0)
        {
            OAIconTextExTableViewCell* cell;
            cell = (OAIconTextExTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextExTableViewCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextExCell" owner:self options:nil];
                cell = (OAIconTextExTableViewCell *)[nib objectAtIndex:0];
            }
            
            if (cell)
            {
                int coordsCount = _foundCoords.count;
                
                CGRect f = cell.textView.frame;
                CGFloat oldX = f.origin.x;
                f.origin.x = 12.0;
                f.origin.y = 14.0;

                if (coordsCount == 1)
                    f.size.width = tableView.frame.size.width - 24.0;
                else
                    f.size.width += (oldX - f.origin.x);

                cell.textView.frame = f;

                NSString *text = @"";
                if (coordsCount == 1)
                {
                    NSString *coord1 = [OAUtilities floatToStrTrimZeros:[_foundCoords[0] doubleValue]];
                    
                    text = [NSString stringWithFormat:@"%@ %@ %@ #.## %@ ##’##’##.#", OALocalizedString(@"latitude"), coord1, OALocalizedString(@"longitude"), OALocalizedString(@"shared_string_or")];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.arrowIconView.hidden = YES;
                }
                else if (coordsCount > 1)
                {
                    NSString *coord1 = [OAUtilities floatToStrTrimZeros:[_foundCoords[0] doubleValue]];
                    NSString *coord2 = [OAUtilities floatToStrTrimZeros:[_foundCoords[1] doubleValue]];

                    text = [NSString stringWithFormat:@"%@: %@, %@", OALocalizedString(@"sett_arr_loc"), coord1, coord2];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.arrowIconView.hidden = NO;
                }
                
                [cell.textView setText:text];
                [cell.iconView setImage: nil];
            }
            return cell;
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
            OAIconTextTableViewCell* cell;
            cell = (OAIconTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            }
            
            if (cell)
            {
                CGRect f = cell.textView.frame;
                f.origin.y = 14.0;
                cell.textView.frame = f;
                
                [cell.textView setText:OALocalizedString(@"all_categories")];
                [cell.iconView setImage: nil];
            }
            return cell;
        }
        else
        {
            OASearchMoreCell* cell;
            cell = (OASearchMoreCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OASearchMoreCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASearchMoreCell" owner:self options:nil];
                cell = (OASearchMoreCell *)[nib objectAtIndex:0];
            }
            if (_searchRadiusIndex < _searchRadiusIndexMax)
            {
                cell.textView.text = OALocalizedString(@"poi_insrease_radius %@", [[OsmAndApp instance] getFormattedDistance:kSearchRadiusKm[_searchRadiusIndex + 1] * 1000.0]);
            }
            else
            {
                cell.textView.text = OALocalizedString(@"poi_max_radius_reached");
            }
            return cell;
        }
    }
    
    id obj;
    if (row >= _dataArray.count)
        obj = _dataPoiArray[row - _dataArray.count];
    else
        obj = _dataArray[row];
    
    
    if ([obj isKindOfClass:[OAPOI class]])
    {
        static NSString* const reusableIdentifierPoint = @"OAPointDescCell";
        
        OAPointDescCell* cell;
        cell = (OAPointDescCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointDescCell" owner:self options:nil];
            cell = (OAPointDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            
            OAPOI* item = obj;
            [cell.titleView setText:item.nameLocalized];
            cell.titleIcon.image = [item icon];
            [cell.descView setText:item.type.nameLocalized];
            [cell updateDescVisibility];
            if (item.hasOpeningHours)
            {
                [cell.openingHoursView setText:item.openingHours];
                cell.timeIcon.hidden = NO;
                [cell updateOpeningTimeInfo];
            }
            else
            {
                cell.openingHoursView.hidden = YES;
                cell.timeIcon.hidden = YES;
            }
            
            [cell.distanceView setText:item.distance];
            if (_searchNearMapCenter)
            {
                cell.directionImageView.hidden = YES;
                CGRect frame = cell.distanceView.frame;
                frame.origin.x = 51.0;
                cell.distanceView.frame = frame;
            }
            else
            {
                cell.directionImageView.hidden = NO;
                CGRect frame = cell.distanceView.frame;
                frame.origin.x = 69.0;
                cell.distanceView.frame = frame;
                cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            }
        }
        return cell;
    }
    else if ([obj isKindOfClass:[OAPOIType class]])
    {
        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAPOIType* item = obj;
            
            CGRect f = cell.textView.frame;
            if (item.categoryLocalized.length == 0)
                f.origin.y = 14.0;
            else
                f.origin.y = 8.0;
            cell.textView.frame = f;

            [cell.textView setText:item.nameLocalized];
            [cell.descView setText:item.categoryLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
    }
    else if ([obj isKindOfClass:[OAPOIFilter class]])
    {
        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAPOIFilter* item = obj;
            
            CGRect f = cell.textView.frame;
            if (item.categoryLocalized.length == 0)
                f.origin.y = 14.0;
            else
                f.origin.y = 8.0;
            cell.textView.frame = f;
            
            [cell.textView setText:item.nameLocalized];
            [cell.descView setText:item.categoryLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
    }
    else if ([obj isKindOfClass:[OAPOICategory class]])
    {
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAPOICategory* item = obj;
            
            CGRect f = cell.textView.frame;
            f.origin.y = 14.0;
            cell.textView.frame = f;

            [cell.textView setText:item.nameLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
    }
    else
    {
        return nil;
    }
    
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
        [self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
    [self refreshVisibleRows];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int row = indexPath.row;
    
    if (_showCoordinates)
    {
        if (row == 0)
            return 50.0;
        else
            row--;
    }
    
    int index = row - _dataArray.count;
    if (index >= 0 && index < _dataPoiArray.count)
    {
        OAPOI* item = _dataPoiArray[index];
        
        CGSize size = [OAUtilities calculateTextBounds:item.nameLocalized width:_tableView.bounds.size.width - 59.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
        
        return 30.0 + size.height;
    }
    else
    {
        return 50.0;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    int row = indexPath.row;
    if (_showCoordinates)
    {
        if (row == 0)
        {
            double lat = [_foundCoords[0] doubleValue];
            double lon = [_foundCoords[1] doubleValue];
            [self goToPoint:lat longitude:lon];
            return;
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
        NSString *name = item.nameLocalized;
        if (!name)
            name = item.type.nameLocalized;
        
        [self goToPoint:item];
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
    [self generateData];
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
                    [_currentScopeCategoryName isEqualToString:poi.category])
                {
                    _currentScope = EPOIScopeType;
                    _currentScopePoiTypeName = poi.name;
                    _currentScopePoiTypeNameLoc = poi.nameLocalized;
                    _currentScopeFilterName = poi.filter;
                    _currentScopeFilterNameLoc = poi.filterLocalized;
                    _currentScopeCategoryName = poi.category;
                    _currentScopeCategoryNameLoc = poi.categoryLocalized;
                    
                    return;
                }
            }
            searchableContent = [OAPOIHelper sharedInstance].poiFilters.allKeys;
            for (OAPOIFilter *filter in searchableContent) {
                
                if ([nextStr localizedCaseInsensitiveCompare:filter.nameLocalized] == NSOrderedSame &&
                    [_currentScopeCategoryName isEqualToString:filter.category])
                {
                    _currentScope = EPOIScopeFilter;
                    _currentScopePoiTypeName = nil;
                    _currentScopePoiTypeNameLoc = nil;
                    _currentScopeFilterName = filter.name;
                    _currentScopeFilterNameLoc = filter.nameLocalized;
                    _currentScopeCategoryName = filter.category;
                    _currentScopeCategoryNameLoc = filter.categoryLocalized;
                    
                    return;
                }
            }
        }
        return;
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
            _currentScopeFilterName = poi.filter;
            _currentScopeFilterNameLoc = poi.filterLocalized;
            _currentScopeCategoryName = poi.category;
            _currentScopeCategoryNameLoc = poi.categoryLocalized;
            
            break;
        }
        else if ([str localizedCaseInsensitiveCompare:poi.filterLocalized] == NSOrderedSame)
        {
            found = YES;
            _currentScope = EPOIScopeFilter;
            _currentScopePoiTypeName = nil;
            _currentScopePoiTypeNameLoc = nil;
            _currentScopeFilterName = poi.filter;
            _currentScopeFilterNameLoc = poi.filterLocalized;
            _currentScopeCategoryName = poi.category;
            _currentScopeCategoryNameLoc = poi.categoryLocalized;
            
            break;
        }
        else if ([str localizedCaseInsensitiveCompare:poi.categoryLocalized] == NSOrderedSame)
        {
            found = YES;
            _currentScope = EPOIScopeCategory;
            _currentScopePoiTypeName = nil;
            _currentScopePoiTypeNameLoc = nil;
            _currentScopeFilterName = nil;
            _currentScopeFilterNameLoc = nil;
            _currentScopeCategoryName = poi.category;
            _currentScopeCategoryNameLoc = poi.categoryLocalized;
            
            break;
        }
    }
    
    if (!found)
    {
        NSArray* searchableContent = [OAPOIHelper sharedInstance].poiCategories.allKeys;
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
    if (searchString == nil || [searchString length] == 0)
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
        NSArray *sortedCategories = [[OAPOIHelper sharedInstance].poiCategories.allKeys sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
            return [obj1.nameLocalized localizedCaseInsensitiveCompare:obj2.nameLocalized];
        }];
        
        for (OAPOICategory *c in sortedCategories)
            if ([self beginWithOrAfterSpace:str text:c.nameLocalized] || [self beginWithOrAfterSpace:str text:c.name])
                [_dataArrayTemp addObject:c];

        NSArray *sortedFilters = [[OAPOIHelper sharedInstance].poiFilters.allKeys sortedArrayUsingComparator:^NSComparisonResult(OAPOIFilter* obj1, OAPOIFilter* obj2) {
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
        for (OAPOIType *poi in searchableContent) {
            
            if (_currentScopeCategoryName && ![poi.category isEqualToString:_currentScopeCategoryName])
                continue;
            if (_currentScopeFilterName && ![poi.filter isEqualToString:_currentScopeFilterName])
                continue;
            if (_currentScopePoiTypeName && ![poi.name isEqualToString:_currentScopePoiTypeName])
                continue;
            
            if (_currentScope == EPOIScopeUndefined && poi.reference)
                continue;
            
            if (!str)
            {
                // remove POI Types if search string ie empty
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
            else if ([self beginWithOrAfterSpace:str text:poi.filterLocalized] || [self beginWithOrAfterSpace:str text:poi.filter])
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
    
    [self setSearchNearMapCenter:NO];
    [UIView animateWithDuration:.25 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self generateData];
    }];
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
        self.searchString = nil;
    }
    
    [self generateData];
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
    OARootViewController* rootViewController = [OARootViewController instance];
    [rootViewController closeMenuAndPanelsAnimated:YES];
    
    const OsmAnd::LatLon latLon(poi.latitude, poi.longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    Point31 pos = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [mapVC goToPosition:pos andZoom:kDefaultFavoriteZoomOnShow animated:YES];
    [mapVC showContextPinMarker:poi.latitude longitude:poi.longitude];
    
    CGPoint touchPoint = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    touchPoint.x *= mapRendererView.contentScaleFactor;
    touchPoint.y *= mapRendererView.contentScaleFactor;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    //if (poi.type)
    //    [userInfo setObject:poi.type forKey:@"poiType"];
    
    if (poi.type && [poi.type.name isEqualToString:@"wiki_place"])
        [userInfo setObject:@"wiki" forKey:@"objectType"];
    
    [userInfo setObject:@"yes" forKey:@"centerMap"];
    [userInfo setObject:poi.nameLocalized forKey:@"caption"];
    [userInfo setObject:[NSNumber numberWithDouble:latLon.latitude] forKey:@"lat"];
    [userInfo setObject:[NSNumber numberWithDouble:latLon.longitude] forKey:@"lon"];
    [userInfo setObject:[NSNumber numberWithFloat:touchPoint.x] forKey:@"touchPoint.x"];
    [userInfo setObject:[NSNumber numberWithFloat:touchPoint.y] forKey:@"touchPoint.y"];
    
    if ([poi hasOpeningHours])
        [userInfo setObject:poi.openingHours forKey:@"openingHours"];
    if (poi.desc)
        [userInfo setObject:poi.desc forKey:@"desc"];

    if (poi.localizedNames)
        [userInfo setObject:poi.localizedNames forKey:@"names"];
    if (poi.localizedContent)
        [userInfo setObject:poi.localizedContent forKey:@"content"];
    
    
    UIImage *icon = (poi.type ? [poi.type mapIcon] : nil);
    if (icon)
        [userInfo setObject:icon forKey:@"icon"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetTargetPoint
                                                        object:self
                                                      userInfo:userInfo];
    
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
        
        if (_currentScope == EPOIScopeUndefined)
            [poiHelper findPOIsByKeyword:self.searchString];
        else
            [poiHelper findPOIsByKeyword:self.searchString categoryName:_currentScopeCategoryName poiTypeName:_currentScopePoiTypeName radiusIndex:&_searchRadiusIndex];
    });
}

#pragma mark - OAPOISearchDelegate

-(void)poiFound:(OAPOI *)poi
{
    if (_currentScope == EPOIScopeFilter && ![poi.type.filter isEqualToString:_currentScopeFilterName])
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
            
            if (sortedArray.count > kSearchLimit)
                [_searchPoiArray setArray:[sortedArray subarrayWithRange:NSMakeRange(0, kSearchLimit)]];
            else
                [_searchPoiArray setArray:sortedArray];
        }

        _coreFoundScope = _currentScope;
        _coreFoundScopeCategoryName = _currentScopeCategoryName;
        _coreFoundScopeFilterName = _currentScopeFilterName;
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

            [self showSearchIcon];
            
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
    for (OAPOI *poi in self.searchPoiArray)
    {
        NSString *nextStr = [[self nextToken:self.searchString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (nextStr.length == 0 || [self beginWith:nextStr text:poi.nameLocalized] || [self beginWithAfterSpace:nextStr text:poi.nameLocalized])
            [arr addObject:poi];
    }

    self.dataPoiArray = [arr mutableCopy];
}

@end
