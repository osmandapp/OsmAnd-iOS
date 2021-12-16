//
//  OAInfoBottomView.m
//  OsmAnd
//
//  Created by Paul on 03.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAInfoBottomView.h"
#import "OATitleIconRoundCell.h"
#import "Localization.h"

@interface OAInfoBottomView () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAInfoBottomView
{
    UIView *_tableHeaderView;
    
    EOABottomInfoViewType _type;
    
    NSArray *_data;
}

- (instancetype) initWithType:(EOABottomInfoViewType)type
{
    self = [super init];
    if (self) {
        _type = type;
        [self generateData];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [NSBundle.mainBundle loadNibNamed:@"OAInfoBottomView" owner:self options:nil];
    [self addSubview:_contentView];
    _contentView.frame = self.bounds;
    _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _leftButton.layer.cornerRadius = 9.;
    _rightButton.layer.cornerRadius = 9.;
    
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void) generateData
{
    switch (_type) {
        case EOABottomInfoViewTypeAddAfter:
        {
            _data = @[
                @{
                    @"type" : [OATitleIconRoundCell getCellIdentifier],
                    @"title" : OALocalizedString(@"add_one_more_pnt"),
                    @"img" : @"ic_custom_add_point_after"
                }
            ];
            break;
        }
        case EOABottomInfoViewTypeAddBefore:
        {
            _data = @[
                @{
                    @"type" : [OATitleIconRoundCell getCellIdentifier],
                    @"title" : OALocalizedString(@"add_one_more_pnt"),
                    @"img" : @"ic_custom_add_point_before"
                }
            ];
            break;
        }
        default:
        {
            _data = @[];
            break;
        }
    }
}

- (void)setHeaderViewText:(NSString *)headerViewText
{
    _headerViewText = headerViewText;
    _tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerViewText font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0.0 isTitle:NO];
    _tableView.tableHeaderView = _tableHeaderView;
}

- (CGFloat) getViewHeight
{
    return 57. + (_type == EOABottomInfoViewTypeMove ? _tableHeaderView.frame.size.height : _tableView.contentSize.height) + 60. + OAUtilities.getBottomMargin;
}

- (IBAction)leftButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate onLeftButtonPressed];
}
- (IBAction)rightButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate onRightButtonPressed];
}
- (IBAction)closeButtonPressed:(id)sender {
    if (self.delegate)
        [self.delegate onCloseButtonPressed];
}
    
#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        OATitleIconRoundCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OATitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconRoundCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data.count - 1)];
            cell.titleView.text = item[@"title"];
            
            
            cell.textColorNormal = nil;
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.titleView.textColor = UIColor.blackColor;
            cell.separatorView.hidden = indexPath.row == _data.count - 1;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count == 0 ? 0 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        if (_type == EOABottomInfoViewTypeAddBefore)
            [self.delegate onAddOneMorePointPressed:EOAAddPointModeBefore];
        else if (_type == EOABottomInfoViewTypeAddAfter)
            [self.delegate onAddOneMorePointPressed:EOAAddPointModeAfter];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        return [OATitleIconRoundCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    return UITableViewAutomaticDimension;
}

@end
