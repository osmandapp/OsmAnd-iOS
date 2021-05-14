//
//  OAPublicTransportOptionsBottomSheet.m
//  OsmAnd
//
//  Created by nnngrach on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAPublicTransportOptionsBottomSheet.h"
#import "OABottomSheetHeaderIconCell.h"
#import "OASettingSwitchCell.h"
#import "OAMapStyleSettings.h"
#import "Localization.h"
#import "OAColors.h"

#define kButtonsDividerTag 150

@interface OAPublicTransportOptionsBottomSheetScreen ()

@end

@implementation OAPublicTransportOptionsBottomSheetScreen
{
    OAMapStyleSettings* _styleSettings;
    OAPublicTransportOptionsBottomSheetViewController *vwController;
    NSArray* _data;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAPublicTransportOptionsBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAPublicTransportOptionsBottomSheetViewController *)viewController
{
    _styleSettings = [OAMapStyleSettings sharedInstance];
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{
        @"type" : @"OABottomSheetHeaderIconCell",
        @"title" : OALocalizedString(@"transport"),
        @"description" : @""
        }];
    
    
    NSArray* params = [_styleSettings getParameters:@"transport"];
    
    for (OAMapStyleParameter *param in params)
    {
        if (!param)
            continue;
        
        NSString* imageName = [self getIconNameForStyleName:param.name];
        
        [arr addObject:@{
            @"type" : @"OASettingSwitchCell",
            @"name" : param.name,
            @"title" : param.title,
            @"value" : param.value,
            @"img" : imageName,
            }];
    }
 
    _data = [NSArray arrayWithArray:arr];
    
    [vwController.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
}

- (NSString *) getIconNameForStyleName:(NSString *)name
{
    NSString* imageName = @"";
    if ([name isEqualToString:@"tramTrainRoutes"])
        imageName = @"ic_custom_transport_tram";
    else if ([name isEqualToString:@"subwayMode"])
        imageName = @"ic_custom_transport_subway";
    else if ([name isEqualToString:@"transportStops"])
        imageName = @"ic_custom_transport_stop";
    else if ([name isEqualToString:@"publicTransportMode"])
        imageName = @"ic_custom_transport_bus";
    
    return imageName;
}

- (BOOL) cancelButtonPressed
{
    return YES;
}

- (void) initData
{
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderIconCell"])
    {
        static NSString* const identifierCell = @"OABottomSheetHeaderIconCell";
        OABottomSheetHeaderIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OABottomSheetHeaderIconCell" owner:self options:nil];
            cell = (OABottomSheetHeaderIconCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.iconView.hidden = !cell.iconView.image;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OASettingSwitchCell"])
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
            [self updateSettingSwitchCell:cell data:item];
            
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            cell.switchView.on = [item[@"value"] isEqualToString:@"true"];
            [cell.switchView addTarget:self action:@selector(onSwitchClick:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (void) updateSettingSwitchCell:(OASettingSwitchCell *)cell data:(NSDictionary *)data
{
    UIImage *img = nil;
    NSString *imgName = data[@"img"];
    NSString *secondaryImgName = data[@"secondaryImg"];
    if (imgName)
        img = [UIImage templateImageNamed:imgName];
    
    cell.textView.text = data[@"title"];
    NSString *desc = data[@"description"];
    cell.descriptionView.text = desc;
    cell.descriptionView.hidden = desc.length == 0;
    cell.imgView.image = img;
    cell.imgView.tintColor = UIColorFromRGB(color_primary_purple);
    
    [cell setSecondaryImage:secondaryImgName.length > 0 ? [UIImage imageNamed:data[@"secondaryImg"]] : nil];
    if ([cell needsUpdateConstraints])
        [cell setNeedsUpdateConstraints];
}


- (void) onSwitchClick:(id)sender
{
    UISwitch *sw = (UISwitch *)sender;
    int position = (int)sw.tag;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:position inSection:0];
    NSString *name = [self getItem:indexPath][@"name"];
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapStyleParameter *p = [_styleSettings getParameter:name];
        if (p)
        {
            p.value = sw.on ? @"true" : @"false";
            [_styleSettings save:p];
        }
    });
}


#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 32.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:@"OASwitchCell"])
        return indexPath;
    else
        return nil;
}

@synthesize vwController;

@end



@interface OAPublicTransportOptionsBottomSheetViewController ()

@end

@implementation OAPublicTransportOptionsBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAPublicTransportOptionsBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:nil];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    [super hideDoneButton];
}

@end

