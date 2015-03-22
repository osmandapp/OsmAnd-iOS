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
#import "OAPOIHelper.h"
#import "OAPointDescCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAIconTextDescCell.h"
#import "OAAutoObserverProxy.h"

#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OADefaultFavorite.h"
#import "OANativeUtilities.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

typedef enum
{
    EPOIScopeUndefined = -1,
    EPOIScopeCategory = 0,
    EPOIScopeType,
    
} EPOIScope;

@interface OAPOISearchViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, OAPOISearchDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;

@property (nonatomic) NSMutableArray* dataArray;
@property (nonatomic) NSMutableArray* searchDataArray;
@property (nonatomic) NSString* searchString;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;
@property NSTimeInterval lastUpdate;

@end

@implementation OAPOISearchViewController {

    BOOL isDecelerating;
    BOOL _isSearching;
    BOOL _poiInList;

    NSLock *_lock;
    
    UIPanGestureRecognizer *_tblMove;
    
    UIImageView *_leftImgView;
    UIActivityIndicatorView *_activityIndicatorView;
    
    BOOL _needRestartSearch;
    BOOL _ignoreSearchResult;
    BOOL _initData;
    
    EPOIScope _currentScope;
    NSString *_currentScopePoiTypeName;
    NSString *_currentScopePoiTypeNameLoc;
    NSString *_currentScopeCategoryName;
    NSString *_currentScopeCategoryNameLoc;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _lock = [[NSLock alloc] init];
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
}

-(void)viewWillAppear:(BOOL)animated {
    
    [self generateData];
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
    
    [self.textField becomeFirstResponder];
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
    [_lock lock];
    @try {
        if (!_poiInList)
            return;

        if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !_initData)
            return;
        self.lastUpdate = [[NSDate date] timeIntervalSince1970];
        
        OsmAndAppInstance app = [OsmAndApp instance];
        // Obtain fresh location and heading
        CLLocation* newLocation = app.locationServices.lastKnownLocation;
        CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
        (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
        ? newLocation.course
        : newHeading;
        
        [_dataArray enumerateObjectsUsingBlock:^(id item, NSUInteger idx, BOOL *stop) {
            
            if ([item isKindOfClass:[OAPOI class]]) {
            
                OAPOI *itemData = item;
                
                const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                                  newLocation.coordinate.latitude,
                                                                  itemData.longitude, itemData.latitude);
                
                
                
                itemData.distance = [app getFormattedDistance:distance];
                itemData.distanceMeters = distance;
                CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:itemData.latitude longitude:itemData.longitude]];
                itemData.direction = -(itemDirection + newDirection / 180.0f * M_PI);
            }
            
        }];
        
        if ([_dataArray count] > 0) {
            NSArray *sortedArray = [_dataArray sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                
                double distance1 = 0;
                double distance2 = 0;
                
                if ([obj1 isKindOfClass:[OAPOI class]])
                    distance1 = ((OAPOI *)obj1).distanceMeters;
                if ([obj2 isKindOfClass:[OAPOI class]])
                    distance2 = ((OAPOI *)obj2).distanceMeters;
                
                if (distance1 > 0 || distance2 > 0) {
                    return distance1 > distance2 ? NSOrderedDescending : distance1 < distance2 ? NSOrderedAscending : NSOrderedSame;
                    
                } else {
                    
                    NSString *name1 = @"";
                    NSString *name2 = @"";
                    
                    if ([obj1 isKindOfClass:[OAPOIType class]])
                        name1 = [((OAPOIType *)obj1).nameLocalized lowercaseString];
                    else if ([obj1 isKindOfClass:[OAPOICategory class]])
                        name1 = [((OAPOICategory *)obj1).nameLocalized lowercaseString];
                    
                    if ([obj2 isKindOfClass:[OAPOIType class]])
                        name2 = [((OAPOIType *)obj2).nameLocalized lowercaseString];
                    else if ([obj2 isKindOfClass:[OAPOICategory class]])
                        name2 = [((OAPOICategory *)obj2).nameLocalized lowercaseString];
                    
                    return [name1 compare:name2];
                }
            }];
            [_dataArray setArray:sortedArray];
        }
        
        if (isDecelerating)
            return;
        
    } @finally {
        [_lock unlock];
    }
    
    //[self refreshVisibleRows];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableView reloadData];
        if (_initData && _dataArray.count > 0) {
            [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
        _initData = NO;
    });
}

