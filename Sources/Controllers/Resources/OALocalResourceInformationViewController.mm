//
//  OALocalResourceInformationViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALocalResourceInformationViewController.h"
#import "OsmAndApp.h"
#import "OALocalResourceInfoCell.h"
#import "OAButtonTableViewCell.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASQLiteTileSource.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAOnlineTilesEditingViewController.h"
#import "OAResourcesUIHelper.h"
#import "GeneratedAssetSymbols.h"

#import "Localization.h"

@interface OALocalResourceInformationViewController ()<UITableViewDelegate, UITableViewDataSource, OATilesEditingViewControllerDelegate>
{
    NSArray *tableKeys;
    NSArray *tableValues;
    NSArray *tableButtons;
    
    NSDateFormatter *formatter;
    
    NSString *_resourceId;
}

@end

@implementation OALocalResourceInformationViewController
{
    CALayer *_horizontalLine;
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
    self.navigationItem.title = OALocalizedString(@"shared_string_details");
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    self.tableView.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 16.0, 0., 0.);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:NO];
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.shadowColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    UINavigationBarAppearance *blurAppearance = [[UINavigationBarAppearance alloc] init];
    blurAppearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleRegular];
    blurAppearance.backgroundColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    blurAppearance.titleTextAttributes = @{
        NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline],
        NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameNavBarTextColorPrimary]
    };
    self.navigationController.navigationBar.standardAppearance = blurAppearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.tintColor = [UIColor colorNamed:ACColorNameNavBarTextColorPrimary];
    self.navigationController.navigationBar.prefersLargeTitles = NO;
    if (self.regionTitle)
        self.navigationItem.title = self.regionTitle;

    [self applySafeAreaMargins];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        _horizontalLine.backgroundColor = [[UIColor colorNamed:ACColorNameCustomSeparator] CGColor];
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}

