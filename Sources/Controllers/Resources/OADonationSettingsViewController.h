//
//  OADonationSettingsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

typedef NS_ENUM(NSInteger, EDonationSettingsScreen)
{
    EDonationSettingsScreenUndefined = -1,
    EDonationSettingsScreenMain = 0,
    EDonationSettingsScreenRegion
};

@interface OACountryItem : NSObject

@property (nonatomic) NSString *localName;
@property (nonatomic) NSString *downloadName;

- (instancetype)initWithLocalName:(NSString *)localName downloadName:(NSString *) downloadName;

@end

@interface OADonationSettingsViewController : OABaseButtonsViewController

@property (nonatomic, readonly) EDonationSettingsScreen settingsType;
@property (nonatomic) OACountryItem *selectedCountryItem;
@property (nonatomic) NSArray<OACountryItem *> *countryItems;

- (instancetype)initWithSettingsType:(EDonationSettingsScreen)settingsType parentController:(OADonationSettingsViewController *)parentController;

- (void)initCountries;
- (OACountryItem *)getCountryItem:(NSString *)downloadName;

@end
