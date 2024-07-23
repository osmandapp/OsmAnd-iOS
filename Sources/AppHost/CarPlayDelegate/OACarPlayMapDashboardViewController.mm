//
//  OACarPlayMapViewController.m
//  OsmAnd Maps
//

#import "OACarPlayMapDashboardViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OARootViewController.h"

@interface OACarPlayMapDashboardViewController ()

@end

@implementation OACarPlayMapDashboardViewController
{
    OAMapViewController *_mapVc;
}

- (instancetype)initWithCarPlayMapViewController:(OAMapViewController *)mapVC
{
    self = [super init];
    if (self) {
        _mapVc = mapVC;
    }
    return self;
}

- (void)attachMapToWindow
{
    if (_mapVc)
    {
        [_mapVc.mapView suspendRendering];
        [_mapVc removeFromParentViewController];
        [_mapVc.view removeFromSuperview];
        
        [self addChildViewController:_mapVc];
        [self.view addSubview:_mapVc.view];
        _mapVc.view.frame = self.view.frame;
        _mapVc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [_mapVc.mapView resumeRendering];
    }
}

- (void)detachFromCarPlayWindow
{
    if (_mapVc)
    {
        [_mapVc.mapView suspendRendering];
        
        [_mapVc removeFromParentViewController];
        [_mapVc.view removeFromSuperview];
        
        OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
        
        [mapPanel addChildViewController:_mapVc];
        [mapPanel.view insertSubview:_mapVc.view atIndex:0];
        _mapVc.view.frame = mapPanel.view.frame;
        _mapVc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_mapVc.mapView resumeRendering];
    }
}

@end
