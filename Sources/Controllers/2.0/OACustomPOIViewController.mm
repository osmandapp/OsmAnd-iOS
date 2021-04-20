//
//  OACustomPOIViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACustomPOIViewController.h"
#import "OAPOIHelper.h"
#import "OAPOICategory.h"
#import "OASettingSwitchCell.h"
#import "OAPOISearchHelper.h"
#import "OASelectSubcategoryViewController.h"
#import "OAPOIUIFilter.h"
#import "OAPOIFiltersHelper.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASizes.h"
#import "OAColors.h"

@interface OACustomPOIViewController () <UITableViewDataSource, UITableViewDelegate, OASelectSubcategoryDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UILabel *textView;

@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UILabel *bottomTextView;
@property (weak, nonatomic) IBOutlet UILabel *bottomBtnView;

@end

@implementation OACustomPOIViewController
{
    OAPOIFiltersHelper *_filterHelper;
    OAPOIUIFilter *_filter;
    NSArray<OAPOICategory *> *_dataArray;
    BOOL _editMode;
    BOOL _bottomViewVisible;
}

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _filterHelper = [OAPOIFiltersHelper sharedInstance];
        _filter = filter;
        _editMode = _filter != [_filterHelper getCustomPOIFilter];
        [self initData];
    }
    return self;
}

