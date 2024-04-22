//
//  OAFavoriteListViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 07.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteListViewController.h"
#import "OAPointTableViewCell.h"
#import "OAPointHeaderTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAMapViewController.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMultiselectableHeaderView.h"
#import "OAEditColorViewController.h"
#import "OAEditGroupViewController.h"
#import "OARootViewController.h"
#import "OATargetInfoViewController.h"
#import "OAFavoriteGroupEditorViewController.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OAIndexConstants.h"
#import "OAGPXAppearanceCollection.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAChoosePlanHelper.h"
#import "OACloudIntroductionViewController.h"
#import "OAAppSettings.h"
#import "OABackupHelper.h"
#import "OAFavoriteImportViewController.h"
#import "Localization.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "GeneratedAssetSymbols.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define _(name) OAFavoriteListViewController__##name
#define kWasClosedFreeBackupFavoritesBannerKey @"wasClosedFreeBackupFavoritesBanner"

#define FavoriteTableGroup _(FavoriteTableGroup)

@interface FavoriteTableGroup : NSObject
    @property BOOL isOpen;
    @property OAFavoriteGroup *favoriteGroup;
@end

@implementation FavoriteTableGroup

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.isOpen = NO;
    }
    return self;
}

@end

@interface OAFavoriteListViewController () <OAMultiselectableHeaderDelegate, OAEditorDelegate, OAEditGroupViewControllerDelegate, OAEditColorViewControllerDelegate, UIDocumentPickerDelegate, UISearchResultsUpdating, UISearchBarDelegate>
{

    BOOL isDecelerating;
}
    @property (strong, nonatomic) NSArray*  menuItems;
    @property (strong, nonatomic) NSMutableArray*  sortedFavoriteItems;
    @property NSUInteger sortingType;
@end

@implementation OAFavoriteListViewController
{
    OAMultiselectableHeaderView *_sortedHeaderView;
    OAMultiselectableHeaderView *_menuHeaderView;
    NSArray *_unsortedHeaderViews;
    NSMutableArray<NSArray *> *_data;
    NSMutableArray *_filteredItems;

    OAEditColorViewController *_colorController;
    OAEditGroupViewController *_groupController;

    CALayer *_horizontalLine;
    NSMutableArray<NSIndexPath *> *_selectedItems;

    UIBarButtonItem *_directionButton;
    UIBarButtonItem *_editButton;
    UISearchController *_searchController;
    FreeBackupBanner *_freeBackupBanner;
    
    BOOL _isSearchActive;
    BOOL _isFiltered;
    OAGPXAppearanceCollection *_appearanceCollection;
}

static UIViewController *parentController;

+ (BOOL)popToParent
{
    if (!parentController)
        return NO;

    [OAFavoriteListViewController doPop];

    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    isDecelerating = NO;
    self.sortingType = 0;
    self.view.backgroundColor = [UIColor colorNamed:ACColorNameViewBg];

    _sortedHeaderView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    _sortedHeaderView.delegate = self;
    [_sortedHeaderView setTitleText:OALocalizedString(@"favorites_item")];

    _menuHeaderView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    _menuHeaderView.editable = NO;
    [_menuHeaderView setTitleText:OALocalizedString(@"import_export")];

    _editToolbarView.hidden = YES;

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
    self.editToolbarView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    [self.editToolbarView.layer addSublayer:_horizontalLine];

    _selectedItems = [[NSMutableArray alloc] init];
    
    self.tabBarController.navigationItem.title = OALocalizedString(@"my_favorites");
    [self addNotification:OAIAPProductPurchasedNotification selector:@selector(productPurchased:)];
    [self addNotification:OAFavoriteImportViewControllerDidDismissNotification selector:@selector(favoriteImportViewControllerDidDismiss:)];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
}

- (void)favoriteImportViewControllerDidDismiss:(NSNotification *)notification
{
    if (self.isViewLoaded && self.view.window != nil)
    {
        [self generateData];
    }
}

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configurePaymentBanner];
    });
}

- (BOOL)isAvailablePaymentBanner
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kWasClosedFreeBackupFavoritesBannerKey]
    && ![OAIAPHelper isOsmAndProAvailable]
    && !OABackupHelper.sharedInstance.isRegistered;
}

- (void)resizeHeaderBanner {
    if ([self isAvailablePaymentBanner] && _freeBackupBanner)
    {
        CGFloat titleHeight = [OAUtilities calculateTextBounds:_freeBackupBanner.titleLabel.text width:self.favoriteTableView.frame.size.width - _freeBackupBanner.leadingTrailingOffset font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height;
        
        CGFloat descriptionHeight = [OAUtilities calculateTextBounds:_freeBackupBanner.descriptionLabel.text width:self.favoriteTableView.frame.size.width - _freeBackupBanner.leadingTrailingOffset font:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]].height;
        _freeBackupBanner.frame = CGRectMake(0,
                                             0,
                                             self.favoriteTableView.frame.size.width,
                                             _freeBackupBanner.defaultFrameHeight + titleHeight + descriptionHeight);
        self.favoriteTableView.tableHeaderView = _freeBackupBanner;
        UIEdgeInsets insets = self.favoriteTableView.layoutMargins;
        if (insets.left != 0 || insets.right != 0)
        {
            _freeBackupBanner.leadingSubviewConstraint.constant = insets.left;
            _freeBackupBanner.trailingSubviewConstraint.constant = insets.right;
        }
    }
}

- (void)configurePaymentBanner
{
    if ([self isAvailablePaymentBanner])
    {
        if (!_freeBackupBanner) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"FreeBackupBanner" owner:self options:nil];
            _freeBackupBanner = (FreeBackupBanner *)nib[0];
            __weak OAFavoriteListViewController *weakSelf = self;
            _freeBackupBanner.didOsmAndCloudButtonAction = ^{
                [weakSelf.navigationController pushViewController:[OACloudIntroductionViewController new] animated:YES];
            };
            _freeBackupBanner.didCloseButtonAction = ^{
                [weakSelf closeFreeBackupBanner];
            };
            [_freeBackupBanner configureWithBannerType:BannerTypeFavorite];
            
            [self configureSeparator:[UIView new] top:YES];
            [self configureSeparator:[UIView new] top:NO];

            [self changeContentInsetTop:20];
        }
    }
    else if (_freeBackupBanner) {
        [self closeFreeBackupBanner];
    }
}

- (void)configureSeparator:(UIView *)view top:(BOOL)top
{
    view.translatesAutoresizingMaskIntoConstraints = NO;
    view.backgroundColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    [_freeBackupBanner addSubview:view];
    
    [NSLayoutConstraint activateConstraints:@[
        [view.leadingAnchor constraintEqualToAnchor:_freeBackupBanner.leadingAnchor],
        [view.trailingAnchor constraintEqualToAnchor:_freeBackupBanner.trailingAnchor],
        [view.heightAnchor constraintEqualToConstant:1.0 / [UIScreen mainScreen].scale]
    ]];
    
    if (top)
        [view.topAnchor constraintEqualToAnchor:_freeBackupBanner.topAnchor].active = YES;
    else
        [view.bottomAnchor constraintEqualToAnchor:_freeBackupBanner.bottomAnchor].active = YES;

}

