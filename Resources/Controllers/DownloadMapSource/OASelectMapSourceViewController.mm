//
//  OASelectMapSourceViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASelectMapSourceViewController.h"
#import "OAMapSource.h"
#import "OsmAndApp.h"
#import "OABottomSheetActionCell.h"
#import "OAMapCreatorHelper.h"
#import "OASQLiteTileSource.h"

#include "Localization.h"
#include "OASizes.h"
#include <QSet>

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define _(name) OASelectMapSourceViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define Item _(Item)
@interface Item : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@property NSString *path;
@end
@implementation Item
@end

#define Item_OnlineTileSource _(Item_OnlineTileSource)
@interface Item_OnlineTileSource : Item
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end

#define Item_SqliteDbTileSource _(Item_SqliteDbTileSource)
@interface Item_SqliteDbTileSource : Item
@property uint64_t size;
@property BOOL isOnline;
@end
@implementation Item_SqliteDbTileSource
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OASelectMapSourceViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OASelectMapSourceViewController
{
    OsmAndAppInstance _app;
    NSArray *_onlineMapSources;
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = OALocalizedString(@"select_online_source");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _app = [OsmAndApp instance];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(10., 0., 0., 0.);
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    [self setupView];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (void) adjustViews
{
    CGRect buttonFrame = _cancelButton.frame;
    CGRect titleFrame = _titleView.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    buttonFrame.origin.y = statusBarHeight;
    titleFrame.origin.y = statusBarHeight;
    _cancelButton.frame = buttonFrame;
    _titleView.frame = titleFrame;
}

- (void) setupView
{
    // Collect all needed resources
    NSMutableArray *onlineMapSources = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > onlineTileSourcesResources;
    const auto localResources = _app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
        if (localResource->type == OsmAndResourceType::OnlineTileSources)
            onlineTileSourcesResources.push_back(localResource);
    
    // Process online tile sources resources
    for(const auto& resource : onlineTileSourcesResources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        NSString* resourceId = resource->id.toNSString();
        
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            Item_OnlineTileSource* item = [[Item_OnlineTileSource alloc] init];
            
            NSString *caption = onlineTileSource->name.toNSString();
            
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:onlineTileSource->name.toNSString() name:caption];
            item.resource = resource;
            item.onlineTileSource = onlineTileSource;
            item.path = [_app.cachePath stringByAppendingPathComponent:caption];
            [onlineMapSources addObject:item];
        }
    }
    
    [onlineMapSources sortedArrayUsingComparator:^NSComparisonResult(Item_OnlineTileSource* obj1, Item_OnlineTileSource* obj2) {
        NSString *caption1 = obj1.onlineTileSource->name.toNSString();
        NSString *caption2 = obj2.onlineTileSource->name.toNSString();
        return [caption2 compare:caption1];
    }];

    
    NSMutableArray *sqlitedbArr = [NSMutableArray array];
    for (NSString *fileName in [OAMapCreatorHelper sharedInstance].files.allKeys)
    {
        NSString *path = [OAMapCreatorHelper sharedInstance].files[fileName];
        if ([OASQLiteTileSource isOnlineTileSource:path])
        {
            Item_SqliteDbTileSource* item = [[Item_SqliteDbTileSource alloc] init];
            item.mapSource = [[OAMapSource alloc] initWithResource:fileName andVariant:@"" name:@"sqlitedb"];
            item.path = path;
            item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
            item.isOnline = YES;
            [sqlitedbArr addObject:item];
        }
    }
    
    [sqlitedbArr sortUsingComparator:^NSComparisonResult(Item_SqliteDbTileSource *obj1, Item_SqliteDbTileSource *obj2) {
        return [obj1.mapSource.resourceId caseInsensitiveCompare:obj2.mapSource.resourceId];
    }];
    
    [onlineMapSources addObjectsFromArray:sqlitedbArr];
    _onlineMapSources = [NSArray arrayWithArray:onlineMapSources];
}

- (IBAction) onCancelButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedString(@"online_sources");
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _onlineMapSources.count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString* caption = nil;
    Item *item = _onlineMapSources[indexPath.row];
    if ([item isKindOfClass:Item_SqliteDbTileSource.class])
    {
        caption = [[item.mapSource.resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
    }
    else if ([item isKindOfClass:Item_OnlineTileSource.class])
    {
        caption = item.mapSource.name;
    }
    
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
        img = [UIImage imageNamed:@"ic_custom_map_online"];
        
        cell.textView.text = caption;
        cell.descView.hidden = YES;
        cell.iconView.image = img;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        
        if ([_app.data.lastMapSource isEqual:item.mapSource])
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ic_checmark_default.png"]];
        else
            cell.accessoryView = nil;
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item* item = [_onlineMapSources objectAtIndex:indexPath.row];
    _app.data.lastMapSource = item.mapSource;
    if (self.delegate)
        [self.delegate onNewSourceSelected];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

