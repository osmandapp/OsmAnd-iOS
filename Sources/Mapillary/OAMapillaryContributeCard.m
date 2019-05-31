//
//  OAMapillaryContributeCard.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAMapillaryContributeCard.h"
#import "OAMapillaryContributeCell.h"
#import "Localization.h"
#import "OAMapillaryPlugin.h"
#import "OAColors.h"

#define kContributeCard @"OAMapillaryContributeCell"

@implementation OAMapillaryContributeCard

- (void) build:(UICollectionViewCell *) cell
{
    [super build:cell];
    
    OAMapillaryContributeCell *contributeCell;
    
    if (cell && [cell isKindOfClass:OAMapillaryContributeCell.class])
        contributeCell = (OAMapillaryContributeCell *) cell;
    
    if (contributeCell)
    {
        contributeCell.contributeLabel.text = OALocalizedString(@"mapil_contribute");
        [contributeCell.addPhotosButton setImage:[[UIImage imageNamed:@"ic_custom_mapillary_symbol.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [contributeCell.addPhotosButton setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(0xCC458)] forState:UIControlStateNormal];
        contributeCell.addPhotosButton.imageView.tintColor = [UIColor whiteColor];
        [contributeCell.addPhotosButton setTitle:OALocalizedString(@"mapil_add_photos") forState:UIControlStateNormal];
        [contributeCell.addPhotosButton addTarget:self action:@selector(addPhotosButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) addPhotosButtonPressed:(id)sender
{
    [OAMapillaryPlugin installOrOpenMapillary];
}

+ (NSString *) getCellNibId
{
    return kContributeCard;
}

@end
