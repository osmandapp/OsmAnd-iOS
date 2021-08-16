//
//  OASettingsModalPresentationViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASettingsModalPresentationViewController.h"
#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@interface OASettingsModalPresentationViewController()

@end

@implementation OASettingsModalPresentationViewController

- (instancetype) initWithAppMode:(OAApplicationMode *)am
{
    self = [super initWithNibName:@"OASettingsModalPresentationViewController" bundle:nil];
    if (self)
    {
        _appMode = am;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) applyLocalization
{
    [super applyLocalization];
    _subtitleLabel.text = _appMode.toHumanString;
}

- (IBAction) cancelButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction) doneButtonPressed:(id)sender
{
}

- (UIView *) getTableHeaderViewWithText:(NSString *)text
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [self heightForLabel:text];
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight + kSidePadding)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, kSidePadding, textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                        attributes:@{NSParagraphStyleAttributeName : style,
                                                        NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                        NSFontAttributeName : [UIFont systemFontOfSize:15.0],
                                                        NSBackgroundColorAttributeName : UIColor.clearColor}];
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    tableHeaderView.backgroundColor = UIColor.clearColor;
    [tableHeaderView addSubview:label];
    return tableHeaderView;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return @"";
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (void) onSettingsChanged
{
    [_tableView reloadData];
}

@end
