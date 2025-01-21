//
//  OACollapsableMapillaryView.mm
//  OsmAnd
//
//  Created by Paul on 24/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableCardsView.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAAppSettings.h"
#import "GeneratedAssetSymbols.h"
#import "OAMapillaryImageCardWrapper.h"

#include <OsmAndCore/Utilities.h>

#define kMapillaryViewHeight 170

static NSArray<NSString *> *nibNames;

@interface OACollapsableCardsView () <UICollectionViewDataSource, UICollectionViewDelegate, AbstractCardDelegate>

@end

@implementation OACollapsableCardsView
{
    UICollectionView *_cardCollection;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        nibNames = @[[ImageCard getCellNibId], [NoImagesCard getCellNibId], [MapillaryContributeCard getCellNibId]];
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

- (void) setCollapsed:(BOOL)collapsed
{
    [super setCollapsed:collapsed];
    [[OAAppSettings sharedManager].onlinePhotosRowCollapsed set:collapsed];
    if (!collapsed && self.delegate)
        [self.delegate onViewExpanded];
}

- (void) buildViews
{
    _cardCollection.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    if (!self.collapsed)
    {
        [self buildViews];
        [_cardCollection reloadData];
    }
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (!self.collapsed)
    {
        [self buildViews];
        [_cardCollection reloadData];
    }
}

- (void) updateLayout:(CGFloat)width
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, kMapillaryViewHeight);
    _cardCollection.frame = CGRectMake(0, 0, width, kMapillaryViewHeight);
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

- (void) setCards:(NSArray<AbstractCard *> *)cards
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _cards = cards;
        for (AbstractCard *card in cards)
            card.delegate = self;
        
        [self buildViews];
        [_cardCollection reloadData];
    });
}

#pragma mark - UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    AbstractCard *card = _cards[indexPath.row];
    NSString *reuseIdentifier = [card.class getCellNibId];
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    if (cell && !self.collapsed)
        [card buildIn:cell];
    
    return cell;
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
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    AbstractCard *card = _cards[indexPath.row];
//    if ([card isKindOfClass:[MapillaryImageCard class]])
//    {
//        MapillaryImageCard *mapillaryImageCard = (MapillaryImageCard *)card;
//        [OAMapillaryImageCardWrapper onCardPressed:[OARootViewController instance].mapPanel latitude:mapillaryImageCard.latitude longitude:mapillaryImageCard.longitude ca:mapillaryImageCard.ca key:mapillaryImageCard.key];
//    }
//    else
//    {
        [card onCardPressed:[OARootViewController instance].mapPanel];
 //   }
}

#pragma mark - AbstractCardDelegate

- (void) requestCardReload:(AbstractCard *)card
{
    [card update];
    NSInteger row = [_cards indexOfObject:card];
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
    [_cardCollection reloadItemsAtIndexPaths:@[path]];
}

@end