- (void)closeFreeBackupBanner
{
    self.favoriteTableView.tableHeaderView = nil;
    [self changeContentInsetTop:-20];
    _freeBackupBanner = nil;
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kWasClosedFreeBackupFavoritesBannerKey];
}

- (void)changeContentInsetTop:(CGFloat)top
{
    UIEdgeInsets insets = [self.favoriteTableView contentInset];
    [self.favoriteTableView setContentInset:UIEdgeInsetsMake(insets.top + top, insets.left, insets.bottom, insets.right)];
}


-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self resizeHeaderBanner];
}

-(UIView *) getMiddleView
{
    return _favoriteTableView;
}

-(UIView *) getBottomView
{
    return [self.favoriteTableView isEditing] ? _editToolbarView : nil;
}

-(CGFloat) getToolBarHeight
{
    return favoritesToolBarHeight;
}

- (void)updateDistanceAndDirection
{
    [self updateDistanceAndDirection:NO];
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.favoriteTableView isEditing])
            return;

        if ([[NSDate date] timeIntervalSince1970] - self.lastUpdate < 0.3 && !forceUpdate)
            return;
        self.lastUpdate = [[NSDate date] timeIntervalSince1970];

        OsmAndAppInstance app = [OsmAndApp instance];
        // Obtain fresh location and heading
        CLLocation* newLocation = app.locationServices.lastKnownLocation;
        if (!newLocation)
            return;

        CLLocationDirection newHeading = app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection =
        (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
        ? newLocation.course
        : newHeading;

        [self.sortedFavoriteItems enumerateObjectsUsingBlock:^(OAFavoriteItem* itemData, NSUInteger idx, BOOL *stop) {
            const auto& favoritePosition31 = itemData.favorite->getPosition31();
            const auto favoriteLon = OsmAnd::Utilities::get31LongitudeX(favoritePosition31.x);
            const auto favoriteLat = OsmAnd::Utilities::get31LatitudeY(favoritePosition31.y);

            const auto distance = OsmAnd::Utilities::distance(newLocation.coordinate.longitude,
                                                                newLocation.coordinate.latitude,
                                                                favoriteLon, favoriteLat);



            itemData.distance = [OAOsmAndFormatter getFormattedDistance:distance];
            itemData.distanceMeters = distance;
            CGFloat itemDirection = [app.locationServices radiusFromBearingToLocation:[[CLLocation alloc] initWithLatitude:favoriteLat longitude:favoriteLon]];
            itemData.direction = OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);

         }];

        if (self.sortingType == 1 && [self.sortedFavoriteItems count] > 0)
        {
            NSArray *sortedArray = [self.sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2){
                return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
            }];
            [self.sortedFavoriteItems setArray:sortedArray];
        }

        if (isDecelerating)
            return;

        [self refreshVisibleRows];
    });
}

- (void)refreshVisibleRows
{
    if ([self.favoriteTableView isEditing])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{

        [self.favoriteTableView beginUpdates];
        NSArray *visibleIndexPaths = [self.favoriteTableView indexPathsForVisibleRows];
        for (NSIndexPath *i in visibleIndexPaths)
        {
            UITableViewCell *cell = [self.favoriteTableView cellForRowAtIndexPath:i];
            if ([cell isKindOfClass:[OAPointTableViewCell class]])
            {
                OAFavoriteItem* item;
                if (_directionButton.tag == 1)
                {
                    if (i.section == 0)
                        item = [self.sortedFavoriteItems objectAtIndex:i.row];
                }
                else
                {
                    NSDictionary *groupData = _data[i.section][0];
                    NSString *cellType = groupData[@"type"];
                    if ([cellType isEqualToString:@"group"])
                    {
                        FavoriteTableGroup *group = groupData[@"group"];
                        item = [group.favoriteGroup.points objectAtIndex:i.row - 1];
                    }
                }

                if (item)
                {
                    OAPointTableViewCell *c = (OAPointTableViewCell *)cell;

                    [c.titleView setText:[item getDisplayName]];
                    c = [self setupPoiIconForCell:c withFavaoriteItem:item];

                    [c.distanceView setText:item.distance];
                    c.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
                }
            }
        }
        [self.favoriteTableView endUpdates];

        //NSArray *visibleIndexPaths = [self.favoriteTableView indexPathsForVisibleRows];
        //[self.favoriteTableView reloadRowsAtIndexPaths:visibleIndexPaths withRowAnimation:UITableViewRowAnimationNone];

    });
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setupView];
    [self generateData];
    [self setupView];
    [self updateDistanceAndDirection:YES];

    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(updateDistanceAndDirection)
                                                                     andObserve:app.locationServices.updateObserver];
    [self applySafeAreaMargins];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    _editButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"icon_edit"] style:UIBarButtonItemStylePlain target:self action:@selector(editButtonClicked:)];
    _directionButton = [[UIBarButtonItem alloc] initWithImage:[UIImage templateImageNamed:@"icon_direction"] style:UIBarButtonItemStylePlain target:self action:@selector(sortByDistance:)];
    [self.navigationController.navigationBar.topItem setRightBarButtonItems:@[_editButton, _directionButton] animated:YES];
    self.tabBarController.navigationItem.title = OALocalizedString(@"my_favorites");
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchResultsUpdater = self;
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    self.tabBarController.navigationItem.searchController = _searchController;
    self.definesPresentationContext = YES;
    [self setupSearchController:NO filtered:NO];
    [self addAccessibilityLabels];
    [self configurePaymentBanner];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.locationServicesUpdateObserver)
    {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    self.definesPresentationContext = NO;
}

-(void) addAccessibilityLabels
{
    _editButton.accessibilityLabel = OALocalizedString(@"shared_string_edit");
    self.exportButton.accessibilityLabel = OALocalizedString(@"shared_string_export");
    self.deleteButton.accessibilityLabel = OALocalizedString(@"shared_string_delete");
}

