#import <XCTest/XCTest.h>
#import "OAMapPanelViewController.h"
#import "OABaseScrollableHudViewController.h"

@interface OAMapPanelViewController (MenuRestorationTests)
@property (nonatomic, strong) OATargetPointView *targetMenuView;
- (void)hideTargetPointMenu:(CGFloat)duration onComplete:(void (^)(void))completion hideActiveTarget:(BOOL)hideActiveTarget mapGestureAction:(BOOL)mapGestureAction;
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
@end
