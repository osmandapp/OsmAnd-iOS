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

#import "OsmAndApp.h"


#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@interface OAFavoriteColorViewController ()

@property (strong, nonatomic) NSMutableArray* colors;

@end

@implementation OAFavoriteColorViewController

-(id)initWithFavorite:(OAFavoriteItem*)item {
    self = [super init];
    if (self) {
        self.colors = [NSMutableArray arrayWithArray:[OADefaultFavorite builtinColors]];
        self.favorite = item;

        NSArray* availableColors = [OADefaultFavorite builtinColors];
        self.colorIndex = [availableColors indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            UIColor* uiColor = (UIColor*)[obj objectAtIndex:1];
            OsmAnd::FColorARGB fcolor;
            [uiColor getRed:&fcolor.r
                      green:&fcolor.g
                       blue:&fcolor.b
                      alpha:&fcolor.a];
            OsmAnd::ColorRGB color = OsmAnd::FColorRGB(fcolor);
            
            if (color == self.favorite.favorite->getColor())
                return YES;
            return NO;
        }];
        
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self generateData];
    [self setupView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



-(void)generateData {
}


-(void)setupView {
    
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [@[OALocalizedString(@"Colors")] objectAtIndex:section];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.colors count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierPoint = @"OAViewTextTableViewCell";
    
    OAViewTextTableViewCell* cell;
    cell = (OAViewTextTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAViewTextCell" owner:self options:nil];
        cell = (OAViewTextTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell) {
        NSString* colorName = [((NSArray*)[self.colors objectAtIndex:indexPath.row]) objectAtIndex:0];
        UIColor* currColor = [((NSArray*)[self.colors objectAtIndex:indexPath.row]) objectAtIndex:1];
        [cell.textView setText:colorName];
        [cell setColor:currColor];
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
- (IBAction)saveClicked:(id)sender {
    OsmAndAppInstance app = [OsmAndApp instance];
    
    UIColor* color_ = [[[OADefaultFavorite builtinColors] objectAtIndex:self.colorIndex] objectAtIndex:1];
    OsmAnd::FColorARGB color;
    [color_ getRed:&color.r
             green:&color.g
              blue:&color.b
             alpha:&color.a];
    
    
    self.favorite.favorite->setColor(OsmAnd::FColorRGB(color));
    
    [app saveFavoritesToPermamentStorage];
    [self backButtonClicked:self];
}

- (IBAction)favoriteClicked:(id)sender {
}

- (IBAction)gpxClicked:(id)sender {
    OAGPXListViewController* favController = [[OAGPXListViewController alloc] init];
    [self.navigationController pushViewController:favController animated:NO];
}

@end
