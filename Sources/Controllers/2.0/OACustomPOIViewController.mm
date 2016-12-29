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
#import "OAIconTextSwitchCell.h"
#import "OAPOISearchHelper.h"

@interface OACustomPOIViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *btnCancel;
@property (weak, nonatomic) IBOutlet UILabel *textView;

@end

@implementation OACustomPOIViewController
{
    NSArray<OAPOICategory *> *_dataArray;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _dataArray = [OAPOIHelper sharedInstance].poiCategoriesNoOther;
    _dataArray = [_dataArray sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory * _Nonnull c1, OAPOICategory * _Nonnull c2) {
        return [c1.nameLocalized localizedCaseInsensitiveCompare:c2.nameLocalized];
    }];
}

- (IBAction)cancelPress:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAPOICategory* item = _dataArray[indexPath.row];
    return [OAIconTextSwitchCell getHeight:item.nameLocalized descHidden:YES cellWidth:tableView.bounds.size.width];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAIconTextSwitchCell* cell;
    cell = (OAIconTextSwitchCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextSwitchCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextSwitchCell" owner:self options:nil];
        cell = (OAIconTextSwitchCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [cell.textView setTextColor:[UIColor blackColor]];
        
        OAPOICategory* item = _dataArray[indexPath.row];
        
        [cell.textView setText:item.nameLocalized];
        [cell.iconView setImage: [item icon]];
        cell.descView.hidden = YES;
        //[cell layoutIfNeeded];
    }
    return cell;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dataArray.count;
}

@end