-(void)generateData
{
    NSMutableArray *allGroups = [[NSMutableArray alloc] init];
    self.menuItems = [[NSArray alloc] init];
    self.sortedFavoriteItems = [[NSMutableArray alloc] init];

    NSMutableArray *headerViews = [NSMutableArray array];
    NSMutableArray *tableData = [NSMutableArray array];

    NSArray *favorites = [NSMutableArray arrayWithArray:[OAFavoritesHelper getFavoriteGroups]];
    for (OAFavoriteGroup *group in favorites)
    {
        FavoriteTableGroup* itemData = [[FavoriteTableGroup alloc] init];
        itemData.favoriteGroup = group;

        // Sort items
        NSArray *sortedArrayItems = [itemData.favoriteGroup.points sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
            return [[[obj1 getDisplayName] lowercaseString] compare:[[obj2 getDisplayName] lowercaseString]];
        }];
        [itemData.favoriteGroup.points setArray:sortedArrayItems];

        for (OAFavoriteItem *item in group.points)
            [self.sortedFavoriteItems addObject:item];
        [allGroups addObject:itemData];
    }
    if (!_isSearchActive)
    {
        NSArray *sortedArray = [self.sortedFavoriteItems sortedArrayUsingComparator:^NSComparisonResult(OAFavoriteItem* obj1, OAFavoriteItem* obj2) {
            return obj1.distanceMeters > obj2.distanceMeters ? NSOrderedDescending : obj1.distanceMeters < obj2.distanceMeters ? NSOrderedAscending : NSOrderedSame;
        }];
        [self.sortedFavoriteItems setArray:sortedArray];
    }
    for (FavoriteTableGroup *group in allGroups)
    {
        NSMutableArray *groupData = [NSMutableArray array];
        [groupData addObject:@{
            @"type" : @"group",
            @"group" : group
        }];
        [tableData addObject:groupData];
    }

    for (int i = 0; i < tableData.count;)
    {
        OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
        [headerView.selectAllBtn setHidden:YES];
        headerView.section = i++;
        headerView.delegate = self;
        [headerViews addObject:headerView];
    }

    // Generate menu items
    self.menuItems = @[@{@"type" : @"actionItem",
                         @"text": OALocalizedString(@"fav_import_title"),
                         @"icon": @"ic_custom_import",
                         @"action": @"onImportClicked"},
                       @{@"type" : @"actionItem",
                         @"text": OALocalizedString(@"fav_export_title"),
                         @"icon": @"ic_custom_export",
                         @"action": @"onExportClicked"}];
    [tableData addObject:self.menuItems];

    OAMultiselectableHeaderView *headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    [headerView setTitleText:OALocalizedString(@"import_export")];
    headerView.editable = NO;
    [headerViews addObject:headerView];

    _data = [NSMutableArray arrayWithArray:tableData];

    [self.favoriteTableView reloadData];

    _unsortedHeaderViews = [NSArray arrayWithArray:headerViews];
}

-(void)setupView
{
    self.favoriteTableView.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
    [self.favoriteTableView setDataSource:self];
    [self.favoriteTableView setDelegate:self];
    self.favoriteTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.favoriteTableView reloadData];
    _isSearchActive = NO;
    _isFiltered = NO;
}

- (void) setupSearchController:(BOOL)isSearchActive filtered:(BOOL)isFiltered
{
    if (isSearchActive)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    }
    else if (isFiltered)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorNamed:ACColorNameTextColorTertiary]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
    else
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _searchController.searchBar.searchTextField.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Actions

- (IBAction)sortByDistance:(id)sender
{
    if (![self.favoriteTableView isEditing])
    {
        if (_directionButton.tag == 0)
        {
            _directionButton.tag = 1;
            _directionButton.image = [UIImage imageNamed:@"icon_direction_active"];
            self.sortingType = 1;
        }
        else
        {
            _directionButton.tag = 0;
            _directionButton.image = [UIImage imageNamed:@"icon_direction"];
            self.sortingType = 0;
        }
        [self generateData];
        [self updateDistanceAndDirection:YES];
    }
}

- (IBAction) deletePressed:(id)sender
{
    if ([_selectedItems count] == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_select_remove")
                                   preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];

        return;
    }

    UIAlertController *alert = [UIAlertController
                                alertControllerWithTitle:nil
                                message:OALocalizedString(@"fav_remove_q")
                                preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *yesButton = [UIAlertAction
                                actionWithTitle:OALocalizedString(@"shared_string_yes")
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * _Nonnull action) {
        [self removeFavoriteItems];
    }];
    UIAlertAction *cancelButton = [UIAlertAction
                             actionWithTitle:OALocalizedString(@"shared_string_no")
                             style:UIAlertActionStyleCancel
                             handler:nil];
    [alert addAction:yesButton];
    [alert addAction:cancelButton];
    [self presentViewController:alert animated:YES completion:nil];

}

- (IBAction) favoriteChangeColorClicked:(id)sender
{
    if ([_selectedItems count] == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_select")
                                   preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];

        return;
    }

    _colorController = [[OAEditColorViewController alloc] init];
    _colorController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_colorController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction) favoriteChangeGroupClicked:(id)sender
{
    if ([_selectedItems count] == 0)
    {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_select")
                                   preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}];

        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];

        return;
    }

    NSMutableArray *groupNames = [NSMutableArray array];
    for (OAFavoriteGroup *group in [OAFavoritesHelper getFavoriteGroups])
    {
        [groupNames addObject:group.name];
    }
    _groupController = [[OAEditGroupViewController alloc] initWithGroupName:nil groups:groupNames];
    _groupController.delegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_groupController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - OAEditColorViewControllerDelegate

- (void)colorChanged
{
    if ([_selectedItems count] == 0)
        return;

    if (_colorController.saveChanges)
    {
        OAFavoriteColor *favCol = [[OADefaultFavorite builtinColors] objectAtIndex:_colorController.colorIndex];
        NSMutableSet<NSString *> *groupNames = [NSMutableSet set];

        for (NSIndexPath *indexPath in _selectedItems)
        {
            OAFavoriteItem* item;
            if (_directionButton.tag == 1)
            {
                if (indexPath.section == 0)
                    item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            }
            else
            {
                NSDictionary *groupData = _data[indexPath.section][0];
                NSString *cellType = groupData[@"type"];
                if ([cellType isEqualToString:@"group"])
                {
                    FavoriteTableGroup* tableGroup = groupData[@"group"];
                    if (indexPath.row != 0)
                        item = [tableGroup.favoriteGroup.points objectAtIndex:indexPath.row - 1];
                    else
                        tableGroup.favoriteGroup.color = favCol.color;
                }
            }

            if (item)
            {
                [item setColor:favCol.color];
                [groupNames addObject:item.getCategory];

                if (indexPath.row == 1)
                {
                    OAFavoriteGroup *group = [OAFavoritesHelper getGroupByName:[item getCategory]];
                    group.color = favCol.color;
                }
            }
        }
        [OAFavoritesHelper saveCurrentPointsIntoFile];
    }
    [self finishEditing];
    [self.favoriteTableView reloadData];
}

#pragma mark - OAEditGroupViewControllerDelegate

