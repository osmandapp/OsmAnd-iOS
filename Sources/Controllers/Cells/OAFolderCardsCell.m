//
//  OAHorizontalCollectionViewIconCell.m
//  OsmAnd
//
//  Created by nnngrach on 08.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAFolderCardsCell.h"
#import "OAFolderCardCollectionViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

#define kMargin 16
#define kCellWidth 120
#define kCellHeight 69

@interface OAFolderCardsCell() <UICollectionViewDelegate, UICollectionViewDataSource>

@end

@implementation OAFolderCardsCell
{
    NSMutableArray *_data;
    NSInteger _selectedItemIndex;
    
    UIFont *_originalGroupFont;
    UIFont *_italicGroupFont;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerNib:[UINib nibWithNibName:[OAFolderCardCollectionViewCell getCellIdentifier] bundle:nil] forCellWithReuseIdentifier:[OAFolderCardCollectionViewCell getCellIdentifier]];
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumInteritemSpacing = 0;
    layout.minimumLineSpacing = kMargin;
    layout.sectionInset = UIEdgeInsetsMake(0, kMargin, kMargin, kMargin);
    [_collectionView setCollectionViewLayout:layout];
    [_collectionView setShowsHorizontalScrollIndicator:NO];
    [_collectionView setShowsVerticalScrollIndicator:NO];
    _data = [NSMutableArray new];
}

- (void) setValues:(NSArray<NSString *> *)values sizes:(NSArray<NSNumber *> *)sizes colors:(NSArray<UIColor *> *)colors hidden:(NSArray<NSNumber *> *)hidden addButtonTitle:(NSString *)addButtonTitle withSelectedIndex:(int)index
{
    _data = [NSMutableArray new];
    _selectedItemIndex = index;

    for (NSInteger i = 0; i < values.count; i++)
    {
        NSString *sizeString;
        NSNumber *size = (i < sizes.count && sizes[i]) ? sizes[i] : nil;
        sizeString = size ? [NSString stringWithFormat:@"%i", size.intValue] : @"";
        UIColor *color = (i < colors.count && colors[i]) ? colors[i] : [UIColor colorNamed:ACColorNameIconColorActive];
        BOOL visible = (i < hidden.count && hidden[i]) ? !hidden[i].boolValue : YES;
        NSString *img = visible ? @"ic_custom_folder" : @"ic_custom_folder_hidden_outlined";
        if (!visible)
            color = [UIColor colorNamed:ACColorNameIconColorSecondary];
        
        [_data addObject:@{
            @"title" : values[i],
            @"size" : sizeString,
            @"color" : color,
            @"img" : img,
            @"hidden" : @(!visible),
            @"key" : @"home"}];
    }
    
    [_data addObject:@{
        @"title" : addButtonTitle,
        @"size" : @"",
        @"color" : [UIColor colorNamed:ACColorNameIconColorActive],
        @"img" : @"ic_custom_add",
        @"hidden" : @(NO),
        @"key" : @"work"}];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex
{
    NSInteger prevSelectedItemIndex = _selectedItemIndex;
    _selectedItemIndex = selectedIndex;
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath indexPathForRow:prevSelectedItemIndex inSection:0],
                                                   [NSIndexPath indexPathForRow:_selectedItemIndex inSection:0]]];
}

#pragma mark - Scroll offset calculations

- (void) updateContentOffset
{
    if (![_state containsValueForIndex:_cellIndex])
    {
        CGPoint initialOffset = [self calculateOffset:_selectedItemIndex];
        [_state setOffset:initialOffset forIndex:_cellIndex];
        self.collectionView.contentOffset = initialOffset;
    }
    else
    {
        CGPoint loadedOffset = [_state getOffsetForIndex:_cellIndex];
        if ([OAUtilities getLeftMargin] > 0)
            loadedOffset.x -= [OAUtilities getLeftMargin] - kMargin;
        self.collectionView.contentOffset = loadedOffset;
    }
}

- (void) saveOffset
{
    CGPoint offset = self.collectionView.contentOffset;
    if ([OAUtilities getLeftMargin] > 0)
        offset.x += [OAUtilities getLeftMargin] - kMargin;
    [_state setOffset:offset forIndex:_cellIndex];
}

- (CGPoint) calculateOffset:(NSInteger)index;
{
    CGFloat selectedOffset = index * (kCellWidth + kMargin);
    CGFloat fullLength = _data.count * (kCellWidth + kMargin);
    CGFloat maxOffset = fullLength - DeviceScreenWidth + kMargin * 3;
    if (selectedOffset > maxOffset)
        selectedOffset = maxOffset;
    return CGPointMake(selectedOffset, 0);
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
    return CGSizeMake(kCellWidth,kCellHeight);
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[OAFolderCardCollectionViewCell getCellIdentifier] forIndexPath:indexPath];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFolderCardCollectionViewCell getCellIdentifier] owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if (cell && [cell isKindOfClass:OAFolderCardCollectionViewCell.class])
    {
        OAFolderCardCollectionViewCell *destCell = (OAFolderCardCollectionViewCell *) cell;
        if (!_originalGroupFont)
        {
            _originalGroupFont = destCell.titleLabel.font;
            UIFontDescriptor *italicDescriptor = [destCell.titleLabel.font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
            _italicGroupFont = [UIFont fontWithDescriptor:italicDescriptor size:0];
        }
        BOOL hidden = ((NSNumber *) item[@"hidden"]).boolValue;
        destCell.layer.cornerRadius = 9;
        destCell.titleLabel.text = item[@"title"];
        destCell.descLabel.text = item[@"size"];
        destCell.imageView.tintColor = item[@"color"];
        [destCell.imageView setImage:[UIImage templateImageNamed:item[@"img"]]];
        destCell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        destCell.titleLabel.textColor = [UIColor colorNamed:hidden ? ACColorNameTextColorSecondary : ACColorNameTextColorActive];
        destCell.titleLabel.font = hidden ? _italicGroupFont : _originalGroupFont;

        if (indexPath.row == _selectedItemIndex)
        {
            destCell.layer.borderWidth = 2;
            destCell.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
        }
        else
        {
            destCell.layer.borderWidth = 1;
            destCell.layer.borderColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary].CGColor;
        }
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)colView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [cell setBackgroundColor:[UIColor colorNamed:ACColorNameIconColorDisabled]];
    }
                     completion:nil];
}

- (void)collectionView:(UICollectionView *)colView  didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell* cell = [colView cellForItemAtIndexPath:indexPath];
    [UIView animateWithDuration:0.2
                          delay:0
                        options:(UIViewAnimationOptionAllowUserInteraction)
                     animations:^{
        [cell setBackgroundColor:[UIColor colorNamed:ACColorNameGroupBg]];
    }
                     completion:nil];
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == _data.count - 1)
    {
        if (_delegate)
            [_delegate onAddFolderButtonPressed];
    }
    else
    {
        if (_delegate)
        {
            [_delegate onItemSelected:indexPath.row];
            [self setSelectedIndex:indexPath.row];
        }
    }
    
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self saveOffset];
}

@end
