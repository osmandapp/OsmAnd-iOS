//
//  OAColorsPaletteCell.m
//  OsmAnd Maps
//
// Created by Max Kojin on 20.08.2024.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorsPaletteCell.h"
#import "OASizes.h"
#import "UITableViewCell+getTableView.h"

@interface OAColorsPaletteCell () <UIGestureRecognizerDelegate>

//@property (weak, nonatomic) IBOutlet UIStackView *contentOutsideStackViewVertical;
//@property (weak, nonatomic) IBOutlet UIStackView *topMarginStackView;
//@property (weak, nonatomic) IBOutlet UIStackView *collectionStackView;
//@property (weak, nonatomic) IBOutlet UIStackView *bottomMarginStackView;
//
//@property (strong, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeight;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topTitleOffset;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomTitleOffset;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;

@end

@implementation OAColorsPaletteCell
{
}

#pragma mark - Initialization

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self setupViews];
}

- (void) setupViews
{
    self.separatorHeight.constant = 1.0 / [UIScreen mainScreen].scale;
}

- (IBAction) onBottomButoonPressed:(id)sender
{
}


#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
//    if (_collectionHandler)
//        [_collectionHandler onItemSelected:indexPath collectionView:collectionView];
}

#pragma mark - Selectors

- (void) onRightActionButtonPressed:(UIGestureRecognizer *)recognizer
{
//    if (self.delegate && recognizer.state == UIGestureRecognizerStateEnded)
//        [self.delegate onRightActionButtonPressed:self.rightActionButton.tag];
}

//#pragma mark - UIGestureRecognizerDelegate
//
//- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
//{
//    if (self.rightActionButton.hidden || !self.rightActionButton.enabled)
//        return NO;
//
//    CGFloat leftInset = [self getLeftInsetToView:self.rightActionButton];
//    CGFloat pressedXLocation = [gestureRecognizer locationInView:self].x;
//    if ([self isDirectionRTL])
//        return [self getTableView].frame.size.width - pressedXLocation >= (leftInset - self.collectionStackView.spacing);
//    else
//        return pressedXLocation >= (leftInset - self.collectionStackView.spacing);
//}

@end