- (void)groupChanged
{
    if ([_selectedItems count] == 0)
        return;

    if (_groupController.saveChanges)
    {
        NSMutableArray<NSIndexPath *> * sortedSelectedItems = [NSMutableArray arrayWithArray:_selectedItems];
        [sortedSelectedItems sortUsingComparator:^NSComparisonResult(NSIndexPath* obj1, NSIndexPath* obj2) {
            NSNumber *row1 = [NSNumber numberWithInteger:obj1.row];
            NSNumber *row2 = [NSNumber numberWithInteger:obj2.row];
            return [row2 compare:row1];
        }];

        NSMutableSet *groupNames = [NSMutableSet set];
        for (NSIndexPath *indexPath in sortedSelectedItems)
        {
            OAFavoriteItem* item;
            if (_directionButton.tag == 1)
            {
                if (indexPath.section == 0)
                    item = [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            }
            else
            {
                NSDictionary *groupData = _data[indexPath.section][0];
                NSString *cellType = groupData[@"type"];
                if ([cellType isEqualToString:@"group"])
                {
                    if (indexPath.row != 0)
                    {
                        FavoriteTableGroup* group = groupData[@"group"];
                        item = [group.favoriteGroup.points objectAtIndex:indexPath.row - 1];
                    }
                }
            }

            if (item)
            {
                [groupNames addObject:item.getCategory];
                [OAFavoritesHelper editFavoriteName:item newName:[item getDisplayName] group:_groupController.groupName descr:[item getDescription] address:[item getAddress]];
            }
        }
    }
    [self finishEditing];
    [self generateData];
}

- (NSArray<OAFavoriteItem *> *)getItemsForRows:(NSArray<NSIndexPath *> *)indexPath
{
    NSMutableArray<OAFavoriteItem *> *itemList = [[NSMutableArray alloc] init];
    if (_directionButton.tag == 1)
    { // Sorted
        [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
            [itemList addObject:[self.sortedFavoriteItems objectAtIndex:path.row]];
        }];
    }
    else
    {
        [indexPath enumerateObjectsUsingBlock:^(NSIndexPath* path, NSUInteger idx, BOOL *stop) {
            NSDictionary *groupData = _data[path.section][0];
            FavoriteTableGroup* group = groupData[@"group"];
            if (path.row != 0)
            {
                [itemList addObject:[group.favoriteGroup.points objectAtIndex:path.row - 1]];
            }
        }];
    }
    return itemList;
}

- (void) startEditing
{
    [self.favoriteTableView setEditing:YES animated:YES];
    _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    _editToolbarView.hidden = NO;
    [UIView animateWithDuration:.3 animations:^{
        self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
        [self applySafeAreaMargins];
    } completion:^(BOOL finished) {
        [self.tabBarController.tabBar setHidden:YES];
    }];

    _editButton.image = [UIImage imageNamed:@"icon_edit_active"];
    self.tabBarController.navigationItem.hidesBackButton = YES;
    [self.navigationController.navigationBar.topItem setRightBarButtonItems:@[_editButton] animated:YES];
    [self.favoriteTableView reloadData];
}

- (void) finishEditing
{
    _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight - _editToolbarView.bounds.size.height, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight + 1, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
    [UIView animateWithDuration:.3 animations:^{
        [self.tabBarController.tabBar setHidden:NO];
        self.tabBarController.tabBar.frame = CGRectMake(0.0, DeviceScreenHeight - self.tabBarController.tabBar.frame.size.height, DeviceScreenWidth, self.tabBarController.tabBar.frame.size.height);
        _editToolbarView.frame = CGRectMake(0.0, DeviceScreenHeight + 1.0, DeviceScreenWidth, _editToolbarView.bounds.size.height);
    } completion:^(BOOL finished) {
        _editToolbarView.hidden = YES;
        [self applySafeAreaMargins];
    }];

    _editButton.image = [UIImage imageNamed:@"icon_edit"];
    self.tabBarController.navigationItem.hidesBackButton = NO;

    if (_directionButton.tag == 1)
        _directionButton.image = [UIImage imageNamed:@"icon_direction_active"];
    else
        _directionButton.image = [UIImage imageNamed:@"icon_direction"];

    [self.navigationController.navigationBar.topItem setRightBarButtonItems:@[_editButton, _directionButton] animated:YES];
    [self.favoriteTableView setEditing:NO animated:YES];
    [_selectedItems removeAllObjects];
}

- (IBAction)editButtonClicked:(id)sender
{
    [self.favoriteTableView beginUpdates];
    if ([self.favoriteTableView isEditing])
        [self finishEditing];
    else
        [self startEditing];
    [self.favoriteTableView endUpdates];
}

- (IBAction) shareButtonClicked:(id)sender
{
    // Share selected favorites
    [self shareItems:_selectedItems];
    [self finishEditing];
    [self generateData];
}

- (void)shareItems:(NSArray<NSIndexPath *> *)selectedItems
{
    if ([selectedItems count] == 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                   message:OALocalizedString(@"fav_export_select")
                                   preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    NSArray<OAFavoriteItem *> *selectedFavoriteItems = [self getItemsForRows:selectedItems];
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [NSMutableDictionary dictionary];
    for (OAFavoriteItem *point in selectedFavoriteItems)
    {
        OAFavoriteGroup *group = groups[[point getCategory]];
        if (!group)
        {
            group = [[OAFavoriteGroup alloc] initWithPoint:point];
            groups[[point getCategory]] = group;
        }
        [group.points addObject:point];
    }

    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *filename = app.favoritesFilePrefix;
    if (groups.count == 1)
    {
        NSString *groupName = groups.allKeys.firstObject;
        filename = [NSString stringWithFormat:@"%@%@%@",
                    filename,
                    groupName.length > 0 ? app.favoritesGroupNameSeparator : @"",
                    groupName];
    }
    filename = [filename stringByAppendingString:GPX_FILE_EXT];

    NSString *fullFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    [OAFavoritesHelper saveFile:groups.allValues file:fullFilename];

    NSURL *favoritesUrl = [NSURL fileURLWithPath:fullFilename];
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[favoritesUrl] applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    activityViewController.popoverPresentationController.sourceRect = self.view.frame;
    activityViewController.completionWithItemsHandler = ^void(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        [NSFileManager.defaultManager removeItemAtURL:favoritesUrl error:nil];
    };

    [self presentViewController:activityViewController
                       animated:YES
                     completion:nil];
}

- (IBAction)goRootScreen:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void)onImportClicked
{
    NSArray<UTType *> *contentTypes = @[[UTType importedTypeWithIdentifier:@"com.topografix.gpx" conformingToType:UTTypeXML]];
    UIDocumentPickerViewController *documentPickerVC = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:contentTypes asCopy:YES];
    documentPickerVC.allowsMultipleSelection = NO;
    documentPickerVC.delegate = self;
    [self presentViewController:documentPickerVC animated:YES completion:nil];
}

- (void)onExportClicked
{
    if (self.sortedFavoriteItems.count == 0)
        return;

    NSString *filename = [[OsmAndApp instance].favoritesFilePrefix stringByAppendingString:GPX_FILE_EXT];
    NSString *fullFilename = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    [OAFavoritesHelper saveFile:[OAFavoritesHelper getFavoriteGroups] file:fullFilename];

    NSURL *favoritesUrl = [NSURL fileURLWithPath:fullFilename];
    UIActivityViewController *activityViewController =
    [[UIActivityViewController alloc] initWithActivityItems:@[favoritesUrl]
                                      applicationActivities:nil];
    activityViewController.popoverPresentationController.sourceView = self.view;
    activityViewController.popoverPresentationController.sourceRect = _exportButton.frame;
    activityViewController.completionWithItemsHandler = ^void(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        [NSFileManager.defaultManager removeItemAtURL:favoritesUrl error:nil];
    };
    
    [self presentViewController:activityViewController
                       animated:YES
                     completion:nil];
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (_directionButton.tag == 1)
        return [self getSortedNumberOfSectionsInTableView];
    return [self getUnsortedNumberOfSectionsInTableView];
}

