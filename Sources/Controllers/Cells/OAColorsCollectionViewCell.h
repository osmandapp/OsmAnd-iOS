//
//  OAColorsCollectionViewCell.h
//  OsmAnd
//
//  Created by igor on 06.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAColorsCollectionViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIView *selectionView;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *colorView;

@end

