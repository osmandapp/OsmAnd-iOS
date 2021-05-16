//
//  OANoImagesCard.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OANoImagesCard.h"
#import "OANoImagesCell.h"
#import "Localization.h"
#import "OAMapillaryPlugin.h"
#import "OAColors.h"

@implementation OANoImagesCard

- (void) build:(UICollectionViewCell *) cell
{
    [super build:cell];
    
    OANoImagesCell *noImagesCell;
    
    if (cell && [cell isKindOfClass:OANoImagesCell.class])
        noImagesCell = (OANoImagesCell *) cell;
    
    if (noImagesCell)
    {
        noImagesCell.noImagesLabel.text = OALocalizedString(@"mapil_no_images");
        [noImagesCell.imageView setImage:[UIImage templateImageNamed:@"ic_custom_trouble.png"]];
        noImagesCell.imageView.tintColor = UIColorFromRGB(color_icon_color);
        [noImagesCell.addPhotosButton setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(0x007AFF)] forState:UIControlStateNormal];
        [noImagesCell.addPhotosButton setImage:[UIImage templateImageNamed:@"ic_custom_add.png"] forState:UIControlStateNormal];
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
    return [OANoImagesCell getCellIdentifier];
}

@end
