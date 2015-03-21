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
#import "OAPointTableViewCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAIconTextDescCell.h"
#import "OAAutoObserverProxy.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

@interface OAPOISearchViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, OAPOISearchDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *btnBack;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;

@property (nonatomic) NSMutableArray* dataArray;
@property (nonatomic) NSMutableArray* searchDataArray;
@property (nonatomic) NSString* searchString;

@property (nonatomic) NSString* poiTypeName;
@property (nonatomic) NSString* searchStringType;
@property (nonatomic) NSString* categoryName;
@property (nonatomic) NSString* searchStringCategory;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;
@property NSTimeInterval lastUpdate;

@end

@implementation OAPOISearchViewController {

    BOOL isDecelerating;
    BOOL _isSearching;
    BOOL _poiInList;

    NSObject *_dataLock;
    
    UIPanGestureRecognizer *_tblMove;
    
    UIImageView *_leftImgView;
    UIActivityIndicatorView *_activityIndicatorView;
    
    BOOL _needRestartSearch;
    BOOL _ignoreSearchResult;
    BOOL _initData;
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
    _dataLock = [[NSObject alloc] init];
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
    
    if (!_searchString && !_poiTypeName && !_categoryName)
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

-(void)updateLayout:(BOOL)animated
{
    if (animated) {

        [UIView animateWithDuration:.3 animations:^{
            if (!_poiTypeName && !_categoryName) {
                _btnBack.alpha = 0.0;
                _textField.frame = CGRectMake(8.0, 25.0, DeviceScreenWidth - 82.0, 30.0);
            } else {
                _btnBack.alpha = 1.0;
                _textField.frame = CGRectMake(44.0, 25.0, DeviceScreenWidth - 118.0, 30.0);
            }
        }];
        
    } else {
        if (!_poiTypeName && !_categoryName) {
            _btnBack.alpha = 0.0;
            _textField.frame = CGRectMake(8.0, 25.0, DeviceScreenWidth - 82.0, 30.0);
        } else {
            _btnBack.alpha = 1.0;
            _textField.frame = CGRectMake(44.0, 25.0, DeviceScreenWidth - 118.0, 30.0);
        }
    }
}

-(void)viewWillLayoutSubviews
{
    [self updateLayout:NO];
}

-(IBAction)btnBackClick:(id)sender
{
    if (_poiTypeName) {
        self.poiTypeName = nil;
        self.searchString = self.searchStringType;
        self.searchStringType = nil;
        [self updateTextField:self.searchString];
        [self updateLayout:YES];
        
    } else if (_categoryName) {
        self.categoryName = nil;
        self.searchString = self.searchStringCategory;
        self.searchStringCategory = nil;
        [self updateTextField:self.searchString];
        [self updateLayout:YES];
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
    @synchronized(_dataLock) {
        
        if (!_poiInList)
            return;

        if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3)
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
        
        //[self refreshVisibleRows];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadData];
            if (_initData && _dataArray.count > 0) {
                [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            }
            _initData = NO;
        });
    }
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
    
    @synchronized(_dataLock) {
        if (self.searchString) {
            
            //if (!_categoryName) {
            //    _ignoreSearchResult = YES;
            //    [self updateSearchResults];
            //} else {
            _ignoreSearchResult = NO;
            [self startCoreSearch];
            //}
            
        } else if (self.poiTypeName) {
            
            _ignoreSearchResult = NO;
            _poiInList = NO;
            [self startCoreSearch];
            
        } else if (self.categoryName) {
            
            _ignoreSearchResult = YES;
            _poiInList = NO;
            NSArray *sortedArrayItems = [[[OAPOIHelper sharedInstance] poiTypesForCategory:_categoryName] sortedArrayUsingComparator:^NSComparisonResult(OAPOIType* obj1, OAPOIType* obj2) {
                return [[obj1.nameLocalized lowercaseString] compare:[obj2.nameLocalized lowercaseString]];
            }];
            self.dataArray = [NSMutableArray arrayWithArray:sortedArrayItems];
            
        } else {
            
            _ignoreSearchResult = YES;
            _poiInList = NO;
            NSArray *sortedArrayItems = [[OAPOIHelper sharedInstance].poiCategories.allKeys sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
                return [[obj1.nameLocalized lowercaseString] compare:[obj2.nameLocalized lowercaseString]];
            }];
            self.dataArray = [NSMutableArray arrayWithArray:sortedArrayItems];
        }
        [_tableView reloadData];
        if (_dataArray.count > 0)
            [_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
    }
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

    id obj = _dataArray[indexPath.row];
    
    if ([obj isKindOfClass:[OAPOI class]]) {
        
        static NSString* const reusableIdentifierPoint = @"OAPointTableViewCell";
        
        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointCell" owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell) {
            
            OAPOI* item = obj;
            [cell.titleView setText:item.nameLocalized];
            cell.titleIcon.image = [item.type icon];
            
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
        //OAPOI* item = obj;
    
    } else if ([obj isKindOfClass:[OAPOIType class]]) {
        OAPOIType* item = obj;
        self.poiTypeName = item.name;
        self.searchStringType = self.searchString;
        self.searchString = nil;
        [self updateTextField:nil];
        [self updateLayout:YES];
        
    } else if ([obj isKindOfClass:[OAPOICategory class]]) {
        OAPOICategory* item = obj;
        self.categoryName = item.name;
        self.searchStringCategory = self.searchString;
        self.searchString = nil;
        [self updateTextField:nil];
        [self updateLayout:YES];
    }
}

