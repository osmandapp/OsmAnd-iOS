#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import <CarPlay/CarPlay.h>
#import "OAHistoryItem.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OATableDataModel.h"
#import "OAQuickSearchHelper.h"
#import "OASearchUICore.h"
#import "OASearchResult.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAHistorySettingsViewController.h"
#import "OAActionAddCategoryViewController.h"
#import "OACategoriesTableViewController.h"
#import "OACarPlayCategoryResultListController.h"
#import "OACarPlayHistoryListController.h"
#import "OASearchCategoriesListController.h"

@interface OALifetimeSearchCore : OASearchUICore
@property(nonatomic) NSMutableArray *completions;
@end

@implementation OALifetimeSearchCore
- (instancetype)init
{
    self = [super initWithLang:@"en" transliterate:NO];
    if (self)
        _completions = [NSMutableArray array];
    return self;
}
- (void)shallowSearchAsync:(Class)cl text:(NSString *)text matcher:(OAResultMatcher<OASearchResult *> *)matcher resortAll:(BOOL)resortAll removeDuplicates:(BOOL)removeDuplicates searchSettings:(OASearchSettings *)settings completion:(void (^)(OASearchResultCollection *))completion
{
    [self.completions addObject:[completion copy]];
}
@end

static OALifetimeSearchCore *lifetimeSearchCore;

@interface OAQuickSearchHelper (LifetimeTest)
- (OASearchUICore *)lifetimeTestCore;
@end
@implementation OAQuickSearchHelper (LifetimeTest)
- (OASearchUICore *)lifetimeTestCore { return lifetimeSearchCore; }
@end

@interface OACategoriesTableViewController (LifetimeTest)
- (void)generateData;
@end
@interface OABaseCarPlayListController (LifetimeTest)
- (NSArray *)generateSections;
@end
@interface OACarPlayCategoryResultListController (LifetimeTest)
- (void)searchAndDisplayResult;
@end

// Each probe observes the application boundary while keeping the production request and lifecycle code.
@protocol OALifetimeScreenProbe <NSObject>
@property(nonatomic) NSUInteger appliedCount;
@end

@interface OALifetimeHistoryController : OAHistorySettingsViewController <OALifetimeScreenProbe>
@property(nonatomic) NSUInteger appliedCount;
@end
@implementation OALifetimeHistoryController
- (void)generateDataWithSearchResults:(NSArray *)results request:(NSUInteger)request { self.appliedCount++; }
@end

@interface OALifetimeActionController : OAActionAddCategoryViewController <OALifetimeScreenProbe>
@property(nonatomic) NSUInteger appliedCount;
@end
@implementation OALifetimeActionController
- (void)updateDataWithResults:(OASearchResultCollection *)results { self.appliedCount++; }
@end

@interface OALifetimeCategoriesController : OACategoriesTableViewController <OALifetimeScreenProbe>
@property(nonatomic) NSUInteger appliedCount;
@end
@implementation OALifetimeCategoriesController
- (void)updateDataWithResults:(OASearchResultCollection *)results { self.appliedCount++; }
@end

@interface OALifetimeCarPlayResults : OACarPlayCategoryResultListController <OALifetimeScreenProbe>
@property(nonatomic) NSUInteger appliedCount;
@end
@implementation OALifetimeCarPlayResults
- (void)updateSections:(NSArray *)sections { self.appliedCount++; }
@end

@interface OALifetimeCarPlayHistory : OACarPlayHistoryListController <OALifetimeScreenProbe>
@property(nonatomic) NSUInteger appliedCount;
@end
@implementation OALifetimeCarPlayHistory
- (void)updateSections:(NSArray *)sections { self.appliedCount++; }
@end

@interface OALifetimeCarPlayCategories : OASearchCategoriesListController <OALifetimeScreenProbe>
@property(nonatomic) NSUInteger appliedCount;
@end
@implementation OALifetimeCarPlayCategories
- (void)updateSections:(NSArray *)sections { self.appliedCount++; }
@end

@protocol OALifetimeCarPlayScene <CPTemplateApplicationSceneDelegate, CPInterfaceControllerDelegate, OACarPlayListLifecycleDelegate>
- (void)dismissListControllers;
@end

