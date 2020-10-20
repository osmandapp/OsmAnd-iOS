//
//  OACheckForProfileDuplicatesViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACheckForProfileDuplicatesViewController.h"
#import "OAActivityViewWithTitleCell.h"
#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6
#define kBottomPadding 32
#define kCellTypeWithActivity @"OAActivityViewWithTitleCell"

@interface OACheckForProfileDuplicatesViewController() <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OACheckForProfileDuplicatesViewController
{
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
    return OALocalizedString(@"Preparing");
}

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.bottomBarView.hidden = YES;
    self.primaryBottomButton.hidden = YES;
    self.secondaryBottomButton.hidden = YES;
    self.additionalNavBarButton.hidden = YES;
    [super viewDidLoad];
}

#pragma mark - Table View

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        NSString *descriptionString = [NSString stringWithFormat:OALocalizedString(@"checking_for_duplicates_descr"), @"Strikelines.ocf"];
        CGFloat textWidth = tableView.bounds.size.width - 32;
        CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionString width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
        UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16., 8., textWidth, heightForHeader)];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        description.font = labelFont;
        [description setTextColor: UIColorFromRGB(color_text_footer)];
        description.attributedText = [OAUtilities getStringWithBoldPart:descriptionString mainString:[NSString stringWithFormat:OALocalizedString(@"checking_for_duplicates_descr"), @"Strikelines.ocf"] boldString:@"Strikelines.ocf" lineSpacing:4.];
        description.numberOfLines = 0;
        description.lineBreakMode = NSLineBreakByWordWrapping;
        description.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [vw addSubview:description];
        return vw;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        _heightForHeader = [self heightForLabel:OALocalizedString(@"checking_for_duplicates_descr")];
        return _heightForHeader + kBottomPadding + kTopPadding;
    }
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = kCellTypeWithActivity;
    OAActivityViewWithTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OAActivityViewWithTitleCell *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        cell.titleView.text = OALocalizedString(@"checking_for_duplicates");
        
        BOOL inProgress = YES; // to change
        if (inProgress)
        {
            cell.activityIndicatorView.hidden = NO;
            [cell.activityIndicatorView startAnimating];
        }
        else
        {
            cell.activityIndicatorView.hidden = YES;
            [cell.activityIndicatorView startAnimating];
        }
    }
    return cell;
}


@end
