//
//  OAImportGPXBottomSheetViewController.mm
//  OsmAnd
//
//  Created by Paul on 23/11/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAImportGPXBottomSheetViewController.h"
#import "Localization.h"
#import "OAMenuSimpleCell.h"
#import "OAWaypointHeaderCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@interface OAImportGPXBottomSheetScreen ()

@end


@implementation OAImportGPXBottomSheetScreen
{
    OsmAndAppInstance _app;
    
    id<OAGPXImportDelegate> _gpxImportDelegate;
    
    NSArray* _data;
}

@synthesize tableData, vwController, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAImportGPXBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController param:param];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAImportGPXBottomSheetViewController *)viewController param:(id<OAGPXImportDelegate>)param
{
    _app = [OsmAndApp instance];
    
    _gpxImportDelegate = param;
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    NSMutableArray *arr = [NSMutableArray array];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"gpx_import_desc"),
                      @"key" : @"gpx_import_desc",
                      @"type" : @"OAWaypointHeaderCell" } ];
    
    [arr addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"import_from_docs"),
                      @"key" : @"import_from_docs",
                      @"img" : @"favorite_import_icon",
                      @"type" : [OAMenuSimpleCell getCellIdentifier] } ];

    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 44.0, 4.0, 0.0)];
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
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

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
//            cell.textView.textColor = UIColorFromRGB(color_menu_button);
            cell.descriptionView.textColor = UIColorFromRGB(color_secondary_text_blur);
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [UIImage imageNamed:imgName];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            cell.imgView.image = img;
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OAWaypointHeaderCell"])
    {
        static NSString* const identifierCell = @"OAWaypointHeaderCell";
        OAWaypointHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWaypointHeaderCell" owner:self options:nil];
            cell = (OAWaypointHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.progressView.hidden = YES;
            cell.switchView.hidden = YES;
            cell.imageButton.hidden = YES;
            cell.textButton.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            NSString *text = item[@"title"];
            cell.titleView.text = text;
            cell.titleView.lineBreakMode = NSLineBreakByWordWrapping;
            cell.titleView.numberOfLines = 0;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 0.0, 4.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"import_from_docs"])
        [_gpxImportDelegate importAllGPXFromDocuments];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [vwController dismiss];
}

@end

@interface OAImportGPXBottomSheetViewController ()

@end

@implementation OAImportGPXBottomSheetViewController

- (instancetype) initWithDelegate:(id<OAGPXImportDelegate>)gpxImportDelegate
{
    return [super initWithParam:gpxImportDelegate];
}

- (id<OAGPXImportDelegate>) gpxImportDelegate
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAImportGPXBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.gpxImportDelegate];
    
    [super setupView];
}

@end
