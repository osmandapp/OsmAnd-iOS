#import <XCTest/XCTest.h>
#import "OAEditPointViewController.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OAIconsPaletteCell.h"
#import "OAColorCollectionHandler.h"
#import "Localization.h"
#import "OAFavoriteEditingHandler.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAFavoritesHelperBridge.h"
#import "OAFavoriteFolderBridgeItem.h"
#import "OAGPXAppearanceCollection.h"
#import "OAAppSettings.h"
#import "OAAppDelegate.h"
#import "OARootViewController.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAEditPointViewController (FavoriteIconTesting)
- (void)onGroupSelected:(NSString *)name;
@end

@interface OABaseEditorViewController (FavoriteIconTesting)
- (void)onCollectionItemSelected:(NSIndexPath *)indexPath selectedItem:(id)selectedItem collectionView:(UICollectionView *)collectionView shouldDismiss:(BOOL)shouldDismiss;
@end

@interface OAFavoriteIconTestPointEditor : OAEditPointViewController
@end

@implementation OAFavoriteIconTestPointEditor

- (void)dismissViewController
{
    // Keep the real Save path, but do not open the map context menu from a headless test.
}

@end

@interface OAFavoriteIconTests : XCTestCase
@property(nonatomic) NSMutableArray<UITableViewCell *> *boundIconCells;
@property(nonatomic) UINavigationController *groupNavigationController;
@end

@implementation OAFavoriteIconTests

- (void)tearDown
{
    self.boundIconCells = nil;
    self.groupNavigationController = nil;
    [super tearDown];
}

- (void)retainIconCell:(UITableViewCell *)cell
{
    if (!self.boundIconCells)
        self.boundIconCells = [NSMutableArray new];
    [self.boundIconCells addObject:cell];
}

- (void)bindPointIconCell:(OAEditPointViewController *)editor
{
    NSIndexPath *path = [NSIndexPath indexPathForRow:[[editor valueForKey:@"poiIconRowIndex"] integerValue]
                                         inSection:[[editor valueForKey:@"appearenceSectionIndex"] integerValue]];
    [self retainIconCell:[editor getRow:path]];
}

- (void)setUpWithCompletionHandler:(void (^)(NSError *))completion
{
    __weak OAFavoriteIconTests *weakSelf = self;
    [super setUpWithCompletionHandler:^(NSError *error) {
        if (error)
            completion(error);
        else
            [weakSelf waitForApplicationUntil:[NSDate dateWithTimeIntervalSinceNow:90] completion:completion];
    }];
}

- (void)waitForApplicationUntil:(NSDate *)deadline completion:(void (^)(NSError *))completion
{
    UIApplication *application = UIApplication.sharedApplication;
    OAAppDelegate *appDelegate = (OAAppDelegate *)application.delegate;
    UIWindow *window = application.mainWindow;
    UIViewController *root = window.rootViewController;
    BOOL hasApplicationRoot = appDelegate.rootViewController != nil
        && (root == appDelegate.rootViewController
            || ([root isKindOfClass:UINavigationController.class]
                && [((UINavigationController *)root).viewControllers containsObject:appDelegate.rootViewController]));
    if ([OsmAndApp instance].initialized && !appDelegate.isAppInitializing
        && window != nil && window.windowScene == application.mainScene && hasApplicationRoot
        && root.viewIfLoaded.window == window && root.transitionCoordinator == nil)
    {
        NSError *storageError = [self isolateFavoritesStorage];
        if (storageError)
        {
            completion(storageError);
            return;
        }
        OAAppSettings *settings = OAAppSettings.sharedManager;
        NSString *lastGroup = settings.lastFavCategoryEntered.get;
        NSArray *lastIcons = settings.lastUsedFavIcons.get;
        BOOL showFavorites = settings.mapSettingShowFavorites.get;
        OAGPXAppearanceCollection *appearance = OAGPXAppearanceCollection.sharedInstance;
        NSArray<OASPaletteItemSolid *> *colors = [appearance getAvailableColorsSortingByLastUsed];
        NSSet *colorIds = [NSSet setWithArray:[colors valueForKey:@"id"]];
        [self addTeardownBlock:^{
            [settings.lastFavCategoryEntered set:lastGroup];
            [settings.lastUsedFavIcons set:lastIcons];
            [settings setShowFavorites:showFavorites];
            for (OASPaletteItemSolid *color in [appearance getAvailableColorsSortingByLastUsed])
            {
                if (![colorIds containsObject:color.id])
                    [appearance deleteColor:color];
            }
            for (OASPaletteItemSolid *color in colors)
                [[OsmAndApp instance].paletteRepository updatePaletteItemItem:color];
        }];
        completion(nil);
    }
    else if (deadline.timeIntervalSinceNow <= 0)
    {
        completion([NSError errorWithDomain:@"FavoriteIconTests" code:1
                                  userInfo:@{NSLocalizedDescriptionKey: @"Application main window initialization timed out"}]);
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 20), dispatch_get_main_queue(), ^{
            [self waitForApplicationUntil:deadline completion:completion];
        });
    }
}