- (void) deleteClicked
{
    if (!_localItem)
        return;
    
    [self.baseController offerDeleteResourceOf:self.localItem executeAfterSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

- (void) clearCacheClicked
{
    if (!_localItem)
           return;
       
   [self.baseController offerClearCacheOf:self.localItem executeAfterSuccess:^{
       dispatch_async(dispatch_get_main_queue(), ^{
           if ([_localItem isKindOfClass:[OAOnlineTilesResourceItem class]])
           {
               [self calculateSizeAndUpdate:(OAOnlineTilesResourceItem *)_localItem];
           }
           if ([_localItem isKindOfClass:[OASqliteDbResourceItem class]])
           {
               [self updateLocalSqliteDbItem:(OASqliteDbResourceItem *)_localItem];
           }
       });
   }];
}

- (void) editClicked
{
    OAOnlineTilesEditingViewController *editViewController = [[OAOnlineTilesEditingViewController alloc] initWithLocalItem:_localItem baseController:self.baseController];
    editViewController.delegate = self;
    [self.navigationController pushViewController:editViewController animated:YES];
}

- (void)initWithLocalSqliteDbItem:(OASqliteDbResourceItem *)item;
{
    self.localItem = item;
    BOOL isOnlineSql = [OASQLiteTileSource isOnlineTileSource:item.path];
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    NSMutableArray *tButtons = [NSMutableArray array];
    
    // Type
    [tKeys addObject:OALocalizedString(@"shared_string_type")];
    [tValues addObject:isOnlineSql ? OALocalizedString(@"online_raster_map") : OALocalizedString(@"offline_raster_map")];
    
    // Size
    [tKeys addObject:OALocalizedString(@"shared_string_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]];
    
    // Timestamp
    NSError *error;
    NSURL *fileUrl = [NSURL fileURLWithPath:item.path];
    NSDate *d;
    [fileUrl getResourceValue:&d forKey:NSURLCreationDateKey error:&error];
    if (!error)
    {
        [tKeys addObject:OALocalizedString(@"created_on")];
        
        if (!formatter)
        {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }
        
        [tValues addObject:[NSString stringWithFormat:@"%@", [formatter stringFromDate:d]]];
        
        if (isOnlineSql)
            [tButtons addObject:@"clear_cache"];
        
        [tButtons addObject:@"edit"];
        [tButtons addObject:@"delete"];
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
    tableButtons = tButtons;
}

- (void)updateLocalSqliteDbItem:(OASqliteDbResourceItem *)item
{
    [item updateSize];
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    
    [tKeys addObject:OALocalizedString(@"shared_string_type")];
    [tValues addObject:[OASQLiteTileSource isOnlineTileSource:item.path] ? OALocalizedString(@"online_raster_map") : OALocalizedString(@"offline_raster_map")];
    
    [tKeys addObject:OALocalizedString(@"shared_string_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]];
    
    NSError *error;
    NSURL *fileUrl = [NSURL fileURLWithPath:item.path];
    NSDate *d;
    [fileUrl getResourceValue:&d forKey:NSURLCreationDateKey error:&error];
    if (!error)
    {
        [tKeys addObject:OALocalizedString(@"created_on")];
        
        if (!formatter)
        {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }
        
        [tValues addObject:[NSString stringWithFormat:@"%@", [formatter stringFromDate:d]]];
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
    
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)initWithLocalOnlineSourceItem:(OAOnlineTilesResourceItem *)item
{
    self.localItem = item;
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    NSMutableArray *tButtons = [NSMutableArray array];
    
    // Type
    [tKeys addObject:OALocalizedString(@"shared_string_type")];
    [tValues addObject:OALocalizedString(@"online_map")];
    
    // Size
    [tKeys addObject:OALocalizedString(@"shared_string_size")];
    [tValues addObject:OALocalizedString(@"calculating_progress")];
    
    [tButtons addObject:@"clear_cache"];
    [tButtons addObject:@"edit"];
    [tButtons addObject:@"delete"];
    
    tableKeys = tKeys;
    tableValues = tValues;
    tableButtons = tButtons;
    
    [self calculateSizeAndUpdate:item];
}

- (void) calculateSizeAndUpdate:(OAOnlineTilesResourceItem *)item
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        NSString *size = [NSByteCountFormatter stringFromByteCount:[OAUtilities folderSize:item.path] countStyle:NSByteCountFormatterCountStyleFile];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSMutableArray *tKeys = [NSMutableArray array];
            NSMutableArray *tValues = [NSMutableArray array];
            
            // Type
            [tKeys addObject:OALocalizedString(@"shared_string_type")];
            [tValues addObject:OALocalizedString(@"online_map")];
            
            // Size
            [tKeys addObject:OALocalizedString(@"shared_string_size")];
            [tValues addObject:size];
            
            tableKeys = tKeys;
            tableValues = tValues;
            
            [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        });
    });
}

- (void)initWithLocalResourceId:(NSString*)resourceId
{
    [self inflateRootWithLocalResourceId:resourceId forRegion:nil];
}

- (void)initWithLocalResourceId:(NSString*)resourceId
                              forRegion:(OAWorldRegion*)region
{
    [self inflateRootWithLocalResourceId:resourceId forRegion:region];
}


- (void)inflateRootWithLocalResourceId:(NSString*)resourceId
                                      forRegion:(OAWorldRegion*)region
{
    _resourceId = resourceId;
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    NSMutableArray *tButtons = [NSMutableArray array];
    
    const auto& resource = [OsmAndApp instance].resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    const auto localResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource);
    if (!resource || !localResource)
        return;
    
    const auto installedResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(localResource);

    // Type
    [tKeys addObject:OALocalizedString(@"shared_string_type")];
    NSString *typeLocalized = [OAResourceType resourceTypeLocalized:localResource->type];
    if ([OAResourceType isSRTMResourceType:resource])
        typeLocalized = [NSString stringWithFormat:@"%@ (%@)", typeLocalized, [OAResourceType getSRTMFormatResource:resource longFormat:NO]];
    [tValues addObject:typeLocalized];

    // Size
    [tKeys addObject:OALocalizedString(@"shared_string_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:localResource->size countStyle:NSByteCountFormatterCountStyleFile]];

    if (installedResource)
    {
        // Timestamp
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:installedResource->timestamp / 1000];
        
        if (!formatter)
        {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }

        NSString *dateStr = [formatter stringFromDate:d];
        if (dateStr.length > 0)
        {
            [tKeys addObject:OALocalizedString(@"created_on")];
            [tValues addObject:[NSString stringWithFormat:@"%@", dateStr]];
        }
        [tButtons addObject:@"delete"];
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
    tableButtons = tButtons;
}

- (OAButtonTableViewCell *) getButtonCell:(NSString *)type
{
    OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAButtonTableViewCell *) nib[0];
        [cell leftIconVisibility:NO];
        [cell titleVisibility:NO];
        [cell descriptionVisibility:NO];
        cell.button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    }
    if (cell)
    {
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        if ([type isEqual:@"delete"])
        {
            [cell.button setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(deleteClicked) forControlEvents:UIControlEventTouchDown];
        }
        else if ([type isEqual:@"clear_cache"])
        {
            [cell.button setTitle:OALocalizedString(@"shared_string_clear_cache") forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(clearCacheClicked) forControlEvents:UIControlEventTouchDown];
        }
        else if ([type isEqual:@"edit"])
        {
            [cell.button setTitle:OALocalizedString(@"shared_string_edit") forState:UIControlStateNormal];
            [cell.button addTarget:self action:@selector(editClicked) forControlEvents:UIControlEventTouchDown];
        }
    }
    return cell;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return tableKeys.count;
    else
        return tableButtons.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedStringUp(@"shared_string_details");
    else
        return OALocalizedStringUp(@"shared_string_actions");
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        NSString *title = [tableKeys objectAtIndex:indexPath.row];
        NSString *subtitle = [tableValues objectAtIndex:indexPath.row];
        
        // Obtain reusable cell or create one
        OALocalResourceInfoCell* cell = [tableView dequeueReusableCellWithIdentifier:[OALocalResourceInfoCell getCellIdentifier]];
        if (cell == nil)
        {
            cell = [[OALocalResourceInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[OALocalResourceInfoCell getCellIdentifier]];
        }
            
        // Fill cell content
        cell.leftLabelView.text = title;
        cell.rightLabelView.text = subtitle;
        
        return cell;
    }
    else
    {
        return [self getButtonCell:tableButtons[indexPath.row]];
    }
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}


#pragma mark - OATilesEditingViewControllerDelegate

- (void) onTileSourceSaved:(OALocalResourceItem *)item
{
    if ([item isKindOfClass:OASqliteDbResourceItem.class])
    {
        OASqliteDbResourceItem *sqlite = (OASqliteDbResourceItem *)item;
        self.regionTitle = sqlite.title;
        [self initWithLocalSqliteDbItem:sqlite];
    }
    else if ([item isKindOfClass:OAOnlineTilesResourceItem.class])
    {
        OAOnlineTilesResourceItem *tileSource = (OAOnlineTilesResourceItem *)item;
        self.regionTitle = tileSource.title;
        [self initWithLocalOnlineSourceItem:tileSource];
    }
    
    [self.tableView reloadData];
}

@end