// CPInterfaceController is provided by CarPlay, so the test supplies only its navigation contract.
@interface OALifetimeCarPlayInterface : NSObject
@property(nonatomic) NSMutableArray<CPTemplate *> *templates;
@property(nonatomic, weak) id<CPInterfaceControllerDelegate> delegate;
@end
@implementation OALifetimeCarPlayInterface
- (instancetype)init
{
    self = [super init];
    if (self)
        _templates = [NSMutableArray arrayWithObject:[[CPListTemplate alloc] initWithTitle:@"Root" sections:@[]]];
    return self;
}
- (void)pushTemplate:(CPTemplate *)cpTemplate animated:(BOOL)animated completion:(void (^)(BOOL, NSError *))completion
{
    [self.templates addObject:cpTemplate];
    completion(YES, nil);
}
@end

@interface OALifetimePreparedHistoryController : OAHistorySettingsViewController
@property(nonatomic) dispatch_queue_t preparationQueue;
@property(nonatomic) NSUInteger appliedCount;
@property(nonatomic) OATableDataModel *appliedData;
@end
@implementation OALifetimePreparedHistoryController
- (dispatch_queue_t)historyDataQueue { return self.preparationQueue; }
- (void)applyHistoryData:(OATableDataModel *)data
{
    self.appliedCount++;
    self.appliedData = data;
}
@end

@interface OASearchScreenLifetimeTest : XCTestCase
@end

@implementation OASearchScreenLifetimeTest
{
    BOOL _searchHistory;
}

- (void)setUp
{
    [super setUp];
    XCTAssertTrue(NSThread.isMainThread);
    XCTNSPredicateExpectation *initialized = [[XCTNSPredicateExpectation alloc]
        initWithPredicate:[NSPredicate predicateWithFormat:@"initialized == YES"] object:OsmAndApp.instance];
    [self waitForExpectations:@[initialized] timeout:60];
    lifetimeSearchCore = [[OALifetimeSearchCore alloc] init];
    method_exchangeImplementations(class_getInstanceMethod(OAQuickSearchHelper.class, @selector(getCore)),
                                   class_getInstanceMethod(OAQuickSearchHelper.class, @selector(lifetimeTestCore)));
    _searchHistory = [OAAppSettings.sharedManager.searchHistory get];
    [OAAppSettings.sharedManager.searchHistory set:YES];
}

- (void)tearDown
{
    method_exchangeImplementations(class_getInstanceMethod(OAQuickSearchHelper.class, @selector(getCore)),
                                   class_getInstanceMethod(OAQuickSearchHelper.class, @selector(lifetimeTestCore)));
    [OAAppSettings.sharedManager.searchHistory set:_searchHistory];
    lifetimeSearchCore = nil;
    [super tearDown];
}

- (void)testPendingShallowSearchDoesNotRetainAnyScreen
{
    for (NSInteger screen = 0; screen < 6; screen++)
    {
        __weak id weakController;
        @autoreleasepool
        {
            id controller;
            switch (screen)
            {
                case 0:
                    controller = [[OAHistorySettingsViewController alloc] initWithSettingsType:EOAHistorySettingsTypeSearch editing:NO];
                    [controller generateData];
                    break;
                case 1:
                    controller = [[OAActionAddCategoryViewController alloc] initWithNames:[NSMutableArray array]];
                    [controller generateData];
                    break;
                case 2:
                    controller = [[OACategoriesTableViewController alloc] initWithNibName:nil bundle:nil];
                    [controller generateData];
                    break;
                case 3:
                    controller = [[OACarPlayCategoryResultListController alloc] initWithInterfaceController:nil searchResult:[[OASearchResult alloc] initWithPhrase:nil]];
                    [controller searchAndDisplayResult];
                    break;
                case 4:
                    controller = [[OACarPlayHistoryListController alloc] initWithInterfaceController:nil];
                    [controller generateSections];
                    break;
                default:
                    controller = [[OASearchCategoriesListController alloc] initWithInterfaceController:nil];
                    [controller generateSections];
                    break;
            }
            weakController = controller;
        }
        XCTAssertNil(weakController, @"Screen %ld is retained by a pending shallow search", (long)screen);
    }
    XCTAssertEqual(lifetimeSearchCore.completions.count, 6u);
}