- (NSError *)isolateFavoritesStorage
{
    // Setup runs after synchronous favorites initialization; each test completes its saves in teardown.
    OsmAndAppInstance app = [OsmAndApp instance];
    NSString *originalFavoritesPath = app.favoritesPath;
    NSString *originalBackupPath = app.favoritesBackupPath;
    NSString *root = [NSTemporaryDirectory() stringByAppendingPathComponent:
                     [@"FavoriteIconTests-" stringByAppendingString:NSUUID.UUID.UUIDString]];
    NSString *favoritesPath = [root stringByAppendingPathComponent:@"favorites"];
    NSString *backupPath = [root stringByAppendingPathComponent:@"favorites_backup"];
    NSFileManager *files = NSFileManager.defaultManager;
    NSError *error;
    if (![files createDirectoryAtPath:favoritesPath withIntermediateDirectories:YES attributes:nil error:&error]
        || ![files createDirectoryAtPath:backupPath withIntermediateDirectories:YES attributes:nil error:&error])
    {
        if ([files fileExistsAtPath:root])
            [files removeItemAtPath:root error:nil];
        return error;
    }

    // Registered before the per-test cleanup, so it runs after fixture groups are removed.
    [self addTeardownBlock:^{
        // Complete the serial save queue while both paths still point to temporary storage.
        // This runs after the test assertions and fixture cleanup, not as part of the Save check.
        [OAFavoritesHelper saveCurrentPointsIntoFile:NO];
        [(NSObject *)app setValue:originalFavoritesPath forKey:@"favoritesPath"];
        [(NSObject *)app setValue:originalBackupPath forKey:@"favoritesBackupPath"];
        XCTAssertEqualObjects(app.favoritesPath, originalFavoritesPath);
        XCTAssertEqualObjects(app.favoritesBackupPath, originalBackupPath);
        NSError *cleanupError;
        XCTAssertTrue([files removeItemAtPath:root error:&cleanupError], @"%@", cleanupError);
        XCTAssertFalse([files fileExistsAtPath:root]);
    }];
    // KVC overrides the app's backing ivars only for this test, including filename helpers.
    [(NSObject *)app setValue:favoritesPath forKey:@"favoritesPath"];
    [(NSObject *)app setValue:backupPath forKey:@"favoritesBackupPath"];
    XCTAssertEqualObjects(app.favoritesPath, favoritesPath);
    XCTAssertEqualObjects(app.favoritesBackupPath, backupPath);
    return nil;
}

- (OAFavoriteGroup *)groupWithIcon:(NSString *)icon pointIcons:(NSArray<NSString *> *)icons
{
    NSString *name = [@"Favorite icon test " stringByAppendingString:NSUUID.UUID.UUIDString];
    OAFavoriteGroup *group = [[OAFavoriteGroup alloc] initWithName:name isVisible:YES color:UIColor.blueColor];
    group.iconName = icon;
    group.backgroundType = @"square";
    group.points = [NSMutableArray new];
    for (NSString *pointIcon in icons)
    {
        OAFavoriteItem *point = [[OAFavoriteItem alloc] initWithLat:48.45 lon:35.05
                                                           name:[NSString stringWithFormat:@"Point %lu", (unsigned long)group.points.count]
                                                       category:name];
        [point setIcon:pointIcon];
        [point setColor:UIColor.redColor];
        [point setBackgroundIcon:@"circle"];
        [group.points addObject:point];
    }
    // Register only this test's groups; do not replace or clear the application's favorites.
    [OAFavoritesHelper getGroups][name] = group;
    [self addTeardownBlock:^{ [[OAFavoritesHelper getGroups] removeObjectForKey:name]; }];
    return group;
}

- (OAFavoriteGroup *)storedGroupWithIcon:(NSString *)icon pointIcons:(NSArray<NSString *> *)icons
{
    OAFavoriteGroup *fixture = [self groupWithIcon:icon pointIcons:icons];
    // Register through the production API so editor Save includes this folder in storage.
    [OAFavoritesHelper addFavoriteGroup:fixture.name color:fixture.color iconName:fixture.iconName backgroundIconName:fixture.backgroundType];
    OAFavoriteGroup *group = [OAFavoritesHelper getGroups][fixture.name];
    [self addTeardownBlock:^{
        [OAFavoritesHelper deleteFavoriteGroups:@[group] andFavoritesItems:nil isNewFavorite:YES];
        [OAFavoritesHelper saveCurrentPointsIntoFile:NO];
        XCTAssertFalse([NSFileManager.defaultManager fileExistsAtPath:[[OsmAndApp instance] favoritesStorageFilename:group.name]]);
    }];
    if (fixture.points.count > 0)
    {
        for (OAFavoriteItem *point in fixture.points)
            [point setAltitude:1];
        XCTAssertTrue([OAFavoritesHelper addFavorites:fixture.points lookupAddress:NO sortAndSave:NO pointsGroup:nil]);
    }
    [OAFavoritesHelper saveCurrentPointsIntoFile:NO];
    return group;
}

- (OAFavoriteGroup *)loadStoredGroup:(OAFavoriteGroup *)group
{
    NSString *path = [[OsmAndApp instance] favoritesStorageFilename:group.name];
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:path]);
    NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [NSMutableDictionary new];
    [OAFavoritesHelper loadFileGroups:path groups:groups];
    XCTAssertNotNil(groups[group.name]);
    return groups[group.name];
}

- (void)tapIcon:(NSString *)icon inPointEditor:(OAEditPointViewController *)editor
{
    PoiIconCollectionHandler *icons = [editor valueForKey:@"poiIconCollectionHandler"];
    [icons setIconName:icon];
    OAIconsPaletteCell *cell = icons.hostCell;
    XCTAssertNotNil(cell);
    XCTAssertNotNil([icons getSelectedIndexPath]);
    // Use the same cell delegate entry point as a user's palette tap.
    [cell collectionView:cell.collectionView didSelectItemAtIndexPath:[icons getSelectedIndexPath]];
}

