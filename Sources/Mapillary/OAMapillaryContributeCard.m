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

@interface OAMapillaryContributeCard ()

@property (nonatomic) OAMapillaryContributeCell *collectionCell;

@end

@implementation OAMapillaryContributeCard

- (void) build:(UICollectionViewCell *) cell
{
    if (cell && [cell isKindOfClass:OAMapillaryContributeCell.class])
        _collectionCell = (OAMapillaryContributeCell *) cell;
    [super build:cell];
}

- (void)update
{
    if (_collectionCell)
    {
        _collectionCell.contributeLabel.text = OALocalizedString(@"mapil_contribute");
        [_collectionCell.addPhotosButton setImage:[UIImage templateImageNamed:@"ic_custom_mapillary_symbol.png"] forState:UIControlStateNormal];
        [_collectionCell.addPhotosButton setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(0xCC458)] forState:UIControlStateNormal];
        _collectionCell.addPhotosButton.imageView.tintColor = [UIColor whiteColor];
        [_collectionCell.addPhotosButton setTitle:OALocalizedString(@"mapil_add_photos") forState:UIControlStateNormal];
        [_collectionCell.addPhotosButton addTarget:self action:@selector(addPhotosButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) addPhotosButtonPressed:(id)sender
{
    [OAMapillaryPlugin installOrOpenMapillary];
}

+ (NSString *) getCellNibId
{
    return [OAMapillaryContributeCell getCellIdentifier];
}

@end
