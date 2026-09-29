#import <XCTest/XCTest.h>
#import "OAEditPointViewController.h"
#import "OAGPXAction.h"
#import "OAFavoriteAction.h"
#import "OAActionConfigurationViewController.h"
#import "OAEditGroupViewController.h"
#import "OrderedDictionary.h"
#import "OAGpxWptEditingHandler.h"
#import "OAGPXAppearanceCollection.h"
#import "OADefaultFavorite.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGpxWptItem.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAEditPointViewController (WaypointGroupSelectionTesting)
- (void)onItemSelected:(NSInteger)index;
- (void)onGroupSelected:(NSString *)name;
- (void)onGroupChanged:(NSString *)name;
- (void)setupGroups;
- (void)applyQuickActionParams:(NSDictionary *)params;
@end

@interface OAEditGroupViewController (WaypointGroupSelectionTesting)
- (void)editGroupName:(id)sender;
- (void)onRowSelected:(NSIndexPath *)indexPath;
@end

@interface QuickActionSerializer (WaypointMigrationTesting)
+ (NSData *)migrateLegacyWaypointCategories:(NSData *)data error:(NSError **)error;
@end

@interface OAWaypointGroupSelectionTest : XCTestCase
@end

@implementation OAWaypointGroupSelectionTest

- (void)setUpWithCompletionHandler:(void (^)(NSError *))completion
{
    [super setUpWithCompletionHandler:^(NSError *error) {
        if (error)
            completion(error);
        else
            [self waitForApplicationUntil:[NSDate dateWithTimeIntervalSinceNow:90] completion:completion];
    }];
}

- (void)waitForApplicationUntil:(NSDate *)deadline completion:(void (^)(NSError *))completion
{
    if ([OsmAndApp instance].initialized)
    {
        [self preservePalette];
        completion(nil);
    }
    else if (deadline.timeIntervalSinceNow <= 0)
    {
        completion([NSError errorWithDomain:@"WaypointGroupTests" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Application initialization timed out"}]);
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC / 20), dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [self waitForApplicationUntil:deadline completion:completion];
        });
    }
}


- (void)preservePalette
{
    OAGPXAppearanceCollection *appearance = [OAGPXAppearanceCollection sharedInstance];
    NSArray<OASPaletteItemSolid *> *originalItems = [appearance getAvailableColorsSortingByLastUsed];
    NSSet *originalIds = [NSSet setWithArray:[originalItems valueForKey:@"id"]];
    [self addTeardownBlock:^{
        for (OASPaletteItemSolid *item in [appearance getAvailableColorsSortingByLastUsed])
        {
            if (![originalIds containsObject:item.id])
                [appearance deleteColor:item];
        }
        for (OASPaletteItemSolid *item in originalItems)
            [[OsmAndApp instance].paletteRepository updatePaletteItemItem:item];
        NSArray *restoredItems = [appearance getAvailableColorsSortingByLastUsed];
        XCTAssertEqualObjects([NSSet setWithArray:[restoredItems valueForKey:@"id"]], originalIds);
        XCTAssertEqualObjects([restoredItems valueForKey:@"lastUsedTime"], [originalItems valueForKey:@"lastUsedTime"]);
    }];
}

- (UIColor *)unusedColor
{
    NSMutableSet *usedColors = [NSMutableSet new];
    for (OASPaletteItemSolid *item in [[OAGPXAppearanceCollection sharedInstance] getAvailableColorsSortingByLastUsed])
        [usedColors addObject:@(item.colorInt)];
    int value = (int)0xFF123456;
    while ([usedColors containsObject:@(value)])
        value++;
    return UIColorFromARGB(value);
}

- (OAEditPointViewController *)editorWithFile:(OASGpxFile *)file
{
    OAEditPointViewController *editor = [[OAEditPointViewController alloc] initWithLocation:CLLocationCoordinate2DMake(0, 0)
                                                                                   title:@"Waypoint"
                                                                                 address:@""
                                                                             customParam:nil
                                                                               pointType:EOAEditPointTypeWaypoint
                                                                         targetMenuState:nil
                                                                                     poi:nil
                                                                                 gpxFile:file
                                                                            targetObject:nil];
    [editor loadViewIfNeeded];
    return editor;
}