- (void)showController:(UIViewController *)controller
{
    [controller beginAppearanceTransition:YES animated:NO];
    [controller endAppearanceTransition];
}

- (void)hideController:(UIViewController *)controller
{
    [controller beginAppearanceTransition:NO animated:NO];
    [controller endAppearanceTransition];
}

- (void)drainMainQueue
{
    XCTestExpectation *drained = [self expectationWithDescription:@"main queue drained"];
    dispatch_async(dispatch_get_main_queue(), ^{ [drained fulfill]; });
    [self waitForExpectations:@[drained] timeout:5];
}

- (void)completeRequest:(NSUInteger)index
{
    void (^completion)(OASearchResultCollection *) = lifetimeSearchCore.completions[index];
    completion(nil);
}

- (id<OALifetimeScreenProbe>)phoneScreen:(NSInteger)screen
{
    UIViewController<OALifetimeScreenProbe> *controller;
    if (screen == 0)
        controller = [[OALifetimeHistoryController alloc] initWithSettingsType:EOAHistorySettingsTypeSearch editing:NO];
    else if (screen == 1)
        controller = [[OALifetimeActionController alloc] initWithNames:[NSMutableArray array]];
    else
        controller = [[OALifetimeCategoriesController alloc] initWithNibName:@"OACategoriesTableViewController" bundle:nil];
    [controller loadViewIfNeeded];
    [self showController:controller];
    return controller;
}

- (id<OALifetimeScreenProbe>)carPlayScreen:(NSInteger)screen interface:(OALifetimeCarPlayInterface *)interface
{
    if (screen == 0)
    {
        OASearchResult *category = [[OASearchResult alloc] initWithPhrase:nil];
        category.localeName = @"Test category";
        return [[OALifetimeCarPlayResults alloc] initWithInterfaceController:(id)interface searchResult:category];
    }
    if (screen == 1)
        return [[OALifetimeCarPlayHistory alloc] initWithInterfaceController:(id)interface];
    return [[OALifetimeCarPlayCategories alloc] initWithInterfaceController:(id)interface];
}

- (id<OALifetimeCarPlayScene>)sceneDelegateFor:(OALifetimeCarPlayInterface *)interface
{
    Class sceneClass = NSClassFromString(@"OsmAnd_Maps.CarPlaySceneDelegate");
    XCTAssertNotNil(sceneClass);
    id<OALifetimeCarPlayScene> scene = [[sceneClass alloc] init];
    [scene templateApplicationScene:nil didConnectInterfaceController:(id)interface toWindow:nil];
    XCTAssertEqual(interface.delegate, scene);
    return scene;
}

- (void)testDismissedPhoneScreensRejectResultsAndReloadOnReturn
{
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        id controller = [self phoneScreen:screen];
        NSUInteger oldRequest = lifetimeSearchCore.completions.count - 1;
        [self hideController:controller];
        [self completeRequest:oldRequest];
        [self drainMainQueue];
        XCTAssertEqual([controller appliedCount], 0u, @"Screen %ld", (long)screen);

        NSUInteger before = lifetimeSearchCore.completions.count;
        [controller generateData];
        XCTAssertEqual(lifetimeSearchCore.completions.count, before, @"Hidden-screen notifications must not restart loading");
        [self showController:controller];
        XCTAssertEqual(lifetimeSearchCore.completions.count, before + 1);
        [self completeRequest:oldRequest];
        [self completeRequest:before];
        [self drainMainQueue];
        XCTAssertEqual([controller appliedCount], 1u, @"Only the new presentation receives results");
        [self hideController:controller];
    }
}

- (void)testPhoneScreensRejectResultsAlreadyQueuedOnMainWhenTheyClose
{
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        id controller = [self phoneScreen:screen];
        [self completeRequest:lifetimeSearchCore.completions.count - 1];
        [self hideController:controller];
        [self drainMainQueue];
        XCTAssertEqual([controller appliedCount], 0u);
    }
}

