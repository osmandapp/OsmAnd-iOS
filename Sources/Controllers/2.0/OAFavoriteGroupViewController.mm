//
//  OAFavoriteGroupViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 10.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAFavoriteGroupViewController.h"
#import "OAIconTextTableViewCell.h"
#import "OATextViewTableViewCell.h"
#import "OANativeUtilities.h"

#import "OsmAndApp.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"

@interface OAFavoriteGroupViewController ()

@property (strong, nonatomic) NSMutableArray* groups;

@end

@implementation OAFavoriteGroupViewController

-(id)initWithFavorite:(OAFavoriteItem*)item {
    self = [super init];
    if (self) {
        self.favorite = item;
        self.groupName = self.favorite.favorite->getGroup().toNSString();
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
    OsmAndAppInstance app = [OsmAndApp instance];

    self.groups = [[OANativeUtilities QListOfStringsToNSMutableArray:app.favoritesCollection->getGroups().toList()] copy];
    if ([self.groups count] > 0) {
        NSArray *sortedArrayGroups = [self.groups sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            return [[obj1 lowercaseString] compare:[obj2 lowercaseString]];
        }];
        self.groups = [[NSMutableArray alloc] initWithArray:sortedArrayGroups];
    }
}


-(void)setupView {
    
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [@[@"Ваши группы", @"Создать новую группу"] objectAtIndex:section];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return [self.groups count];
    else
        return 1;
}

UITextField* textView;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
        OAIconTextTableViewCell* cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            NSString* item = [self.groups objectAtIndex:indexPath.row];
            [cell showImage:NO];
            [cell.textView setText:item];
            [cell.arrowIconView setImage:nil];
            if ([item isEqualToString:self.groupName])
                [cell.arrowIconView setImage:[UIImage imageNamed:@"menu_cell_selected"]];
        
        }
        return cell;
    } else {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextViewCell" owner:self options:nil];
        OATextViewTableViewCell* cell = (OATextViewTableViewCell *)[nib objectAtIndex:0];
        if (cell) {
            
            textView = [[UITextField alloc] initWithFrame:CGRectMake(10, 0, 300, 50)];
            [textView setPlaceholder:@"Введите название группы"];
            [textView setFont:[UIFont fontWithName:@"AvenirNextCondensed-Regular" size:14]];
            [textView addTarget:self action:@selector(editGroupName:) forControlEvents:UIControlEventEditingChanged];
            [textView setDelegate:self];
            [cell addSubview:textView];
            
            return cell;
        }
    
    }
    return nil;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 0) {
        self.groupName = [self.groups objectAtIndex:indexPath.row];
        [self.tableView reloadData];
    } else {
        self.groupName = [textView text];
        [self.tableView reloadData];
    }
}

#pragma mark - UITextFieldDelegate
- (void)editGroupName:(id)sender {
    self.groupName = [((UITextField*)sender) text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender{
    [sender resignFirstResponder];
    return YES;
}


#pragma mark - Actions

- (IBAction)saveClicked:(id)sender {
    OsmAndAppInstance app = [OsmAndApp instance];
    
    QString group = QString::fromNSString(self.groupName);
    self.favorite.favorite->setGroup(group);
    [app saveFavoritesToPermamentStorage];
    [self backButtonClicked:self];
}

- (IBAction)favoriteClicked:(id)sender {
}

- (IBAction)gpxClicked:(id)sender {
}

@end
