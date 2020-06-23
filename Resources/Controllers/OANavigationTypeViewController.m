//
//  OANavigationTypeViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationTypeViewController.h"
#import "OAIconTextTableViewCell.h"
#import "OAButtonIconTableViewCell.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@interface OANavigationTypeViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OANavigationTypeViewController
{
    NSArray<NSArray *> *_data;
    UIView *_tableHeaderView;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
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
    
}

-(void) applyLocalization
{
    _titleLabel.text = OALocalizedString(@"nav_type_title");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self setupTableHeaderViewWithText:OALocalizedString(@"select_nav_profile_dialog_message")];
    [self setupView];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *osmandRoutingArr = [NSMutableArray array];
    NSMutableArray *desertArr = [NSMutableArray array];
    NSMutableArray *customRoutingArr = [NSMutableArray array];
    NSMutableArray *actionsArr = [NSMutableArray array];
    [osmandRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"m_style_bicycle"),
        @"selected" : @NO,
        @"icon" : @"ic_profile_bicycle",
    }];
    [osmandRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"app_mode_boat"),
        @"selected" : @NO,
        @"icon" : @"ic_action_sail_boat_dark",
    }];
    [osmandRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"m_style_car"),
        @"selected" : @YES,
        @"icon" : @"ic_profile_car",
    }];
    [osmandRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"m_style_pulic_transport"),
        @"selected" : @NO,
        @"icon" : @"ic_action_bus_dark",
    }];
    [osmandRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"rendering_value_pedestrian_name"),
        @"selected" : @NO,
        @"icon" : @"ic_profile_pedestrian",
    }];
    [osmandRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"app_mode_skiing"),
        @"selected" : @NO,
        @"icon" : @"ic_action_skiing",
    }];
    [osmandRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"nav_type_straight_line"),
        @"selected" : @NO,
        @"icon" : @"ic_custom_straight_line",
    }];
    
    [desertArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"desert"),
        @"selected" : @NO,
        @"icon" : @"ic_custom_navigation",
    }];
    
    [customRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"m_style_car"),
        @"selected" : @NO,
        @"icon" : @"ic_custom_navigation",
    }];
    [customRoutingArr addObject:@{
        @"type" : @"OAIconTextCell",
        @"title" : OALocalizedString(@"app_mode_boat"),
        @"selected" : @NO,
        @"icon" : @"ic_custom_navigation",
    }];
    
    [actionsArr addObject:@{
        @"type" : @"OAButtonIconTableViewCell",
        @"title" : OALocalizedString(@"import_from_files"),
        @"icon" : @"ic_custom_import",
    }];
    
    [tableData addObject:osmandRoutingArr];
    [tableData addObject:desertArr];
    [tableData addObject:customRoutingArr];
    [tableData addObject:actionsArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) setupTableHeaderViewWithText:(NSString *)text
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [self heightForLabel:text];
    _tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight + kSidePadding)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, kSidePadding, textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                        attributes:@{NSParagraphStyleAttributeName : style,
                                                        NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                        NSFontAttributeName : [UIFont systemFontOfSize:15.0],
                                                        NSBackgroundColorAttributeName : UIColor.clearColor}];
    label.textAlignment = NSTextAlignmentJustified;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableHeaderView.backgroundColor = UIColor.clearColor;
    [_tableHeaderView addSubview:label];
    _tableView.tableHeaderView = _tableHeaderView;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"select_nav_profile_dialog_message")];
        [_tableView reloadData];
    } completion:nil];
}

- (IBAction) backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - TableView

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:@"OAIconTextCell"])
    {
        static NSString* const identifierCell = @"OAIconTextCell";
        OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.arrowIconView.image = [[UIImage imageNamed:@"ic_checmark_default"]  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.arrowIconView.hidden = ![item[@"selected"] boolValue];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    if ([cellType isEqualToString:@"OAButtonIconTableViewCell"])
    {
        static NSString* const identifierCell = @"OAButtonIconTableViewCell";
        OAButtonIconTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAButtonIconTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.buttonView setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
        }
        return cell;
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return OALocalizedString(@"osmand_routing");
    else if (section == 1)
        return OALocalizedString(@"desert_xml");
    else if (section == 2)
        return OALocalizedString(@"routing_custom_xml");
    else if (section == 3)
        return OALocalizedString(@"actions");
    else
        return @"";
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 3)
        return OALocalizedString(@"import_routing_file_descr");
    else
        return @"";
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    CGFloat textWidth = _tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 0.0, textWidth, CGFLOAT_MAX)];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.font = labelFont;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 6.0;
    style.alignment = NSTextAlignmentCenter;
    label.attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName : style}];
    [label sizeToFit];
    return label.frame.size.height;
}

@end
