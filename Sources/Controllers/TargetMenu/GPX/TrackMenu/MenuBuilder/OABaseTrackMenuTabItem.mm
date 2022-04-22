//
//  OABaseTrackMenuTabItem.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuTabItem.h"
#import "OAColors.h"

@interface OABaseTrackMenuTabItem ()

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) BOOL isGeneratedData;

@end

@implementation OABaseTrackMenuTabItem

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    //override
}
- (NSString *)getTabTitle
{
    return @""; //override
}

- (UIImage *)getTabIcon
{
    return nil; //override
}

- (EOATrackMenuHudTab)getTabMode
{
    return EOATrackMenuHudOverviewTab; //override
}

+ (UIImage *)getUnselectedIcon:(NSString *)iconName
{
    return [OAUtilities tintImageWithColor:[UIImage templateImageNamed:iconName]
                                     color:UIColorFromRGB(unselected_tab_icon)];
}

- (void)generateData
{
    self.tableData = [[OAGPXTableData alloc] init]; //override
}

- (void)resetData
{
    _isGeneratedData = NO;
}

- (OAGPXTableData *)getTableData
{
    return self.tableData;
}

- (void)runAdditionalActions
{
    //override
}

@end
