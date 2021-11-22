//
//  OATrackMenuUIBuilder.mm
//  OsmAnd
//
//  Created by Skalii on 02.11.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuUIBuilder.h"
#import "OATabBar.h"
#import "OAColors.h"
#import "OABaseTrackMenuTabItem.h"
#import "OATrackMenuTabOverview.h"
#import "OATrackMenuTabPoints.h"
#import "OATrackMenuTabActions.h"
#import "OATrackMenuTabSegments.h"

@interface OATrackMenuUIBuilder ()

@end

@implementation OATrackMenuUIBuilder
{
    EOATrackMenuHudTab _selectedTab;
    NSArray<OABaseTrackMenuTabItem *> *_tabs;
}

- (instancetype)initWithSelectedTab:(EOATrackMenuHudTab)selectedTab
{
    self = [super init];
    if (self)
    {
        _selectedTab = selectedTab;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _tabs = @[
            [[OATrackMenuTabOverview alloc] init],
            [[OATrackMenuTabSegments alloc] init],
            [[OATrackMenuTabPoints alloc] init],
            [[OATrackMenuTabActions alloc] init]
    ];
}

- (void)updateSelectedTab:(EOATrackMenuHudTab)selectedTab
{
    _selectedTab = selectedTab;
}

- (void)runAdditionalActions
{
    [_tabs[_selectedTab] runAdditionalActions];
}

- (OAGPXTableData *)getTableData
{
    return [_tabs[_selectedTab] getTableData];
}

- (OAGPXTableData *)generateSectionsData
{
    if (_selectedTab < _tabs.count)
    {
        OABaseTrackMenuTabItem *tab = _tabs[_selectedTab];
        if (!tab.trackMenuDelegate)
            tab.trackMenuDelegate = self.trackMenuDelegate;
        [tab generateData];

        return [tab getTableData];
    }
    return [[OAGPXTableData alloc] init];
}

- (void)setupTabBar:(OATabBar *)tabBarView
        parentWidth:(CGFloat)parentWidth
{
    if (tabBarView)
    {
        NSMutableArray *tabBarItems = [NSMutableArray array];
        for (OABaseTrackMenuTabItem *tab in _tabs)
        {
            [tabBarItems addObject:[self createTabBarItem:tab]];
        }
        [tabBarView setItems:tabBarItems animated:YES];

        tabBarView.selectedItem = tabBarView.items[_selectedTab];
        tabBarView.itemWidth = parentWidth / _tabs.count;
    }
}

- (UITabBarItem *)createTabBarItem:(OABaseTrackMenuTabItem *)tab
{
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:[tab getTabTitle]
                                                             image:[tab getTabIcon]
                                                               tag:[tab getTabMode]];
    [tabBarItem setTitleTextAttributes:@{
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer),
            NSFontAttributeName: [UIFont systemFontOfSize:12]
    } forState:UIControlStateNormal];

    [tabBarItem setTitleTextAttributes:@{
            NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple),
            NSFontAttributeName: [UIFont systemFontOfSize:12]
    } forState:UIControlStateSelected];

    return tabBarItem;
}

@end
