//
//  OAIconsPaletteCell.h
//  OsmAnd
//
//  Created by Max Kojin on 20.08.2024.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACollectionSingleLineTableViewCell.h"
#import "OASuperViewController.h"
#import "OAColorCollectionViewController.h"

@interface OAIconsPaletteCell : OACollectionSingleLineTableViewCell <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (weak, nonatomic) IBOutlet UILabel *topLabel;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (weak, nonatomic) OASuperViewController<OAColorCollectionDelegate> *hostVC;

@end
