//
//  OASegmentsTrackMenuViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OASegmentsTrackMenuViewController.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDocument.h"
#import "OAGPXDatabase.h"
#import "OAMeasurementToolLayer.h"

@interface OASegmentsTrackMenuViewController ()

@end

@implementation OASegmentsTrackMenuViewController
{
    OsmAndAppInstance _app;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        self.gpx = gpx;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)applyLocalization
{

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)getToolBarHeight
{
    return _tableView.frame.origin.y;
}

- (CGFloat)getHeaderHeight
{
    return _tableView.frame.origin.y;
}

@end
