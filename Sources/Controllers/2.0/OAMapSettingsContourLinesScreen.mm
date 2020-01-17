//
//  OAMapSettingsContourLinesScreen.m
//  OsmAnd Maps
//
//  Created by igor on 20.11.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapSettingsContourLinesScreen.h"
#import "OAMapSettingsViewController.h"
#import "OAMapStyleSettings.h"
#import "OASettingsTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "Localization.h"

#define kContourLinesDensity @"contourDensity"
#define kContourLinesWidth @"contourWidth"
#define kContourLinesColorScheme @"contourColorScheme"
#define kContourLinesZoomLevel @"contourLines"

@implementation OAMapSettingsContourLinesScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    OAMapStyleSettings *styleSettings;
    NSArray *parameters;
    
    NSMutableArray *arr;
    NSArray* data;
}


@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];

        settingsScreen = EMapSettingsScreenContourLines;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void) dealloc
{
    [self deinit];
}

- (void) commonInit
{
}

- (void) deinit
{
}

- (void) initData
{
}

- (void) setupView
{
    styleSettings = [OAMapStyleSettings sharedInstance];
    NSArray *tmpParameters = [styleSettings getAllParameters];
    NSMutableArray *tmpList = [NSMutableArray array];
    
    for (OAMapStyleParameter *p in tmpParameters)
    {
        if ([p.name isEqual: kContourLinesDensity] || [p.name isEqual: kContourLinesWidth] || [p.name isEqual: kContourLinesColorScheme] || [p.name isEqual: kContourLinesZoomLevel])
            [tmpList addObject: p];
    }
    NSSortDescriptor *sd = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    parameters = [tmpList sortedArrayUsingDescriptors:@[sd]];
    
    title = OALocalizedString(@"product_title_srtm");
    arr = [NSMutableArray array];
    [arr addObject:@{
        @"type" : @"switchCell"
    }];
    
    for (OAMapStyleParameter *p in parameters)
    {
        [arr addObject:@{
            @"type" : @"parameter",
            @"value": p
        }];
    }
    
    
    [tblView reloadData];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *d = arr[indexPath.row];
    if ([d[@"type"] isEqualToString: @"parameter"])
    {
        OAMapStyleParameter *p = d[@"value"];
        return [OASettingsTableViewCell getHeight: p.title value:[p getValueTitle] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

- (BOOL) isContourLinesOn
{
    OAMapStyleParameter *parameter = [styleSettings getParameter:@"contourLines"];
    return [parameter.value isEqual:@"disabled"] ? false : true;
}

- (NSString *) switchCellTitle
{
    if ([self isContourLinesOn])
        return OALocalizedString(@"shared_string_enabled");
    else
        return OALocalizedString(@"rendering_value_disabled_name");
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self isContourLinesOn])
        return arr.count;
    return 1;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *d = arr[indexPath.row];
    if ([d[@"type"] isEqualToString: @"parameter"])
    {
        OAMapStyleParameter *p = d[@"value"];
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            if ([p.name isEqualToString:@"contourLines"])
                [cell.textView setText:OALocalizedString(@"display_starting_at_zoom_level")];
            else
                [cell.textView setText:p.title];
    
            [cell.descriptionView setText:[p getValueTitle]];
        }
        
        return cell;
    }
    else
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText:[self switchCellTitle]];
            [cell.switchView setOn:[self isContourLinesOn]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(mapSettingSwitchChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }

}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kEstimatedRowHeight;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *d = arr[indexPath.row];
    if ([d[@"type"] isEqualToString: @"parameter"])
    {
        OAMapStyleParameter *p = d[@"value"];
        if (p.dataType != OABoolean)
        {
            OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenParameter param:p.name];

            [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];

            [tableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
    else
    {
        OAMapStyleParameter *parameter = [styleSettings getParameter:@"contourLines"];
        parameter.value = ![self isContourLinesOn] ? [_settings.contourLinesZoom get] : @"disabled";
        [styleSettings save:parameter];
        [tblView reloadData];
    }
}

- (void) mapSettingSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        OAMapStyleParameter *parameter = [styleSettings getParameter:@"contourLines"];
        parameter.value = switchView.isOn ? [_settings.contourLinesZoom get] : @"disabled";
        [styleSettings save:parameter];
    }
    [tblView reloadData];
}

@end
