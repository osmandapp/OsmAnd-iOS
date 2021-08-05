//
//  OACustomSelectionButtonCell.h
//  OsmAnd
//
//  Created by Paul on 03.26.2021.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OACustomSelectionButtonCell : UITableViewCell


@property (weak, nonatomic) IBOutlet UIButton *selectDeselectButton;
@property (weak, nonatomic) IBOutlet UIButton *selectDeselectButtonTouchableArea;
@property (weak, nonatomic) IBOutlet UIView *selectionButtonContainer;
@property (weak, nonatomic) IBOutlet UIButton *selectionButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxHeightContainer;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *checkboxWidthContainer;


@end
