//
//  OAMoreOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 26/06/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAUploadProgressBottomSheetViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "OAMapWidgetRegistry.h"
#import "OAProducts.h"
#import "OAMapWidgetRegInfo.h"
#import "OASettingSwitchCell.h"
#import "OAOsmEditingPlugin.h"
#import "MaterialTextFields.h"
#import "OATextInputFloatingCell.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OATextEditingBottomSheetViewController.h"
#import "OAAppSettings.h"
#import "OAProgressBarCell.h"
#import "OAUploadOsmPointsAsyncTask.h"

#define kButtonsDividerTag 150

@interface OAUploadProgressBottomSheetScreen () <OAOsmMessageForwardingDelegate>

@end

@implementation OAUploadProgressBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAUploadProgressBottomSheetViewController *vwController;
    NSArray* _data;
    
    OAProgressBarCell *_pbCell;
    
    OAUploadOsmPointsAsyncTask *_uploadTask;
    
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAUploadProgressBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _uploadTask = param;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAUploadProgressBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    _pbCell = [self getProgressBarCell];
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
                     @"title" : OALocalizedString(@"osm_edit_uploading"),
                     @"description" : @"",
                     }];
    
    [arr addObject:@{
                     @"type" : @"OAProgressBarCell",
                     }];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) setProgress:(float)progress
{
    [_pbCell.progressBar setProgress:progress animated:YES];
}

- (OAProgressBarCell *) getProgressBarCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAProgressBarCell" owner:self options:nil];
    OAProgressBarCell *resultCell = (OAProgressBarCell *)[nib objectAtIndex:0];
    [resultCell.progressBar setProgress:0.0 animated:NO];
    [resultCell.progressBar setProgressTintColor:UIColorFromRGB(color_primary_purple)];
    resultCell.backgroundColor = [UIColor clearColor];
    resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return resultCell;
}

- (BOOL)cancelButtonPressed
{
    [_uploadTask setInterrupted:YES];
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

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
    {
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.sliderView.layer.cornerRadius = 3.0;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
            cell.titleView.text = item[@"title"];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OAProgressBarCell"])
    {
        return _pbCell;
    }
    else
    {
        return nil;
    }
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
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

@synthesize vwController;

# pragma mark OAOsmMessageForwardingDelegate

- (void) refreshData
{
    [self.tblView reloadData];
}

- (void) setMessageText:(NSString *)text
{
}

@end

@interface OAUploadProgressBottomSheetViewController ()

@end

@implementation OAUploadProgressBottomSheetViewController

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAUploadProgressBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void) setProgress:(float)progress
{
    if (self.screenObj)
    {
        OAUploadProgressBottomSheetScreen *screen = (OAUploadProgressBottomSheetScreen *) self.screenObj;
        [screen setProgress:progress];
    }
}

- (void)additionalSetup
{
    [super additionalSetup];
    [super hideDoneButton];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

@end
