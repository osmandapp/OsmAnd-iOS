#import <XCTest/XCTest.h>
#import "OAMapPanelViewController.h"
#import "OABaseScrollableHudViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAMapLayers.h"
#import "OAMeasurementToolLayer.h"
#import "OAAppDelegate.h"
#import "OAMapViewTrackingUtilities.h"
#import "OATargetMultiView.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@interface OABaseScrollableHudViewController (PlanRouteTestFactory)
+ (void)showNewRoute;
@end

@interface OAMapPanelViewController (MenuRestorationTests)
@property (nonatomic, strong) OATargetPointView *targetMenuView;
@property (nonatomic, strong) OATargetMultiView *targetMultiMenuView;
- (void)hideMultiMenuIfNeeded;
- (void)hideTargetPointMenu:(CGFloat)duration onComplete:(void (^)(void))completion;
- (void)hideTargetPointMenu:(CGFloat)duration onComplete:(void (^)(void))completion hideActiveTarget:(BOOL)hideActiveTarget mapGestureAction:(BOOL)mapGestureAction;
- (void)enqueueContextMenuPresentation:(void (^)(void))presentation;
- (void)showMultiPointMenu:(CLLocation *)touchPointLatLon points:(NSArray<OATargetPoint *> *)points selectedObjects:(NSMutableArray<SelectedMapObject *> *)selectedObjects onComplete:(void (^)(void))onComplete;
@end

// Delay dismissal so the tests exercise restoration after the menu animation.
@interface OARestorationTestMenu : UIView
@property (nonatomic, strong) OATargetPoint *targetPoint;
@property (nonatomic, copy) void (^dismissCompletion)(void);
@end

@implementation OARestorationTestMenu
- (BOOL)preHide { return YES; }
- (BOOL)needsManualContextMode { return NO; }
- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))completion
{
    self.dismissCompletion = completion;
}
- (void)finishDismissal
{
    [self removeFromSuperview];
    void (^completion)(void) = self.dismissCompletion;
    self.dismissCompletion = nil;
    completion();
}
@end

@interface OAMapPanelMenuRestorationTests : XCTestCase
@end

@implementation OAMapPanelMenuRestorationTests

- (void)checkRestorationWithBackButton:(BOOL)backButton size:(CGSize)size
{
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    panel.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    OABaseScrollableHudViewController *planner = [[OABaseScrollableHudViewController alloc] initWithNibName:nil bundle:nil];
    planner.view = [[UIView alloc] initWithFrame:panel.view.bounds];
    OARestorationTestMenu *menu = [[OARestorationTestMenu alloc] initWithFrame:panel.view.bounds];
    menu.targetPoint = [[OATargetPoint alloc] init];
    menu.targetPoint.type = OATargetPOI;
    panel.targetMenuView = (OATargetPointView *)menu;

    // Repeat the search/return cycle using the same editor instance.
    for (NSUInteger cycle = 0; cycle < 2; cycle++)
    {
        [planner.view removeFromSuperview];
        [planner removeFromParentViewController];
        [panel setValue:nil forKey:@"scrollableHudViewController"];
        [panel setValue:planner forKey:@"prevScrollableHudViewController"];
        [panel.view addSubview:menu];
        __block BOOL completed = NO;
        [panel targetHideMenu:0.2 backButtonClicked:backButton onComplete:^{ completed = YES; }];
        XCTAssertNil(planner.view.superview);
        XCTAssertFalse(completed);

        [menu finishDismissal];
        XCTAssertTrue(completed);
        XCTAssertEqual(panel.scrollableHudViewController, planner);
        XCTAssertEqual(planner.parentViewController, panel);
        XCTAssertEqual(planner.view.superview, panel.view);
        XCTAssertFalse(planner.view.hidden);
        XCTAssertEqualObjects([NSValue valueWithCGRect:planner.view.frame], [NSValue valueWithCGRect:panel.view.bounds]);
        XCTAssertNil(panel.prevScrollableHudViewController);
    }
}

- (void)testBackButtonRestoresEditorInIPadLandscape
{
    [self checkRestorationWithBackButton:YES size:CGSizeMake(1366, 1024)];
}

- (void)testBackButtonRestoresEditorInPortrait
{
    [self checkRestorationWithBackButton:YES size:CGSizeMake(768, 1024)];
}

