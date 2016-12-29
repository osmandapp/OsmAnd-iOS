//
//  OASelectSubcategoryViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASelectSubcategoryViewController.h"
#import "OATextLineViewCell.h"
#import "OAPOISearchHelper.h"
#import "Localization.h"
#import "OAMultiselectableHeaderView.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"

@interface OASelectSubcategoryViewController () <UITableViewDataSource, UITableViewDelegate, OAMultiselectableHeaderDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIButton *btnDone;

@end

@implementation OASelectSubcategoryViewController
{
    OAMultiselectableHeaderView *_headerView;
    NSArray<NSString *> *_keys;
    NSArray<NSString *> *_data;
    OAPOICategory *_category;
    BOOL _selectAll;
}

- (instancetype)initWithCategory:(OAPOICategory *)category selectAll:(BOOL)selectAll
{
    self = [super init];
    if (self)
    {
        _category = category;
        _selectAll = selectAll;
        [self initData];
    }
    return self;
}

- (void) initData
{
    if (_category)
    {
        NSMutableArray<OAPOIType *> *arr = [NSMutableArray arrayWithArray:_category.poiTypes];
        [arr sortUsingComparator:^NSComparisonResult(OAPOIType * _Nonnull str1, OAPOIType * _Nonnull str2) {
            return [str1.nameLocalized localizedCaseInsensitiveCompare:str2.nameLocalized];
        }];

        NSMutableArray<NSString *> *keys = [NSMutableArray array];
        NSMutableArray<NSString *> *data = [NSMutableArray array];
        for (OAPOIType *pt in arr)
        {
            [keys addObject:pt.name];
            [data addObject:pt.nameLocalized];
        }
        _data = [NSArray arrayWithArray:data];
        _keys = [NSArray arrayWithArray:keys];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_category)
        self.textView.text = _category.nameLocalized;
    else
        self.textView.text = @"";
    
    // add header
    _headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    [_headerView setTitleText:OALocalizedString(@"select_all")];
    
    _headerView.section = 0;
    _headerView.delegate = self;
    
    self.tableView.editing = YES;
    if (_selectAll)
        for (int i = 0; i < _data.count; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
}

-(void)applyLocalization
{
    self.descView.text = OALocalizedString(@"subcategories");
}

- (IBAction)cancelPress:(id)sender
{
    if (_delegate)
        [_delegate selectSubcategoryCancel];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)donePress:(id)sender
{
    if (_delegate)
    {
        NSMutableSet<NSString *> *selectedKeys = [NSMutableSet set];
        NSArray<NSIndexPath *> *rows = [self.tableView indexPathsForSelectedRows];
        for (NSIndexPath *index in rows)
            [selectedKeys addObject:_keys[index.row]];

        [_delegate selectSubcategoryDone:_category keys:selectedKeys allSelected:_keys.count == selectedKeys.count];
    }

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - OAMultiselectableHeaderDelegate

-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
{
    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
    NSInteger section = headerView.section;
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
    
    [self.tableView beginUpdates];
    if (value)
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        for (int i = 0; i < rowsCount; i++)
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.tableView endUpdates];
}

#pragma mark - UITableViewDataSource

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 46.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return _headerView;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [OATextLineViewCell getHeight:_data[indexPath.row] cellWidth:tableView.bounds.size.width];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
}

@end