- (void)refreshVisibleRows
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
        [self.tableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];
        
    });
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)generateData {
    
    [self acquireCurrentScope];

    [_lock lock];
    @try {
        
        if (self.searchString) {
            
            _ignoreSearchResult = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateSearchResults];
                [self refreshTable];
            });
            
        } else {
            
            _ignoreSearchResult = YES;
            _poiInList = NO;
            NSArray *sortedArrayItems = [[OAPOIHelper sharedInstance].poiCategories.allKeys sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
                return [[obj1.nameLocalized lowercaseString] compare:[obj2.nameLocalized lowercaseString]];
            }];
            self.dataArray = [NSMutableArray arrayWithArray:sortedArrayItems];
            [self refreshTable];
        }
        
    } @finally {
        [_lock unlock];
    }
}

-(void)refreshTable
{
    [_tableView reloadData];
    if (_dataArray.count > 0)
        [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

-(void)setupView {
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
    
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    // workaround for superfast typers
    if (indexPath.row >= _dataArray.count) {
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            cell.iconView.frame = CGRectMake(12.5, 12.5, 25.0, 25.0);
        }
        [cell.textView setText:@""];
        return cell;
    }
    
    id obj = _dataArray[indexPath.row];
    
    if ([obj isKindOfClass:[OAPOI class]]) {
        
        static NSString* const reusableIdentifierPoint = @"OAPointDescCell";
        
        OAPointDescCell* cell;
        cell = (OAPointDescCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointDescCell" owner:self options:nil];
            cell = (OAPointDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            
            OAPOI* item = obj;
            [cell.titleView setText:item.nameLocalized];
            cell.titleIcon.image = [item icon];
            [cell.descView setText:item.type.nameLocalized];
            
            [cell.distanceView setText:item.distance];
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }
        
        return cell;

    } else if ([obj isKindOfClass:[OAPOIType class]]) {

        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
            cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            cell.iconView.frame = CGRectMake(12.5, 12.5, 25.0, 25.0);
        }
        
        if (cell) {
            OAPOIType* item = obj;
                
            [cell.textView setText:item.nameLocalized];
            [cell.descView setText:item.categoryLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
        
    } else if ([obj isKindOfClass:[OAPOICategory class]]) {

        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            cell.iconView.frame = CGRectMake(12.5, 12.5, 25.0, 25.0);
        }
        
        if (cell) {
            OAPOICategory* item = obj;
            
            [cell.textView setText:item.nameLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
    
    } else {
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    id obj = _dataArray[indexPath.row];

    if ([obj isKindOfClass:[OAPOI class]]) {
        OAPOI* item = obj;
        [self goToPoint:item.latitude longitude:item.longitude name:item.name];
    
    } else if ([obj isKindOfClass:[OAPOIType class]]) {
        OAPOIType* item = obj;
        self.searchString = [item.nameLocalized stringByAppendingString:@" "];
        [self updateTextField:self.searchString];
        
    } else if ([obj isKindOfClass:[OAPOICategory class]]) {
        OAPOICategory* item = obj;
        self.searchString = [item.nameLocalized stringByAppendingString:@" "];
        [self updateTextField:self.searchString];
    }
}

-(void)updateTextField:(NSString *)text
{
    NSString *t = (text ? text : @"");
    _textField.text = t;
    [self generateData];
}

-(NSString *)firstToken:(NSString *)text
{
    if (!text || text.length == 0)
        return nil;
    
    NSRange r = [text rangeOfString:@" "];
    if (r.length == 0)
        return text;
    else
        return [text substringToIndex:r.location];
}

-(NSString *)nextTokens:(NSString *)text
{
    if (!text || text.length == 0)
        return nil;
    
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
        return;
    
    NSString *nextStr = [[[self nextTokens:self.searchString] lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *currentScopeNameLoc = (_currentScope == EPOIScopeCategory ? _currentScopeCategoryNameLoc : _currentScopePoiTypeNameLoc);
    
    if (_currentScope != EPOIScopeUndefined && [firstToken isEqualToString:currentScopeNameLoc]) {
        
        if (_currentScope == EPOIScopeCategory && nextStr) {
            NSArray* searchableContent = [OAPOIHelper sharedInstance].poiTypes;
            for (OAPOIType *poi in searchableContent) {
                
                if ([nextStr isEqualToString:[poi.nameLocalized lowercaseString]]) {
                    _currentScope = EPOIScopeType;
                    _currentScopePoiTypeName = poi.name;
                    _currentScopePoiTypeNameLoc = poi.nameLocalized;
                    _currentScopeCategoryName = poi.category;
                    _currentScopeCategoryNameLoc = poi.categoryLocalized;
                    
                    self.searchString = [_currentScopePoiTypeNameLoc stringByAppendingString:@" "];
                    [self updateTextField:self.searchString];
                    break;
                }
            }
        }
        return;
    }
    
    _currentScope = EPOIScopeUndefined;
    _currentScopePoiTypeName = nil;
    _currentScopePoiTypeNameLoc = nil;
    _currentScopeCategoryName = nil;
    _currentScopeCategoryNameLoc = nil;

    NSString *str = [firstToken lowercaseString];
    NSArray* searchableContent = [OAPOIHelper sharedInstance].poiTypes;
    for (OAPOIType *poi in searchableContent) {
        
        if ([str isEqualToString:[poi.nameLocalized lowercaseString]]) {
            _currentScope = EPOIScopeType;
            _currentScopePoiTypeName = poi.name;
            _currentScopePoiTypeNameLoc = poi.nameLocalized;
            _currentScopeCategoryName = poi.category;
            _currentScopeCategoryNameLoc = poi.categoryLocalized;
            
            self.searchString = [_currentScopePoiTypeNameLoc stringByAppendingString:@" "];
            [self updateTextField:self.searchString];
            break;
            
        } else if ([str isEqualToString:[poi.categoryLocalized lowercaseString]]) {
            _currentScope = EPOIScopeCategory;
            _currentScopePoiTypeName = nil;
            _currentScopePoiTypeNameLoc = nil;
            _currentScopeCategoryName = poi.category;
            _currentScopeCategoryNameLoc = poi.categoryLocalized;

            self.searchString = [_currentScopeCategoryNameLoc stringByAppendingString:@" "];
            [self updateTextField:self.searchString];
            break;
        }
    }
    
}

- (void)updateSearchResults
{
    [self performSearch:_searchString];
}

- (void)performSearch:(NSString*)searchString
{
    [_lock lock];
    @try {
        self.dataArray = [NSMutableArray array];

        // If case searchString is empty, there are no results
        if (searchString == nil || [searchString length] == 0)
            return;
        
        // In case searchString has only spaces, also nothing to do here
        if ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0)
            return;
        
        // Select where to look
        NSArray* searchableContent = [OAPOIHelper sharedInstance].poiTypes;
        
        NSComparator comparator = ^NSComparisonResult(id obj1, id obj2) {
            OAPOIType *item1 = obj1;
            OAPOIType *item2 = obj2;
            
            return [item1.nameLocalized localizedCaseInsensitiveCompare:item2.nameLocalized];
        };
        
        NSString *str = [searchString lowercaseString];
        if (_currentScope != EPOIScopeUndefined)
            str = [[self nextTokens:str] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if (_currentScope == EPOIScopeUndefined) {
            NSArray *sortedCategories = [[OAPOIHelper sharedInstance].poiCategories.allKeys sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
                return [[obj1.nameLocalized lowercaseString] compare:[obj2.nameLocalized lowercaseString]];
            }];
            
            for (OAPOICategory *c in sortedCategories)
                if ([self beginWithOrAfterSpace:str text:c.nameLocalized])
                    [_dataArray addObject:c];

        }

        if (_currentScope != EPOIScopeType) {
            NSMutableArray *typesArray = [NSMutableArray array];
            for (OAPOIType *poi in searchableContent) {
                
                if (_currentScopeCategoryName && ![poi.category isEqualToString:_currentScopeCategoryName])
                    continue;
                if (_currentScopePoiTypeName && ![poi.name isEqualToString:_currentScopePoiTypeName])
                    continue;

                if (!str)
                    [typesArray addObject:poi];
                else if ([self beginWithOrAfterSpace:str text:poi.nameLocalized])
                    [typesArray addObject:poi];
                else if ([self beginWithOrAfterSpace:str text:poi.filter])
                    [typesArray addObject:poi];
                else if ([self beginWithOrAfterSpace:str text:poi.categoryLocalized])
                    [typesArray addObject:poi];
            }
            [typesArray sortUsingComparator:comparator];
            self.dataArray = [[_dataArray arrayByAddingObjectsFromArray:typesArray] mutableCopy];
        }

        _ignoreSearchResult = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startCoreSearch];
        });

    } @finally {
        [_lock unlock];
    }
}

- (BOOL)beginWithOrAfterSpace:(NSString *)str text:(NSString *)text
{
    return [self beginWith:str text:text] || [self beginWithAfterSpace:str text:text];
}

- (BOOL)beginWith:(NSString *)str text:(NSString *)text
{
    return [[text lowercaseString] hasPrefix:str];
}

- (BOOL)beginWithAfterSpace:(NSString *)str text:(NSString *)text
{
    NSRange r = [text rangeOfString:@" "];
    if (r.length == 0 || r.location + 1 >= text.length)
        return NO;
    
    NSString *s = [text substringFromIndex:r.location + 1];
    return [[s lowercaseString] hasPrefix:str];
}

- (IBAction)btnCancelClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)textFieldValueChanged:(id)sender
{
    if (_textField.text.length > 0)
        self.searchString = _textField.text;
    else
        self.searchString = nil;
    
    [self generateData];
}

- (void)goToPoint:(double)latitude longitude:(double)longitude name:(NSString *)name
{
    OARootViewController* rootViewController = [OARootViewController instance];
    [rootViewController closeMenuAndPanelsAnimated:YES];
    
    const OsmAnd::LatLon latLon(latitude, longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    Point31 pos = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [mapVC goToPosition:pos andZoom:kDefaultFavoriteZoom animated:YES];
    [mapVC showContextPinMarker:latitude longitude:longitude];
    
    CGPoint touchPoint = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    touchPoint.x *= mapRendererView.contentScaleFactor;
    touchPoint.y *= mapRendererView.contentScaleFactor;

    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSetTargetPoint
                                                        object: self
                                                      userInfo:@{@"title" : name,
                                                                 @"lat": [NSNumber numberWithDouble:latLon.latitude],
                                                                 @"lon": [NSNumber numberWithDouble:latLon.longitude],
                                                                 @"touchPoint.x": [NSNumber numberWithFloat:touchPoint.x],
                                                                 @"touchPoint.y": [NSNumber numberWithFloat:touchPoint.y]}];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    self.searchString = nil;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    return YES;
}

-(void)startCoreSearch
{
    _needRestartSearch = YES;
    
    if (![[OAPOIHelper sharedInstance] breakSearch]) {
        _needRestartSearch = NO;
    } else {
        return;
    }
    
    [_lock lock];
    self.searchDataArray = [NSMutableArray array];
    [_lock unlock];
    
    [self showWaitingIndicator];
    
    OAPOIHelper *poiHelper = [OAPOIHelper sharedInstance];
    
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    OAMapRendererView* mapRendererView = (OAMapRendererView*)mapVC.view;
    [poiHelper setVisibleScreenDimensions:[mapRendererView getVisibleBBox31] zoomLevel:mapRendererView.zoomLevel];
    CLLocation* newLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    poiHelper.myLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(newLocation.coordinate.latitude, newLocation.coordinate.longitude));
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        if (_currentScope == EPOIScopeUndefined)
            [poiHelper findPOIsByKeyword:self.searchString];
        else
            [poiHelper findPOIsByKeyword:self.searchString categoryName:_currentScopeCategoryName poiTypeName:_currentScopePoiTypeName radiusMeters:1000.0];
    });
}

#pragma mark - OAPOISearchDelegate

-(void)poiFound:(OAPOI *)poi
{
    [_searchDataArray addObject:poi];
}

-(void)searchDone:(BOOL)wasInterrupted
{
    if (!wasInterrupted && !_needRestartSearch) {

        dispatch_async(dispatch_get_main_queue(), ^{
            [self showSearchIcon];
        });

        if (_ignoreSearchResult) {
            _poiInList = NO;
            return;
        }
        
        _poiInList = _searchDataArray.count > 0;
        
        [_lock lock];
        self.dataArray = [[_dataArray arrayByAddingObjectsFromArray:self.searchDataArray] mutableCopy];
        self.searchDataArray = nil;
        [_lock unlock];
        
        if (_poiInList) {
            _initData = YES;
            [self updateDistanceAndDirection];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_tableView reloadData];
            });
        }
        
    } else if (_needRestartSearch) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startCoreSearch];
        });
    }
}

@end
