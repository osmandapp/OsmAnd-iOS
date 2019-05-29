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

#define kNoImagesCard @"OAMapillaryNoImagesCell"

@implementation OANoImagesCard

- (void) build:(UICollectionViewCell *) cell
{
    [super build:cell];
    
    OAMapillaryNoImagesCell *noImagesCell;
    
    if (cell && [cell isKindOfClass:OAMapillaryNoImagesCell.class])
        noImagesCell = (OAMapillaryNoImagesCell *) cell;
    
    if (noImagesCell)
    {
        noImagesCell.noImagesLabel.text = OALocalizedString(@"mapil_no_images");
        [noImagesCell.imageView setImage:[[UIImage imageNamed:@"ic_custom_trouble.png"]
                                  imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        noImagesCell.imageView.tintColor = UIColorFromRGB(color_icon_color);
    }
}

+ (NSString *) getCellNibId
{
    return kNoImagesCard;
}

@end
