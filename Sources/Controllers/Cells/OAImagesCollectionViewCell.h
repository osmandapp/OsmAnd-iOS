//
//  OAImagesCollectionViewCell.h
//  OsmAnd
//
//  Created by nnngrach on 09.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAImagesCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (nonatomic) NSArray<UIImage *> *images;

@end
