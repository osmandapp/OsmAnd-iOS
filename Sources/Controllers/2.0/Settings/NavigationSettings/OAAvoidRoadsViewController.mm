//
//  OAAvoidRoadsViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 24.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAvoidRoadsViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kCellTypeSwitch @"OASwitchCell"

@interface OAAvoidRoadsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAAvoidRoadsViewController
{
    NSArray<NSArray *> *_data;
    UIView *_tableHeaderView;
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
}

- (void) applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"impassable_road");
    self.subtitleLabel.text = OALocalizedString(@"app_mode_car");
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
    auto router = [self getRouter:[OAApplicationMode CAR]]; // taken from OANavigationSettingsViewController
    if (router)
    {
        auto& parameters = router->getParametersList();
        for (auto& p : parameters)
        {
            NSString *param = [NSString stringWithUTF8String:p.id.c_str()];
            if ([param hasPrefix:@"avoid_"])
            {
                NSString *paramId = [NSString stringWithUTF8String:p.id.c_str()];
                NSString *title = [self getRoutingStringPropertyName:paramId defaultName:[NSString stringWithUTF8String:p.name.c_str()]];
                OAProfileBoolean *value = [settings getCustomRoutingBooleanProperty:paramId defaultValue:p.defaultBoolean];

                [dataArr addObject:
                 @{
                   @"name" : param,
                   @"title" : title,
                   @"value" : value,
                   @"type" : kCellTypeSwitch }
                 ];
            }
        }
    }
    _data = [NSArray arrayWithObject:dataArr];
}

- (std::shared_ptr<GeneralRouter>) getRouter:(OAApplicationMode *)am
{
    OsmAndAppInstance app = [OsmAndApp instance];
    auto router = app.defaultRoutingConfig->getRouter([am.stringKey UTF8String]);
    if (!router && am.parent)
        router = app.defaultRoutingConfig->getRouter([am.parent.stringKey UTF8String]);
    
    return router;
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

#pragma mark - TableView

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = kCellTypeSwitch;
        OASwitchTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.switchView.on = [item[@"isOn"] boolValue];
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
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
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
}

@end