- (void)testNewerPhoneRequestWinsWithoutClosingTheScreen
{
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        id controller = [self phoneScreen:screen];
        NSUInteger oldRequest = lifetimeSearchCore.completions.count - 1;
        [controller generateData];
        [self completeRequest:oldRequest + 1];
        [self completeRequest:oldRequest];
        [self drainMainQueue];
        XCTAssertEqual([controller appliedCount], 1u);
        [self hideController:controller];
    }
}

- (void)testCarPlayPopToRootInvalidatesEveryRemovedScreen
{
    OALifetimeCarPlayInterface *interface = [[OALifetimeCarPlayInterface alloc] init];
    id<CPInterfaceControllerDelegate> scene = [self sceneDelegateFor:interface];
    NSMutableArray *controllers = [NSMutableArray array];
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        id controller = [self carPlayScreen:screen interface:interface];
        [controllers addObject:controller];
        [controller present];
    }
    CPTemplate *last = interface.templates.lastObject;
    [interface.templates removeObjectsInRange:NSMakeRange(1, 3)];
    [scene templateDidDisappear:last animated:NO];
    for (NSUInteger request = 0; request < 3; request++)
        [self completeRequest:request];
    [self drainMainQueue];
    for (id controller in controllers)
        XCTAssertEqual([controller appliedCount], 0u);
}

- (void)testCarPlayBackInvalidatesOnlyTheRemovedScreen
{
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        OALifetimeCarPlayInterface *interface = [[OALifetimeCarPlayInterface alloc] init];
        id<CPInterfaceControllerDelegate> scene = [self sceneDelegateFor:interface];
        id parent = [self carPlayScreen:2 interface:interface];
        [parent present];
        NSUInteger parentRequest = lifetimeSearchCore.completions.count - 1;
        id child = [self carPlayScreen:screen interface:interface];
        [child present];
        NSUInteger childRequest = lifetimeSearchCore.completions.count - 1;
        // Completion is already queued when the user presses Back.
        [self completeRequest:childRequest];
        CPTemplate *childTemplate = interface.templates.lastObject;
        [interface.templates removeLastObject];
        [scene templateDidDisappear:childTemplate animated:NO];
        [self completeRequest:parentRequest];
        [self drainMainQueue];
        XCTAssertEqual([child appliedCount], 0u);
        XCTAssertEqual([parent appliedCount], 1u);
    }
}

- (void)testCarPlayCoveredScreenKeepsItsRequestAndCanReturn
{
    OALifetimeCarPlayInterface *interface = [[OALifetimeCarPlayInterface alloc] init];
    id<CPInterfaceControllerDelegate> scene = [self sceneDelegateFor:interface];
    id controller = [self carPlayScreen:2 interface:interface];
    [controller present];
    CPTemplate *parent = interface.templates.lastObject;
    CPTemplate *child = [[CPListTemplate alloc] initWithTitle:@"Child" sections:@[]];
    [interface.templates addObject:child];
    [scene templateDidDisappear:parent animated:NO];
    [self completeRequest:0];
    [self drainMainQueue];
    XCTAssertEqual([controller appliedCount], 1u);
    [interface.templates removeLastObject];
    [scene templateDidDisappear:child animated:NO];
    XCTAssertEqual(lifetimeSearchCore.completions.count, 1u);
    XCTAssertEqual([controller appliedCount], 1u);
}

- (void)testCarPlayReopeningRejectsOldResultsIncludingThoseQueuedOnMain
{
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        OALifetimeCarPlayInterface *interface = [[OALifetimeCarPlayInterface alloc] init];
        id<CPInterfaceControllerDelegate> scene = [self sceneDelegateFor:interface];
        id controller = [self carPlayScreen:screen interface:interface];
        [controller present];
        NSUInteger oldRequest = lifetimeSearchCore.completions.count - 1;
        [self completeRequest:oldRequest];
        CPTemplate *oldTemplate = interface.templates.lastObject;
        [interface.templates removeLastObject];
        [scene templateDidDisappear:oldTemplate animated:NO];
        [self drainMainQueue];
        XCTAssertEqual([controller appliedCount], 0u);
        [controller present];
        [self completeRequest:oldRequest];
        [self completeRequest:oldRequest + 1];
        [self drainMainQueue];
        XCTAssertEqual([controller appliedCount], 1u);
    }
}

