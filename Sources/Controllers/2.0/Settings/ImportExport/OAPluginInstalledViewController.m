//
//  OAPluginInstalledViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 22.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPluginInstalledViewController.h"
#import "OATextViewSimpleCell.h"
#import "OAPlugin.h"
#import "OAColors.h"
#import "Localization.h"

#define kSidePadding 20.0
#define kTopPadding 6
#define kBottomPadding 32
#define kIconWidth 48

@interface OAPluginInstalledViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *disableButton;
@property (weak, nonatomic) IBOutlet UIButton *enableButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@end

@implementation OAPluginInstalledViewController
{
    NSString *_pluginId;
    OAPlugin *_plugin;
    
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype) initWithPluginId:(NSString *)pluginId
{
    self = [super init];
    if (self) {
        _pluginId = pluginId;
        _plugin = [OAPlugin getPluginById:_pluginId];
    }
    return self;
}

- (void)applyLocalization
{
    [self.closeButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.enableButton setTitle:OALocalizedString(@"shared_string_enable") forState:UIControlStateNormal];
    [self.disableButton setTitle:OALocalizedString(@"shared_string_disable") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.enableButton.layer.cornerRadius = 9.;
    self.disableButton.layer.cornerRadius = 9.;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.tableHeaderView = [self getHeaderForTableView:self.tableView withFirstSectionText:self.descriptionText boldFragment:self.descriptionBoldText];
    
    [self setupView];
}

- (NSString *)descriptionText
{
    return OALocalizedString(@"new_plugin_added");
}

- (NSString *)descriptionBoldText
{
    return _plugin.getName;
}

- (void) setupView
{
    [self generateData];
}

- (void) generateData
{
    NSMutableArray *sectionData = [NSMutableArray new];
    [sectionData addObject:@{
        @"type" : [OATextViewSimpleCell getCellIdentifier],
        @"text" : _plugin.getDescription
    }];
    _data = @[sectionData];
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [self getHeaderForTableView:self.tableView withFirstSectionText:self.descriptionText boldFragment:self.descriptionBoldText];
        [self.tableView reloadData];
    } completion:nil];
}

- (IBAction)onDisablePressed:(UIButton *)sender
{
    if (_plugin)
        [OAPlugin enablePlugin:_plugin enable:NO];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onEnablePressed:(id)sender
{
    if (_plugin)
        [OAPlugin enablePlugin:_plugin enable:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

// MARK: UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewSimpleCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.textView.attributedText = [OAUtilities attributedStringFromHtmlString:item[@"text"] fontSize:17];
            cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
            [cell.textView sizeToFit];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (UIView *) getHeaderForTableView:(UITableView *)tableView withFirstSectionText:(NSString *)text boldFragment:(NSString *)boldFragment
{
    NSString *descriptionText;
    if (boldFragment && boldFragment.length > 0)
        descriptionText = [NSString stringWithFormat:@"%@\n\n%@", text, boldFragment];
    else
        descriptionText = text;
    NSAttributedString *attrString;
    if (boldFragment && boldFragment.length > 0)
    {
        attrString = [OAUtilities getStringWithBoldPart:descriptionText mainString:text boldString:boldFragment lineSpacing:4. fontSize:17. boldFontSize:34. boldColor:UIColor.blackColor mainColor:UIColorFromRGB(color_text_footer)];
    }
    else
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        attrString = [[NSAttributedString alloc] initWithString:descriptionText attributes:@{NSParagraphStyleAttributeName : style}];
    }
    return [OAUtilities setupTableHeaderViewWithText:attrString tintColor:UIColor.whiteColor icon:_plugin.getLogoResource iconFrameSize:48. iconBackgroundColor:UIColorFromRGB(color_primary_purple) iconContentMode:UIViewContentModeScaleAspectFit];
}

@end
