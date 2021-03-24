//
//  OAHomeWorkCell.m
//  OsmAnd
//
//  Created by Paul on 26/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAHomeWorkCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAHomeWorkCollectionViewCell.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OARTargetPoint.h"
#import "OAPointDescription.h"
#import "OATargetPointsHelper.h"

#define defaultCellHeight 60.0
#define titleTextWidthDelta 50.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

#define kDestCell @"OAHomeWorkCollectionViewCell"

@interface OAHomeWorkCell() <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation OAHomeWorkCell
{
    NSArray *_data;
    UILongPressGestureRecognizer *_longPress;
    
    NSIndexPath *_touchIndexPath;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerNib:[UINib nibWithNibName:kDestCell bundle:nil] forCellWithReuseIdentifier:kDestCell];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0.;
    layout.minimumLineSpacing = 0.;
    layout.sectionInset = UIEdgeInsetsZero;
    [_collectionView setCollectionViewLayout:layout];
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    
    _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    _longPress.delegate = self;
    _longPress.delaysTouchesBegan = YES;
    [self.collectionView addGestureRecognizer:_longPress];
    
    [self generateData];
}

- (void) generateData
{
    OAAppData *data = [OsmAndApp instance].data;
    OARTargetPoint *homePoint = [[OATargetPointsHelper sharedInstance] getHomePoint];
    OARTargetPoint *workPoint = [[OATargetPointsHelper sharedInstance] getWorkPoint];
    NSString *homeName = homePoint ? [homePoint.pointDescription getSimpleName:NO] : nil;
    NSString *workName = workPoint ? [workPoint.pointDescription getSimpleName:NO] : nil;
    _data = @[
              @{
                    @"title" : OALocalizedString(@"home_pt"),
                    @"descr" : homeName ? homeName : OALocalizedString(@"shared_string_add"),
                    @"img" : @"ic_custom_home",
                    @"key" : @"home"
              },
              @{
                    @"title" : OALocalizedString(@"work_pt"),
                    @"descr" : workName ? workName : OALocalizedString(@"shared_string_add"),
                    @"img" : @"ic_custom_work",
                    @"key" : @"work"
              }
            ];
    [self.collectionView reloadData];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        CGPoint p = [gestureRecognizer locationInView:self.collectionView];
        _touchIndexPath = [self.collectionView indexPathForItemAtPoint:p];
        [self collectionView:self.collectionView didHighlightItemAtIndexPath:_touchIndexPath];
    }
    else if (gestureRecognizer.state == UIGestureRecognizerStateEnded && _delegate)
    {
        [self collectionView:self.collectionView didUnhighlightItemAtIndexPath:_touchIndexPath];
        [_delegate onItemSelected:_data[_touchIndexPath.row][@"key"] overrideExisting:YES];
    }
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _data.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(collectionView.bounds.size.width / 2, collectionView.bounds.size.height);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kDestCell forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDestCell owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (cell && [cell isKindOfClass:OAHomeWorkCollectionViewCell.class])
    {
        OAHomeWorkCollectionViewCell *destCell = (OAHomeWorkCollectionViewCell *) cell;
        destCell.titleLabel.text = item[@"title"];
        destCell.descrLabel.text = item[@"descr"];
        destCell.imageView.image = [UIImage imageNamed:item[@"img"]];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [cell setBackgroundColor:UIColorFromRGB(color_tint_gray)];
    }
                     completion:nil];
}

- (void)collectionView:(UICollectionView *)colView  didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [cell setBackgroundColor:UIColor.whiteColor];
    }
                     completion:nil];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (_delegate)
    {
        [_delegate onItemSelected:item[@"key"]];
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}


@end