- (void)testCarPlayDisconnectDoesNotCancelAnotherInterfacesRequest
{
    OALifetimeCarPlayInterface *first = [[OALifetimeCarPlayInterface alloc] init];
    OALifetimeCarPlayInterface *second = [[OALifetimeCarPlayInterface alloc] init];
    id<OALifetimeCarPlayScene> firstScene = [self sceneDelegateFor:first];
    id<OALifetimeCarPlayScene> secondScene = [self sceneDelegateFor:second];
    NSMutableArray *controllers = [NSMutableArray array];
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        id controller = [self carPlayScreen:screen interface:first];
        [controllers addObject:controller];
        [controller present];
    }
    id other = [self carPlayScreen:2 interface:second];
    [other present];
    // Exercise the scene's disconnect cleanup without changing the host app's map or routing state.
    [firstScene dismissListControllers];
    for (NSUInteger request = 0; request < 4; request++)
        [self completeRequest:request];
    [self drainMainQueue];
    for (id controller in controllers)
        XCTAssertEqual([controller appliedCount], 0u);
    XCTAssertEqual([other appliedCount], 1u);
    XCTAssertEqual(second.delegate, secondScene);
}

- (void)testCarPlayReconnectDoesNotDeliverOldResultsToNewScreens
{
    OALifetimeCarPlayInterface *first = [[OALifetimeCarPlayInterface alloc] init];
    id<OALifetimeCarPlayScene> scene = [self sceneDelegateFor:first];
    id oldController = [self carPlayScreen:2 interface:first];
    [oldController present];
    [self completeRequest:0];
    [scene dismissListControllers];
    first.delegate = nil;

    OALifetimeCarPlayInterface *second = [[OALifetimeCarPlayInterface alloc] init];
    [scene templateApplicationScene:nil didConnectInterfaceController:(id)second toWindow:nil];
    id newController = [self carPlayScreen:2 interface:second];
    [newController present];
    [self completeRequest:0];
    [self completeRequest:1];
    [self drainMainQueue];
    XCTAssertEqual([oldController appliedCount], 0u);
    XCTAssertEqual([newController appliedCount], 1u);
    XCTAssertEqual(second.delegate, scene);
}

- (void)testCarPlaySceneDoesNotRegisterAnotherInterfacesController
{
    OALifetimeCarPlayInterface *first = [[OALifetimeCarPlayInterface alloc] init];
    OALifetimeCarPlayInterface *second = [[OALifetimeCarPlayInterface alloc] init];
    id<OALifetimeCarPlayScene> firstScene = [self sceneDelegateFor:first];
    id<OALifetimeCarPlayScene> secondScene = [self sceneDelegateFor:second];
    id controller = [self carPlayScreen:2 interface:second];
    [controller present];
    [firstScene registerListController:controller];
    [firstScene dismissListControllers];
    [self completeRequest:0];
    [self drainMainQueue];
    XCTAssertEqual([controller appliedCount], 1u);
    XCTAssertEqual(second.delegate, secondScene);
}

- (OALifetimePreparedHistoryController *)historyWithQueue:(dispatch_queue_t)queue
{
    OALifetimePreparedHistoryController *controller = [[OALifetimePreparedHistoryController alloc] initWithSettingsType:EOAHistorySettingsTypeSearch editing:NO];
    controller.preparationQueue = queue;
    [controller loadViewIfNeeded];
    [self showController:controller];
    return controller;
}

- (void)finishHistoryQueue:(dispatch_queue_t)queue
{
    XCTestExpectation *finished = [self expectationWithDescription:@"history worker and final main callback finished"];
    dispatch_async(queue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{ [finished fulfill]; });
    });
    [self waitForExpectations:@[finished] timeout:10];
}

