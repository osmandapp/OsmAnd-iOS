//
//  OAColorsPaletteCell.m
//  OsmAnd Maps
//
// Created by Max Kojin on 20.08.2024.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAColorsPaletteCell.h"
#import "OASizes.h"
#import "Localization.h"
#import "UITableViewCell+getTableView.h"
#import "OAColorCollectionHandler.h"

@interface OAColorsPaletteCell () <UIGestureRecognizerDelegate>

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topTitleOffset;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomTitleOffset;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *separatorHeight;

@end

@implementation OAColorsPaletteCell

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
    [self.rightActionButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
    [self.rightActionButton addTarget:self action:@selector(onRightButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
    self.rightActionButton.accessibilityLabel = OALocalizedString(@"shared_string_add_color");
    self.topLabel.text = OALocalizedString(@"shared_string_color");
    [self.bottomButton setTitle:OALocalizedString(@"shared_string_all_colors") forState:UIControlStateNormal];
}

- (OAColorCollectionHandler *)getColorCollectionHandler
{
    return (OAColorCollectionHandler *)[super getCollectionHandler];
}


#pragma mark - UICollectionViewDelegate

- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self getColorCollectionHandler])
        [[self getColorCollectionHandler] onItemSelected:indexPath collectionView:collectionView];
}

#pragma mark - Selectors

- (IBAction) onBottomButoonPressed:(id)sender
{
    [[self getColorCollectionHandler] openAllColorsScreen];
}

- (void) onRightButtonPressed:(UIButton *)sender
{
    [[self getColorCollectionHandler] openColorPickerWithSelectedColor];
}

@end
