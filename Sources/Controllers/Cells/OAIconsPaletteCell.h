//
//  OAIconsPaletteCell.h
//  OsmAnd
//
//  Created by Max Kojin on 20.08.2024.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACollectionSingleLineTableViewCell.h"
#import "OAColorCollectionViewController.h"

@class OASuperViewController;

@interface OAIconsPaletteCell : OACollectionSingleLineTableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (weak, nonatomic) OASuperViewController *hostVC;

@end
