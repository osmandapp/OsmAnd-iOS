//
//  OAColorsPaletteCell.h
//  OsmAnd
//
//  Created by Max Kojin on 20.08.2024.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACollectionSingleLineTableViewCell.h"

@interface OAColorsPaletteCell : OACollectionSingleLineTableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@end