- (void)selectColor:(UIColor *)color editor:(OAEditPointViewController *)editor
{
    OASPaletteItemSolid *item = [[OAGPXAppearanceCollection sharedInstance] getColorItemWithValue:color.toARGBNumber];
    [editor setValue:item forKey:@"selectedColorItem"];
}

- (void)assertColor:(UIColor *)color editor:(OAEditPointViewController *)editor
{
    OASPaletteItemSolid *selected = [editor valueForKey:@"selectedColorItem"];
    XCTAssertEqual(selected.colorInt, color.toARGBNumber);
    NSArray *items = [editor valueForKey:@"sortedColorItems"];
    XCTAssertNotEqual([[OAGPXAppearanceCollection sharedInstance] indexOfColorItem:selected items:items], NSNotFound);
}

- (void)testRepeatedDefaultCardSelectionRestoresGroupColor
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    OAEditPointViewController *editor = [self editorWithFile:file];
    for (UIColor *color in @[UIColor.blueColor, UIColor.greenColor])
    {
        [self selectColor:color editor:editor];
        [editor onItemSelected:0];
        [self assertColor:[OADefaultFavorite getDefaultColor] editor:editor];
    }
    XCTAssertEqual(file.getPointsList.count, 0);
}

- (void)testCardsAndListApplyGroupMetadataInsteadOfPointColor
{
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    OASWptPt *point = [[OASWptPt alloc] init];
    point.category = @"Blue";
    [point setColorColor:[[OASInt alloc] initWithInt:UIColor.redColor.toARGBNumber]];
    [file addPointPoint:point];
    file.pointsGroups[@"Blue"].color = UIColor.blueColor.toARGBNumber;
    file.pointsGroups[@"Green"] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@"Green" iconName:@"" backgroundType:@"" color:UIColor.greenColor.toARGBNumber hidden:NO];
    OAEditPointViewController *editor = [self editorWithFile:file];
    NSArray *names = [editor valueForKey:@"groupNames"];
    [editor onItemSelected:[names indexOfObject:@"Blue"]];
    [self assertColor:UIColor.blueColor editor:editor];
    [editor onGroupSelected:@"Green"];
    [self assertColor:UIColor.greenColor editor:editor];
    [editor onGroupSelected:@"Blue"];
    [self assertColor:UIColor.blueColor editor:editor];
    XCTAssertEqual(point.getColor, UIColor.redColor.toARGBNumber);
    XCTAssertEqual(file.getPointsList.count, 1);
}

- (void)testPendingGroupSelectionRefreshesMissingPaletteItem
{
    OAEditPointViewController *editor = [self editorWithFile:[[OASGpxFile alloc] initWithAuthor:@"test"]];
    OAGpxWptEditingHandler *handler = [editor valueForKey:@"pointHandler"];
    UIColor *color = [self unusedColor];
    [handler setGroup:@"New group" color:color save:NO];
    [editor setupGroups];
    [editor setValue:[NSMutableArray new] forKey:@"sortedColorItems"];
    [editor onGroupSelected:@"New group"];
    [self assertColor:color editor:editor];
    [editor onItemSelected:0];
    [editor onGroupSelected:@"New group"];
    [self assertColor:color editor:editor];
}

- (void)testUnknownGroupDoesNotApplyRedFallback
{
    OAEditPointViewController *editor = [self editorWithFile:[[OASGpxFile alloc] initWithAuthor:@"test"]];
    [self selectColor:UIColor.blueColor editor:editor];
    [editor onGroupChanged:@"Unknown"];
    [self assertColor:UIColor.blueColor editor:editor];
}


