#import <XCTest/XCTest.h>
#import "OAEditPointViewController.h"
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
                                                                                 gpxFile:file];
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
@end