- (void)testDismissRestoresEditorInIPadLandscape
{
    [self checkRestorationWithBackButton:NO size:CGSizeMake(1366, 1024)];
}

- (void)testMenuReplacementKeepsEditorSuspended
{
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    panel.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1366, 1024)];
    OABaseScrollableHudViewController *planner = [[OABaseScrollableHudViewController alloc] initWithNibName:nil bundle:nil];
    planner.view = [[UIView alloc] initWithFrame:panel.view.bounds];
    [panel setValue:planner forKey:@"prevScrollableHudViewController"];
    OARestorationTestMenu *menu = [[OARestorationTestMenu alloc] initWithFrame:panel.view.bounds];
    panel.targetMenuView = (OATargetPointView *)menu;
    [panel.view addSubview:menu];

    [panel hideTargetPointMenu:0.2 onComplete:nil hideActiveTarget:YES mapGestureAction:NO];
    [menu finishDismissal];

    XCTAssertNil(panel.scrollableHudViewController);
    XCTAssertNil(planner.view.superview);
    XCTAssertEqual(panel.prevScrollableHudViewController, planner);
}

- (void)checkMultiMenuRestorationWithBackButton:(BOOL)backButton
{
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    panel.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1366, 1024)];
    OABaseScrollableHudViewController *planner = [[OABaseScrollableHudViewController alloc] initWithNibName:nil bundle:nil];
    planner.view = [[UIView alloc] initWithFrame:panel.view.bounds];
    [panel setValue:planner forKey:@"prevScrollableHudViewController"];
    OATargetMultiView *menu = [[OATargetMultiView alloc] initWithFrame:panel.view.bounds];
    panel.targetMultiMenuView = menu;
    [panel.view addSubview:menu];

    __block BOOL completed = NO;
    if (backButton)
    {
        [panel targetHideMenu:0.2 backButtonClicked:YES onComplete:^{ completed = YES; }];
    }
    else
    {
        [panel hideTargetPointMenu:0.2 onComplete:^{ completed = YES; }];
    }
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return completed;
    }];
    XCTNSPredicateExpectation *dismissed = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:nil];
    [self waitForExpectations:@[dismissed] timeout:3];

    XCTAssertTrue(completed);
    XCTAssertEqual(panel.scrollableHudViewController, planner);
    XCTAssertEqual(planner.parentViewController, panel);
    XCTAssertEqual(planner.view.superview, panel.view);
    XCTAssertNil(panel.prevScrollableHudViewController);
    XCTAssertNil(menu.superview);
}

- (void)testMultiMenuDismissRestoresEditor
{
    [self checkMultiMenuRestorationWithBackButton:NO];
}

- (void)testMultiMenuBackButtonRestoresEditor
{
    [self checkMultiMenuRestorationWithBackButton:YES];
}

- (void)testReplacingMultiMenuKeepsEditorSuspended
{
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    panel.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1366, 1024)];
    OABaseScrollableHudViewController *planner = [[OABaseScrollableHudViewController alloc] initWithNibName:nil bundle:nil];
    planner.view = [[UIView alloc] initWithFrame:panel.view.bounds];
    [panel setValue:planner forKey:@"prevScrollableHudViewController"];
    OATargetMultiView *menu = [[OATargetMultiView alloc] initWithFrame:panel.view.bounds];
    panel.targetMultiMenuView = menu;
    [panel.view addSubview:menu];

    [panel hideMultiMenuIfNeeded];
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return menu.superview == nil;
    }];
    XCTNSPredicateExpectation *dismissed = [[XCTNSPredicateExpectation alloc] initWithPredicate:predicate object:nil];
    [self waitForExpectations:@[dismissed] timeout:3];

    XCTAssertNil(panel.scrollableHudViewController);
    XCTAssertNil(planner.view.superview);
    XCTAssertEqual(panel.prevScrollableHudViewController, planner);
}