- (void)testSameDisplayTitleKeepsCardSelectionAndSavedCategorySeparate
{
    NSString *name = OALocalizedString(@"shared_string_waypoints");
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    file.pointsGroups[@""] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@"" iconName:@"" backgroundType:@"" color:UIColor.blueColor.toARGBNumber hidden:NO];
    file.pointsGroups[name] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:name iconName:@"" backgroundType:@"" color:UIColor.greenColor.toARGBNumber hidden:NO];
    for (NSString *key in @[name, @""])
    {
        OAEditPointViewController *editor = [self editorWithFile:file];
        NSArray *keys = [editor valueForKey:@"waypointGroupKeys"];
        [editor onItemSelected:[keys indexOfObject:key]];
        [self assertColor:key.length > 0 ? UIColor.greenColor : UIColor.blueColor editor:editor];
        XCTAssertEqualObjects([editor valueForKey:@"selectedWaypointGroupKey"], key);
        [editor setValue:nil forKey:@"poiIconCollectionHandler"];
        [editor onRightNavbarButtonPressed];
        OAGpxWptEditingHandler *handler = [editor valueForKey:@"pointHandler"];
        OAGpxWptItem *item = [handler valueForKey:@"gpxWpt"];
        XCTAssertEqualObjects(item.point.category ?: @"", key);
    }
}

- (void)testListDistinguishesSameTitlesAndReselectsCurrentWaypointGroup
{
    NSString *name = OALocalizedString(@"shared_string_waypoints");
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    file.pointsGroups[name] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:name iconName:@"" backgroundType:@"" color:UIColor.greenColor.toARGBNumber hidden:NO];
    OAEditPointViewController *editor = [self editorWithFile:file];
    OAGpxWptEditingHandler *handler = [editor valueForKey:@"pointHandler"];
    NSArray *groups = [handler getGroups];
    for (NSInteger index = 0; index < groups.count; index++)
    {
        NSString *key = groups[index][@"category"];
        [editor onGroupSelected:key];
        [self selectColor:UIColor.blueColor editor:editor];
        SelectFavoriteGroupViewController *list = [[SelectFavoriteGroupViewController alloc] initWithSelectedGroupName:key gpxWptGroups:groups];
        list.delegate = (id)editor;
        [list loadViewIfNeeded];
        [list onRowSelected:[NSIndexPath indexPathForRow:index inSection:1]];
        [self assertColor:key.length > 0 ? UIColor.greenColor : [OADefaultFavorite getDefaultColor] editor:editor];
        XCTAssertEqualObjects([editor valueForKey:@"selectedWaypointGroupKey"], key);
    }
}

- (void)testQuickActionRawCategorySurvivesConfigurationAndSerialization
{
    NSString *title = OALocalizedString(@"shared_string_waypoints");
    for (NSString *category in @[@"", title, @"Waypoints", @"  Named group  "])
    {
        OAGPXAction *action = [[OAGPXAction alloc] init];
        action.params = @{@"category_name": category};
        OrderedDictionary *model = [action getUIModel];
        XCTAssertTrue([action fillParams:model]);
        NSData *json = [NSJSONSerialization dataWithJSONObject:action.getParams options:0 error:nil];
        NSDictionary *restored = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
        XCTAssertEqualObjects(restored[@"category_name"], category);
        XCTAssertEqualObjects([OAGPXAction categoryFromParams:restored], category);
    }
}

- (void)testQuickActionUsesAndroidCategoryAndRemovesStaleKey
{
    OAGPXAction *action = [[OAGPXAction alloc] init];
    action.params = @{@"category_name": @"Bar", @"category_key": @"Foo", @"name": @"Test point"};
    XCTAssertEqualObjects([OAGPXAction categoryFromParams:action.getParams], @"Bar");
    XCTAssertTrue([action fillParams:[action getUIModel]]);
    XCTAssertEqualObjects(action.getParams[@"category_name"], @"Bar");
    XCTAssertNil(action.getParams[@"category_key"]);
    XCTAssertEqualObjects(action.getParams[@"name"], @"Test point");
    XCTAssertEqualObjects([OAGPXAction categoryFromParams:@{}], @"");
}