-(NSInteger)getSortedNumberOfSectionsInTableView
{
    return _isSearchActive ? 1 : 2;
}

-(NSInteger)getUnsortedNumberOfSectionsInTableView
{
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_isSearchActive)
        return 0;
    else if (_data.count == 1)
        return 44;
    NSDictionary *item = _data[section][0];
    NSString *cellType = item[@"type"];
    return [cellType isEqualToString:@"actionItem"] || _directionButton.tag == 1 ? 44 : 16;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (_isSearchActive)
    {
        return nil;
    }
    else if (_directionButton.tag == 1)
    {
        if (section == 0)
            return _sortedHeaderView;
        else
            return _menuHeaderView;
    }
    else
    {
        return _unsortedHeaderViews[section];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != self.favoriteTableView.numberOfSections - 1 || _isSearchActive)
        return 60.;
    return  44.;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_directionButton.tag == 1)
        return [self getSortedNumberOfRowsInSection:section];
    return [self getUnsortedNumberOfRowsInSection:section];
}

-(NSInteger)getSortedNumberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || _isSearchActive)
        return _isFiltered ? [_filteredItems count] : [self.sortedFavoriteItems count];
    return _data.lastObject.count;
}

-(NSInteger)getUnsortedNumberOfRowsInSection:(NSInteger)section
{
    NSDictionary *item = _data[section][0];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"group"])
    {
        FavoriteTableGroup* groupData = item[@"group"];
        if (groupData.isOpen)
            return [groupData.favoriteGroup.points count] + 1;
        return 1;
    }
    return _data[section].count;
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point
{
    NSDictionary *item = _data[indexPath.section][0];
    NSString *cellType = item[@"type"];
    if (indexPath.row == 0 &&[cellType isEqualToString:@"group"])
    {
        NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];

        UIAction *appearanceAction = [UIAction actionWithTitle:OALocalizedString(@"change_appearance")
                                                         image:[UIImage systemImageNamed:@"paintpalette"]
                                                    identifier:nil
                                                       handler:^(__kindof UIAction * _Nonnull action) {
            FavoriteTableGroup *groupData = item[@"group"];
            OAFavoriteGroupEditorViewController *viewController =
                [[OAFavoriteGroupEditorViewController alloc] initWithGroup:[groupData.favoriteGroup toPointsGroup]];
            viewController.delegate = self;
            [self showModalViewController:viewController];
        }];
        appearanceAction.accessibilityLabel = OALocalizedString(@"change_appearance");
        [menuElements addObject:appearanceAction];

        UIAction *shareAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_share")
                                                    image:[UIImage systemImageNamed:@"square.and.arrow.up"]
                                               identifier:nil
                                                  handler:^(__kindof UIAction * _Nonnull action) {
            NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
            NSDictionary *item = _data[indexPath.section][0];
            FavoriteTableGroup *groupData = item[@"group"];
            for (NSInteger i = 0; i <= groupData.favoriteGroup.points.count; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            }
            [self shareItems:indexPaths];
        }];
        shareAction.accessibilityLabel = OALocalizedString(@"shared_string_share");
        [menuElements addObject:shareAction];

        UIAction *deleteAction = [UIAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                     image:[UIImage systemImageNamed:@"trash"]
                                                identifier:nil
                                                   handler:^(__kindof UIAction * _Nonnull action) {

            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:nil
                                        message:OALocalizedString(@"fav_remove_q")
                                        preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *yesButton = [UIAlertAction
                                        actionWithTitle:OALocalizedString(@"shared_string_yes")
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction * _Nonnull action) {
                NSDictionary *item = _data[indexPath.section][0];
                FavoriteTableGroup *groupData = item[@"group"];
                for (NSInteger i = 0; i <= groupData.favoriteGroup.points.count; i++)
                {
                    [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
                }
                [self removeFavoriteItems];
            }];
            UIAlertAction *cancelButton = [UIAlertAction
                                     actionWithTitle:OALocalizedString(@"shared_string_no")
                                     style:UIAlertActionStyleCancel
                                     handler:nil];
            [alert addAction:yesButton];
            [alert addAction:cancelButton];
            [self presentViewController:alert animated:YES completion:nil];
        }];
        deleteAction.accessibilityLabel = OALocalizedString(@"shared_string_delete");
        deleteAction.attributes = UIMenuElementAttributesDestructive;
        [menuElements addObject:[UIMenu menuWithTitle:@""
                                           image:nil
                                      identifier:nil
                                         options:UIMenuOptionsDisplayInline
                                        children:@[deleteAction]]];

        UIMenu *contextMenu = [UIMenu menuWithChildren:menuElements];
        return [UIContextMenuConfiguration configurationWithIdentifier:nil
                                                        previewProvider:nil
                                                        actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            return contextMenu;
        }];
    }

    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_directionButton.tag == 1)
        return [self getSortedcellForRowAtIndexPath:indexPath];
    return [self getUnsortedcellForRowAtIndexPath:indexPath];
}

-(UITableViewCell*)getSortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 || _isSearchActive)
    {
        OAPointTableViewCell* cell;
        cell = (OAPointTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        }

        if (cell)
        {
            OAFavoriteItem* item = _isFiltered ? [_filteredItems objectAtIndex:indexPath.row] : [self.sortedFavoriteItems objectAtIndex:indexPath.row];
            [cell.titleView setText:[item getDisplayName]];
            cell = [self setupPoiIconForCell:cell withFavaoriteItem:item];

            [cell.distanceView setText:item.distance];
            cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
            cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
        }

        return cell;

    }
    else
    {
        OASimpleTableViewCell* cell;
        cell = (OASimpleTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
        }

        if (cell)
        {
            NSDictionary* item = [self.menuItems objectAtIndex:indexPath.row];
            [cell.titleLabel setText:[item objectForKey:@"text"]];
            [cell.leftIconView setImage:[UIImage imageNamed:[item objectForKey:@"icon"]]];
        }
        return cell;
    }
}

- (UITableViewCell*)getUnsortedcellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"group"])
    {
        if (indexPath.row == 0)
            return [self getGroupHeaderCellForRowAtIndexPath:indexPath];
        else
            return [self getGroupElementCellForRowAtIndexPath:indexPath];
    }
    return [self getActionCellForRowAtIndexPath:indexPath];
}

- (UITableViewCell*)getGroupHeaderCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];

    OAPointHeaderTableViewCell* cell;
    cell = (OAPointHeaderTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAPointHeaderTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointHeaderTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointHeaderTableViewCell *)[nib objectAtIndex:0];
        cell.folderIcon.image = [UIImage templateImageNamed:@"ic_custom_folder"];
        [cell.valueLabel setHidden:YES];
    }
    if (cell)
    {
        OAFavoriteGroup* group = groupData.favoriteGroup;
        [cell.groupTitle setText:[OAFavoriteGroup getDisplayName:group.name]];
        cell.folderIcon.tintColor = groupData.favoriteGroup.color;

        cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
        [cell.openCloseGroupButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        if ([self.favoriteTableView isEditing])
            [cell.openCloseGroupButton setHidden:NO];
        else
            [cell.openCloseGroupButton setHidden:YES];

        if (groupData.isOpen)
        {
            cell.arrowImage.image = [UIImage templateImageNamed:@"ic_custom_arrow_down"];
        }
        else
        {
            cell.arrowImage.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"].imageFlippedForRightToLeftLayoutDirection;
            if ([cell isDirectionRTL])
                [cell.arrowImage setImage:cell.arrowImage.image.imageFlippedForRightToLeftLayoutDirection];
        }
        cell.arrowImage.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    }
    return cell;
}