- (void)checkReopeningMultiMenuDuringHide:(BOOL)animated backButton:(BOOL)backButton
{
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    panel.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, OAUtilities.calculateScreenWidth, OAUtilities.calculateScreenHeight)];
    OABaseScrollableHudViewController *planner = [[OABaseScrollableHudViewController alloc] initWithNibName:nil bundle:nil];
    planner.view = [[UIView alloc] initWithFrame:panel.view.bounds];
    [panel setValue:planner forKey:@"prevScrollableHudViewController"];
    OATargetMultiView *menu = [[OATargetMultiView alloc] initWithFrame:panel.view.bounds];
    panel.targetMultiMenuView = menu;
    OATargetPoint *point = [[OATargetPoint alloc] init];
    point.title = @"Test point";
    menu.targetPoints = @[point];
    [panel.view addSubview:menu];
    XCTestExpectation *initialShow = [self expectationWithDescription:@"Menu initially shown"];
    [menu show:YES onComplete:^{ [initialShow fulfill]; }];
    [self waitForExpectations:@[initialShow] timeout:3];
    CGRect visibleFrame = menu.frame;
    XCTAssertTrue(CGRectContainsRect(panel.view.bounds, visibleFrame));

    XCTestExpectation *hideCompleted = [self expectationWithDescription:@"Cancelled hide must not complete"];
    hideCompleted.inverted = YES;
    [panel targetHideMenu:0.2 backButtonClicked:backButton onComplete:^{
        [hideCompleted fulfill];
    }];
    XCTestExpectation *showCompleted = [self expectationWithDescription:@"Menu shown again"];
    [menu show:animated onComplete:^{
        [showCompleted fulfill];
    }];
    [self waitForExpectations:@[hideCompleted, showCompleted] timeout:1];

    XCTAssertEqual(menu.superview, panel.view);
    XCTAssertEqualObjects([NSValue valueWithCGRect:menu.frame], [NSValue valueWithCGRect:visibleFrame]);
    XCTAssertTrue(CGRectContainsRect(panel.view.bounds, menu.frame));
    XCTAssertNil(panel.scrollableHudViewController);
    XCTAssertNil(planner.parentViewController);
    XCTAssertNil(planner.view.superview);
    XCTAssertEqual(panel.prevScrollableHudViewController, planner);

    XCTestExpectation *dismissed = [self expectationWithDescription:@"Reopened menu dismissed"];
    [panel targetHideMenu:0.2 backButtonClicked:backButton onComplete:^{ [dismissed fulfill]; }];
    [self waitForExpectations:@[dismissed] timeout:3];

    XCTAssertNil(menu.superview);
    XCTAssertEqual(panel.scrollableHudViewController, planner);
    XCTAssertEqual(planner.parentViewController, panel);
    XCTAssertEqual(planner.view.superview, panel.view);
    XCTAssertNil(panel.prevScrollableHudViewController);
}

- (void)testReopeningMultiMenuDuringHideKeepsItVisible
{
    [self checkReopeningMultiMenuDuringHide:YES backButton:NO];
}

- (void)testReopeningMultiMenuWithoutAnimationDuringHideKeepsItVisible
{
    [self checkReopeningMultiMenuDuringHide:NO backButton:NO];
}

- (void)testReopeningMultiMenuDuringBackButtonDismissalKeepsEditorSuspended
{
    [self checkReopeningMultiMenuDuringHide:YES backButton:YES];
}

- (void)checkReopeningMultiMenuInIPhoneLandscape:(BOOL)animated
{
    XCTSkipIf(UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPhone, @"Requires the iPhone landscape layout");
    UIWindow *window = UIApplication.sharedApplication.mainWindow;
    XCTAssertNotNil(window);
    if (!window)
        return;

    CGRect originalFrame = window.frame;
    @try
    {
        // The menu determines its landscape layout from the app window's width.
        window.frame = CGRectMake(0, 0, 844, 390);
        XCTAssertEqualWithAccuracy(OAUtilities.calculateScreenWidth, 844, 0.01);
        XCTAssertEqualWithAccuracy(OAUtilities.calculateScreenHeight, 390, 0.01);
        [self checkReopeningMultiMenuDuringHide:animated backButton:NO];
    }
    @finally
    {
        window.frame = originalFrame;
    }
}

- (void)testReopeningMultiMenuDuringHideInIPhoneLandscapeKeepsItVisible
{
    [self checkReopeningMultiMenuInIPhoneLandscape:YES];
}

- (void)testReopeningMultiMenuWithoutAnimationDuringHideInIPhoneLandscapeKeepsItVisible
{
    [self checkReopeningMultiMenuInIPhoneLandscape:NO];
}

