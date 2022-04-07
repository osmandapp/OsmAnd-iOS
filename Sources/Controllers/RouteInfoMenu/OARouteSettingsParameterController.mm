//
//  OARouteSettingsParameterController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteSettingsParameterController.h"
#import "OARoutePreferencesParameters.h"
#import "OARoutingHelper.h"
#import "OAIconTextTableViewCell.h"
#import "OATableViewCustomFooterView.h"
#import "OAColors.h"

@interface OARouteSettingsParameterController ()

@end

@implementation OARouteSettingsParameterController
{
    OALocalRoutingParameterGroup *_group;
    NSInteger _indexSelected;
}

- (instancetype) initWithParameterGroup:(OALocalRoutingParameterGroup *) group
{
    self = [super init];
    if (self)
    {
        _group = group;
        _indexSelected = [[_group getRoutingParameters] indexOfObject:[_group getSelected]];
    }
    return self;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = _group.getText;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(10., 0., 0., 0.);
    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

- (void) setupView
{
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.tableView reloadData];
}

- (void)backButtonClicked:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneButtonPressed
{
    OALocalRoutingParameter *useElevation;
    if (_group.getRoutingParameters.count > 0
            && ([[NSString stringWithUTF8String:_group.getRoutingParameters.firstObject.routingParameter.id.c_str()] isEqualToString:kRouteParamIdHeightObstacles]))
        useElevation = _group.getRoutingParameters.firstObject;
    BOOL anySelected = NO;

    for (NSInteger i = 0; i < _group.getRoutingParameters.count; i++)
    {
        OALocalRoutingParameter *param = _group.getRoutingParameters[i];
        if (i == _indexSelected && param == useElevation)
            anySelected = YES;

        [param setSelected:i == _indexSelected && !anySelected];
    }
    if (useElevation)
        [useElevation setSelected:!anySelected];
    [self.routingHelper recalculateRouteDueToSettingsChange];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _group.getRoutingParameters.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OALocalRoutingParameter *param = _group.getRoutingParameters[indexPath.row];
    NSString *text = [param getText];
    UIImage *icon = [[param getIcon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIColor *color = [param getTintColor];

    OAIconTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OAIconTextTableViewCell *) nib[0];
    }
    
    if (cell)
    {
        [cell.textView setText:text];
        [cell showImage:icon != nil];
        cell.iconView.image = icon;
        if (indexPath.row == _indexSelected)
        {
            [cell.arrowIconView setImage:color
                    ? [UIImage templateImageNamed:@"menu_cell_selected"]
                    : [UIImage imageNamed:@"menu_cell_selected"]];

            if (color)
                cell.iconView.tintColor = color;
        }
        else
        {
            cell.iconView.tintColor = UIColorFromRGB(color_icon_inactive);
            [cell.arrowIconView setImage:nil];
        }

        if (color)
            cell.arrowIconView.tintColor = color;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _indexSelected = indexPath.row;
    [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
             withRowAnimation:UITableViewRowAnimationNone];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    OALocalRoutingParameter *param = _group.getRoutingParameters[_indexSelected];
    NSString *footer = [param getDescription];
    return [OATableViewCustomFooterView getHeight:footer ? footer : @"" width:self.tableView.bounds.size.width];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    OALocalRoutingParameter *param = _group.getRoutingParameters[_indexSelected];
    NSString *footer = [param getDescription];
    if (!footer || footer.length == 0)
        return nil;

    OATableViewCustomFooterView *vw =
            [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont systemFontOfSize:13];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:footer attributes:@{
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
    }];
    vw.label.attributedText = textStr;
    return vw;
}

@end