- (OAEditPointViewController *)newPointEditorInGroup:(OAFavoriteGroup *)group fromPOI:(BOOL)fromPOI
{
    OAPOI *poi;
    if (fromPOI)
    {
        poi = [OAPOI new];
        poi.name = @"Test supermarket";
        poi.latitude = 48.45;
        poi.longitude = 35.05;
        poi.type = [[OAPOIHelper sharedInstance] getPoiTypeByName:@"supermarket"];
        poi.mapIconName = @"shop_supermarket";
    }
    return [self newPointEditorInGroup:group poi:poi];
}

- (OAEditPointViewController *)newPointEditorInGroup:(OAFavoriteGroup *)group poi:(OAPOI *)poi
{
    [OAAppSettings.sharedManager.lastFavCategoryEntered set:group.name];
    OAEditPointViewController *editor = [[OAFavoriteIconTestPointEditor alloc] initWithLocation:CLLocationCoordinate2DMake(48.45, 35.05)
                                                                                   title:@"Test favorite" address:@"" customParam:nil
                                                                               pointType:EOAEditPointTypeFavorite targetMenuState:nil poi:poi targetObject:nil];
    [editor loadViewIfNeeded];
    [self bindPointIconCell:editor];
    return editor;
}

- (ItemsCollectionViewController *)allIconsForHandler:(PoiIconCollectionHandler *)icons
{
    ItemsCollectionViewController *allIcons = [[ItemsCollectionViewController alloc] initWithCollectionType:ColorCollectionTypePoiIconCategories
                                                                                                   items:icons.categories selectedItem:[icons getSelectedItem]];
    allIcons.iconsDelegate = icons;
    icons.allIconsVCDelegate = allIcons;
    [allIcons loadViewIfNeeded];
    return allIcons;
}

- (void)assertPointEditor:(OAEditPointViewController *)editor icon:(NSString *)icon group:(OAFavoriteGroup *)group
{
    NSString *selected = [editor valueForKey:@"selectedIconName"];
    if ([selected hasPrefix:@"mx_"])
        selected = [selected substringFromIndex:3];
    XCTAssertEqualObjects(selected, icon);
    OASPaletteItemSolid *color = [editor valueForKey:@"selectedColorItem"];
    XCTAssertEqual(color.colorInt, group.color.toARGBNumber);
    NSArray *shapes = [editor valueForKey:@"backgroundIconNames"];
    NSInteger shapeIndex = [[editor valueForKey:@"selectedBackgroundIndex"] integerValue];
    XCTAssertTrue(shapeIndex >= 0 && shapeIndex < shapes.count);
    if (shapeIndex >= 0 && shapeIndex < shapes.count)
        XCTAssertEqualObjects(shapes[shapeIndex], group.backgroundType);
}

- (FavoriteGroupEditorViewController *)editorForGroup:(OAFavoriteGroup *)group
{
    FavoriteGroupEditorViewController *editor = [[FavoriteGroupEditorViewController alloc] initWithGroup:group.toPointsGroup];
    [editor loadViewIfNeeded];
    // Bind the real icon cell so category changes use the same callback as the inline menu.
    [self retainIconCell:[editor getRow:[NSIndexPath indexPathForRow:0 inSection:1]]];
    return editor;
}

- (void)saveNewPointEditor:(OAEditPointViewController *)editor inGroup:(OAFavoriteGroup *)group expectedIcon:(NSString *)icon
{
    XCTAssertEqual(group.points.count, 0u);
    NSString *expectedGroupIcon = group.iconName ?: @"";
    UIColor *expectedColor = group.color;
    NSString *expectedShape = group.backgroundType;
    OAFavoriteEditingHandler *handler = [editor valueForKey:@"pointHandler"];
    NSString *expectedName = handler.getFavoriteItem.getName;
    [editor onRightNavbarButtonPressed];

    // Wait for the editor's save; do not issue another save that could hide a regression.
    NSString *path = [[OsmAndApp instance] favoritesStorageFilename:group.name];
    NSPredicate *pointIsStored = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [NSMutableDictionary new];
        [OAFavoritesHelper loadFileGroups:path groups:groups];
        OAFavoriteGroup *loaded = groups[group.name];
        return loaded.points.count == 1 && [loaded.points.firstObject.getName isEqualToString:expectedName];
    }];
    [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:pointIsStored object:nil]] timeout:10];

    OAFavoriteGroup *loaded = [self loadStoredGroup:group];
    XCTAssertEqualObjects(loaded.iconName ?: @"", expectedGroupIcon);
    XCTAssertEqualObjects(loaded.color, expectedColor);
    XCTAssertEqualObjects(loaded.backgroundType, expectedShape);
    XCTAssertEqual(loaded.points.count, 1u);
    OAFavoriteItem *point = loaded.points.firstObject;
    XCTAssertNotNil(point);
    XCTAssertEqualObjects(point.getName, expectedName);
    XCTAssertEqualObjects(point.getCategory, group.name);
    XCTAssertEqualObjects(point.getIcon, icon);
    XCTAssertEqualObjects(point.getColor, expectedColor);
    XCTAssertEqualObjects(point.getBackgroundIcon, expectedShape);
}

