//
//  OAActionAddMapSourceViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionAddMapSourceViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OABottomSheetActionCell.h"
#import "OASizes.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OAMapSource.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"


#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define _(name) OAActionAddMapSourceViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define Item _(Item)
@interface Item : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@end
@implementation Item
@end

#define Item_OnlineTileSource _(Item_OnlineTileSource)
@interface Item_OnlineTileSource : Item
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end


@interface OAActionAddMapSourceViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAActionAddMapSourceViewController
{
    EOAMapSourceType _type;
    NSArray *_data;
    
    NSMutableArray<NSString *> *_initialValues;
    
    OsmAndAppInstance _app;
}

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names type:(EOAMapSourceType)type
{
    self = [super init];
    if (self) {
        _initialValues = names;
        _app = [OsmAndApp instance];
        _type = type;
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
    NSMutableArray *onlineMapSources = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > onlineTileSourcesResources;
    
    const auto localResources = _app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::OnlineTileSources)
            onlineTileSourcesResources.push_back(localResource);
    }
    
    for(const auto& resource : onlineTileSourcesResources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        NSString* resourceId = resource->id.toNSString();
        
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            Item_OnlineTileSource* item = [[Item_OnlineTileSource alloc] init];
            
            NSString *caption = onlineTileSource->title.toNSString();
            
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:onlineTileSource->name.toNSString() name:caption];
            item.resource = resource;
            item.onlineTileSource = onlineTileSource;
            
            [onlineMapSources addObject:item];
        }
    }
    
    
    NSArray *arr = [onlineMapSources sortedArrayUsingComparator:^NSComparisonResult(Item_OnlineTileSource* obj1, Item_OnlineTileSource* obj2) {
        NSString *caption1 = obj1.onlineTileSource->title.toNSString();
        NSString *caption2 = obj2.onlineTileSource->title.toNSString();
        return [caption2 compare:caption1];
    }];
    Item_OnlineTileSource* itemNone = [[Item_OnlineTileSource alloc] init];
    itemNone.mapSource = [[OAMapSource alloc] initWithResource:nil andVariant:[self getNoSourceItemId] name:[self getNoSourceName]];
    _data = [arr arrayByAddingObject:itemNone];
}


- (void)applyLocalization
{
    _titleView.text = [self getTitle];
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (NSString *) getTitle
{
    switch (_type) {
        case EOAMapSourceTypePrimary:
            return OALocalizedString(@"select_map_source");
        case EOAMapSourceTypeOverlay:
            return OALocalizedString(@"select_overlay");
        case EOAMapSourceTypeUnderlay:
            return OALocalizedString(@"select_underlay");
        default:
            return @"";
    }
}

- (NSString *) getNoSourceItemId
{
    switch (_type) {
        case EOAMapSourceTypePrimary:
            return @"type_default";
        case EOAMapSourceTypeOverlay:
            return @"no_overlay";
        case EOAMapSourceTypeUnderlay:
            return @"no_underlay";
        default:
            return @"";
    }
}

- (NSString *) getNoSourceName
{
    switch (_type) {
        case EOAMapSourceTypePrimary:
            return OALocalizedString(@"offline_vector_maps");
        case EOAMapSourceTypeOverlay:
            return OALocalizedString(@"quick_action_no_overlay");
        case EOAMapSourceTypeUnderlay:
            return OALocalizedString(@"quick_action_no_underlay");
        default:
            return @"";
    }
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
        Item_OnlineTileSource* source = [self getItem:path];
        [arr addObject:@[source.mapSource.variant ,source.mapSource.name]];
    }
    
    if (self.delegate)
        [self.delegate onMapSourceSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

-(Item_OnlineTileSource *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item_OnlineTileSource* item = [self getItem:indexPath];
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
        img = [UIImage imageNamed:@"ic_custom_map_style"];
        
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
    Item_OnlineTileSource *item = [self getItem:indexPath];
    return [OABottomSheetActionCell getHeight:item.mapSource.name value:nil cellWidth:tableView.bounds.size.width];
}

@end
