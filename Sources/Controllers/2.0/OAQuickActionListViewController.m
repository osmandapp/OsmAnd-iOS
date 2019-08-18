//
//  OAQuickActionListViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionListViewController.h"
#import "OAActionConfigurationViewController.h"
#import "OAAddQuickActionViewController.h"
#import "Localization.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickActionFactory.h"
#import "OAQuickAction.h"
#import "MGSwipeButton.h"
#import "OATitleDescrDraggableCell.h"
#import "OASizes.h"
#import "OAColors.h"

@interface OAQuickActionListViewController () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *btnAdd;
@property (weak, nonatomic) IBOutlet UIButton *btnEdit;


@end

@implementation OAQuickActionListViewController
{
    OAQuickActionRegistry *_registry;
    NSMutableArray<OAQuickAction *> *_data;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.backBtn setImage:[[UIImage imageNamed:@"ic_navbar_chevron"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.backBtn setTintColor:UIColor.whiteColor];
    [self.btnAdd setImage:[[UIImage imageNamed:@"ic_custom_plus"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.btnAdd setTintColor:UIColor.whiteColor];
    [self.btnEdit setImage:[[UIImage imageNamed:@"ic_custom_edit"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.btnEdit setTintColor:UIColor.whiteColor];
   
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
}

-(void) commonInit
{
    _registry = [OAQuickActionRegistry sharedInstance];
    _data = [NSMutableArray arrayWithArray:_registry.getQuickActions];
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"quick_action_name");
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (IBAction)backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveChanges
{
    [_registry updateQuickActions:[NSArray arrayWithArray:_data]];
    [_registry.quickActionListChangedObservable notifyEvent];
}

- (IBAction)editPressed:(id)sender
{
    [self.tableView beginUpdates];
    BOOL shouldEdit = ![self.tableView isEditing];
    [self.tableView setEditing:shouldEdit animated:YES];
    if (!shouldEdit)
    {
        [self saveChanges];
    }
    [self.tableView endUpdates];
}

- (IBAction)addActionPressed:(id)sender
{
    OAAddQuickActionViewController *vc = [[OAAddQuickActionViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void) openQuickActionSetupFor:(NSIndexPath *)indexPath
{
    OAQuickAction *item = [self getAction:indexPath];
    OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithAction:item isNew:NO];
    [self.navigationController pushViewController:actionScreen animated:YES];
}

- (NSInteger)getScreensCount
{
    NSInteger numOfItems = _data.count;
    BOOL oneSection = numOfItems / 6 < 1;
    BOOL hasRemainder = numOfItems % 6 != 0;
    if (oneSection)
        return 1;
    else
        return (numOfItems / 6) + (hasRemainder ? 1 : 0);
}

- (OAQuickAction *) getAction:(NSIndexPath *)indexPath
{
    return _data[6 * indexPath.section + indexPath.row];
}


#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_tableView.isEditing)
        [self openQuickActionSetupFor:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    OAQuickAction *sourceAction = [self getAction:sourceIndexPath];
    OAQuickAction *destAction = [self getAction:destinationIndexPath];
    [_data setObject:sourceAction atIndexedSubscript:destinationIndexPath.section * 6 + destinationIndexPath.row];
    [_data setObject:destAction atIndexedSubscript:sourceIndexPath.section * 6 + sourceIndexPath.row];
    [_tableView reloadData];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.isEditing;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [_data removeObject:[self getAction:indexPath]];
        [tableView reloadData];
        [self saveChanges];
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAQuickAction *action = [self getAction:indexPath];
    OATitleDescrDraggableCell* cell = (OATitleDescrDraggableCell *)[tableView dequeueReusableCellWithIdentifier:@"OATitleDescrDraggableCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATitleDescrDraggableCell" owner:self options:nil];
        cell = (OATitleDescrDraggableCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText:action.getName];
        [cell.descView setText:@""];
        [cell.iconView setImage:[UIImage imageNamed:action.getIconResName]];
        if (cell.iconView.subviews.count > 0)
            [[cell.iconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
        
        if (action.hasSecondaryIcon)
        {
            CGRect frame = CGRectMake(0., 0., cell.iconView.frame.size.width, cell.iconView.frame.size.height);
            UIImage *imgBackground = [[UIImage imageNamed:@"ic_custom_compound_action_background"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
            [background setTintColor:UIColor.whiteColor];
            [cell.iconView addSubview:background];
            UIImage *img = [UIImage imageNamed:action.getSecondaryIconName];
            UIImageView *view = [[UIImageView alloc] initWithImage:img];
            view.frame = frame;
            [cell.iconView addSubview:view];
        }
        cell.delegate = self;
        cell.leftButtons = nil;
        cell.rightButtons = nil;
        cell.allowsSwipeWhenEditing = YES;
        [cell.overflowButton setImage:[[UIImage imageNamed:@"menu_cell_pointer.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [cell.overflowButton setTintColor:UIColorFromRGB(color_tint_gray)];
        [cell.overflowButton.imageView setContentMode:UIViewContentModeCenter];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self getScreensCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BOOL oneSection = _data.count / 6 < 1;
    BOOL lastSection = section == _data.count / 6;
    return oneSection || lastSection ? _data.count % 6 : 6;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:OALocalizedString(@"quick_action_screen_header"), section + 1];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OATitleDescrDraggableCell getHeight:_data.firstObject.getName value:@"" cellWidth:DeviceScreenWidth];
}

#pragma mark - Swipe Delegate

- (BOOL) swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction;
{
    return _tableView.isEditing;
}



//- (NSArray *) swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
//               swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings
//{
//    swipeSettings.transition = MGSwipeTransitionDrag;
//    expansionSettings.buttonIndex = 0;
//
//    if (direction == MGSwipeDirectionRightToLeft)
//    {
//        //expansionSettings.fillOnTrigger = YES;
//        expansionSettings.threshold = 10.0;
//
//        CGFloat padding = 15;
//
//        NSIndexPath * indexPath = [_tableView indexPathForCell:cell];
//
//        MGSwipeButton *remove = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"ic_trip_removepoint"] backgroundColor:UIColorFromRGB(0xF0F0F5) padding:padding callback:^BOOL(MGSwipeTableCell *sender)
//                                 {
//                                     [_data removeObjectAtIndex:indexPath.section * 6 + indexPath.row];
//                                     [_tableView reloadData];
//                                     return YES;
//                                 }];
//        return @[remove];
//    }
//    return nil;
//}

- (void) swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive
{
    if (state != MGSwipeStateNone)
        cell.showsReorderControl = NO;
    else
        cell.showsReorderControl = YES;
}

@end
