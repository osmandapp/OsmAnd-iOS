//
//  OAPoiViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPoiViewController.h"
#import "OAPOI.h"

@interface OAPoiViewController ()

@property (nonatomic) OAPOI *poi;

@end

@implementation OAPoiViewController

- (id)initWithPoi:(OAPOI *)poi
{
    self = [super init];
    if (self)
    {
        self.poi = poi;
    }
    return self;
}

- (void)build
{
    [self.poi.values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        UIImage *icon = nil;
        UIColor *textColor = nil;
        NSString *textPrefix = nil;
        BOOL isText = NO;
        BOOL isDescription = NO;
        BOOL needLinks = ![@"population" isEqualToString:key];
        BOOL isPhoneNumber = NO;
        BOOL isUrl = NO;
        int poiTypeOrder = 0;
        
        self.poi.type.name;
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
