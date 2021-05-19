//
//  OANoImagesCell.h
//  OsmAnd
//
//  Created by Paul on 25/15/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OANoImagesCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *noImagesLabel;
@property (weak, nonatomic) IBOutlet UIButton *addPhotosButton;

@end
