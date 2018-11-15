//
//  OALocalResourceInformationViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OALocalResourceInformationViewController.h"

#import "OsmAndApp.h"
#include "Localization.h"
#import "OALocalResourceInfoCell.h"
#import "OAPurchasesViewController.h"
#import "OAPluginsViewController.h"
#import "OAUtilities.h"
#import "OAMapCreatorHelper.h"
#import "OASizes.h"

typedef OsmAnd::ResourcesManager::LocalResource OsmAndLocalResource;

@interface OALocalResourceInformationViewController ()<UITableViewDelegate, UITableViewDataSource> {
    
    NSArray *tableKeys;
    NSArray *tableValues;
    
    NSDateFormatter *formatter;
    
    NSString *_resourceId;
}

@end

@implementation OALocalResourceInformationViewController
{
    CALayer *_horizontalLine;
}

-(void)applyLocalization
{
    _titleView.text = OALocalizedString(@"res_details");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    
    [_btnToolbarMaps setTitle:OALocalizedString(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPlugins setTitle:OALocalizedString(@"plugins") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedString(@"purchases") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
    [OAUtilities layoutComplexButton:self.btnToolbarPlugins];
    [OAUtilities layoutComplexButton:self.btnToolbarPurchases];
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.toolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.toolbarView.layer addSublayer:_horizontalLine];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.regionTitle)
        self.titleView.text = self.regionTitle;

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [self applySafeAreaMargins:self.view.frame.size toolBarHeight:defaultToolBarHeight];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(UIView *) getBottomView
{
    return _toolbarView;
}

-(IBAction)backButtonClicked:(id)sender;
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)deleteButtonClicked:(id)sender;
{
    if (!_localItem)
        return;
    
    [self.baseController offerDeleteResourceOf:self.localItem executeAfterSuccess:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
    }];
}

- (void)initWithLocalSqliteDbItem:(SqliteDbResourceItem *)item;
{
    self.localItem = item;
    
    NSMutableArray *tKeys = [NSMutableArray array];
    NSMutableArray *tValues = [NSMutableArray array];
    
    // Type
    [tKeys addObject:OALocalizedString(@"res_type")];
    [tValues addObject:OALocalizedString(@"map_creator")];
    
    // Size
    [tKeys addObject:OALocalizedString(@"res_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:item.size countStyle:NSByteCountFormatterCountStyleFile]];
    
    // Timestamp
    NSError *error;
    NSURL *fileUrl = [NSURL fileURLWithPath:item.path];
    NSDate *d;
    [fileUrl getResourceValue:&d forKey:NSURLCreationDateKey error:&error];
    if (!error)
    {
        [tKeys addObject:OALocalizedString(@"res_created_on")];
        
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }
        
        [tValues addObject:[NSString stringWithFormat:@"%@", [formatter stringFromDate:d]]];
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
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
    
    const auto& resource = [OsmAndApp instance].resourcesManager->getLocalResource(QString::fromNSString(resourceId));
    const auto localResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::LocalResource>(resource);
    if (!resource || !localResource)
        return;
    
    const auto installedResource = std::dynamic_pointer_cast<const OsmAnd::ResourcesManager::InstalledResource>(localResource);

    // Type
    [tKeys addObject:OALocalizedString(@"res_type")];
    [tValues addObject:[OAResourcesBaseViewController resourceTypeLocalized:localResource->type]];

    // Size
    [tKeys addObject:OALocalizedString(@"res_size")];
    [tValues addObject:[NSByteCountFormatter stringFromByteCount:localResource->size countStyle:NSByteCountFormatterCountStyleFile]];

    if (installedResource)
    {
        // Timestamp
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:installedResource->timestamp / 1000];
        
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateStyle:NSDateFormatterShortStyle];
            [formatter setTimeStyle:NSDateFormatterShortStyle];
        }

        NSString *dateStr = [formatter stringFromDate:d];
        if (dateStr.length > 0)
        {
            [tKeys addObject:OALocalizedString(@"res_created_on")];
            [tValues addObject:[NSString stringWithFormat:@"%@", dateStr]];
        }
    }
    
    tableKeys = tKeys;
    tableValues = tValues;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableKeys.count;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return OALocalizedStringUp(@"res_details");
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const detailsCell = @"detailsCell";
    
    NSString* title = [tableKeys objectAtIndex:indexPath.row];
    NSString* subtitle = [tableValues objectAtIndex:indexPath.row];
    
    // Obtain reusable cell or create one
    OALocalResourceInfoCell* cell = [tableView dequeueReusableCellWithIdentifier:detailsCell];
    if (cell == nil)
    {
        cell = [[OALocalResourceInfoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:detailsCell];
    }
        
    // Fill cell content
    cell.leftLabelView.text = title;
    cell.rightLabelView.text = subtitle;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (IBAction)btnToolbarMapsClicked:(id)sender
{
}

- (IBAction)btnToolbarPluginsClicked:(id)sender
{
    OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
    pluginsViewController.openFromSplash = _openFromSplash;
    [self.navigationController pushViewController:pluginsViewController animated:NO];
}

- (IBAction)btnToolbarPurchasesClicked:(id)sender
{
    OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
    purchasesViewController.openFromSplash = _openFromSplash;
    [self.navigationController pushViewController:purchasesViewController animated:NO];
}

@end
