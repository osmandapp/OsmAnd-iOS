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
    [self topButtonVisibility:NO];
}

- (void) setupViews
{
    self.separatorInset = UIEdgeInsetsZero;
    self.separatorHeight.constant = 1.0 / [UIScreen mainScreen].scale;
    self.topTitleOffset.constant = 20;
    self.bottomTitleOffset.constant = 8;
}

- (void)topButtonVisibility:(BOOL)show
{
    self.topButton.hidden = !show;
}

- (IconCollectionHandler *)getIconsCollectionHandler
{
    return (IconCollectionHandler *)[super getCollectionHandler];
}

- (void)setCollectionHandler:(OABaseCollectionHandler *)collectionHandler
{
    IconCollectionHandler * handler = (IconCollectionHandler *)collectionHandler;
    [super setCollectionHandler:handler];
    handler.hostCell = self;

    UIMenu *menu = [[self getIconsCollectionHandler] buildTopButtonContextMenu];
    if (menu)
    {
        self.topButton.showsMenuAsPrimaryAction = YES;
        self.topButton.menu = menu;
    }
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
    [[self getIconsCollectionHandler] openAllIconsScreen];
}

@end