- (UITableViewCell*)getGroupElementCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];

    NSInteger dataIndex = indexPath.row - 1;
    OAPointTableViewCell* cell;
    cell = (OAPointTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OAPointTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAPointTableViewCell *)[nib objectAtIndex:0];
        cell.directionImageView.image = [UIImage templateImageNamed:@"ic_small_direction"];
    }
    if (cell)
    {
        OAFavoriteItem* item = [groupData.favoriteGroup.points objectAtIndex:dataIndex];
        [cell.titleView setText:[item getDisplayName]];
        cell = [self setupPoiIconForCell:cell withFavaoriteItem:item];

        [cell.distanceView setText:item.distance];

        cell.directionImageView.tintColor = UIColorFromRGB(color_elevation_chart);
        cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
    }
    return cell;
}

- (OAPointTableViewCell *) setupPoiIconForCell:(OAPointTableViewCell *)cell withFavaoriteItem:(OAFavoriteItem*)item
{
    cell.titleIcon.image = [item getCompositeIcon];
    return cell;
}

- (UITableViewCell*)getActionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    OASimpleTableViewCell* cell;
    cell = (OASimpleTableViewCell *)[self.favoriteTableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        [cell descriptionVisibility:NO];
    }

    if (cell)
    {
        [cell.titleLabel setText:[item objectForKey:@"text"]];
        [cell.leftIconView setImage:[UIImage templateImageNamed:[item objectForKey:@"icon"]]];
        cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
    }
    return cell;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        if (_directionButton.tag == 0)
        {
            NSDictionary *item = _data[indexPath.section][0];
            NSString *cellType = item[@"type"];
            if ([cellType isEqualToString:@"group"])
                return indexPath;
            return nil;
        }
        else if (indexPath.section > 0)
        {
            return nil;
        }
    }
    return indexPath;

}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_directionButton.tag == 1)
        return [self canEditSortedRowAtIndexPath:indexPath];

    return [self canEditUnsortedRowAtIndexPath:indexPath];
}

- (BOOL) canEditSortedRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
        return YES;
    else
        return NO;
}

-(BOOL)canEditUnsortedRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][0];
    NSString *cellType = item[@"type"];
    return [cellType isEqualToString:@"group"];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.row != 0 && _directionButton.tag == 0) || _directionButton.tag == 1)
        return UITableViewCellEditingStyleDelete;
    else
        return UITableViewCellEditingStyleNone;
}