- (void)waitForTransitionOfViewController:(UIViewController *)controller
{
    id<UIViewControllerTransitionCoordinator> transition = controller.transitionCoordinator;
    if (transition)
    {
        XCTestExpectation *completed = [self expectationWithDescription:@"View controller transition completed"];
        [transition animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            [completed fulfill];
        }];
        [self waitForExpectations:@[completed] timeout:5];
    }
}

- (UINavigationController *)showGroupEditor:(FavoriteGroupEditorViewController *)editor
{
    UIWindow *window = UIApplication.sharedApplication.mainWindow;
    XCTAssertNotNil(window);
    XCTAssertEqual(window.windowScene, UIApplication.sharedApplication.mainScene);
    if (!window)
        return nil;
    if (!self.groupNavigationController)
    {
        UIViewController *root = window.rootViewController;
        XCTAssertNotNil(root);
        UIViewController *presenter = root;
        while (presenter.presentedViewController)
            presenter = presenter.presentedViewController;
        [self waitForTransitionOfViewController:presenter];
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
        navigation.modalPresentationStyle = UIModalPresentationFullScreen;
        [navigation pushViewController:editor animated:NO];
        // Present in the main window without replacing its application root or key window.
        [self addTeardownBlock:^{
            [self waitForTransitionOfViewController:navigation];
            [self waitForTransitionOfViewController:navigation.presentedViewController];
            if (navigation.presentingViewController)
            {
                XCTestExpectation *dismissed = [self expectationWithDescription:@"Editor presentation dismissed"];
                [presenter dismissViewControllerAnimated:NO completion:^{ [dismissed fulfill]; }];
                [self waitForExpectations:@[dismissed] timeout:5];
            }
            XCTAssertNil(navigation.presentingViewController);
            XCTAssertNil(presenter.presentedViewController);
            XCTAssertEqual(window.rootViewController, root);
            XCTAssertEqual(UIApplication.sharedApplication.mainWindow, window);
        }];
        self.groupNavigationController = navigation;
        XCTestExpectation *presented = [self expectationWithDescription:@"Editor presented in main window"];
        [presenter presentViewController:navigation animated:NO completion:^{ [presented fulfill]; }];
        [self waitForExpectations:@[presented] timeout:5];
    }
    else
    {
        [self waitForTransitionOfViewController:self.groupNavigationController];
        [self.groupNavigationController setViewControllers:@[[UIViewController new], editor] animated:NO];
    }
    [window layoutIfNeeded];
    XCTAssertEqual(editor.view.window, window);
    return self.groupNavigationController;
}

- (void)applyIcon:(NSString *)icon toGroup:(OAFavoriteGroup *)group points:(BOOL)points defaults:(BOOL)defaults
{
    XCTestExpectation *completion = [self expectationWithDescription:@"Group icon update completes"];
    [OAFavoritesHelper updateGroup:group iconName:icon updatePoints:points updateGroupIcon:defaults saveImmediately:NO completion:^{
        [completion fulfill];
    }];
    [self waitForExpectations:@[completion] timeout:5];
}

- (void)testGroupCreatedInFavoriteEditorAppearsInMyPlacesWithoutSavingPoint
{
    OAFavoriteGroup *source = [self groupWithIcon:@"" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:source fromPOI:YES];
    NSString *name = [@"Favorite editor group " stringByAppendingString:NSUUID.UUID.UUIDString];
    NSPredicate *matchingGroup = [NSPredicate predicateWithFormat:@"groupName == %@", name];
    OAFavoritesHelperBridge *bridge = OAFavoritesHelperBridge.shared;
    // Prime the same folder cache used by My Places before creating the group.
    XCTAssertEqual([[bridge.favoriteFolders filteredArrayUsingPredicate:matchingGroup] count], 0u);
    [self addTeardownBlock:^{
        OAFavoriteGroup *group = [OAFavoritesHelper groupByName:name];
        if (group)
            [OAFavoritesHelper deleteFavoriteGroups:@[group] andFavoritesItems:nil isNewFavorite:YES];
        [OAFavoritesHelper notifyFavoritesStorageChanged];
    }];
    XCTestExpectation *foldersUpdated = [self expectationForNotification:@"FavoritesStorageChangedNotification"
                                                                 object:nil handler:^BOOL(NSNotification *notification) {
        return [[bridge.favoriteFolders filteredArrayUsingPredicate:matchingGroup] count] == 1;
    }];

    // Done in the child group editor calls this delegate before the favorite is saved.
    [(id<OAEditorDelegate>)editor addNewItemWithName:name iconName:@"" color:UIColor.blueColor backgroundIconName:@"square"];
    [self waitForExpectations:@[foldersUpdated] timeout:5];

    OAFavoriteGroup *group = [OAFavoritesHelper groupByName:name];
    XCTAssertNotNil(group);
    XCTAssertEqual(group.points.count, 0u);
    XCTAssertEqualObjects(editor.groupTitle, name);
    NSArray<OAFavoriteFolderBridgeItem *> *folders = [bridge.favoriteFolders filteredArrayUsingPredicate:matchingGroup];
    XCTAssertEqual(folders.count, 1u);
    XCTAssertEqual(folders.firstObject.pointsCount, 0u);
    XCTAssertEqualObjects(folders.firstObject.color, UIColor.blueColor);
}

- (void)testNewPOIUsesOriginalIconAndFolderColorAndShape
{
    OAFavoriteGroup *group = [self storedGroupWithIcon:@"" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:group fromPOI:YES];
    [self assertPointEditor:editor icon:@"shop_supermarket" group:group];
    PoiIconCollectionHandler *icons = [editor valueForKey:@"poiIconCollectionHandler"];
    XCTAssertEqualObjects(icons.categoriesByKeyName[icons.ORIGINAL_KEY].iconKeys, (@[@"shop_supermarket"]));
    [self saveNewPointEditor:editor inGroup:group expectedIcon:@"shop_supermarket"];
}

