//
//  OACollapsableMapillaryView.mm
//  OsmAnd
//
//  Created by Paul on 24/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableCardsView.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAAbstractCard.h"

#include <OsmAndCore/Utilities.h>

static NSArray<NSString *> *nibNames;

@interface OACollapsableCardsView () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation OACollapsableCardsView
{
    UICollectionView *_cardCollection;
    
    NSArray<OAAbstractCard *> *_cards;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        nibNames = @[@"OAImageCardCell", @"OAMapillaryNoImagesCell"];
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(270, 160);
        layout.minimumInteritemSpacing = 16.0;
        layout.sectionInset = UIEdgeInsetsMake(0, 46, 0, 46);
        _cardCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) collectionViewLayout:layout];
        _cardCollection.dataSource = self;
        _cardCollection.delegate = self;
        [_cardCollection setShowsHorizontalScrollIndicator:NO];
        [_cardCollection setShowsVerticalScrollIndicator:NO];
        [self registerSupportedNibs];
        [self addSubview:_cardCollection];
    }
    return self;
}

- (void) registerSupportedNibs
{
    for (NSString *name in nibNames)
    {
        [_cardCollection registerNib:[UINib nibWithNibName:name bundle:nil]
          forCellWithReuseIdentifier:name];
    }
}

- (void) buildViews
{
    _cardCollection.backgroundColor = [UIColor clearColor];
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat mapillaryViewHeight = 170;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, mapillaryViewHeight);
    _cardCollection.frame = CGRectMake(0, 0, width, mapillaryViewHeight);
    if (self.collapsed)
        [_cardCollection reloadData];
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

- (void) setCards:(NSArray<OAAbstractCard *> *)cards
{
    _cards = cards;
    [self buildViews];
    [_cardCollection reloadData];
}

#pragma mark - UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    return [_cards[indexPath.row] build:collectionView indexPath:indexPath];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _cards.count;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [_cards[indexPath.row] onCardPressed:[OARootViewController instance].mapPanel];
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end
