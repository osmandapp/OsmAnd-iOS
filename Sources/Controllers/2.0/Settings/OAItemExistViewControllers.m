//
//  OAItemExistViewControllers.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAItemExistViewControllers.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6

@interface OAItemExistViewControllers () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAItemExistViewControllers
{
    NSArray<NSDictionary *> *_data;
    
    CGFloat _heightForHeader;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
    }
    return self;
}

- (void) applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"import_duplicates_title");
}

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.additionalNavBarButton.hidden = YES;
    [self setupBottomViewMultyLabelButtons];
    
    [super viewDidLoad];
}

- (void) setupBottomViewMultyLabelButtons
{
    self.primaryBottomButton.hidden = NO;
    self.secondaryBottomButton.hidden = NO;
    
    [self setToButton: self.secondaryBottomButton firstLabelText:OALocalizedString(@"keep_both") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:UIColorFromRGB(color_primary_purple) secondLabelText:OALocalizedString(@"keep_both_desc") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:UIColorFromRGB(color_icon_inactive)];
    
    [self setToButton: self.primaryBottomButton firstLabelText:OALocalizedString(@"replace_all") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:[UIColor whiteColor] secondLabelText:OALocalizedString(@"replace_all_desc") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5]];
}

- (NSArray<NSString *> *) getTestData
{
    return @[@"Driving", @"Add favorite", @"Add POI"];
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
    description.attributedText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"import_duplicates_description") attributes:@{NSParagraphStyleAttributeName : style}];
    description.numberOfLines = 0;
    [vw addSubview:description];
    return vw;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    _heightForHeader = [self heightForLabel:OALocalizedString(@"import_duplicates_description")];
    return _heightForHeader + kSidePadding + kTopPadding;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self getTestData].count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *text = [self getTestData][indexPath.row];
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    [cell.textLabel setText:text];
    return cell;
}



@end