- (void)removeItemFromSortedFavoriteItems:(NSIndexPath *)indexPath
{
    OAFavoriteItem *item = _isFiltered ? _filteredItems[indexPath.row] : self.sortedFavoriteItems[indexPath.row];
    if (item)
    {
        NSInteger itemIndex = _isFiltered ? [_filteredItems indexOfObject:item] : [self.sortedFavoriteItems indexOfObject:item];
        if (itemIndex != NSNotFound)
        {
            [self.favoriteTableView beginUpdates];
            if (!_isFiltered)
            {
                [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[self.sortedFavoriteItems[itemIndex]]];
                [self.sortedFavoriteItems removeObjectAtIndex:itemIndex];
            }
            else
            {
                [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[_filteredItems[itemIndex]]];
                [_filteredItems removeObjectAtIndex:itemIndex];
            }
            
            [self.favoriteTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            [self.favoriteTableView endUpdates];
        }
    }
}

- (void)removeItemFromUnsortedFavoriteItems:(NSIndexPath *)indexPath
{
    NSInteger dataIndex = indexPath.row - 1;
    NSDictionary *groupData = _data[indexPath.section][0];
    FavoriteTableGroup *group = groupData[@"group"];
    OAFavoriteItem *item = group.favoriteGroup.points[dataIndex];
    if (item)
    {
        NSInteger itemIndex = [group.favoriteGroup.points indexOfObject:item];
        if (itemIndex != NSNotFound)
        {
            NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
            [self.favoriteTableView beginUpdates];
            if (group.favoriteGroup.points.count == 1)
            {
                NSMutableArray *unsortedHeaderViews = [_unsortedHeaderViews mutableCopy];
                [unsortedHeaderViews removeObject:_unsortedHeaderViews[indexPath.section]];
                _unsortedHeaderViews = unsortedHeaderViews;

                for (NSInteger i = indexPath.section; i < _unsortedHeaderViews.count - 1; i++)
                {
                    ((OAMultiselectableHeaderView *) _unsortedHeaderViews[i]).section--;
                    [indexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:i]];
                }
            }
            [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[group.favoriteGroup.points[itemIndex]]];

            NSInteger sortedItemIndex = _isFiltered ? [_filteredItems indexOfObject:item] : [self.sortedFavoriteItems indexOfObject:item];
            if (sortedItemIndex != NSNotFound)
                _isFiltered ? [_filteredItems removeObjectAtIndex:sortedItemIndex] : [self.sortedFavoriteItems removeObjectAtIndex:sortedItemIndex];

            if (group.favoriteGroup.points.count == 0)
            {
                [_data removeObjectAtIndex:indexPath.section];
                [self.favoriteTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
            }
            else
            {
                [self.favoriteTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
            }
            [self.favoriteTableView endUpdates];

            if (indexPaths.count > 0)
                [self.favoriteTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    }
}

- (void)removeItemsFromSortedFavoriteItems
{
    NSSortDescriptor *rowDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:NO];
    NSSortDescriptor *sectionDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:NO];
    NSArray<NSIndexPath *> *sortedArray = [_selectedItems sortedArrayUsingDescriptors:@[sectionDescriptor, rowDescriptor]];

    for (NSIndexPath *selectedItem in sortedArray)
    {
        OAFavoriteItem* item = _isFiltered ? _filteredItems[selectedItem.row] : self.sortedFavoriteItems[selectedItem.row];
        if (item)
        {
            NSInteger itemIndex = _isFiltered ? [_filteredItems indexOfObject:item] : [self.sortedFavoriteItems indexOfObject:item];
            if (itemIndex != NSNotFound)
            {
                [self.favoriteTableView beginUpdates];
                if (!_isFiltered)
                {
                    [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[self.sortedFavoriteItems[itemIndex]]];
                    [self.sortedFavoriteItems removeObjectAtIndex:itemIndex];
                }
                else
                {
                    [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[_filteredItems[itemIndex]]];
                    [_filteredItems removeObjectAtIndex:itemIndex];
                }
                [self.favoriteTableView deleteRowsAtIndexPaths:@[selectedItem] withRowAnimation:UITableViewRowAnimationLeft];
                [self.favoriteTableView endUpdates];
            }
        }
    }
    [self finishEditing];
}

- (void)removeItemsFromUnsortedFavoriteItems
{
    NSSortDescriptor *rowDescriptor = [[NSSortDescriptor alloc] initWithKey:@"row" ascending:NO];
    NSSortDescriptor *sectionDescriptor = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:NO];
    NSArray<NSIndexPath *> *sortedArray = [_selectedItems sortedArrayUsingDescriptors:@[sectionDescriptor, rowDescriptor]];

    for (NSIndexPath *selectedItem in sortedArray)
    {
        if (selectedItem.row == 0)
        {
            [self removeGroupHeader:selectedItem];
        }
        else
        {
            NSDictionary *groupData = _data[selectedItem.section][0];
            FavoriteTableGroup *group = groupData[@"group"];
            NSInteger index = selectedItem.row - 1;
            OAFavoriteItem* item = group.favoriteGroup.points[index];
            if (item && group.isOpen)
            {
                [self.favoriteTableView beginUpdates];
                [OAFavoritesHelper deleteFavoriteGroups:nil andFavoritesItems:@[item]];
                NSInteger sortedItemIndex = _isFiltered ? [_filteredItems indexOfObject:item] : [self.sortedFavoriteItems indexOfObject:item];
                if (sortedItemIndex != NSNotFound)
                    _isFiltered ? [_filteredItems removeObjectAtIndex:sortedItemIndex] : [self.sortedFavoriteItems removeObjectAtIndex:sortedItemIndex];
                [self.favoriteTableView deleteRowsAtIndexPaths:@[selectedItem] withRowAnimation:UITableViewRowAnimationLeft];
                [self.favoriteTableView endUpdates];
            }
        }
    }
    [self finishEditing];
}

- (void)removeGroupHeader:(NSIndexPath *)indexPath
{
    NSInteger numberOfRows = [self.favoriteTableView numberOfRowsInSection:[indexPath section]];

    if (numberOfRows == 1)
    {
        [self.favoriteTableView beginUpdates];

        NSDictionary *groupData = _data[indexPath.section][0];
        FavoriteTableGroup* group = groupData[@"group"];
        [OAFavoritesHelper deleteFavoriteGroups:@[group.favoriteGroup] andFavoritesItems:nil];

        [_data removeObjectAtIndex:indexPath.section];

        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
        NSMutableArray *unsortedHeaderViews = [_unsortedHeaderViews mutableCopy];
        [unsortedHeaderViews removeObject:_unsortedHeaderViews[indexPath.section]];
        _unsortedHeaderViews = unsortedHeaderViews;

        for (NSInteger i = indexPath.section; i < _unsortedHeaderViews.count - 1; i++)
        {
            ((OAMultiselectableHeaderView *) _unsortedHeaderViews[i]).section--;
            [indexPaths addObject:[NSIndexPath indexPathForRow:0 inSection:i]];
        }

        [self.favoriteTableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                              withRowAnimation:UITableViewRowAnimationFade];
        [self.favoriteTableView endUpdates];
        if (indexPaths.count > 0)
            [self.favoriteTableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void) removeFavoriteItems
{
    if (_directionButton.tag == 0)
        [self removeItemsFromUnsortedFavoriteItems];
    else
        [self removeItemsFromSortedFavoriteItems];
}

- (void)removeFavoriteItem:(NSIndexPath *)indexPath
{
    if (_directionButton.tag == 0)
        [self removeItemFromUnsortedFavoriteItems:indexPath];
    else
        [self removeItemFromSortedFavoriteItems:indexPath];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:nil
                                    message:OALocalizedString(@"fav_remove_q")
                                    preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *yesButton = [UIAlertAction
                                    actionWithTitle:OALocalizedString(@"shared_string_yes")
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * _Nonnull action) {
            [self removeFavoriteItem:indexPath];
        }];
        UIAlertAction *cancelButton = [UIAlertAction
                                 actionWithTitle:OALocalizedString(@"shared_string_no")
                                 style:UIAlertActionStyleCancel
                                 handler:nil];
        [alert addAction:yesButton];
        [alert addAction:cancelButton];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    isDecelerating = YES;
}

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
    {
        isDecelerating = NO;
        //[self refreshVisibleRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    isDecelerating = NO;
    //[self refreshVisibleRows];
}

#pragma mark - Favorite group's item editing operations

- (void) addIndexPathToSelectedCellsArray:(NSIndexPath *)indexPath
{
    if (![_selectedItems containsObject:indexPath])
         [_selectedItems addObject:indexPath];
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
    if ([_selectedItems containsObject:indexPath])
        [_selectedItems removeObject:indexPath];
}

- (void)openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];

    [self openCloseFavoriteGroup:indexPath];
}

- (void) selectAllItemsInGroup:(NSIndexPath *)indexPath selectHeader:(BOOL)selectHeader
{
    NSInteger rowsCount = [self.favoriteTableView numberOfRowsInSection:indexPath.section];

    [self.favoriteTableView beginUpdates];
    if (selectHeader)
        for (int i = 0; i < rowsCount; i++)
        {
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
    else
        for (int i = 0; i < rowsCount; i++)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES];
        }
    [self.favoriteTableView endUpdates];
}

- (void) selectGroupForEditing:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];
    if (groupData.isOpen)
        [self selectAllItemsInGroup:indexPath selectHeader:YES];
    else
        for (NSInteger i = 0; i <= groupData.favoriteGroup.points.count; i++)
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
}

- (void) deselectGroupForEditing:(NSIndexPath *)indexPath
{
    BOOL isGroupHeaderSelected = [self.favoriteTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];

    if (groupData.isOpen)
    {
        NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
        NSInteger rowsCount = [self.favoriteTableView numberOfRowsInSection:indexPath.section];
        [self selectAllItemsInGroup:indexPath selectHeader:(rowsCount != selectedRows.count && isGroupHeaderSelected)];
    }
    else
    {
        NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:_selectedItems];
        for (NSUInteger i = 0; i < tmp.count; i++)
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
    }
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
    for (NSIndexPath *itemPath in _selectedItems)
        if (itemPath.section == indexPath.section)
            [self.favoriteTableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void) openCloseFavoriteGroup:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][0];
    FavoriteTableGroup* groupData = item[@"group"];
    if (groupData.isOpen)
    {
        groupData.isOpen = NO;
        [self.favoriteTableView beginUpdates];
        [self.favoriteTableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self.favoriteTableView endUpdates];
        if ([_selectedItems containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        groupData.isOpen = YES;
        [self.favoriteTableView beginUpdates];
        [self.favoriteTableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self.favoriteTableView endUpdates];

        [self selectPreselectedCells:indexPath];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_directionButton.tag == 1)
        [self didSelectRowAtIndexPathSorter:indexPath];
    else
    {
        NSDictionary *item = _data[indexPath.section][0];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:@"group"])
        {
            if (indexPath.row == 0 && ![self.favoriteTableView isEditing])
                [self openCloseFavoriteGroup:indexPath];
            else if (indexPath.row == 0 && [self.favoriteTableView isEditing])
                [self selectGroupForEditing:indexPath];
            else
                [self didSelectRowAtIndexPathUnsorted:indexPath];
        }
        else
            [self didSelectRowAtIndexPathUnsorted:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_directionButton.tag == 1)
        [self didDeselectRowAtIndexPathSorted:indexPath];
    else
    {
        NSDictionary *item = _data[indexPath.section][0];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:@"group"])
        {
            if (indexPath.row == 0 && ![self.favoriteTableView isEditing])
                [self openCloseFavoriteGroup:indexPath];
            else if (indexPath.row == 0 && [self.favoriteTableView isEditing])
                [self deselectGroupForEditing:indexPath];
            else
                [self didDeselectRowAtIndexPathUnsorted:indexPath];
        }
    }
}

