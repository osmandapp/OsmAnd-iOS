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
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OANoImagesCard ()

@property (nonatomic) OANoImagesCell *collectionCell;

@end

@implementation OANoImagesCard

- (void) build:(UICollectionViewCell *) cell
{
    if (cell && [cell isKindOfClass:OANoImagesCell.class])
        _collectionCell = (OANoImagesCell *) cell;
    [super build:cell];
}

- (void)update
{
    if (_collectionCell)
    {
        _collectionCell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        _collectionCell.noImagesLabel.text = OALocalizedString(@"mapil_no_images");
        [_collectionCell.imageView setImage:[UIImage templateImageNamed:@"ic_custom_trouble.png"]];
        _collectionCell.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
        [_collectionCell.addPhotosButton setBackgroundImage:[OAUtilities imageWithColor:[UIColor colorNamed:ACColorNameButtonBgColorPrimary]] forState:UIControlStateNormal];
        [_collectionCell.addPhotosButton setImage:[UIImage templateImageNamed:@"ic_custom_add.png"] forState:UIControlStateNormal];
        _collectionCell.addPhotosButton.imageView.tintColor = [UIColor colorNamed:ACColorNameButtonTextColorPrimary];
        [_collectionCell.addPhotosButton setTitle:OALocalizedString(@"shared_string_add_photos") forState:UIControlStateNormal];
        [_collectionCell.addPhotosButton addTarget:self action:@selector(addPhotosButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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
