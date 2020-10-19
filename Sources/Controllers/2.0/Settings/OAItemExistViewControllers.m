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
#import "OAApplicationMode.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickActionType.h"
#import "OAQuickAction.h"
#import "OAMenuSimpleCell.h"
#import "OAIconTitleButtonCell.h"
#import "OAImportCompleteViewController.h"

#define kSidePadding 16
#define kTopPadding 6
#define kMenuSimpleCell @"OAMenuSimpleCell"
#define kMenuSimpleCellNoIcon @"OAMenuSimpleCellNoIcon"
#define kIconTitleButtonCell @"OAIconTitleButtonCell"

@interface OAItemExistViewControllers () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAItemExistViewControllers
{
    NSMutableArray<NSMutableArray<NSDictionary *> *> *_data;
    NSArray<OAApplicationMode *> * _profileList;
    NSArray<OAQuickActionType *> *_quickActionsList;
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

- (void) generateFakeData
{
    //TODO: for now here is generating fake data, just for demo
    _data = [NSMutableArray new];
    _profileList = [NSArray arrayWithObject:OAApplicationMode.CAR];
    NSArray<OAQuickActionType *> *allQuickActions = [[OAQuickActionRegistry sharedInstance] produceTypeActionsListWithHeaders];
    _quickActionsList = [allQuickActions subarrayWithRange:NSMakeRange(1,2)];
}

- (void) generateData
{
    [self generateFakeData];
    
    if (_profileList.count > 0)
    {
        NSMutableArray<NSDictionary *> *profileItems = [NSMutableArray new];
        [profileItems addObject: @{
            @"type": @"header",
            @"label": OALocalizedString(@"shared_string_profiles"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_profiles") lowerCase]]
        }];
        for (OAApplicationMode *profile in _profileList)
        {
            [profileItems addObject: @{
                @"type": @"profile",
                @"label": profile.toHumanString,
                @"description": profile.getProfileDescription,
                @"icon": profile.getIcon,
                @"iconColor": UIColorFromRGB(profile.getIconColor)
            }];
        }
        [_data addObject:profileItems];
    }
    
    if (_quickActionsList.count > 0)
    {
        NSMutableArray<NSDictionary *> *quickActionsItems = [NSMutableArray new];
        [quickActionsItems addObject: @{
            @"type": @"header",
            @"label": OALocalizedString(@"shared_string_quick_actions"),
            @"description": [NSString stringWithFormat:OALocalizedString(@"listed_exist"), [OALocalizedString(@"shared_string_quick_actions") lowerCase]]
        }];
        for (OAQuickActionType *action in _quickActionsList)
        {
            [quickActionsItems addObject: @{
                @"type": @"quickAction",
                @"label": action.name,
                @"iconName": action.iconName,
                @"secondaryIconName": action.hasSecondaryIcon ? [action createNew].getSecondaryIconName : @""
            }];
        }
        [_data addObject:quickActionsItems];
    }
};

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
    self.tableView.allowsSelection = NO;
    
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

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
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
    else
    {
        return nil;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        _heightForHeader = [self heightForLabel:OALocalizedString(@"import_duplicates_description")];
        return _heightForHeader + kSidePadding + kTopPadding;
    }
    else
    {
        return UITableViewAutomaticDimension;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"header"])
    {
        return 56.;
    }
    else if ([item[@"type"] isEqualToString:@"profile"])
    {
        return 60.;
    }
    else if ([item[@"type"] isEqualToString:@"quickAction"])
    {
        return 44.;
    }
    else
    {
        return 48.;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"header"])
    {
        NSString* const identifierCell = kMenuSimpleCellNoIcon;
        OAMenuSimpleCell* cell;
        cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCellNoIcon owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 0.0);
        }
        cell.textView.text = item[@"label"];
        cell.descriptionView.text = item[@"description"];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"profile"])
    {
        NSString* const identifierCell = kMenuSimpleCell;
        OAMenuSimpleCell* cell;
        cell = (OAMenuSimpleCell *)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMenuSimpleCell owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62., 0.0, 0.0);
        }
        cell.textView.text = item[@"label"];
        cell.descriptionView.text = item[@"description"];
        cell.imgView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        //cell.imgView.tintColor = item[@"iconColor"];
        cell.imgView.tintColor = UIColorFromRGB(color_chart_orange);
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"quickAction"])
    {
        NSString* const identifierCell = kIconTitleButtonCell;
        OAIconTitleButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTitleButtonCell" owner:self options:nil];
            cell = (OAIconTitleButtonCell *)[nib objectAtIndex:0];
        }
        cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
        cell.titleView.text = item[@"label"];
        cell.iconView.image = [UIImage imageNamed:item[@"iconName"]];
        if (cell.iconView.subviews.count > 0)
            [[cell.iconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        NSString* secondaryIconName = item[@"secondaryIconName"];
        if (secondaryIconName.length > 0)
        {
            CGRect frame = CGRectMake(0., 0., cell.iconView.frame.size.width, cell.iconView.frame.size.height);
            UIImage *imgBackground = [[UIImage imageNamed:@"ic_custom_compound_action_background"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
            [background setTintColor:UIColor.whiteColor];
            [cell.iconView addSubview:background];
            UIImage *img = [UIImage imageNamed:item[@"secondaryIconName"]];
            UIImageView *view = [[UIImageView alloc] initWithImage:img];
            view.frame = frame;
            [cell.iconView addSubview:view];
        }
        cell.buttonView.hidden = YES;
        cell.buttonView.imageEdgeInsets = UIEdgeInsetsMake(0., cell.buttonView.frame.size.width - 30, 0, 0);
        return cell;
    }
}

- (IBAction)primaryButtonPressed:(id)sender
{
    NSLog(@"primaryButtonPressed");
    OAImportCompleteViewController* importComplete = [[OAImportCompleteViewController alloc] init];
    [self.navigationController pushViewController:importComplete animated:YES];
}

- (IBAction)secondaryButtonPressed:(id)sender
{
    NSLog(@"secondaryButtonPressed");
}

@end