- (void)testNewPOIUsesConcreteFolderAppearanceAfterSaving
{
    OAFavoriteGroup *group = [self storedGroupWithIcon:@"special_heart" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:group fromPOI:YES];
    [self assertPointEditor:editor icon:@"special_heart" group:group];
    [self saveNewPointEditor:editor inGroup:group expectedIcon:@"special_heart"];
}

- (void)testConcreteFolderIconOverridesPOIAndOriginalRestoresIt
{
    OAFavoriteGroup *group = [self storedGroupWithIcon:@"special_heart" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:group fromPOI:YES];
    [self assertPointEditor:editor icon:@"special_heart" group:group];
    PoiIconCollectionHandler *icons = [editor valueForKey:@"poiIconCollectionHandler"];
    [icons onMenuItemSelectedWithName:icons.ORIGINAL_KEY];
    [self assertPointEditor:editor icon:@"shop_supermarket" group:group];
    [self saveNewPointEditor:editor inGroup:group expectedIcon:@"shop_supermarket"];
}

- (void)testNewPOIFollowsFolderUntilAnIconIsManuallySelected
{
    OAFavoriteGroup *original = [self groupWithIcon:@"" pointIcons:@[]];
    OAFavoriteGroup *concrete = [self groupWithIcon:@"special_heart" pointIcons:@[]];
    concrete.color = UIColor.greenColor;
    concrete.backgroundType = @"octagon";
    OAEditPointViewController *editor = [self newPointEditorInGroup:original fromPOI:YES];
    [editor onGroupSelected:concrete.name];
    [self assertPointEditor:editor icon:@"special_heart" group:concrete];
    [editor onGroupSelected:original.name];
    [self assertPointEditor:editor icon:@"shop_supermarket" group:original];
    [self tapIcon:@"special_bicycle" inPointEditor:editor];
    [editor onGroupSelected:concrete.name];
    [self assertPointEditor:editor icon:@"special_bicycle" group:concrete];
    [editor onGroupSelected:original.name];
    [self assertPointEditor:editor icon:@"special_bicycle" group:original];
}

- (void)testEmptyMapPointUsesStarForOriginalAndConcreteFolderIconOtherwise
{
    OAFavoriteGroup *original = [self groupWithIcon:@"" pointIcons:@[]];
    OAFavoriteGroup *concrete = [self groupWithIcon:@"special_heart" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:original fromPOI:NO];
    [self assertPointEditor:editor icon:@"special_star" group:original];
    [editor onGroupSelected:concrete.name];
    [self assertPointEditor:editor icon:@"special_heart" group:concrete];
}

- (void)testDuplicateCheckForFirstPointPreservesEmptyFolderDefaults
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:group fromPOI:NO];
    [self tapIcon:@"special_bicycle" inPointEditor:editor];
    OAFavoriteEditingHandler *handler = [editor valueForKey:@"pointHandler"];

    // Save checks for duplicate names before inserting the first point into the folder.
    XCTAssertNil([handler checkDuplicates:@"First favorite" group:group.name]);
    XCTAssertEqual([OAFavoritesHelper getGroups][group.name], group);
    XCTAssertEqualObjects(group.iconName, @"special_heart");
    XCTAssertEqualObjects(group.color, UIColor.blueColor);
    XCTAssertEqualObjects(group.backgroundType, @"square");
    XCTAssertEqual(group.points.count, 0u);
    [self assertPointEditor:editor icon:@"special_bicycle" group:group];

    OAEditPointViewController *nextEditor = [self newPointEditorInGroup:group fromPOI:NO];
    [self assertPointEditor:nextEditor icon:@"special_heart" group:group];
}

- (void)testOriginalPOIIconDoesNotLeakIntoOtherPointOrFolderEditors
{
    OAFavoriteGroup *group = [self groupWithIcon:@"" pointIcons:@[]];
    OAEditPointViewController *supermarket = [self newPointEditorInGroup:group fromPOI:YES];
    PoiIconCollectionHandler *supermarketIcons = [supermarket valueForKey:@"poiIconCollectionHandler"];
    OAPOI *poi = [OAPOI new];
    poi.name = @"Test cafe";
    poi.latitude = 48.45;
    poi.longitude = 35.05;
    poi.type = [[OAPOIHelper sharedInstance] getPoiTypeByName:@"cafe"];
    poi.mapIconName = @"amenity_cafe";
    OAEditPointViewController *cafe = [self newPointEditorInGroup:group poi:poi];
    PoiIconCollectionHandler *cafeIcons = [cafe valueForKey:@"poiIconCollectionHandler"];

    XCTAssertEqualObjects(supermarketIcons.categoriesByKeyName[supermarketIcons.ORIGINAL_KEY].iconKeys, (@[@"shop_supermarket"]));
    XCTAssertEqualObjects(cafeIcons.categoriesByKeyName[cafeIcons.ORIGINAL_KEY].iconKeys, (@[@"amenity_cafe"]));
    [supermarketIcons onMenuItemSelectedWithName:supermarketIcons.ORIGINAL_KEY];
    [cafeIcons onMenuItemSelectedWithName:cafeIcons.ORIGINAL_KEY];
    [self assertPointEditor:supermarket icon:@"shop_supermarket" group:group];
    [self assertPointEditor:cafe icon:@"amenity_cafe" group:group];

    OAEditPointViewController *regular = [self newPointEditorInGroup:group fromPOI:NO];
    PoiIconCollectionHandler *regularIcons = [regular valueForKey:@"poiIconCollectionHandler"];
    XCTAssertNil(regularIcons.categoriesByKeyName[regularIcons.ORIGINAL_KEY]);
    [self assertPointEditor:regular icon:@"special_star" group:group];

    FavoriteGroupEditorViewController *folderEditor = [self editorForGroup:group];
    PoiIconCollectionHandler *folderIcons = folderEditor.getPoiIconCollectionHandler;
    XCTAssertNotNil(folderIcons.categoriesByKeyName[folderIcons.ORIGINAL_KEY]);
    XCTAssertEqual(folderIcons.categoriesByKeyName[folderIcons.ORIGINAL_KEY].iconKeys.count, 0u);
}

