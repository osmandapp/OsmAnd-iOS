//
//  OAConfigureMenuMainScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAConfigureMenuMainScreen.h"
#import "OAConfigureMenuViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAAppModeCell.h"
#import "OAMapWidgetRegInfo.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import "OASettingSwitchCell.h"

@interface OAConfigureMenuMainScreen () <OAAppModeCellDelegate>

@end

@implementation OAConfigureMenuMainScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    
    OAAppModeCell *_appModeCell;
}

@synthesize configureMenuScreen, tableData, vwController, tblView, title;

- (id) initWithTable:(UITableView *)tableView viewController:(OAConfigureMenuViewController *)viewController
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
        
        title = OALocalizedString(@"layer_map_appearance");
        configureMenuScreen = EConfigureMenuScreenMain;
        
        vwController = viewController;
        tblView = tableView;
        //tblView.separatorInset = UIEdgeInsetsMake(0, 44, 0, 0);
        
        [self initData];
    }
    return self;
}

- (void) initData
{
}

- (void) setupView
{
    [self setupViewInternal];
    [tblView reloadData];
}

- (void) setupViewInternal
{
    NSMutableDictionary *sectionMapStyle = [NSMutableDictionary dictionary];
    [sectionMapStyle setObject:@"OAAppModeCell" forKey:@"type"];
    
    NSMutableArray *arr = [NSMutableArray array];
    
    NSDictionary *mapStyles = @{ @"groupName" : @"",
                                 @"cells" : @[sectionMapStyle]
                                 };
    [arr addObject:mapStyles];
    
    // Right panel
    NSMutableArray *controlsList = [NSMutableArray array];
    NSArray *controls = @[ @{ @"groupName" : OALocalizedString(@"map_widget_right"),
                              @"cells" : controlsList,
                              } ];
    
    [self addControls:controlsList widgets:[_mapWidgetRegistry getRightWidgetSet] mode:_settings.applicationMode];
    
    if (controlsList.count > 0)
        [arr addObjectsFromArray:controls];
    
    // Left panel
    controlsList = [NSMutableArray array];
    controls = @[ @{ @"groupName" : OALocalizedString(@"map_widget_left"),
                     @"cells" : controlsList,
                     } ];
    
    [self addControls:controlsList widgets:[_mapWidgetRegistry getLeftWidgetSet] mode:_settings.applicationMode];
    
    if (controlsList.count > 0)
        [arr addObjectsFromArray:controls];
    
    tableData = [NSArray arrayWithArray:arr];
}

- (void) addControls:(NSMutableArray *)controlsList widgets:(NSOrderedSet<OAMapWidgetRegInfo *> *)widgets mode:(OAApplicationMode *)mode
{
    for (OAMapWidgetRegInfo *r in widgets)
    {
        if (![mode isWidgetAvailable:r.key])
            continue;
        
        BOOL selected = [r visibleCollapsed:mode] || [r visible:mode];
        NSString *collapsedStr = OALocalizedString(@"shared_string_collapse");
        
        [controlsList addObject:@{ @"title" : [r getMessage],
                                   @"description" : [r visibleCollapsed:mode] ? collapsedStr : @"",
                                   @"key" : r.key,
                                   @"img" : [r getImageId],
                                   @"selected" : @(selected),
                                   @"color" : selected ? UIColorFromRGB(0xff8f00) : [NSNull null],
                                   @"secondaryImg" : r.widget ? @"ic_action_additional_option" : [NSNull null],
                                   
                                   @"type" : @"OASettingSwitchCell"} ];
    }
}

- (BOOL) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
    [self setVisibility:indexPath visible:sw.on collapsed:NO];
    [tblView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    return NO;
}

- (void) setVisibility:(NSIndexPath *)indexPath visible:(BOOL)visible collapsed:(BOOL)collapsed
{
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    NSString *key = data[@"key"];
    if (key)
    {
        OAMapWidgetRegInfo *r = [_mapWidgetRegistry widgetByKey:key];
        if (r)
        {
            [_mapWidgetRegistry setVisibility:r visible:visible collapsed:collapsed];
            [[OARootViewController instance].mapPanel recreateControls];

            [self setupViewInternal];
            
            //NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
            //[self updateSettingSwitchCell:[tblView cellForRowAtIndexPath:indexPath] data:data];
        }
    }
}

#pragma mark - OAAppModeCellDelegate

- (void) appModeChanged:(OAApplicationMode *)mode
{
    [vwController waitForIdle];
    _settings.applicationMode = mode;
    [self setupView];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return tableData.count;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return tableData[section][@"groupName"];
}


- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [tableData[section][@"cells"] count];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    if ([data[@"type"] isEqualToString:@"OAAppModeCell"])
    {
        return 44.0;
    }
    else if ([data[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        return [OASettingSwitchCell getHeight:data[@"title"] desc:data[@"description"] hasSecondaryImg:data[@"secondaryImg"] != [NSNull null] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    
    UITableViewCell* outCell = nil;
    if ([data[@"type"] isEqualToString:@"OAAppModeCell"])
    {
        if (!_appModeCell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAAppModeCell" owner:self options:nil];
            _appModeCell = (OAAppModeCell *)[nib objectAtIndex:0];
            _appModeCell.showDefault = YES;
            _appModeCell.selectedMode = [OAAppSettings sharedManager].applicationMode;
            _appModeCell.delegate = self;
        }
        
        outCell = _appModeCell;
    }
    else if ([data[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [self updateSettingSwitchCell:cell data:data];
            
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = ((NSNumber *)data[@"selected"]).boolValue;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    
    return outCell;
}

- (void) updateSettingSwitchCell:(OASettingSwitchCell *)cell data:(NSDictionary *)data
{
    UIImage *img = nil;
    NSString *imgName = data[@"img"];
    if (imgName)
    {
        UIColor *color = nil;
        if (data[@"color"] != [NSNull null])
            color = data[@"color"];
        
        if (color)
            img = [OAUtilities tintImageWithColor:[UIImage imageNamed:imgName] color:color];
        else
            img = [UIImage imageNamed:imgName];
    }
    
    cell.textView.text = data[@"title"];
    NSString *desc = data[@"description"];
    cell.descriptionView.text = desc;
    cell.descriptionView.hidden = desc.length == 0;
    cell.imgView.image = img;
    cell.secondaryImgView.image = data[@"secondaryImg"] != [NSNull null] ? [UIImage imageNamed:data[@"secondaryImg"]] : nil;
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSDictionary* data = tableData[section][@"cells"][0];
    if ([data[@"type"] isEqualToString:@"OAAppModeCell"])
        return 0.01;
    else
        return 34.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAConfigureMenuViewController *configureMenuViewController;
    NSDictionary* data = tableData[indexPath.section][@"cells"][indexPath.row];
    if ([data[@"type"] isEqualToString:@"OASettingSwitchCell"])
    {
        configureMenuViewController = [[OAConfigureMenuViewController alloc] initWithConfigureMenuScreen:EConfigureMenuScreenVisibility param:data[@"key"]];
    }
    
    if (configureMenuViewController)
        [configureMenuViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
