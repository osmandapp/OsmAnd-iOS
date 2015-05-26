//
//  OAFavoriteColorViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 10.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteColorViewController.h"
#import "OAViewTextTableViewCell.h"
#import "OANativeUtilities.h"
#import "OADefaultFavorite.h"
#import "OAGPXListViewController.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"

#import "OsmAndApp.h"


#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@implementation OAFavoriteColorViewController

-(id)initWithFavorite:(OAFavoriteItem *)item
{
    self = [super init];
    if (self) {
        UIColor* color = [UIColor colorWithRed:item.favorite->getColor().r/255.0 green:item.favorite->getColor().g/255.0 blue:item.favorite->getColor().b/255.0 alpha:1.0];
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        self.colorIndex = [[OADefaultFavorite builtinColors] indexOfObject:favCol];
        self.favorite = item;
    }
    return self;
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"fav_color");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    
    [_favoriteButtonView setTitle:OALocalizedStringUp(@"favorites") forState:UIControlStateNormal];
    [_gpxButtonView setTitle:OALocalizedStringUp(@"tracks") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.favoriteButtonView];
    [OAUtilities layoutComplexButton:self.gpxButtonView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _saveChanges = NO;
    
    [self generateData];
    [self setupView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews
{
    CGRect f = _tableView.frame;
    f.size.height = (self.hideToolbar ? f.size.height + _toolbarView.bounds.size.height : f.size.height);
    self.tableView.frame = f;
}

-(void)generateData
{
}


-(void)setupView
{
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    if (self.hideToolbar)
        _toolbarView.hidden = YES;
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [@[OALocalizedString(@"fav_colors")] objectAtIndex:section];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[OADefaultFavorite builtinColors] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const reusableIdentifierPoint = @"OAViewTextTableViewCell";
    
    OAViewTextTableViewCell* cell;
    cell = (OAViewTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAViewTextCell" owner:self options:nil];
        cell = (OAViewTextTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][indexPath.row];
        [cell.textView setText:favCol.name];
        [cell.titleIcon setImage:favCol.icon];
        [cell.iconView setImage:nil];
        
        if (indexPath.row == self.colorIndex)
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected"]];
    }
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    self.colorIndex = indexPath.row;
    [self.tableView reloadData];
}

#pragma mark - Actions

- (IBAction)saveClicked:(id)sender
{
    if (self.favorite)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        
        OAFavoriteColor *favCol = [[OADefaultFavorite builtinColors] objectAtIndex:self.colorIndex];
        CGFloat r,g,b,a;
        [favCol.color getRed:&r
                       green:&g
                        blue:&b
                       alpha:&a];
        
        self.favorite.favorite->setColor(OsmAnd::FColorRGB(r,g,b));
        
        [app saveFavoritesToPermamentStorage];
    }
    _saveChanges = YES;
    [self backButtonClicked:self];
}

- (IBAction)favoriteClicked:(id)sender
{
}

- (IBAction)gpxClicked:(id)sender
{
    OAGPXListViewController* favController = [[OAGPXListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

@end