- (void)testAllIconsKeepsPickedIconAndHighlightAfterBrowsingAndReopening
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_heart"]];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    PoiIconCollectionHandler *icons = editor.getPoiIconCollectionHandler;
    ItemsCollectionViewController *allIcons = [self allIconsForHandler:icons];
    [allIcons onCollectionItemSelected:[NSIndexPath indexPathForRow:0 inSection:0]
                         selectedItem:@"mx_shop_supermarket" collectionView:[icons getCollectionView] shouldDismiss:NO];
    XCTAssertEqualObjects([icons getSelectedItem], @"mx_shop_supermarket");
    XCTAssertEqualObjects(editor.appearanceIconName, @"mx_shop_supermarket");

    allIcons = [self allIconsForHandler:icons];
    [allIcons scrollToCategoryWithCategoryKey:icons.specialKey];
    XCTAssertEqualObjects([icons getSelectedItem], @"mx_shop_supermarket");
    XCTAssertEqualObjects(editor.appearanceIconName, @"mx_shop_supermarket");
    icons.allIconsVCDelegate = nil;

    ItemsCollectionViewController *reopened = [self allIconsForHandler:icons];
    NSUInteger categoryIndex = [icons.categories indexOfObjectPassingTest:^BOOL(IconsAppearanceCategory *category, NSUInteger index, BOOL *stop) {
        return [category.iconKeys containsObject:@"mx_shop_supermarket"];
    }];
    XCTAssertNotEqual(categoryIndex, NSNotFound);
    if (categoryIndex != NSNotFound)
    {
        OACollectionSingleLineTableViewCell *cell = (OACollectionSingleLineTableViewCell *)[reopened getRow:[NSIndexPath indexPathForRow:0 inSection:categoryIndex + 1]];
        [self retainIconCell:cell];
        IconCollectionHandler *grid = (IconCollectionHandler *)[cell getCollectionHandler];
        NSUInteger iconIndex = [icons.categories[categoryIndex].iconKeys indexOfObject:@"mx_shop_supermarket"];
        XCTAssertEqualObjects([grid getSelectedIndexPath], [NSIndexPath indexPathForRow:iconIndex inSection:0]);
        XCTAssertEqualObjects([grid getSelectedItem], @"mx_shop_supermarket");
    }
    icons.allIconsVCDelegate = nil;
}

- (void)testExistingFavoriteKeepsIconWhenMovedToConcreteOrOriginalFolder
{
    for (NSString *icon in @[@"special_heart", @""])
    {
        OAFavoriteGroup *source = [self storedGroupWithIcon:@"special_heart" pointIcons:@[@"special_bicycle"]];
        OAFavoriteGroup *destination = [self storedGroupWithIcon:icon pointIcons:@[]];
        OAFavoriteItem *point = source.points.firstObject;
        OAEditPointViewController *editor = [[OAEditPointViewController alloc] initWithFavorite:point];
        [editor loadViewIfNeeded];
        [self bindPointIconCell:editor];
        [editor onGroupSelected:destination.name];
        [self assertPointEditor:editor icon:@"special_bicycle" group:destination];
        [editor onRightNavbarButtonPressed];

        XCTAssertEqual(source.points.count, 0u);
        XCTAssertEqual(destination.points.count, 1u);
        XCTAssertEqual(destination.points.firstObject, point);
        XCTAssertEqualObjects(point.getCategory, destination.name);
        XCTAssertEqualObjects(point.getIcon, @"special_bicycle");

        // Wait for the editor's asynchronous save without issuing a second save from the test.
        NSPredicate *moveIsStored = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            NSMutableDictionary<NSString *, OAFavoriteGroup *> *groups = [NSMutableDictionary new];
            [OAFavoritesHelper loadFileGroups:[[OsmAndApp instance] favoritesStorageFilename:source.name] groups:groups];
            [OAFavoritesHelper loadFileGroups:[[OsmAndApp instance] favoritesStorageFilename:destination.name] groups:groups];
            return groups[source.name] != nil && groups[source.name].points.count == 0
                && groups[destination.name].points.count == 1
                && [groups[destination.name].points.firstObject.getCategory isEqualToString:destination.name];
        }];
        XCTNSPredicateExpectation *saved = [[XCTNSPredicateExpectation alloc] initWithPredicate:moveIsStored object:nil];
        [self waitForExpectations:@[saved] timeout:10];
        XCTAssertEqual([self loadStoredGroup:source].points.count, 0u);
        OAFavoriteGroup *storedDestination = [self loadStoredGroup:destination];
        XCTAssertEqual(storedDestination.points.count, 1u);
        OAFavoriteItem *storedPoint = storedDestination.points.firstObject;
        XCTAssertEqualObjects(storedPoint.getCategory, destination.name);
        XCTAssertEqualObjects(storedPoint.getIcon, @"special_bicycle");
        XCTAssertEqualObjects(storedPoint.getColor, destination.color);
        XCTAssertEqualObjects(storedPoint.getBackgroundIcon, destination.backgroundType);
        if (storedPoint)
        {
            OAEditPointViewController *reopened = [[OAEditPointViewController alloc] initWithFavorite:storedPoint];
            [reopened loadViewIfNeeded];
            [self bindPointIconCell:reopened];
            [self assertPointEditor:reopened icon:@"special_bicycle" group:destination];
        }
    }
}

