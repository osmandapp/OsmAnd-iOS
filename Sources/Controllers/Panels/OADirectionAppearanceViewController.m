//
//  OADirectionAppearanceViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 14.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OADirectionAppearanceViewController.h"
#import "OATableViewCustomHeaderView.h"
#import "OATableViewCustomFooterView.h"
#import "OASettingSwitchCell.h"
#import "OASettingsCheckmarkCell.h"

#include "Localization.h"
#include "OASizes.h"
#include "OAColors.h"

#define kHeaderId @"TableViewSectionHeader"
#define kFooterId @"TableViewSectionFooter"

@interface OADirectionAppearanceViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;


@end

@implementation OADirectionAppearanceViewController
{
    NSDictionary *_data;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"appearance");
    
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupView];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

-(CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) setupView
{
    
    [self applySafeAreaMargins];
    [self adjustViews];
    
    _data = [NSMutableDictionary dictionary];
    
    NSMutableArray *activeMarkersArr = [NSMutableArray array];
    NSMutableArray *distanceIndicationArr = [NSMutableArray array];
    NSMutableArray *appearanceOnMapArr = [NSMutableArray array];
    
//    [activeMarkersArr addObject:@{
//                        @"type" : @"OATableViewCustomHeaderView",
//                        @"title" : OALocalizedString(@"active_markers"),
//                        }];
//
    [activeMarkersArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"value" : @YES,
                        @"title" : OALocalizedString(@"one"),
                        @"fg_img" : @"ic_custom_direction_topbar_one.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_chart_orange)
                        }];
    
    [activeMarkersArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"value" : @NO,
                        @"title" : OALocalizedString(@"two"),
                        @"fg_img" : @"ic_custom_direction_topbar_two.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_tint_gray)
                        }];
    
//    [activeMarkersArr addObject:@{
//                        @"type" : @"OATableViewCustomFooterView",
//                        @"title" : OALocalizedString(@"specify_number_of_dir_indicators"),
//                        }];
    
    
    
//    [distanceIndicationArr addObject:@{
//                        @"type" : @"OATableViewCustomHeaderView",
//                        @"title" : OALocalizedString(@"active_markers"),
//                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"title" : OALocalizedString(@"distance_indication"),
                        @"value" : @YES,
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"value" : @YES,
                        @"title" : OALocalizedString(@"top_bar"),
                        @"fg_img" : @"ic_custom_direction_topbar_one.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_chart_orange)
                        }];
    
    [distanceIndicationArr addObject:@{
                        @"type" : @"OASettingsCheckmarkCell",
                        @"value" : @NO,
                        @"title" : OALocalizedString(@"widgets"),
                        @"fg_img" : @"ic_custom_direction_widget_two.png",
                        @"fg_color" : UIColorFromRGB(color_primary_purple),
                        @"bg_img" : @"ic_custom_direction_device.png",
                        @"bg_color" : UIColorFromRGB(color_tint_gray)
                        }];
    
//    [distanceIndicationArr addObject:@{
//                        @"type" : @"OATableViewCustomFooterView",
//                        @"title" : OALocalizedString(@"specify_number_of_dir_indicators"),
//                        }];
    
    
    
//    [appearanceOnMapArr addObject:@{
//                        @"type" : @"OATableViewCustomHeaderView",
//                        @"title" : OALocalizedString(@"active_markers"),
//                        }];
    
    
    [appearanceOnMapArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"title" : OALocalizedString(@"arrows_on_map"),
                        @"value" : @YES,
                        }];
    
    [appearanceOnMapArr addObject:@{
                        @"type" : @"OASettingSwitchCell",
                        @"title" : OALocalizedString(@"direction_lines"),
                        @"value" : @YES,
                        }];
    
