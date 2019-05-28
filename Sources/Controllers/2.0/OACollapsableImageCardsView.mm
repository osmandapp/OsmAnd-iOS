//
//  OACollapsableMapillaryView.mm
//  OsmAnd
//
//  Created by Paul on 24/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableImageCardsView.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OATransportRouteController.h"
#import "OAImageCard.h"
#import "OAImageCardCell.h"
#import "OAMapillaryNoImagesCell.h"
#import "OAMapillaryImage.h"
#import "OAMapLayers.h"
#import "Localization.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

#define kUserLabelInset 8

@interface OACollapsableImageCardsView () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation OACollapsableImageCardsView
{
    UICollectionView *_cardCollection;
    
    NSArray *_images;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.itemSize = CGSizeMake(270, 160);
        layout.minimumInteritemSpacing = 16.0;
        layout.sectionInset = UIEdgeInsetsMake(0, 46, 0, 46);
        _cardCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) collectionViewLayout:layout];
        _cardCollection.dataSource = self;
        _cardCollection.delegate = self;
        [_cardCollection registerNib:[UINib nibWithNibName:@"OAImageCardCell" bundle:nil]
                   forCellWithReuseIdentifier:@"OAImageCardCell"];
        [_cardCollection registerNib:[UINib nibWithNibName:@"OAMapillaryNoImagesCell" bundle:nil]
                   forCellWithReuseIdentifier:@"OAMapillaryNoImagesCell"];
        [_cardCollection setShowsHorizontalScrollIndicator:NO];
        [_cardCollection setShowsVerticalScrollIndicator:NO];
        [self addSubview:_cardCollection];
    }
    return self;
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

- (void) setImageCards:(NSArray *)imageCards
{
    _images = imageCards;
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
    OAImageCard *card = _images[indexPath.row];
    if (card && [card.type isEqualToString:TYPE_MAPILLARY_EMPTY])
    {
        OAMapillaryNoImagesCell *cell = (OAMapillaryNoImagesCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"OAMapillaryNoImagesCell" forIndexPath:indexPath];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMapillaryNoImagesCell" owner:self options:nil];
            cell = (OAMapillaryNoImagesCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.noImagesLabel.text = OALocalizedString(@"mapil_no_images");
            [cell.imageView setImage:[[UIImage imageNamed:@"ic_custom_trouble.png"]
                                      imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            cell.imageView.tintColor = UIColorFromRGB(color_icon_color);
            cell.layer.cornerRadius = 6.0;
            cell.layer.shadowOffset = CGSizeMake(0, 3);
            cell.layer.shadowOpacity = 0.2;
            cell.layer.shadowRadius = 3.0;
        }
        return cell;
    }
    // TODO Add condition for contribute mapillary card
    else if (card && card.type)
    {
        OAImageCardCell *cell = (OAImageCardCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"OAImageCardCell" forIndexPath:indexPath];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAImageCardCell" owner:self options:nil];
            cell = (OAImageCardCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAImageCard *imageCard = _images[indexPath.row];
            if (imageCard.image)
                [cell.imageView setImage:imageCard.image];
            else
            {
                [cell.imageView setImage:nil];
                if (!self.collapsed)
                {
                    [imageCard downloadImage:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_cardCollection reloadItemsAtIndexPaths:@[indexPath]];
                        });
                    }];
                }
            }
            cell.usernameLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
            cell.usernameLabel.topInset = kUserLabelInset;
            cell.usernameLabel.bottomInset = kUserLabelInset;
            cell.usernameLabel.leftInset = kUserLabelInset;
            cell.usernameLabel.rightInset = kUserLabelInset;
            [cell setUserName:imageCard.userName];
            
            [cell.logoView setImage:[UIImage imageNamed:card.topIcon]];
            cell.layer.cornerRadius = 6.0;
            cell.layer.shadowOffset = CGSizeMake(0, 3);
            cell.layer.shadowOpacity = 0.2;
            cell.layer.shadowRadius = 3.0;
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _images.count;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    OAImageCard *card = _images[indexPath.row];
    if ([card.type isEqualToString:TYPE_MAPILLARY_PHOTO])
    {
        OAMapillaryImage *img = [[OAMapillaryImage alloc] initWithDictionary:@{@"lat" : @(card.latitude),
                                                                               @"lon" : @(card.longitude),
                                                                               @"key" : card.key,
                                                                               @"ca" : @(card.ca)
                                                                               }];
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.mapillaryLayer getTargetPoint:img];
        newTarget.centerMap = YES;
        [mapPanel hideContextMenu];
        [mapPanel showContextMenu:newTarget];
    }
    else if (card.type && [card.type isEqualToString:TYPE_URL_PHOTO])
    {
        NSString *cardUrl = [card getSuitableUrl];
        if (cardUrl && cardUrl.length > 0)
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:cardUrl]];
    }
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end