- (void)testReopeningMultiMenuCancelsPendingPresentationAndAllowsNextRequest
{
    OAMapPanelViewController *panel = [[OAMapPanelViewController alloc] initWithNibName:nil bundle:nil];
    panel.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1366, 1024)];
    OABaseScrollableHudViewController *planner = [[OABaseScrollableHudViewController alloc] initWithNibName:nil bundle:nil];
    planner.view = [[UIView alloc] initWithFrame:panel.view.bounds];
    [panel setValue:planner forKey:@"prevScrollableHudViewController"];
    OATargetMultiView *menu = [[OATargetMultiView alloc] initWithFrame:panel.view.bounds];
    OATargetPoint *point = [[OATargetPoint alloc] init];
    point.title = @"Test point";
    menu.targetPoints = @[point];
    panel.targetMultiMenuView = menu;
    [panel.view addSubview:menu];
    [menu show:NO onComplete:nil];

    ContextMenuPresentationCoordinator *coordinator = [ContextMenuPresentationCoordinator new];
    [panel setValue:coordinator forKey:@"contextMenuPresentationCoordinator"];
    XCTestExpectation *cancelled = [self expectationWithDescription:@"Superseded presentation must not run"];
    cancelled.inverted = YES;
    [panel enqueueContextMenuPresentation:^{ [cancelled fulfill]; }];
    XCTAssertTrue(coordinator.isTransitionInProgress);

    [panel showMultiPointMenu:nil points:@[point] selectedObjects:nil onComplete:nil];
    XCTAssertFalse(coordinator.isTransitionInProgress);
    [self waitForExpectations:@[cancelled] timeout:1];
    XCTAssertEqual(menu.superview, panel.view);
    XCTAssertNil(panel.scrollableHudViewController);
    XCTAssertNil(planner.view.superview);
    XCTAssertEqual(panel.prevScrollableHudViewController, planner);

    XCTestExpectation *presented = [self expectationWithDescription:@"Next presentation completed"];
    [panel enqueueContextMenuPresentation:^{ [presented fulfill]; }];
    [self waitForExpectations:@[presented] timeout:3];
    XCTAssertFalse(coordinator.isTransitionInProgress);
    XCTAssertNil(menu.superview);
    XCTAssertEqual(panel.prevScrollableHudViewController, planner);
}

- (void)testNewHideCancelsPreviousDismissal
{
    UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1366, 1024)];
    OATargetMultiView *menu = [[OATargetMultiView alloc] initWithFrame:container.bounds];
    [container addSubview:menu];
    XCTestExpectation *cancelled = [self expectationWithDescription:@"Previous hide cancelled"];
    [menu hide:YES duration:0.2 completion:^(BOOL hidden) {
        XCTAssertFalse(hidden);
        [cancelled fulfill];
    }];
    XCTestExpectation *dismissed = [self expectationWithDescription:@"New hide completed"];
    [menu hide:YES duration:0.3 completion:^(BOOL hidden) {
        XCTAssertTrue(hidden);
        [dismissed fulfill];
    }];
    [self waitForExpectations:@[cancelled, dismissed] timeout:3];
    XCTAssertNil(menu.superview);
}

