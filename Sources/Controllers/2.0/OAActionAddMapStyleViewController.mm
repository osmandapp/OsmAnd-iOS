//
//  OAActionAddMapStyleViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionAddMapStyleViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetActionCell.h"
#import "OASizes.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OAMapSource.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAMapStyleTitles.h"


#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>

#define _(name) OAActionAddMapStyleViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define Item _(Item)
@interface Item : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@end
@implementation Item
@end

#define Item_MapStyle _(Item_MapStyle)
@interface Item_MapStyle : Item
@property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@property int sortIndex;
@end
@implementation Item_MapStyle
@end


@interface OAActionAddMapStyleViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAActionAddMapStyleViewController
{
    NSArray *_data;
    
    NSMutableArray<NSString *> *_initialValues;
}

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names
{
    self = [super init];
    if (self) {
        _initialValues = names;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 55., 0.0, 0.0);
    [self.tableView setEditing:YES];
    [self.backBtn setImage:[[UIImage imageNamed:@"ic_navbar_chevron"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.backBtn setTintColor:UIColor.whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
}


-(void) commonInit
{
    NSDictionary *stylesTitlesOffline = [OAMapStyleTitles getMapStyleTitles];
    NSMutableArray *offlineMapSources = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    const auto localResources = [OsmAndApp instance].resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
            mapStylesResources.push_back(localResource);
    }
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode;
    
    for(const auto& resource : mapStylesResources)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
        
        NSString* resourceId = resource->id.toNSString();
        
        Item_MapStyle* item = [[Item_MapStyle alloc] init];
        item.mapSource = [[OsmAndApp instance].data lastMapSourceByResourceId:resourceId];
        if (item.mapSource == nil)
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId andVariant:mode.variantKey];
        
        NSString *caption = mapStyle->title.toNSString();
        OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
        if ([caption isEqualToString:@"Ski-map"] && ![iapHelper.skiMap isActive])
            continue;
        if ([caption isEqualToString:@"nautical"] && ![iapHelper.nautical isActive])
            continue;
        
        NSString *newCaption = [stylesTitlesOffline objectForKey:caption];
        if (newCaption)
            caption = newCaption;
        
        item.mapSource.name = caption;
        
        item.resource = resource;
        item.mapStyle = mapStyle;
        
        if ([item.mapStyle->title.toNSString() isEqualToString:@"default"])
            item.sortIndex = 0;
        else if ([item.mapStyle->title.toNSString() isEqualToString:@"UniRS"])
            item.sortIndex = 1;
        else if ([item.mapStyle->title.toNSString() isEqualToString:@"Touring-view_(more-contrast-and-details).render"])
            item.sortIndex = 2;
        else if ([item.mapStyle->title.toNSString() isEqualToString:@"LightRS"])
            item.sortIndex = 3;
        else if ([item.mapStyle->title.toNSString() isEqualToString:@"Ski-map"])
            item.sortIndex = 4;
        else if ([item.mapStyle->title.toNSString() isEqualToString:@"nautical"])
            item.sortIndex = 5;
        else if ([item.mapStyle->title.toNSString() isEqualToString:@"Offroad by ZLZK"])
            item.sortIndex = 6;
        else
            item.sortIndex = 7;
        
        [offlineMapSources addObject:item];
    }
    NSArray *res = [offlineMapSources sortedArrayUsingComparator:^NSComparisonResult(Item_MapStyle* obj1, Item_MapStyle* obj2) {
        if (obj1.sortIndex < obj2.sortIndex)
            return NSOrderedAscending;
        if (obj1.sortIndex > obj2.sortIndex)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    _data = res;
}


- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"select_map_style");
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (IBAction)backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneButtonPressed:(id)sender
{
    NSArray *selectedItems = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSIndexPath *path in selectedItems)
    {
        Item_MapStyle* style = [self getItem:path];
        [arr addObject:style.mapSource.name];
    }
    
    if (self.delegate)
        [self.delegate onMapStylesSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

-(Item_MapStyle *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item_MapStyle* item = [self getItem:indexPath];
    static NSString* const identifierCell = @"OABottomSheetActionCell";
    OABottomSheetActionCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OABottomSheetActionCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        UIImage *img = nil;
        NSString *imgName = [NSString stringWithFormat:@"img_mapstyle_%@", [item.mapSource.resourceId stringByReplacingOccurrencesOfString:@".render.xml" withString:@""]];
        if (imgName)
            img = [UIImage imageNamed:imgName];
        
        cell.textView.text = item.mapSource.name;
        cell.descView.hidden = YES;
        cell.iconView.image = img;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        if ([_initialValues containsObject:item.mapSource.name])
        {
            [_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [_initialValues removeObject:item.mapSource.name];
        }
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"groups");
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item_MapStyle *item = [self getItem:indexPath];
    return [OABottomSheetActionCell getHeight:item.mapSource.name value:nil cellWidth:tableView.bounds.size.width];
}

@end
