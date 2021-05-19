//
//  OAAvoidRoadsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAvoidPreferParametersViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAApplicationMode.h"
#import "OARouteProvider.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16

@interface OAAvoidPreferParametersViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAAvoidPreferParametersViewController
{
    NSArray<NSDictionary *> *_data;
    UIView *_tableHeaderView;
    
    BOOL _isAvoid;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode isAvoid:(BOOL)isAvoid
{
    self = [super initWithAppMode:appMode];
    if (self) {
        _isAvoid = isAvoid;
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    if (_isAvoid)
        self.titleLabel.text = OALocalizedString(@"impassable_road");
    else
        self.titleLabel.text = OALocalizedString(@"prefer_in_routing_title");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupTableHeaderViewWithText:OALocalizedString(@"avoid_routes_and_road")];
    [self setupView];
}

- (void) setupView
{
    NSMutableArray *dataArr = [NSMutableArray array];
    OAAppSettings* settings = [OAAppSettings sharedManager];
    auto router = [OsmAndApp.instance getRouter:self.appMode];
    NSString *prefix = _isAvoid ? @"avoid_" : @"prefer_";
    if (router)
    {
        auto& parameters = router->getParametersList();
        for (auto& p : parameters)
        {
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            if ([param hasPrefix:prefix])
            {
                NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
                OAProfileBoolean *value = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];

                [dataArr addObject:
                 @{
                   @"name" : param,
                   @"title" : title,
                   @"value" : value,
                   @"type" : [OASwitchTableViewCell getCellIdentifier] }
                 ];
            }
        }
    }
    _data = [NSArray arrayWithArray:dataArr];
}

+ (BOOL) hasPreferParameters:(OAApplicationMode *)appMode
{
    auto router = [OsmAndApp.instance getRouter:appMode];
    if (router)
    {
        auto& parameters = router->getParametersList();
        for (auto& p : parameters)
        {
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            if ([param hasPrefix:@"prefer_"])
                return YES;
        }
    }
    return NO;
}

- (NSString *) getRoutingStringPropertyName:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    return res;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderViewWithText:OALocalizedString(@"avoid_routes_and_road")];
        [self.tableView reloadData];
    } completion:nil];
}

- (IBAction) backButtonPressed:(id)sender
{
    [self dismissViewController];
}

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            id v = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            if ([v isKindOfClass:[OAProfileBoolean class]])
            {
                OAProfileBoolean *value = v;
                cell.switchView.on = [value get:self.appMode];
            }
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 17.0;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data.count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Switch

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = _data[indexPath.row];
        BOOL isChecked = ((UISwitch *) sender).on;
        id v = item[@"value"];
        if ([v isKindOfClass:[OAProfileBoolean class]])
        {
            OAProfileBoolean *value = v;
            [value set:isChecked mode:self.appMode];
        }
        if (self.delegate)
            [self.delegate onSettingsChanged];
    }
}

@end