-(void)updateTextField:(NSString *)text
{
    NSString *t = (text ? text : @"");
    _textField.text = t;
    [self generateData];
}

- (void)updateSearchResults
{
    [self performSearch:_searchString];
}

- (void)performSearch:(NSString*)searchString
{
    @synchronized(_dataLock)
    {
        
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
        
        if (!_categoryName && !_poiTypeName) {
            NSArray *sortedCategories = [[OAPOIHelper sharedInstance].poiCategories.allKeys sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory* obj1, OAPOICategory* obj2) {
                return [[obj1.nameLocalized lowercaseString] compare:[obj2.nameLocalized lowercaseString]];
            }];
            
            for (OAPOICategory *c in sortedCategories)
                if ([self beginWithOrAfterSpace:str text:c.nameLocalized])
                    [_dataArray addObject:c];
        }

        if (!_poiTypeName) {
            NSMutableArray *typesArray = [NSMutableArray array];
            for (OAPOIType *poi in searchableContent) {
                
                if (_categoryName && ![poi.category isEqualToString:_categoryName])
                    continue;
                if (_poiTypeName && ![poi.name isEqualToString:_poiTypeName])
                    continue;
                
                if ([self beginWithOrAfterSpace:str text:poi.nameLocalized])
                    [typesArray addObject:poi];
                else if ([self beginWithOrAfterSpace:str text:poi.filter])
                    [typesArray addObject:poi];
                else if ([self beginWithOrAfterSpace:str text:poi.categoryLocalized])
                    [typesArray addObject:poi];
            }
            [typesArray sortUsingComparator:comparator];
            self.dataArray = [[_dataArray arrayByAddingObjectsFromArray:typesArray] mutableCopy];
        }
        
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
    
    if ([[OAPOIHelper sharedInstance] isSearchDone]) {
        _needRestartSearch = NO;
    } else {
        [[OAPOIHelper sharedInstance] breakSearch];
        return;
    }
    
    self.searchDataArray = [NSMutableArray array];
    [self showWaitingIndicator];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[OAPOIHelper sharedInstance] findPOIsByKeyword:self.searchString categoryName:self.categoryName poiTypeName:self.poiTypeName];
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
        
        if (_ignoreSearchResult) {
            _poiInList = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self showSearchIcon];
            });
            return;
        }
        
        _poiInList = _searchDataArray.count > 0;
        @synchronized(_dataLock) {
            self.dataArray = [NSMutableArray arrayWithArray:self.searchDataArray];
            self.searchDataArray = nil;
        }
        if (_poiInList) {
            _initData = YES;
            [self updateDistanceAndDirection];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_tableView reloadData];
            });
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self showSearchIcon];
        });
        
    } else if (_needRestartSearch) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self startCoreSearch];
        });
    }
}

@end
