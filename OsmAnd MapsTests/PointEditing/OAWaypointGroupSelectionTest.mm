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
    UIColor *color = UIColorFromARGB(0xFF123456);
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

@end
