//
//  OAActionAddMapStyleViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionAddMapStyleViewController.h"
#import "Localization.h"
#import "OAMenuSimpleCell.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OARendererRegistry.h"
#import "OAResourcesUIHelper.h"
#import "OAIndexConstants.h"

#include <OsmAndCore/Map/UnresolvedMapStyle.h>

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
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 48.;
    [self.backBtn setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    [self.backBtn setTintColor:UIColor.whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
}


-(void) commonInit
{
    NSMutableArray *offlineMapSources = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    const auto localResources = [OsmAndApp instance].resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
            mapStylesResources.push_back(localResource);
    }
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;
    
    for(const auto& resource : mapStylesResources)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;

        NSString* resourceId = resource->id.toNSString();
        NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:mapStyle->title.toNSString()];

        OAMapStyleResourceItem* item = [[OAMapStyleResourceItem alloc] init];
        item.mapSource = [[OsmAndApp instance].data lastMapSourceByResourceId:resourceId];
        if (!item.mapSource)
        {
            item.mapSource = [[OAMapSource alloc] initWithResource:[[mapStyleInfo[@"id"] lowercaseString] stringByAppendingString:RENDERER_INDEX_EXT]
                                                        andVariant:mode.variantKey
                                                              name:mapStyleInfo[@"title"]];
        }
        else if (![item.mapSource.name isEqualToString:mapStyleInfo[@"title"]])
        {
            item.mapSource.name = mapStyleInfo[@"title"];
        }

        OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
        if ([mapStyleInfo[@"title"] isEqualToString:WINTER_SKI_RENDER] && ![iapHelper.skiMap isActive])
            continue;
        if ([mapStyleInfo[@"title"] isEqualToString:NAUTICAL_RENDER] && ![iapHelper.nautical isActive])
            continue;

        item.resourceType = OsmAndResourceType::MapStyle;
        item.resource = resource;
        item.mapStyle = mapStyle;
        item.sortIndex = [mapStyleInfo[@"sort_index"] intValue];
        
        [offlineMapSources addObject:item];
    }
    NSArray *res = [offlineMapSources sortedArrayUsingComparator:^NSComparisonResult(OAMapStyleResourceItem* obj1, OAMapStyleResourceItem* obj2) {
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
        OAMapStyleResourceItem* style = [self getItem:path];
        NSString *imgName = [NSString stringWithFormat:@"img_mapstyle_%@", [style.mapSource.resourceId stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""]];
        [arr addObject:@{@"name" : style.mapSource.name, @"img" : imgName ? imgName : @"ic_custom_show_on_map"}];
    }
    
    if (self.delegate)
        [self.delegate onMapStylesSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

-(OAMapStyleResourceItem *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMapStyleResourceItem* item = [self getItem:indexPath];
    
    OAMenuSimpleCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
        cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        UIImage *img = nil;
        NSString *imgName = [NSString stringWithFormat:@"img_mapstyle_%@", [item.mapSource.resourceId stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""]];
        if (imgName)
            img = [UIImage imageNamed:imgName];
        
        cell.textView.text = item.mapSource.name;
        cell.descriptionView.hidden = YES;
        cell.imgView.image = img;
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
    return OALocalizedString(@"available_map_styles");
}

@end