- (void) didSelectRowAtIndexPathSorter:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        [self addIndexPathToSelectedCellsArray:indexPath];
        return;
    }

    if (indexPath.section == 0)
    {
        OAFavoriteItem* item = _isFiltered ? [_filteredItems objectAtIndex:indexPath.row] : [self.sortedFavoriteItems objectAtIndex:indexPath.row];
        [self doPush];
        [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item pushed:YES];

    }
    else
    {
        NSDictionary* item = [_data.lastObject objectAtIndex:indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        [self.favoriteTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void) didDeselectRowAtIndexPathSorted:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        return;
    }
}

- (void) didDeselectRowAtIndexPathUnsorted:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        BOOL isGroupHeaderSelected = [self.favoriteTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
        NSInteger numberOfRowsInSection = [self.favoriteTableView numberOfRowsInSection:indexPath.section] - 1;
        NSInteger numberOfSelectedRowsInSection = 0;
        for (NSIndexPath *item in selectedRows)
        {
            if(item.section == indexPath.section)
                numberOfSelectedRowsInSection++;
        }
        [self removeIndexPathFromSelectedCellsArray:indexPath];

        if (indexPath.row == 0)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        else if (numberOfSelectedRowsInSection == numberOfRowsInSection && isGroupHeaderSelected)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        return;
    }
}

- (void) didSelectRowAtIndexPathUnsorted:(NSIndexPath *)indexPath
{
    if ([self.favoriteTableView isEditing])
    {
        BOOL isGroupHeaderSelected = [self.favoriteTableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        NSArray *selectedRows = [self.favoriteTableView indexPathsForSelectedRows];
        NSInteger numberOfRowsInSection = [self.favoriteTableView numberOfRowsInSection:indexPath.section] - 1;
        NSInteger numberOfSelectedRowsInSection = 0;
        for (NSIndexPath *item in selectedRows)
        {
            if(item.section == indexPath.section)
                numberOfSelectedRowsInSection++;
            [self addIndexPathToSelectedCellsArray:item];
        }
        if (numberOfSelectedRowsInSection == numberOfRowsInSection && !isGroupHeaderSelected)
        {
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        }
        else
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
        }
        return;
    }
    NSDictionary *item = _data[indexPath.section][0];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"group"])
    {
        FavoriteTableGroup* groupData = item[@"group"];
        OAFavoriteItem* item = [groupData.favoriteGroup.points objectAtIndex:indexPath.row - 1];
        [self doPush];
        [[OARootViewController instance].mapPanel openTargetViewWithFavorite:item pushed:YES];

    }
    else
    {
        item = _data[indexPath.section][indexPath.row];
        SEL action = NSSelectorFromString([item objectForKey:@"action"]);
        [self performSelector:action];
        [self removeIndexPathFromSelectedCellsArray:indexPath];
        [self.favoriteTableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)doPush
{
    parentController = self.parentViewController;

    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
    [[OARootViewController instance].navigationController popToRootViewControllerAnimated:NO];
}

+ (void)doPop
{
    CATransition* transition = [CATransition animation];
    transition.duration = 0.4;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionReveal;
    transition.subtype = kCATransitionFromLeft;
    [[OARootViewController instance].navigationController.view.layer addAnimation:transition forKey:nil];
    [[OARootViewController instance].navigationController pushViewController:parentController animated:NO];

    parentController = nil;
}

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
    NSInteger section = headerView.section;
    NSInteger rowsCount = [self.favoriteTableView numberOfRowsInSection:section];

    [self.favoriteTableView beginUpdates];
    if (value)
    {
        for (NSInteger i = 0; i < rowsCount; i++)
            [self.favoriteTableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (NSInteger i = 0; i < rowsCount; i++)
            [self.favoriteTableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.favoriteTableView endUpdates];
}

#pragma mark - OAEditorDelegate

- (void)addNewItemWithName:(NSString *)name
                  iconName:(NSString *)iconName
                     color:(UIColor *)color
        backgroundIconName:(NSString *)backgroundIconName
{
}

- (void)onEditorUpdated;
{
    [self generateData];
}

- (void)selectColorItem:(OAColorItem *)colorItem
{
}

- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color
{
    return [_appearanceCollection addNewSelectedColor:color];
}

- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color
{
    [_appearanceCollection changeColor:colorItem newColor:color];
}

- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem
{
    return [_appearanceCollection duplicateColor:colorItem];
}

- (void)deleteColorItem:(OAColorItem *)colorItem
{
    [_appearanceCollection deleteColor:colorItem];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    if (urls.count == 0)
        return;
    
    NSURL *url = urls.firstObject;
    [OARootViewController.instance importAsFavorites:url];
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBounds;
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            UIEdgeInsets insets = [self.favoriteTableView contentInset];
            [self.favoriteTableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardBounds.size.height, insets.right)];
            [self.favoriteTableView setScrollIndicatorInsets:self.favoriteTableView.contentInset];
        } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            UIEdgeInsets insets = [self.favoriteTableView contentInset];
            [self.favoriteTableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0.0, insets.right)];
            [self.favoriteTableView setScrollIndicatorInsets:self.favoriteTableView.contentInset];
        } completion:nil];
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    if (searchController.isActive && searchController.searchBar.searchTextField.text.length == 0)
    {
        _isSearchActive = YES;
        _isFiltered = NO;
        [self setupSearchController:YES filtered:NO];
        _directionButton.tag = 1;
        [self generateData];
        [self.favoriteTableView reloadData];
    }
    else if (searchController.isActive && searchController.searchBar.searchTextField.text.length > 0)
    {
        _isFiltered = YES;
        [self setupSearchController:NO filtered:YES];
        _filteredItems = [NSMutableArray new];
        for (OAFavoriteItem *item in self.sortedFavoriteItems)
        {
            NSRange nameTagRange = [[item getDisplayName] rangeOfString:searchController.searchBar.searchTextField.text options:NSCaseInsensitiveSearch];
            if (nameTagRange.location != NSNotFound)
                [_filteredItems addObject:item];
        }
        [self.favoriteTableView reloadData];
    }
    else
    {
        _isSearchActive = NO;
        _isFiltered = NO;
        _directionButton.tag = 0;
        [self setupSearchController:NO filtered:NO];
        [self.favoriteTableView reloadData];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"search_activity") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
    searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
    searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
}

@end
