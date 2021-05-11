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
#import "OAMenuSimpleCell.h"
#import "OASizes.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OAMapSource.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAMapCreatorHelper.h"
#import "OAResourcesUIHelper.h"


#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

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
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 48.;
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
    _data = [OAResourcesUIHelper getSortedRasterMapSources:YES];
    
    OAOnlineTilesResourceItem* itemNone = [[OAOnlineTilesResourceItem alloc] init];
    itemNone.mapSource = [[OAMapSource alloc] initWithResource:nil andVariant:[self getNoSourceItemId] name:[self getNoSourceName]];
    
    _data = [_data arrayByAddingObject:itemNone];
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
        OAOnlineTilesResourceItem* source = [self getItem:path];
        [arr addObject:@[source.mapSource.variant ,source.mapSource.name]];
    }
    
    if (self.delegate)
        [self.delegate onMapSourceSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

-(OAOnlineTilesResourceItem *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAOnlineTilesResourceItem* item = [self getItem:indexPath];
    OAMenuSimpleCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
        cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
        cell.descriptionView.hidden = YES;
    }
    
    if (cell)
    {
        UIImage *img = nil;
        img = [UIImage imageNamed:@"ic_custom_map_style"];
        
        cell.textView.text = item.mapSource.name;
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
    return OALocalizedString(@"available_map_sources");
}

@end