- (void)testQuickActionEditorDistinguishesDefaultAndNamedWaypoints
{
    NSString *name = OALocalizedString(@"shared_string_waypoints");
    OASGpxFile *file = [[OASGpxFile alloc] initWithAuthor:@"test"];
    file.pointsGroups[@""] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@"" iconName:@"" backgroundType:@"" color:UIColor.blueColor.toARGBNumber hidden:NO];
    file.pointsGroups[name] = [[OASGpxUtilitiesPointsGroup alloc] initWithName:name iconName:@"" backgroundType:@"" color:UIColor.greenColor.toARGBNumber hidden:NO];
    for (NSString *category in @[@"", name])
    {
        OAEditPointViewController *editor = [self editorWithFile:file];
        [editor applyQuickActionParams:@{@"category_name": category}];
        XCTAssertEqualObjects([editor valueForKey:@"selectedWaypointGroupKey"], category);
        [self assertColor:category.length > 0 ? UIColor.greenColor : UIColor.blueColor editor:editor];
        [editor setValue:nil forKey:@"poiIconCollectionHandler"];
        [editor onRightNavbarButtonPressed];
        OAGpxWptEditingHandler *handler = [editor valueForKey:@"pointHandler"];
        OAGpxWptItem *item = [handler valueForKey:@"gpxWpt"];
        XCTAssertEqualObjects(item.point.category ?: @"", category);
    }
}

- (void)testLegacyQuickActionMigrationPreservesDefaultAndPersonalGroups
{
    NSArray<NSArray<NSString *> *> *examples = @[
        @[OALocalizedString(@"favorites_item"), @""],
        @[OALocalizedString(@"personal_category_name"), @"personal"],
        @[@"  Hiking  ", @"Hiking"],
        @[OALocalizedString(@"shared_string_waypoints"), @""]
    ];
    for (NSArray<NSString *> *example in examples)
    {
        NSDictionary *original = @{@"category_name": example[0], @"name": @"Test", @"category_color": @123};
        NSDictionary *migrated = [OAGPXAction migrateLegacyCategoryInParams:original];
        XCTAssertEqualObjects([OAGPXAction categoryFromParams:migrated], example[1]);
        XCTAssertEqualObjects(migrated[@"name"], @"Test");
        XCTAssertEqualObjects(migrated[@"category_color"], @123);
        XCTAssertEqualObjects([OAGPXAction migrateLegacyCategoryInParams:migrated], migrated);
        XCTAssertEqualObjects(original[@"category_name"], example[0]);
    }
    XCTAssertEqualObjects([OAGPXAction categoryFromParams:[OAGPXAction migrateLegacyCategoryInParams:@{}]], @"");
}

- (void)testLegacyMigrationPreservesNewRawCategories
{
    for (NSString *category in @[OALocalizedString(@"favorites_item"), OALocalizedString(@"personal_category_name"), OALocalizedString(@"shared_string_waypoints"), @"  Hiking  ", @""])
    {
        OAGPXAction *action = [[OAGPXAction alloc] init];
        action.params = @{@"category_name": category};
        XCTAssertTrue([action fillParams:[action getUIModel]]);
        NSDictionary *migrated = [OAGPXAction migrateLegacyCategoryInParams:action.getParams];
        XCTAssertEqualObjects([OAGPXAction categoryFromParams:migrated], category);
    }
}

- (void)testAndroidCategoryRemainsAuthoritativeAfterEditingMigratedAction
{
    NSMutableDictionary *params = [[OAGPXAction migrateLegacyCategoryInParams:@{@"category_name": OALocalizedString(@"favorites_item")}] mutableCopy];
    params[@"category_name"] = @"Favorites";
    XCTAssertEqualObjects([OAGPXAction categoryFromParams:params], @"Favorites");
    XCTAssertEqualObjects([OAGPXAction migrateLegacyCategoryInParams:params], params);
    XCTAssertEqualObjects([OAGPXAction categoryFromParams:@{@"category_name": @"Favorites"}], @"Favorites");
}