- (void)testHistoryPreparationDoesNotRetainTheClosedScreen
{
    dispatch_queue_t queue = dispatch_queue_create("test.history.lifetime", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{ dispatch_semaphore_wait(gate, DISPATCH_TIME_FOREVER); });
    __weak OALifetimePreparedHistoryController *weakController;
    @try
    {
        @autoreleasepool
        {
            OALifetimePreparedHistoryController *controller = [self historyWithQueue:queue];
            [self completeRequest:0];
            [self drainMainQueue];
            [self hideController:controller];
            weakController = controller;
        }
        XCTAssertNil(weakController, @"The queued table preparation must not own the screen");
    }
    @finally
    {
        dispatch_semaphore_signal(gate);
        [self finishHistoryQueue:queue];
    }
}

- (void)testHistoryPreparationRejectsDismissedRetainedScreenAndReloadsOnReturn
{
    dispatch_queue_t queue = dispatch_queue_create("test.history.dismissal", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{ dispatch_semaphore_wait(gate, DISPATCH_TIME_FOREVER); });
    OALifetimePreparedHistoryController *controller = [self historyWithQueue:queue];
    @try
    {
        [self completeRequest:0];
        [self drainMainQueue];
        [self hideController:controller];
    }
    @finally
    {
        dispatch_semaphore_signal(gate);
        [self finishHistoryQueue:queue];
    }
    XCTAssertEqual(controller.appliedCount, 0u);
    [self showController:controller];
    XCTAssertEqual(lifetimeSearchCore.completions.count, 2u);
    [self completeRequest:1];
    [self drainMainQueue];
    [self finishHistoryQueue:queue];
    XCTAssertEqual(controller.appliedCount, 1u);
    XCTAssertEqual([controller.appliedData sectionCount], 1u, @"The history switch is preserved for empty history");
}

- (void)testHistoryRejectsPreparedTableAlreadyQueuedOnMainAfterDismissal
{
    dispatch_queue_t queue = dispatch_queue_create("test.history.main", DISPATCH_QUEUE_SERIAL);
    dispatch_semaphore_t gate = dispatch_semaphore_create(0);
    dispatch_async(queue, ^{ dispatch_semaphore_wait(gate, DISPATCH_TIME_FOREVER); });
    OALifetimePreparedHistoryController *controller = [self historyWithQueue:queue];
    [self completeRequest:0];
    [self drainMainQueue];
    // Wait on the worker without draining main: its final UI update must remain queued.
    dispatch_semaphore_signal(gate);
    dispatch_sync(queue, ^{});
    [self hideController:controller];
    [self drainMainQueue];
    XCTAssertEqual(controller.appliedCount, 0u);
}

- (void)testCompletionAlreadyQueuedOnMainDoesNotRetainCarPlayScreens
{
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        OALifetimeCarPlayInterface *interface = [[OALifetimeCarPlayInterface alloc] init];
        id<OALifetimeCarPlayScene> scene = [self sceneDelegateFor:interface];
        __weak id weakController;
        @autoreleasepool
        {
            id controller = [self carPlayScreen:screen interface:interface];
            [controller present];
            [self completeRequest:lifetimeSearchCore.completions.count - 1];
            weakController = controller;
        }
        XCTAssertNil(weakController);
        [self drainMainQueue];
        [scene dismissListControllers];
        XCTAssertEqual(interface.delegate, scene);
    }
}

- (void)testCompletionAlreadyQueuedOnMainDoesNotRetainPhoneScreens
{
    for (NSInteger screen = 0; screen < 3; screen++)
    {
        __weak id weakController;
        @autoreleasepool
        {
            id controller;
            if (screen == 0)
                controller = [[OALifetimeHistoryController alloc] initWithSettingsType:EOAHistorySettingsTypeSearch editing:NO];
            else if (screen == 1)
                controller = [[OALifetimeActionController alloc] initWithNames:[NSMutableArray array]];
            else
                controller = [[OALifetimeCategoriesController alloc] initWithNibName:nil bundle:nil];
            [controller generateData];
            [self completeRequest:lifetimeSearchCore.completions.count - 1];
            weakController = controller;
        }
        XCTAssertNil(weakController);
        [self drainMainQueue];
    }
}