- (void)checkUpdateWithIcon:(NSString *)icon points:(BOOL)updatePoints defaults:(BOOL)updateDefaults
           expectedDefault:(NSString *)expectedDefault expectedPointIcons:(NSArray<NSString *> *)expectedPointIcons
{
    NSArray *originalIcons = @[@"special_bicycle", @"shop_supermarket"];
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:originalIcons];
    [self applyIcon:icon toGroup:group points:updatePoints defaults:updateDefaults];
    XCTAssertEqualObjects(group.iconName ?: @"", expectedDefault);
    XCTAssertEqual(group.points.count, expectedPointIcons.count);
    for (NSUInteger index = 0; index < MIN(group.points.count, expectedPointIcons.count); index++)
    {
        XCTAssertEqualObjects(group.points[index].getIcon, expectedPointIcons[index]);
        XCTAssertEqualObjects(group.points[index].getColor, UIColor.redColor);
        XCTAssertEqualObjects(group.points[index].getBackgroundIcon, @"circle");
    }
}

- (void)testConcreteIconApplyOnlyToNewPointsChangesDefaultOnly
{
    [self checkUpdateWithIcon:@"special_star" points:NO defaults:YES
             expectedDefault:@"special_star" expectedPointIcons:@[@"special_bicycle", @"shop_supermarket"]];
}

- (void)testConcreteIconApplyToExistingChangesPointsOnly
{
    [self checkUpdateWithIcon:@"special_star" points:YES defaults:NO
             expectedDefault:@"special_heart" expectedPointIcons:@[@"special_star", @"special_star"]];
}

- (void)testConcreteIconApplyToAllChangesDefaultAndPoints
{
    [self checkUpdateWithIcon:@"special_star" points:YES defaults:YES
             expectedDefault:@"special_star" expectedPointIcons:@[@"special_star", @"special_star"]];
}

- (void)testOriginalApplyOnlyToNewPointsClearsDefaultAndPreservesPointIcons
{
    [self checkUpdateWithIcon:@"" points:NO defaults:YES
             expectedDefault:@"" expectedPointIcons:@[@"special_bicycle", @"shop_supermarket"]];
}

- (void)testOriginalApplyToExistingPreservesDefaultAndPointIcons
{
    [self checkUpdateWithIcon:@"" points:YES defaults:NO
             expectedDefault:@"special_heart" expectedPointIcons:@[@"special_bicycle", @"shop_supermarket"]];
}

- (void)testOriginalApplyToAllClearsDefaultAndPreservesPointIcons
{
    [self checkUpdateWithIcon:@"" points:YES defaults:YES
             expectedDefault:@"" expectedPointIcons:@[@"special_bicycle", @"shop_supermarket"]];
}

- (void)testApplyToExistingUsesDefaultsPreviouslySavedForNewPoints
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_heart", @"special_heart"]];
    [self applyIcon:@"special_bicycle" toGroup:group points:NO defaults:YES];
    [OAFavoritesHelper updateGroup:group color:UIColor.greenColor updatePoints:NO updateGroupColor:YES saveImmediately:NO];
    [OAFavoritesHelper updateGroup:group backgroundIconName:@"octagon" updatePoints:NO updateGroupShape:YES saveImmediately:NO];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    [editor onRowSelected:[NSIndexPath indexPathForRow:0 inSection:3]];
    for (OAFavoriteItem *point in group.points)
    {
        XCTAssertEqualObjects(point.getIcon, @"special_bicycle");
        XCTAssertEqualObjects(point.getColor, UIColor.greenColor);
        XCTAssertEqualObjects(point.getBackgroundIcon, @"octagon");
    }
}

- (void)checkExplicitOriginalRoundTripWithPointIcons:(NSArray<NSString *> *)pointIcons
{
    OAFavoriteGroup *group = [self storedGroupWithIcon:@"special_heart" pointIcons:pointIcons];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    [self showGroupEditor:editor];
    PoiIconCollectionHandler *icons = [editor getPoiIconCollectionHandler];
    [icons onMenuItemSelectedWithName:icons.ORIGINAL_KEY];
    XCTAssertEqualObjects(editor.editIconName, @"");
    [editor editPointsGroup:YES updateGroupValues:YES];
    NSPredicate *originalIsStored = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        NSMutableDictionary *groups = [NSMutableDictionary new];
        [OAFavoritesHelper loadFileGroups:[[OsmAndApp instance] favoritesStorageFilename:group.name] groups:groups];
        OAFavoriteGroup *loaded = groups[group.name];
        return loaded != nil && loaded.iconName.length == 0;
    }];
    [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:originalIsStored object:nil]] timeout:10];
    OAFavoriteGroup *loaded = [self loadStoredGroup:group];
    XCTAssertEqualObjects(loaded.iconName ?: @"", @"");
    XCTAssertEqual(loaded.points.count, pointIcons.count);
    for (NSUInteger index = 0; index < MIN(loaded.points.count, pointIcons.count); index++)
        XCTAssertEqualObjects(loaded.points[index].getIcon, pointIcons[index]);
    FavoriteGroupEditorViewController *reopened = [self editorForGroup:loaded];
    XCTAssertEqualObjects(reopened.appearanceIconName, @"");
    XCTAssertEqualObjects(reopened.getPoiIconCollectionHandler.selectedCatagoryKey, icons.ORIGINAL_KEY);
}

