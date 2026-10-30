#import <XCTest/XCTest.h>
#import "OAEditPointViewController.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OAFavoriteEditingHandler.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAGPXAppearanceCollection.h"
#import "OAAppSettings.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAEditPointViewController (FavoriteIconRegressionTesting)
- (void)onGroupSelected:(NSString *)name;
- (void)onIconSelectedFromPalette:(NSString *)iconName;
@end

@interface OAFavoriteIconRegressionTests : XCTestCase
@property(nonatomic) NSMutableArray<UITableViewCell *> *boundIconCells;
@end

@implementation OAFavoriteIconRegressionTests

- (void)tearDown
{
    self.boundIconCells = nil;
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
    __weak OAFavoriteIconRegressionTests *weakSelf = self;
    [super setUpWithCompletionHandler:^(NSError *error) {
        if (error)
            completion(error);
        else
            [weakSelf waitForApplicationUntil:[NSDate dateWithTimeIntervalSinceNow:90] completion:completion];
    }];
}

- (void)waitForApplicationUntil:(NSDate *)deadline completion:(void (^)(NSError *))completion
{
    if ([OsmAndApp instance].initialized)
    {
        OAAppSettings *settings = OAAppSettings.sharedManager;
        NSString *lastGroup = settings.lastFavCategoryEntered.get;
        NSArray *lastIcons = settings.lastUsedFavIcons.get;
        OAGPXAppearanceCollection *appearance = OAGPXAppearanceCollection.sharedInstance;
        NSArray<OASPaletteItemSolid *> *colors = [appearance getAvailableColorsSortingByLastUsed];
        NSSet *colorIds = [NSSet setWithArray:[colors valueForKey:@"id"]];
        [self addTeardownBlock:^{
            [settings.lastFavCategoryEntered set:lastGroup];
            [settings.lastUsedFavIcons set:lastIcons];
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
        completion([NSError errorWithDomain:@"FavoriteIconRegressionTests" code:1
                                  userInfo:@{NSLocalizedDescriptionKey: @"Application initialization timed out"}]);
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 20), dispatch_get_main_queue(), ^{
            [self waitForApplicationUntil:deadline completion:completion];
        });
    }
}

- (OAFavoriteGroup *)groupWithIcon:(NSString *)icon pointIcons:(NSArray<NSString *> *)icons
{
    NSString *name = [@"Favorite icon regression " stringByAppendingString:NSUUID.UUID.UUIDString];
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
    OAEditPointViewController *editor = [[OAEditPointViewController alloc] initWithLocation:CLLocationCoordinate2DMake(48.45, 35.05)
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

- (void)applyIcon:(NSString *)icon toGroup:(OAFavoriteGroup *)group points:(BOOL)points defaults:(BOOL)defaults
{
    XCTestExpectation *completion = [self expectationWithDescription:@"Group icon update completes"];
    [OAFavoritesHelper updateGroup:group iconName:icon updatePoints:points updateGroupIcon:defaults saveImmediately:NO completion:^{
        [completion fulfill];
    }];
    [self waitForExpectations:@[completion] timeout:5];
}

- (OAFavoriteGroup *)roundTripGroup:(OAFavoriteGroup *)group
{
    NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingPathExtension:@"gpx"]];
    [self addTeardownBlock:^{
        if ([NSFileManager.defaultManager fileExistsAtPath:path])
        {
            NSError *error;
            XCTAssertTrue([NSFileManager.defaultManager removeItemAtPath:path error:&error], @"%@", error);
        }
    }];
    [OAFavoritesHelper saveFile:@[group] file:path];
    XCTAssertTrue([NSFileManager.defaultManager fileExistsAtPath:path]);
    NSMutableDictionary *loadedGroups = [NSMutableDictionary new];
    [OAFavoritesHelper loadFileGroups:path groups:loadedGroups];
    OAFavoriteGroup *loaded = loadedGroups[group.name];
    XCTAssertNotNil(loaded);
    XCTAssertEqual(loaded.points.count, group.points.count);
    if (loaded)
        [OAFavoritesHelper getGroups][group.name] = loaded;
    return loaded;
}

- (void)testNewPOIUsesOriginalIconAndFolderColorAndShape
{
    OAFavoriteGroup *group = [self groupWithIcon:@"" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:group fromPOI:YES];
    [self assertPointEditor:editor icon:@"shop_supermarket" group:group];
    PoiIconCollectionHandler *icons = [editor valueForKey:@"poiIconCollectionHandler"];
    XCTAssertEqualObjects(icons.categoriesByKeyName[icons.ORIGINAL_KEY].iconKeys, (@[@"shop_supermarket"]));
}