//    [appearanceOnMapArr addObject:@{
//                        @"type" : @"OATableViewCustomFooterView",
//                        @"title" : OALocalizedString(@"specify_number_of_dir_indicators"),
//                        }];
    
    _data = @{ @"appearanceOnMap" : appearanceOnMapArr,
               @"distanceIndication" : distanceIndicationArr,
               @"activeMarkers" : activeMarkersArr
            };
  
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    //[self.tableView setEditing:YES animated:YES];
    //self.tableView.allowsMultipleSelectionDuringEditing = YES;
    
    
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
   
}


 - (void) adjustViews
 {
     CGRect buttonFrame = _backButton.frame;
     CGRect titleFrame = _titleView.frame;
     CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
     buttonFrame.origin.y = statusBarHeight;
     titleFrame.origin.y = statusBarHeight;
     _backButton.frame = buttonFrame;
     _titleView.frame = titleFrame;
 }

- (UIImage *) drawImage:(UIImage*) fgImage inImage:(UIImage*) bgImage bgColor:(UIColor *)bgColor fgColor:(UIColor *)fgColor
 {
     UIGraphicsBeginImageContextWithOptions(bgImage.size, NO, 0.0);
     
     [bgColor setFill];
     [bgImage drawInRect:CGRectMake( 0, 0, bgImage.size.width, bgImage.size.height)];
     [fgColor setFill];
     [fgImage drawInRect:CGRectMake( 0.0, 0.0, fgImage.size.width, fgImage.size.height)];
     
     UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
     UIGraphicsEndImageContext();

     return newImage;
 }


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
   return _data.count;;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data[_data.allKeys[section]] count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OASettingsCheckmarkCell"])
    {
        static NSString* const identifierCell = @"OASettingsCheckmarkCell";
        OASettingsCheckmarkCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCheckmarkCell" owner:self options:nil];
            cell = (OASettingsCheckmarkCell *)[nib objectAtIndex:0];
        }
        
        UIImage *fgImage = [[UIImage imageNamed:item[@"fg_img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIImage *bgImage = [[UIImage imageNamed:item[@"bg_img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        cell.iconImageView.image = [self drawImage:fgImage inImage:bgImage bgColor:item[@"bg_color"] fgColor:item[@"fg_color"]];
        cell.titleLabel.text = item[@"title"];
        
        cell.checkmarkImageView.hidden = ![item[@"value"] boolValue];
        [cell.checkmarkImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.checkmarkImageView.tintColor = UIColorFromRGB(color_primary_purple);
        
        return cell;
    }
    
    else
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        cell.textView.text = item[@"title"];
        cell.descriptionView.hidden = YES;
        cell.switchView.on = [item[@"value"] boolValue];
        cell.switchView.tag = indexPath.section << 10 | indexPath.row;
        
        return cell;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self getTitleForHeaderSection:section];
    return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = [self getTitleForHeaderSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
    
    if (!title)
    {
        vw.label.text = title;
        return vw;
    }
    
    vw.label.text = [title upperCase];
    return vw;
}

- (NSString *) getTitleForHeaderSection:(NSInteger) section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"active_markers");
        case 1:
            return OALocalizedString(@"distance_indication");
        case 2:
            return OALocalizedString(@"appearance_on_map");
        default:
            return @"";
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *title = [self getTitleForFooterSection:section];
    return [OATableViewCustomFooterView getHeight:title width:tableView.bounds.size.width];
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *title = [self getTitleForFooterSection:section];
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kFooterId];

    vw.label.text = title;
    
    return vw;
}

- (NSString *) getTitleForFooterSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"specify_number_of_dir_indicators");
        case 1:
            return OALocalizedString(@"choose_how_display_distance");
        case 2:
            return OALocalizedString(@"arrows_direction_to_markers");
        default:
            return @"";
    }
}

#pragma mark - UITableViewDelegate

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSDictionary *item = _data[_data.allKeys[indexPath.section]][indexPath.row];
//    
//    if ([item[@"type"] isEqualToString:@"OASettingsCheckmarkCell"])
//    {
//        [_data.allKeys[indexPath.section][indexPath.row] setValue:@NO forKey:@"value"];
//    }
}

@end