- (void)testLegacyActionJSONMigrationPreservesIdentifiersAndOtherActions
{
    NSDictionary *params = @{@"category_name": OALocalizedString(@"favorites_item"), @"name": @"Test"};
    NSData *paramsData = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    NSString *paramsString = [[NSString alloc] initWithData:paramsData encoding:NSUTF8StringEncoding];
    NSDictionary *favorite = @{@"actionType": @"fav.add", @"id": @987, @"params": paramsString};
    NSArray *actions = @[
        @{@"actionType": @"gpx.add", @"id": @"1234567890123", @"name": @"Custom action", @"params": paramsString},
        @{@"type": @6, @"id": @456, @"params": params},
        favorite
    ];
    NSData *data = [NSJSONSerialization dataWithJSONObject:actions options:0 error:nil];
    NSError *error = nil;
    NSData *migrated = [QuickActionSerializer migrateLegacyWaypointCategories:data error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(migrated);
    NSArray *restored = [NSJSONSerialization JSONObjectWithData:migrated options:0 error:nil];
    XCTAssertEqualObjects(restored[0][@"id"], @"1234567890123");
    XCTAssertEqualObjects(restored[0][@"name"], @"Custom action");
    NSData *restoredParamsData = [restored[0][@"params"] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *restoredParams = [NSJSONSerialization JSONObjectWithData:restoredParamsData options:0 error:nil];
    XCTAssertEqualObjects(restoredParams[@"category_name"], @"");
    XCTAssertEqualObjects(restored[1][@"params"][@"category_name"], @"");
    XCTAssertEqualObjects(restored[1][@"id"], @456);
    XCTAssertEqualObjects(restored[2], favorite);
    NSData *repeated = [QuickActionSerializer migrateLegacyWaypointCategories:migrated error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects([NSJSONSerialization JSONObjectWithData:repeated options:0 error:nil], restored);
    XCTAssertEqualObjects(repeated, migrated);
}

- (void)testLegacyActionJSONMigrationIsolatesInvalidRecords
{
    NSDictionary *valid = @{@"actionType": @"gpx.add", @"params": @{@"category_name": OALocalizedString(@"favorites_item")}};
    NSArray *invalidRecords = @[
        @{@"actionType": @"gpx.add", @"params": @"invalid JSON"},
        @{@"actionType": @"gpx.add", @"params": @"null"},
        @{@"actionType": @"gpx.add", @"params": @"[]"},
        @{@"actionType": @"gpx.add", @"params": NSNull.null},
        @{@"actionType": @"gpx.add", @"params": @42},
        @{@"actionType": @"gpx.add", @"params": @{@"category_name": NSNull.null}},
        @{@"actionType": @"gpx.add", @"params": @{@"category_name": @42}},
        @{@"actionType": @"gpx.add", @"params": @"{\"category_name\":null}"},
        @{@"actionType": @"gpx.add", @"params": @"{\"category_name\":42}"},
        NSNull.null,
        @42
    ];
    for (id invalid in invalidRecords)
    {
        NSArray *actions = @[valid, invalid, valid];
        NSData *data = [NSJSONSerialization dataWithJSONObject:actions options:0 error:nil];
        NSError *error = nil;
        NSData *migrated = [QuickActionSerializer migrateLegacyWaypointCategories:data error:&error];
        XCTAssertNil(error);
        XCTAssertNotNil(migrated);
        NSArray *restored = [NSJSONSerialization JSONObjectWithData:migrated options:0 error:nil];
        XCTAssertEqual(restored.count, 3);
        XCTAssertEqualObjects(restored[0][@"params"][@"category_name"], @"");
        XCTAssertEqualObjects(restored[1], invalid);
        XCTAssertEqualObjects(restored[2][@"params"][@"category_name"], @"");
    }
}

- (void)testLegacyCategoryMigrationPreservesInvalidCategoryTypes
{
    for (id category in @[NSNull.null, @42, @[], @{}])
    {
        NSDictionary *params = @{@"category_name": category, @"name": @"Unchanged"};
        XCTAssertEqualObjects([OAGPXAction migrateLegacyCategoryInParams:params], params);
    }
}

- (void)testLegacyActionJSONMigrationPreservesUnchangedBytes
{
    NSArray<NSString *> *examples = @[
        @"[ { \"actionType\": \"fav.add\", \"params\": { \"category_name\": \"Favorites\" } } ]",
        @"[ { \"actionType\": \"gpx.add\", \"id\": 123 } ]",
        @"[ { \"actionType\": \"gpx.add\", \"params\": { \"category_name\": \"Favorites\", \"category_name_format\": \"raw\" } } ]",
        @"[ { \"actionType\": \"gpx.add\", \"params\": \"invalid JSON\" } ]",
        @"[ ]"
    ];
    for (NSString *json in examples)
    {
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        NSData *migrated = [QuickActionSerializer migrateLegacyWaypointCategories:data error:&error];
        XCTAssertNil(error);
        XCTAssertEqualObjects(migrated, data);
    }
}

- (void)testLegacyActionJSONMigrationRejectsInvalidList
{
    for (NSString *json in @[@"invalid JSON", @"{}", @"null"])
    {
        NSData *data = [json dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        XCTAssertNil([QuickActionSerializer migrateLegacyWaypointCategories:data error:&error]);
        XCTAssertNotNil(error);
    }
}

- (void)testQuickActionCategoryDoesNotInterpretLocalizedTitles
{
    for (NSString *category in @[@"", @"Waypoints", @"Путевые точки", @"  Named group  "])
        XCTAssertEqualObjects([OAGPXAction categoryFromParams:@{@"category_name": category}], category);
}

- (void)assertPicker:(OAEditGroupViewController *)picker savesCategory:(NSString *)category
{
    OAGPXAction *action = [[OAGPXAction alloc] init];
    action.params = @{@"category_name": @"Original"};
    OAActionConfigurationViewController *controller = [[OAActionConfigurationViewController alloc] initWithAction:action isNew:NO];
    [controller setValue:[[action getUIModel] mutableCopy] forKey:@"data"];
    [controller setValue:picker forKey:@"groupController"];
    picker.delegate = (id)controller;
    [picker onRightNavbarButtonPressed];
    XCTAssertTrue([action fillParams:[controller valueForKey:@"data"]]);
    XCTAssertEqualObjects(action.getParams[@"category_name"], category);
    XCTAssertNil(action.getParams[@"category_key"]);
}

- (void)testQuickActionTrimsTypedCategoryOnConfirmation
{
    for (NSArray<NSString *> *example in @[@[@"  Hiking ", @"Hiking"], @[@"   ", @""], @[@" Waypoints ", @"Waypoints"]])
    {
        OAEditGroupViewController *picker = [[OAEditGroupViewController alloc] initWithGroupName:@"Original" groups:@[]];
        UITextField *field = [[UITextField alloc] init];
        field.text = example[0];
        [picker editGroupName:field];
        XCTAssertTrue(picker.groupNameWasEdited);
        [self assertPicker:picker savesCategory:example[1]];
    }
}

- (void)testQuickActionPreservesSelectedCategoryAfterTyping
{
    NSString *category = @"  Hiking  ";
    OAEditGroupViewController *picker = [[OAEditGroupViewController alloc] initWithGroupName:@"Original" groups:@[category]];
    UITextField *field = [[UITextField alloc] init];
    field.text = @" Another group ";
    [picker editGroupName:field];
    [picker onRowSelected:[NSIndexPath indexPathForRow:0 inSection:0]];
    XCTAssertFalse(picker.groupNameWasEdited);
    [self assertPicker:picker savesCategory:category];
}

- (void)testQuickActionPreservesUneditedCategory
{
    NSString *category = @"  Hiking  ";
    OAEditGroupViewController *picker = [[OAEditGroupViewController alloc] initWithGroupName:category groups:@[category]];
    XCTAssertFalse(picker.groupNameWasEdited);
    [self assertPicker:picker savesCategory:category];
}

- (void)testFavoriteQuickActionKeepsExistingGroupHandling
{
    OAFavoriteAction *action = [[OAFavoriteAction alloc] init];
    action.params = @{@"category_name": @"Original"};
    OAActionConfigurationViewController *controller = [[OAActionConfigurationViewController alloc] initWithAction:action isNew:NO];
    [controller setValue:[[action getUIModel] mutableCopy] forKey:@"data"];
    OAEditGroupViewController *picker = [[OAEditGroupViewController alloc] initWithGroupName:@"Original" groups:@[]];
    [controller setValue:picker forKey:@"groupController"];
    picker.delegate = (id)controller;
    UITextField *field = [[UITextField alloc] init];
    field.text = @"  Hiking  ";
    [picker editGroupName:field];
    [picker onRightNavbarButtonPressed];
    XCTAssertTrue([action fillParams:[controller valueForKey:@"data"]]);
    XCTAssertEqualObjects(action.getParams[@"category_name"], @"  Hiking  ");
}

@end