- (void)testRealPlannerRestoresViewportCenterToCrosshair
{
    OAAppDelegate *appDelegate = (OAAppDelegate *)UIApplication.sharedApplication.delegate;
    [appDelegate initialize];
    NSPredicate *initialized = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        return !appDelegate.isAppInitializing;
    }];
    XCTestExpectation *appReady = [[XCTNSPredicateExpectation alloc] initWithPredicate:initialized object:nil];
    XCTWaiterResult initializedResult = [XCTWaiter waitForExpectations:@[appReady] timeout:30];
    XCTAssertEqual(initializedResult, XCTWaiterResultCompleted);
    if (initializedResult != XCTWaiterResultCompleted)
        return;

    OARootViewController *previousRoot = appDelegate.rootViewController;
    UIWindowScene *scene = nil;
    for (UIScene *candidate in UIApplication.sharedApplication.connectedScenes)
    {
        if ([candidate isKindOfClass:UIWindowScene.class])
        {
            scene = (UIWindowScene *)candidate;
            break;
        }
    }
    XCTAssertNotNil(scene);
    if (!scene)
        return;
    UIWindow *previousKeyWindow = nil;
    for (UIWindow *window in scene.windows)
        if (window.isKeyWindow)
            previousKeyWindow = window;
    appDelegate.rootViewController = [[OARootViewController alloc] initWithNibName:nil bundle:nil];
    UIWindow *testWindow = [[UIWindow alloc] initWithWindowScene:scene];
    testWindow.frame = UIScreen.mainScreen.bounds;
    testWindow.rootViewController = [[UINavigationController alloc] initWithRootViewController:appDelegate.rootViewController];
    [testWindow makeKeyAndVisible];
    [appDelegate.rootViewController.mapPanel loadViewIfNeeded];
    [appDelegate.rootViewController.view layoutIfNeeded];
    NSPredicate *ready = [NSPredicate predicateWithBlock:^BOOL(id object, NSDictionary *bindings) {
        OAMapViewController *mapController = OARootViewController.instance.mapPanel.mapViewController;
        OAMapRendererView *map = (OAMapRendererView *)mapController.mapRendererView;
        return mapController.mapViewLoaded && map && [map getCenterPixel].y > 0;
    }];
    XCTestExpectation *mapReady = [[XCTNSPredicateExpectation alloc] initWithPredicate:ready object:nil];
    XCTWaiterResult result = [XCTWaiter waitForExpectations:@[mapReady] timeout:30];
    XCTAssertEqual(result, XCTWaiterResultCompleted);
    if (result != XCTWaiterResultCompleted)
    {
        testWindow.hidden = YES;
        testWindow.rootViewController = nil;
        appDelegate.rootViewController = previousRoot;
        [OAMapViewTrackingUtilities.instance setMapViewController:previousRoot.mapPanel.mapViewController];
        [previousKeyWindow makeKeyWindow];
        return;
    }

    OAMapPanelViewController *panel = OARootViewController.instance.mapPanel;
    OAMapViewController *mapController = panel.mapViewController;
    Class plannerClass = NSClassFromString(@"OsmAnd_Maps.PlanRouteScrollableViewController");
    XCTAssertNotNil(plannerClass);
    [plannerClass showNewRoute];
    OABaseScrollableHudViewController *planner = panel.scrollableHudViewController;
    [planner viewWillAppear:NO];
    OAMeasurementToolLayer *layer = mapController.mapLayers.routePlanningLayer;
    @try
    {
        // Hiding the planner for a context menu resets the viewport to full screen.
        for (NSUInteger cycle = 0; cycle < 2; cycle++)
        {
            OAMapRendererView *map = (OAMapRendererView *)mapController.mapRendererView;
            CGPoint cursor = layer.cursorScreenPoint;
            CGPoint cursorPixel = CGPointMake(cursor.x * map.contentScaleFactor, cursor.y * map.contentScaleFactor);
            mapController.viewportYScale = 1.0;
            [map reanchorMapTarget:CGPointMake(planner.view.bounds.size.width / 2, planner.view.bounds.size.height / 2)];
            OsmAnd::PointI locationBefore;
            [map convert:cursorPixel toLocation:&locationBefore];
            [planner viewWillAppear:NO];
            cursor = layer.cursorScreenPoint;
            XCTAssertGreaterThan(cursor.y, 0);
            XCTAssertLessThan(cursor.y, planner.view.bounds.size.height / 2);
            XCTAssertEqualWithAccuracy(mapController.viewportYScale,
                                       2 * cursor.y / planner.view.bounds.size.height, 0.0001);
            OsmAnd::PointI center = [map getCenterPixel];
            XCTAssertEqualWithAccuracy(center.y / map.contentScaleFactor, cursor.y, 1.0);
            XCTAssertEqualWithAccuracy(map.mapTargetScreenPoint.y, cursor.y, 1.0);
            OsmAnd::PointI locationAfter;
            [map convert:cursorPixel toLocation:&locationAfter];
            XCTAssertEqualWithAccuracy(locationAfter.x, locationBefore.x, 1);
            XCTAssertEqualWithAccuracy(locationAfter.y, locationBefore.y, 1);
        }
    }
    @finally
    {
        [planner forceHide];
        if (testWindow)
        {
            testWindow.hidden = YES;
            testWindow.rootViewController = nil;
            appDelegate.rootViewController = previousRoot;
            [OAMapViewTrackingUtilities.instance setMapViewController:previousRoot.mapPanel.mapViewController];
            [previousKeyWindow makeKeyWindow];
        }
    }
}
@end
