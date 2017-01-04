//
//  OAPOIFilterViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAPOIFilterViewController.h"
#import "OAPOISearchHelper.h"
#import "OAPOIUIFilter.h"
#import "Localization.h"
#import "OAPOIFiltersHelper.h"
#import "OACustomPOIViewController.h"

typedef enum
{
    EMenuStandard = 0,
    EMenuCustom,
    EMenuDelete,
    
} EMenuType;

@interface OAPOIFilterViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *btnClose;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIButton *btnMore;

@end

@implementation OAPOIFilterViewController
{
    NSString *_filterByName;
    OAPOIUIFilter *_filter;
}

- (instancetype)initWithFilter:(OAPOIUIFilter * _Nonnull)filter filterByName:(NSString * _Nullable)filterByName
{
    self = [super init];
    if (self)
    {
        _filterByName = filterByName;
        _filter = filter;
    }
    return self;
}

-(void)applyLocalization
{
    _textView.text = OALocalizedString(@"shared_string_filters");
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _descView.text = _filter.name;
}

- (IBAction)closePress:(id)sender
{
    if (!_delegate || [_delegate updateFilter])
        [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)morePress:(id)sender
{
    if (![_filter isStandardFilter])
    {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:_filter.name delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") destructiveButtonTitle:OALocalizedString(@"delete_filter") otherButtonTitles:OALocalizedString(@"edit_filter"), OALocalizedString(@"shared_string_save_as"), nil];
        menu.tag = EMenuCustom;
        [menu showInView:self.btnMore];
    }
    else
    {
        UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:_filter.name delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_cancel") destructiveButtonTitle:nil otherButtonTitles:OALocalizedString(@"save_filter"), nil];
        menu.tag = EMenuStandard;
        [menu showInView:self.btnMore];
    }
}

- (void) deleteFilter
{
    UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:OALocalizedString(@"edit_filter_delete_dialog_title") delegate:self cancelButtonTitle:nil destructiveButtonTitle:OALocalizedString(@"shared_string_yes") otherButtonTitles:OALocalizedString(@"shared_string_no"), nil];
    menu.tag = EMenuDelete;
    [menu showInView:self.view];
}

- (void) editCategories
{
    OACustomPOIViewController *customPOI = [[OACustomPOIViewController alloc] initWithFilter:_filter];
    [self.navigationController pushViewController:customPOI animated:YES];
}

#pragma mark - UITableViewDataSource

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForHeader];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;//[OATextLineViewCell getHeight:_data[indexPath.row] cellWidth:tableView.bounds.size.width];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;//_data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
    /*
    OATextLineViewCell* cell;
    cell = (OATextLineViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OATextLineViewCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextLineViewCell" owner:self options:nil];
        cell = (OATextLineViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [cell.textView setTextColor:[UIColor blackColor]];
        [cell.textView setText:_data[indexPath.row]];
    }
    return cell;
     */
}

#pragma mark - UIActionSheetDelegate

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
        return;
    
    switch (actionSheet.tag)
    {
        case EMenuStandard:
            if (self.delegate && [self.delegate saveFilter])
                [self.navigationController popViewControllerAnimated:YES];
            
            break;
            
        case EMenuCustom:
            if (buttonIndex == actionSheet.destructiveButtonIndex)
            {
                [self deleteFilter];
            }
            else if (buttonIndex == 1)
            {
                [self editCategories];
            }
            else if (buttonIndex == 2)
            {
                if (self.delegate && [self.delegate saveFilter])
                    [self.navigationController popViewControllerAnimated:YES];
            }
            break;
            
        case EMenuDelete:
            if (buttonIndex == actionSheet.destructiveButtonIndex)
            {
                if (self.delegate && [self.delegate removeFilter])
                    [self.navigationController popViewControllerAnimated:YES];
            }
            break;
            
        default:
            break;
    }
}

@end
