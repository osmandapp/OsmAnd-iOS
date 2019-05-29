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
#import "OAMapillaryPlugin.h"
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
        [noImagesCell.addPhotosButton setImage:[[UIImage imageNamed:@"ic_custom_plus.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        noImagesCell.addPhotosButton.imageView.tintColor = [UIColor whiteColor];
        [noImagesCell.addPhotosButton setTitle:OALocalizedString(@"mapil_add_photos") forState:UIControlStateNormal];
        
        [noImagesCell.addPhotosButton addTarget:self action:@selector(addPhotosButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) addPhotosButtonPressed:(id)sender
{
    [OAMapillaryPlugin installOrOpenMapillary];
}

+ (NSString *) getCellNibId
{
    return kNoImagesCard;
}

@end
