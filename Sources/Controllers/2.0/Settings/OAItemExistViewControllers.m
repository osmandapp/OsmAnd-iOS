//
//  OAItemExistViewControllers.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAItemExistViewControllers.h"
#import "OAAppSettings.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6

@interface OAItemExistViewControllers () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAItemExistViewControllers
{
    OAAppSettings *_settings;
    NSArray<NSDictionary *> *_data;
    
    CGFloat _heightForHeader;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (void) applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"import_profile_exists_header");
}

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self setupBottomViewButtons];
    self.additionalNavBarButton.hidden = YES;
    
    [super viewDidLoad];
}

- (void) setupBottomViewButtons
{
    self.primaryBottomButton.hidden = NO;
    self.secondaryBottomButton.hidden = NO;
    
    [self setToButton: self.secondaryBottomButton firstLabelText:OALocalizedString(@"import_profile_exists_keep_booth") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:UIColorFromRGB(color_primary_purple) secondLabelText:OALocalizedString(@"import_profile_exists_keep_booth_descr") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:UIColorFromRGB(color_icon_inactive)];
    
    [self setToButton: self.primaryBottomButton firstLabelText:OALocalizedString(@"import_profile_exists_keep_replace") firstLabelFont:[UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] firstLabelColor:[UIColor whiteColor] secondLabelText:OALocalizedString(@"import_profile_exists_keep_replace_descr") secondLabelFont:[UIFont systemFontOfSize:13] secondLabelColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5]];
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
    description.attributedText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"import_profile_exists_descr") attributes:@{NSParagraphStyleAttributeName : style}];
    description.numberOfLines = 0;
    [vw addSubview:description];
    return vw;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    _heightForHeader = [self heightForLabel:OALocalizedString(@"import_profile_exists_descr")];
    return _heightForHeader + kSidePadding + kTopPadding;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return [[UITableViewCell alloc] init];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

@end
