//
//  OANavigationSettingsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OANavigationSettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"

@interface OANavigationSettingsViewController ()

@end

@implementation OANavigationSettingsViewController
{
    NSDictionary *_data;
}

- (id) initWithSettingsType:(kNavigationSettingsScreen)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
    }
    return self;
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"routing_settings");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
}

- (void) setupView
{
    OAAppSettings* settings = [OAAppSettings sharedManager];
    switch (self.settingsType)
    {
        case kNavigationSettingsScreenGeneral:
        {
            /*
            NSString* metricSystemValue = settings.settingMetricSystem == 0 ? OALocalizedString(@"sett_km") : OALocalizedString(@"sett_ml");
            NSString* geoFormatValue = settings.settingGeoFormat == MAP_GEO_FORMAT_DEGREES ? OALocalizedString(@"sett_deg") : OALocalizedString(@"sett_deg_min");
            NSString* showAltValue = settings.settingShowAltInDriveMode ? OALocalizedString(@"sett_show") : OALocalizedString(@"sett_notshow");
            NSString *recIntervalValue = [settings getFormattedTrackInterval:settings.mapSettingSaveTrackIntervalGlobal];
            NSString* doNotShowDiscountValue = settings.settingDoNotShowPromotions ? OALocalizedString(@"shared_string_yes") : OALocalizedString(@"shared_string_no");
            NSString* doNotUseFirebaseValue = settings.settingDoNotUseFirebase ? OALocalizedString(@"shared_string_yes") : OALocalizedString(@"shared_string_no");
            
            if (![[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_units"), @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_loc_fmt"), @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"show_alt_in_drive"), @"value": showAltValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_show_discount"), @"value": doNotShowDiscountValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_send_anonymous_data"), @"value": doNotUseFirebaseValue, @"img": @"menu_cell_pointer.png"}
                              ];
            }
            else
            {
                self.data = @[
                              @{@"name": OALocalizedString(@"sett_units"), @"value": metricSystemValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"sett_loc_fmt"), @"value": geoFormatValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"show_alt_in_drive"), @"value": showAltValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_show_discount"), @"value": doNotShowDiscountValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"do_not_send_anonymous_data"), @"value": doNotUseFirebaseValue, @"img": @"menu_cell_pointer.png"},
                              @{@"name": OALocalizedString(@"rec_interval"), @"value": recIntervalValue, @"img": @"menu_cell_pointer.png"}
                              ];
            }
             */
            break;
        }
        case kNavigationSettingsScreenAvoidRouting:
        {
            /*
            _titleView.text = OALocalizedString(@"do_not_send_anonymous_data");
            self.data = @[@{@"name": OALocalizedString(@"shared_string_yes"), @"value": @"", @"img": settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""},
                          @{@"name": OALocalizedString(@"shared_string_no"), @"value": @"", @"img": !settings.settingDoNotUseFirebase ? @"menu_cell_selected.png" : @""}
                          ];
             */
            break;
        }
        default:
            break;
    }
}

@end