- (void)testPreparedHistoryPreservesEntriesAndDateGroups
{
    dispatch_queue_t queue = dispatch_queue_create("test.history.content", DISPATCH_QUEUE_SERIAL);
    OALifetimePreparedHistoryController *controller = [self historyWithQueue:queue];
    NSMutableArray *results = [NSMutableArray array];
    for (NSNumber *days in @[@0, @30])
    {
        OAHistoryItem *item = [[OAHistoryItem alloc] init];
        item.name = [NSString stringWithFormat:@"%ld days ago", (long)days.integerValue];
        item.date = [NSCalendar.currentCalendar dateByAddingUnit:NSCalendarUnitDay value:-days.integerValue toDate:NSDate.date options:0];
        OASearchResult *result = [[OASearchResult alloc] initWithPhrase:nil];
        result.object = item;
        [results addObject:result];
    }
    OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:nil];
    [collection addSearchResults:results resortAll:NO removeDuplicates:NO];
    void (^completion)(OASearchResultCollection *) = lifetimeSearchCore.completions[0];
    completion(collection);
    [self drainMainQueue];
    [self finishHistoryQueue:queue];
    XCTAssertEqual(controller.appliedCount, 1u);
    XCTAssertEqual([controller.appliedData sectionCount], 3u, @"Switch, recent history, and older month");
    XCTAssertEqual([controller.appliedData rowCount:1], 1u);
    XCTAssertEqual([controller.appliedData rowCount:2], 1u);
}

- (void)testCompletedActionDataAndSelectionSurviveTemporaryDisappearance
{
    OAActionAddCategoryViewController *controller = [[OAActionAddCategoryViewController alloc] initWithNames:[NSMutableArray array]];
    [controller loadViewIfNeeded];
    [self showController:controller];
    OASearchResult *category = [[OASearchResult alloc] initWithPhrase:nil];
    category.object = [OAPOIHelper.sharedInstance getPoiTypeByKey:@"cafe"].category;
    XCTAssertNotNil(category.object);
    OASearchResultCollection *collection = [[OASearchResultCollection alloc] initWithPhrase:nil];
    [collection addSearchResults:@[category] resortAll:NO removeDuplicates:NO];
    void (^completion)(OASearchResultCollection *) = lifetimeSearchCore.completions[0];
    completion(collection);
    [self drainMainQueue];
    NSIndexPath *selected = [NSIndexPath indexPathForRow:0 inSection:0];
    [controller.tableView selectRowAtIndexPath:selected animated:NO scrollPosition:UITableViewScrollPositionNone];
    XCTAssertEqualObjects(controller.tableView.indexPathsForSelectedRows, @[selected]);
    [self hideController:controller];
    [self showController:controller];
    XCTAssertEqual(lifetimeSearchCore.completions.count, 1u, @"Completed data does not need another query");
    XCTAssertEqualObjects(controller.tableView.indexPathsForSelectedRows, @[selected]);
    [self hideController:controller];
}

- (void)testCompletedHistoryReloadsOnReturnOnlyIfItsDataChangedWhileHidden
{
    dispatch_queue_t queue = dispatch_queue_create("test.history.return", DISPATCH_QUEUE_SERIAL);
    OALifetimePreparedHistoryController *controller = [self historyWithQueue:queue];
    [self completeRequest:0];
    [self drainMainQueue];
    [self finishHistoryQueue:queue];
    XCTAssertEqual(controller.appliedCount, 1u);
    [self hideController:controller];
    [self showController:controller];
    XCTAssertEqual(lifetimeSearchCore.completions.count, 1u);
    [self hideController:controller];
    [controller generateData];
    XCTAssertEqual(lifetimeSearchCore.completions.count, 1u, @"A hidden screen defers its refresh");
    [self showController:controller];
    XCTAssertEqual(lifetimeSearchCore.completions.count, 2u);
    [self completeRequest:1];
    [self drainMainQueue];
    [self finishHistoryQueue:queue];
    XCTAssertEqual(controller.appliedCount, 2u);
    [self hideController:controller];
}
@end