- (void)testExplicitOriginalSurvivesSavingAndReopeningFolder
{
    [self checkExplicitOriginalRoundTripWithPointIcons:@[@"special_heart", @"special_heart"]];
}

- (void)testExplicitOriginalSurvivesSavingAndReopeningMixedFolder
{
    [self checkExplicitOriginalRoundTripWithPointIcons:@[@"special_bicycle", @"shop_supermarket"]];
}

- (void)testSelectingOriginalInAllIconsChangesFolderSelection
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_heart"]];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    PoiIconCollectionHandler *icons = [editor getPoiIconCollectionHandler];
    ItemsCollectionViewController *allIcons = [self allIconsForHandler:icons];
    [allIcons scrollToCategoryWithCategoryKey:icons.ORIGINAL_KEY];
    XCTAssertEqualObjects(editor.editIconName, @"");
    XCTAssertEqualObjects(editor.appearanceIconName, @"");
    icons.allIconsVCDelegate = nil;
}

- (void)testMixedIconsPreserveStoredDefaultOnColorSave
{
    for (NSNumber *applyToAll in @[@NO, @YES])
    {
        NSArray *pointIcons = @[@"special_bicycle", @"shop_supermarket"];
        OAFavoriteGroup *group = [self storedGroupWithIcon:@"special_heart" pointIcons:pointIcons];
        FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
        [self showGroupEditor:editor];
        XCTAssertEqualObjects(editor.editIconName, @"special_heart");
        XCTAssertEqualObjects(editor.appearanceIconName, @"");

        OAColorCollectionHandler *colors = [editor valueForKey:@"colorCollectionHandler"];
        OASPaletteItemSolid *green = [editor.appearanceCollection getColorItemWithValue:UIColor.greenColor.toARGBNumber];
        [editor onCollectionItemSelected:[NSIndexPath indexPathForRow:0 inSection:0] selectedItem:green collectionView:[colors getCollectionView] shouldDismiss:NO];
        XCTAssertEqualObjects(editor.appearanceColor, UIColor.greenColor);
        [editor editPointsGroup:applyToAll.boolValue updateGroupValues:YES];

        NSPredicate *colorIsStored = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
            NSMutableDictionary *groups = [NSMutableDictionary new];
            [OAFavoritesHelper loadFileGroups:[[OsmAndApp instance] favoritesStorageFilename:group.name] groups:groups];
            return [((OAFavoriteGroup *)groups[group.name]).color isEqual:UIColor.greenColor];
        }];
        [self waitForExpectations:@[[[XCTNSPredicateExpectation alloc] initWithPredicate:colorIsStored object:nil]] timeout:10];
        OAFavoriteGroup *loaded = [self loadStoredGroup:group];
        XCTAssertEqualObjects(loaded.iconName, @"special_heart");
        XCTAssertEqual(loaded.points.count, pointIcons.count);
        for (NSUInteger index = 0; index < MIN(loaded.points.count, pointIcons.count); index++)
        {
            XCTAssertEqualObjects(loaded.points[index].getIcon, pointIcons[index]);
            XCTAssertEqualObjects(loaded.points[index].getColor, applyToAll.boolValue ? UIColor.greenColor : UIColor.redColor);
        }
        FavoriteGroupEditorViewController *reopened = [self editorForGroup:loaded];
        XCTAssertEqualObjects(reopened.editIconName, @"special_heart");
        OAEditPointViewController *newPoint = [self newPointEditorInGroup:group fromPOI:NO];
        [self assertPointEditor:newPoint icon:@"special_heart" group:group];
    }
}

- (void)testBackWarnsAfterChangingConcreteIconToOriginal
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_heart"]];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    UINavigationController *navigation = [self showGroupEditor:editor];
    PoiIconCollectionHandler *icons = [editor getPoiIconCollectionHandler];
    [icons onMenuItemSelectedWithName:icons.ORIGINAL_KEY];
    [editor onLeftNavbarButtonPressed];
    XCTAssertEqual(navigation.topViewController, editor);
    XCTAssertTrue([editor.presentedViewController isKindOfClass:UIAlertController.class]);
    XCTAssertEqualObjects(editor.presentedViewController.title, OALocalizedString(@"exit_without_saving"));
    XCTAssertEqualObjects(group.iconName, @"special_heart");
}

- (void)testBackDoesNotWarnForUnchangedMixedIcons
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_bicycle", @"shop_supermarket"]];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    UINavigationController *navigation = [self showGroupEditor:editor];
    [editor onLeftNavbarButtonPressed];
    XCTAssertNil(editor.presentedViewController);
    XCTAssertEqual(navigation.viewControllers.count, 1u);
    XCTAssertEqualObjects(group.iconName, @"special_heart");
}

@end
