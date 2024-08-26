//
//  OAColorsPaletteCell.m
//  OsmAnd Maps
//
// Created by Max Kojin on 20.08.2024.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAIconsPaletteCell.h"
#import "OASizes.h"
#import "Localization.h"
#import "UITableViewCell+getTableView.h"
#import "OAColorCollectionHandler.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAIconsPaletteCell () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topTitleOffset;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomTitleOffset;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;

@end

@implementation OAIconsPaletteCell

#pragma mark - Initialization

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self setupViews];
}

- (void) setupViews
{
    self.separatorInset = UIEdgeInsetsZero;
    self.separatorHeight.constant = 1.0 / [UIScreen mainScreen].scale;
    self.topTitleOffset.constant = 20;
    self.bottomTitleOffset.constant = 8;
    [self rightActionButtonVisibility:NO];
}

- (IconCollectionHandler *)getIconsCollectionHandler
{
    return (IconCollectionHandler *)[super getCollectionHandler];
}


#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self getIconsCollectionHandler])
        [[self getIconsCollectionHandler] onItemSelected:indexPath collectionView:[[self getIconsCollectionHandler] getCollectionView]];
}

#pragma mark - Selectors

- (IBAction) onBottomButoonPressed:(id)sender
{
    // TODO: Implement
//    [[self getIconsCollectionHandler] openAllColorsScreen];
}

@end