- (void)testConcreteFolderIconOverridesPOIAndOriginalRestoresIt
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[]];
    OAEditPointViewController *editor = [self newPointEditorInGroup:group fromPOI:YES];
    [self assertPointEditor:editor icon:@"special_heart" group:group];
    PoiIconCollectionHandler *icons = [editor valueForKey:@"poiIconCollectionHandler"];
    [icons onMenuItemSelectedWithName:icons.ORIGINAL_KEY];
    [self assertPointEditor:editor icon:@"shop_supermarket" group:group];
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
    PoiIconCollectionHandler *icons = [editor valueForKey:@"poiIconCollectionHandler"];
    [icons setIconName:@"special_bicycle"];
    [icons selectIconName:@"special_bicycle"];
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
    PoiIconCollectionHandler *icons = [editor valueForKey:@"poiIconCollectionHandler"];
    [icons setIconName:@"special_bicycle"];
    [icons selectIconName:@"special_bicycle"];
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
    OAFavoriteGroup *source = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_bicycle"]];
    OAEditPointViewController *editor = [[OAEditPointViewController alloc] initWithFavorite:source.points.firstObject];
    [editor loadViewIfNeeded];
    [self bindPointIconCell:editor];
    for (NSString *icon in @[@"special_heart", @""])
    {
        OAFavoriteGroup *destination = [self groupWithIcon:icon pointIcons:@[]];
        [editor onGroupSelected:destination.name];
        [self assertPointEditor:editor icon:@"special_bicycle" group:destination];
    }
    XCTAssertEqualObjects(source.points.firstObject.getIcon, @"special_bicycle");
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
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:pointIcons];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    PoiIconCollectionHandler *icons = [editor getPoiIconCollectionHandler];
    [icons onMenuItemSelectedWithName:icons.ORIGINAL_KEY];
    XCTAssertEqualObjects(editor.editIconName, @"");
    [self applyIcon:editor.appearanceIconName toGroup:group points:YES defaults:YES];
    OAFavoriteGroup *loaded = [self roundTripGroup:group];
    XCTAssertEqualObjects(loaded.iconName ?: @"", @"");
    for (NSUInteger index = 0; index < loaded.points.count; index++)
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

// These three expectations describe the reviewer's requested behavior. Android parity is
// intentionally retained pending a product decision. Keep the expected failures strict:
// when a regression is fixed, XCTest must require removing its expected-failure marker.
- (void)testReviewBrowsingOriginalInAllIconsDoesNotChangeFolderSelection
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_heart"]];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    PoiIconCollectionHandler *icons = [editor getPoiIconCollectionHandler];
    ItemsCollectionViewController *allIcons = [self allIconsForHandler:icons];
    [allIcons scrollToCategoryWithCategoryKey:icons.ORIGINAL_KEY];
    XCTExpectFailureWithOptionsInBlock(@"https://github.com/osmandapp/OsmAnd-iOS/pull/6099#discussion_r4412807946 — Android selects Original on a category tap.",
                                      [XCTExpectedFailureOptions new], ^{
        XCTAssertEqualObjects(editor.editIconName, @"special_heart");
    });
    icons.allIconsVCDelegate = nil;
}

- (void)testReviewMixedIconsDoNotClearStoredDefaultOnUnrelatedSave
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_bicycle", @"shop_supermarket"]];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    // Simulate saving a different appearance field with the icon selection left untouched.
    [OAFavoritesHelper updateGroup:group color:UIColor.greenColor updatePoints:NO updateGroupColor:YES saveImmediately:NO];
    [self applyIcon:editor.appearanceIconName toGroup:group points:NO defaults:YES];
    OAFavoriteGroup *loaded = [self roundTripGroup:group];
    XCTAssertEqualObjects(loaded.color, UIColor.greenColor);
    XCTExpectFailureWithOptionsInBlock(@"https://github.com/osmandapp/OsmAnd-iOS/pull/6099#discussion_r4412807964 — Android initializes mixed icons as Original and saves that default.",
                                      [XCTExpectedFailureOptions new], ^{
        XCTAssertEqualObjects(loaded.iconName, @"special_heart");
    });
}

- (void)testReviewBackWarnsAfterChangingConcreteIconToOriginal
{
    OAFavoriteGroup *group = [self groupWithIcon:@"special_heart" pointIcons:@[@"special_heart"]];
    FavoriteGroupEditorViewController *editor = [self editorForGroup:group];
    UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:[UIViewController new]];
    [navigation pushViewController:editor animated:NO];
    PoiIconCollectionHandler *icons = [editor getPoiIconCollectionHandler];
    [icons onMenuItemSelectedWithName:icons.ORIGINAL_KEY];
    [editor onLeftNavbarButtonPressed];
    XCTExpectFailureWithOptionsInBlock(@"https://github.com/osmandapp/OsmAnd-iOS/pull/6099#discussion_r4412807980 — Android excludes Original from the unsaved icon check.",
                                      [XCTExpectedFailureOptions new], ^{
        XCTAssertEqual(navigation.viewControllers.count, 2u, @"Back must keep the editor open for the unsaved-changes confirmation.");
    });
    XCTAssertEqualObjects(group.iconName, @"special_heart");
}

@end
