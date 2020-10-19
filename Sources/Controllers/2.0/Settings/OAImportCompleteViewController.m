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

#define kSidePadding 16
#define kTopPadding 6
#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"
#define kIconTitleButtonCell @"OAIconTitleButtonCell"

@interface OAImportCompleteViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAImportCompleteViewController
{
    NSArray<NSDictionary *> *_data;
    NSString *_importedFileName;
    CGFloat _heightForHeader;
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
    UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width - OAUtilities.getLeftMargin * 2, _heightForHeader)];
    CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 6.0, textWidth, _heightForHeader)];
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    description.font = labelFont;
    [description setTextColor: UIColorFromRGB(color_text_footer)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    description.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:OALocalizedString(@"import_complete_description"), _importedFileName] attributes:@{NSParagraphStyleAttributeName : style}];
    description.numberOfLines = 0;
    [vw addSubview:description];
    return vw;

}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    _heightForHeader = [self heightForLabel:[NSString stringWithFormat:OALocalizedString(@"import_complete_description"), _importedFileName]];
    return _heightForHeader + kSidePadding + kTopPadding;
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
