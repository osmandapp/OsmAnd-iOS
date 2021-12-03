//
//  OAColorsCollectionViewCell.m
//  OsmAnd
//
//  Created by igor on 06.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAColorsCollectionViewCell.h"

@implementation OAColorsCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.backView.layer.cornerRadius = self.backView.frame.size.height/2;
    self.chessboardView.layer.cornerRadius = self.chessboardView.frame.size.height/2;
    self.colorView.layer.cornerRadius = self.colorView.frame.size.height/2;
}

- (void)setChessboardAlpha:(CGFloat)alpha
{
    self.colorView.alpha = alpha;
    self.chessboardView.hidden = alpha == 1.;
}

@end
