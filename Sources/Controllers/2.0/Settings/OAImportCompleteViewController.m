//
//  OAImportComplete.m
//  OsmAnd
//
//  Created by nnngrach on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportCompleteViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAMultiIconTextDescCell.h"

#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"
#define kIconTitleButtonCell @"OAIconTitleButtonCell"

@interface OAImportCompleteViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAImportCompleteViewController
{
    NSArray<NSDictionary *> *_data;
    NSString *_importedFileName;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
}

- (void) generateData
{
    _data = [NSMutableArray new];
    [self generateFakeData];
}

- (void) generateFakeData
{
    //TODO: for now here is generating fake data, just for demo
    _importedFileName = @"Strikeline.ocf";
    
    _data = @[
        @{
            @"label": @"Quick Action",
            @"iconName": @"ic_custom_quick_action.png",
            @"count": @7
        },
         @{
             @"label": @"Map",
             @"iconName": @"ic_custom_overlay_map.png",
             @"count": @2
         },
         @{
             @"label": @"Settings",
             @"iconName": @"left_menu_icon_settings.png",
             @"count": @1
         },
         @{
             @"label": @"Search",
             @"iconName": @"ic_custom_search.png",
             @"count": @1
         }
     ];
}

- (void) applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"shared_string_import_complete");
}

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsSelection = NO;
    
    self.primaryBottomButton.hidden = YES;
    self.secondaryBottomButton.hidden = NO;
    [self.secondaryBottomButton setTitle:OALocalizedString(@"shared_string_finish") forState:UIControlStateNormal];
    
    self.additionalNavBarButton.hidden = YES;
    [super viewDidLoad];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self generateHeaderForTableView:tableView withFirstSessionText:[NSString stringWithFormat:OALocalizedString(@"import_complete_description"), _importedFileName] forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self generateHeightForHeaderWithFirstHeaderText:[NSString stringWithFormat:OALocalizedString(@"import_complete_description"), _importedFileName] inSection:section];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
      
    OAMultiIconTextDescCell *cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAMultiIconTextDescCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMultiIconTextDescCell" owner:self options:nil];
        cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
    }
    [cell.textView setText:item[@"label"]];
    NSString *countString = [NSString stringWithFormat:OALocalizedString(@"added_items"), item[@"count"]];
    [cell.descView setText:countString];
    cell.iconView.hidden = YES;
    cell.overflowButton.enabled = NO;
    [cell.overflowButton setImage:[[UIImage imageNamed:item[@"iconName"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateDisabled];
    [cell.overflowButton setTintColor:UIColorFromRGB(color_primary_purple)];
    [cell.overflowButton.imageView setContentMode:UIViewContentModeCenter];
    cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
    return cell;
}

- (IBAction)secondaryButtonPressed:(id)sender
{
    NSLog(@"secondaryButtonPressed");
}

@end
