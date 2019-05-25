//
//  OACollapsableMapillaryView.mm
//  OsmAnd
//
//  Created by Paul on 24/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableMapillaryView.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OATransportRouteController.h"
#import "OAImageCard.h"
#import "OAMapillaryImageCell.h"
#import "OAMapillaryNoImagesCell.h"
#import "OAMapillaryImage.h"
#import "OAMapLayers.h"
#import "Localization.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

@interface OACollapsableMapillaryView () <UICollectionViewDataSource, UICollectionViewDelegate>

@end

@implementation OACollapsableMapillaryView
{
    UICollectionView *_mapillaryCardCollection;
    
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
        layout.minimumInteritemSpacing = 0.0;
        layout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
        _mapillaryCardCollection = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height) collectionViewLayout:layout];
        _mapillaryCardCollection.dataSource = self;
        _mapillaryCardCollection.delegate = self;
        [_mapillaryCardCollection registerNib:[UINib nibWithNibName:@"OAMapillaryImageCell" bundle:nil]
                   forCellWithReuseIdentifier:@"OAMapillaryImageCell"];
        [_mapillaryCardCollection registerNib:[UINib nibWithNibName:@"OAMapillaryNoImagesCell" bundle:nil]
                   forCellWithReuseIdentifier:@"OAMapillaryNoImagesCell"];
        [_mapillaryCardCollection setShowsHorizontalScrollIndicator:NO];
        [_mapillaryCardCollection setShowsVerticalScrollIndicator:NO];
        [self addSubview:_mapillaryCardCollection];
    }
    return self;
}

- (void) buildViews
{
    _mapillaryCardCollection.backgroundColor = [UIColor clearColor];
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat mapillaryViewHeight = 170;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, mapillaryViewHeight);
    _mapillaryCardCollection.frame = CGRectMake(0, 0, width, mapillaryViewHeight);
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

- (void) setImages:(NSArray *)mapillaryImages
{
    _images = mapillaryImages;
    [self buildViews];
    [_mapillaryCardCollection reloadData];
}

#pragma mark - UICollectionViewDataSource

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
    return CGSizeZero;
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    OAImageCard *card = _images[indexPath.row];
    if ([card.type isEqualToString:TYPE_MAPILLARY_PHOTO])
    {
        OAMapillaryImageCell *cell = (OAMapillaryImageCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"OAMapillaryImageCell" forIndexPath:indexPath];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMapillaryImageCell" owner:self options:nil];
            cell = (OAMapillaryImageCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAImageCard *imageCard = _images[indexPath.row];
            if (imageCard.image)
                [cell.mapillaryImageView setImage:imageCard.image];
            else
            {
                [cell.mapillaryImageView setImage:nil];
                if (!self.collapsed)
                {
                    [imageCard downloadImage:^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [_mapillaryCardCollection reloadItemsAtIndexPaths:@[indexPath]];
                        });
                    }];
                }
            }
            cell.usernameLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
            [cell setUserName:imageCard.userName];
            cell.layer.cornerRadius = 6.0;
        }
        return cell;
    }
    else if ([card.type isEqualToString:TYPE_MAPILLARY_EMPTY])
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
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

@end
