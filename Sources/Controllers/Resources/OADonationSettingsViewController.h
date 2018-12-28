//
//  OADonationSettingsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

typedef NS_ENUM(NSInteger, EDonationSettingsScreen)
{
    EDonationSettingsScreenUndefined = -1,
    EDonationSettingsScreenMain = 0,
    EDonationSettingsScreenRegion
};

@interface OACountryItem : NSObject

@property (nonatomic) NSString *localName;
@property (nonatomic) NSString *downloadName;

- (id) initWithLocalName:(NSString *)localName downloadName:(NSString *) downloadName;

@end

@interface OADonationSettingsViewController : OACompoundViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) EDonationSettingsScreen settingsType;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (nonatomic) OACountryItem *selectedCountryItem;
@property (nonatomic) NSArray *countryItems;

- (id) initWithSettingsType:(EDonationSettingsScreen)settingsType parentController:(OADonationSettingsViewController *)parentController;

-(void) initCountries;

@end