- (void) initData
{
    _dataArray = [OAPOIHelper sharedInstance].poiCategoriesNoOther;
    _dataArray = [_dataArray sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory * _Nonnull c1, OAPOICategory * _Nonnull c2) {
        return [c1.nameLocalized localizedCaseInsensitiveCompare:c2.nameLocalized];
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // drop shadow
    [_bottomView.layer setShadowColor:[UIColor blackColor].CGColor];
    [_bottomView.layer setShadowOpacity:0.3];
    [_bottomView.layer setShadowRadius:3.0];
    [_bottomView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    _bottomView.hidden = YES;
    [_bottomView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bottomViewPress:)]];
    
    if (_editMode)
    {
        self.textView.text = _filter.name;
    }
    else
    {
        self.textView.text = OALocalizedString(@"create_custom_poi");
        self.bottomBtnView.text = [OALocalizedString(@"sett_show") upperCase];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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

-(UIView *) getBottomView
{
    return _bottomViewVisible ? _bottomView : nil;
}

-(CGFloat) getToolBarHeight
{
    return customSearchToolBarHeight;
}

- (IBAction)bottomViewPress:(id)sender
{
    if (_delegate)
        [_delegate searchByUIFilter:_filter];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)cancelPress:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) saveFilter
{
    [_filterHelper editPoiFilter:_filter];
    if (!_editMode)
    {
        if ([_filter isEmpty])
        {
            [self setBottomViewVisibility:NO];
        }
        else
        {
            self.bottomTextView.text = [NSString stringWithFormat:@"%@: %d", OALocalizedString(@"selected_categories"), [_filter getAcceptedTypesCount]];

            [self setBottomViewVisibility:YES];
        }
    }
}

- (void) setBottomViewVisibility:(BOOL)visible
{
    if (visible)
    {
        if (!_bottomViewVisible)
        {
            _bottomView.frame = CGRectMake(0, self.view.bounds.size.height + 1, self.view.bounds.size.width, _bottomView.bounds.size.height);
            _bottomView.hidden = NO;
            CGRect tableFrame = _tableView.frame;
            tableFrame.size.height -= _bottomView.bounds.size.height;
            [UIView animateWithDuration:.25 animations:^{
                _tableView.frame = tableFrame;
                _bottomView.frame = CGRectMake(0, self.view.bounds.size.height - _bottomView.bounds.size.height, self.view.bounds.size.width, _bottomView.bounds.size.height);
            }];
        }
        _bottomViewVisible = YES;
        [self applySafeAreaMargins];
    }
    else
    {
        if (_bottomViewVisible)
        {
            CGRect tableFrame = _tableView.frame;
            tableFrame.size.height = self.view.bounds.size.height - tableFrame.origin.y;
            [UIView animateWithDuration:.25 animations:^{
                _tableView.frame = tableFrame;
                _bottomView.frame = CGRectMake(0, self.view.bounds.size.height + 1, self.view.bounds.size.width, _bottomView.bounds.size.height);
            } completion:^(BOOL finished) {
                _bottomView.hidden = YES;
            }];
        }
        _bottomViewVisible = NO;
    }
}

#pragma mark - OASelectSubcategoryDelegate

- (void)selectSubcategoryCancel
{
    [self.tableView reloadData];
}

- (void)selectSubcategoryDone:(OAPOICategory *)category keys:(NSMutableSet<NSString *> *)keys allSelected:(BOOL)allSelected;
{
    if (allSelected)
    {
        [_filter selectSubTypesToAccept:category accept:[OAPOIBaseType nullSet]];
    }
    else if (keys.count == 0)
    {
        [_filter setTypeToAccept:category b:NO];
    }
    else
    {
        [_filter selectSubTypesToAccept:category accept:keys];
    }
    
    [self saveFilter];
    [self.tableView reloadData];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OASettingSwitchCell* cell;
    cell = (OASettingSwitchCell *)[tableView dequeueReusableCellWithIdentifier:@"OASettingSwitchCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
        cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        cell.imgView.tintColor = UIColorFromRGB(profile_icon_color_inactive);
    }
    
    if (cell)
    {
        [cell.switchView removeTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [cell.textView setTextColor:[UIColor blackColor]];
        
        OAPOICategory* item = _dataArray[indexPath.row];
        BOOL isSelected = [_filter isTypeAccepted:item];
        
        cell.switchView.tag = indexPath.row;
        [cell.switchView addTarget:self action:@selector(toggle:) forControlEvents:UIControlEventValueChanged];

        [cell.textView setText:item.nameLocalized];
        
        if (isSelected)
        {
            [cell.imgView setImage: [item icon]];
            cell.descriptionView.hidden = NO;
            cell.switchView.on = YES;
            NSSet<NSString *> *subtypes = [_filter getAcceptedSubtypes:item];
            NSMutableSet<NSString *> *poiTypes = [[_filter getAcceptedTypes] objectForKey:item];
            if (subtypes == [OAPOIBaseType nullSet] || item.poiTypes.count == poiTypes.count)
            {
                cell.descriptionView.text = OALocalizedString(@"shared_string_all");
            }
            else
            {
                NSMutableString *str = [NSMutableString string];
                for (NSString *st in subtypes)
                {
                    if (str.length > 0)
                        [str appendString:@", "];
                    [str appendString:[[OAPOIHelper sharedInstance] getPhraseByName:st]];
                }
                cell.descriptionView.text = str;
            }
        }
        else
        {
            UIImage *img = [[item icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [cell.imgView setImage: img];
            cell.descriptionView.hidden = YES;
            cell.switchView.on = NO;
        }
        [cell updateConstraintsIfNeeded];
    }
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OAPOICategory* item = _dataArray[indexPath.row];
    OASelectSubcategoryViewController *subcatController = [[OASelectSubcategoryViewController alloc] initWithCategory:item subcategories:[_filter getAcceptedSubtypes:item] selectAll:[_filter getAcceptedSubtypes:item] == [OAPOIBaseType nullSet]];
    subcatController.delegate = self;
    [self.navigationController pushViewController:subcatController animated:YES];
}

- (void)toggle:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        if (sw.tag >= 0 && sw.tag < _dataArray.count)
        {
            OAPOICategory *item = _dataArray[sw.tag];
            if (sw.on)
            {
                OASelectSubcategoryViewController *subcatController = [[OASelectSubcategoryViewController alloc] initWithCategory:item subcategories:[_filter getAcceptedSubtypes:item] selectAll:YES];
                subcatController.delegate = self;
                [self.navigationController pushViewController:subcatController animated:YES];
            }
            else
            {
                [_filter setTypeToAccept:item b:NO];
                [self saveFilter];
                
                [self.tableView beginUpdates];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:sw.tag inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView endUpdates];
            }
        }
    }
}

@end
