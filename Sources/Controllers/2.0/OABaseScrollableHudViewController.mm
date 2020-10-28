//
//  OABaseScrollableHudViewController.m
//  OsmAnd
//
//  Created by Paul on 10/16/20.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseScrollableHudViewController.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAScrollableTableToolBarView.h"
#import "OAColors.h"

@interface OABaseScrollableHudViewController () <OADraggableViewDelegate>

@property (strong, nonatomic) IBOutlet OAScrollableTableToolBarView *scrollableView;

@end

@implementation OABaseScrollableHudViewController
{
    OAAppSettings *_settings;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseScrollableHudViewController"
                           bundle:nil];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _scrollableView.delegate = self;
    [_scrollableView show:YES state:EOADraggableMenuStateInitial onComplete:nil];
}

- (void)adjustMapViewPort
{
}

- (void) restoreMapViewPort
{
}

- (void) updateViewVisibility
{

}

- (void)viewWillLayoutSubviews
{
}

#pragma mark - OADraggableViewDelegate

- (void)onViewSwippedDown
{
    [_scrollableView hide:YES duration:.2 onComplete:^{
            [self.view removeFromSuperview];
    }];
}

- (void)onViewHeightChanged:(CGFloat)height
{
    
}

@end
