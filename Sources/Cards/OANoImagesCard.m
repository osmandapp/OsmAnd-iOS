//
//  OANoImagesCard.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANoImagesCard.h"
#import "OAMapillaryNoImagesCell.h"
#import "Localization.h"
#import "OAColors.h"

@implementation OANoImagesCard

- (UICollectionViewCell *) build:(UICollectionView *) collectionView indexPath:(NSIndexPath *)indexPath
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
        [self applyShadowToCell:cell];
    }
    return cell;
}

@end
