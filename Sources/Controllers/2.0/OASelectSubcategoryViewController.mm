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
#import "OAPOIHelper.h"

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
    NSSet<NSString *> *_subcategories;
    BOOL _selectAll;
}

- (instancetype)initWithCategory:(OAPOICategory *)category subcategories:(NSSet<NSString *> *)subcategories selectAll:(BOOL)selectAll
{
    self = [super init];
    if (self)
    {
        _category = category;
        _subcategories = subcategories;
        _selectAll = selectAll;
        [self initData];
    }
    return self;
}

- (void) initData
{
    if (_category)
    {
        OAPOIHelper *helper = [OAPOIHelper sharedInstance];
        NSMutableDictionary<NSString *, NSString *> *subMap = [NSMutableDictionary dictionary];
        for (NSString *name in _subcategories)
            [subMap setObject:[helper getPhraseByName:name] forKey:name];

        for (OAPOIType *pt in _category.poiTypes)
            [subMap setObject:pt.nameLocalized forKey:pt.name];
        
        NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithArray:subMap.allKeys];
        NSMutableArray<NSString *> *data = [NSMutableArray arrayWithArray:subMap.allValues];
        
        [keys sortUsingComparator:^NSComparisonResult(NSString * _Nonnull name1, NSString * _Nonnull name2) {
            return [[subMap objectForKey:name1] localizedCaseInsensitiveCompare:[subMap objectForKey:name2]];
        }];
        [data sortUsingComparator:^NSComparisonResult(NSString * _Nonnull nameLoc1, NSString * _Nonnull nameLoc2) {
            return [nameLoc1 localizedCaseInsensitiveCompare:nameLoc2];
        }];

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
    {
        _headerView.selected = YES;
        [self.tableView beginUpdates];
        for (int i = 0; i < _data.count; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView endUpdates];
    }
    else
    {
        _headerView.selected = _subcategories.count == _keys.count;
        [self.tableView beginUpdates];
        for (int i = 0; i < _keys.count; i++)
        {
            NSString *name = _keys[i];
            if ([_subcategories containsObject:name])
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        [self.tableView endUpdates];
    }
    [self applySafeAreaMargins];
}

-(UIView *) getTopView
{
    return _topView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(void)applyLocalization
{
    self.descView.text = OALocalizedString(@"subcategories");
}

- (IBAction)cancelPress:(id)sender
{
    if (_delegate)
        [_delegate selectSubcategoryCancel];

    [self dismissViewController];
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

    [self dismissViewController];
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
