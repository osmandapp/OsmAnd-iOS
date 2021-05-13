//
//  OnlineTilesSettingsViewController.m
//  OsmAnd Maps
//
//  Created by igor on 30.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOnlineTilesSettingsViewController.h"
#import "OASQLiteTileSource.h"
#import "OAResourcesBaseViewController.h"
#import "Localization.h"
#import "OASettingsTitleTableViewCell.h"

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

typedef NS_ENUM(NSInteger, EOAOnlineSourceSetting)
{
    EOAOnlineSourceSettingMercatorProjection = 0,
    EOAOnlineSourceSettingSourceFormat
};

@interface OAOnlineTilesSettingsViewController ()
@end

@implementation OAOnlineTilesSettingsViewController
{
    BOOL _isEllipticYTile;
    EOAOnlineSourceSetting _settingsType;
    EOASourceFormat _sourceFormat;
    NSArray *_data;
}

-(instancetype) initWithEllipticYTile:(BOOL)isEllipticYTile
{
    self = [super init];
    if (self)
    {
        _isEllipticYTile = isEllipticYTile;
        _settingsType = EOAOnlineSourceSettingMercatorProjection;
    }
    return self;
}

-(instancetype) initWithSourceFormat:(EOASourceFormat)sourceFormat
{
    self = [super init];
    if (self)
    {
        _sourceFormat = sourceFormat;
        _settingsType = EOAOnlineSourceSettingSourceFormat;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self generateData];
}

-(void)applyLocalization
{
    switch (_settingsType)
    {
        case EOAOnlineSourceSettingMercatorProjection:
        {
            _titleLabel.text = OALocalizedString(@"res_mercator");
            break;
        }
        case EOAOnlineSourceSettingSourceFormat:
        {
            _titleLabel.text = OALocalizedString(@"res_source_format");
            break;
        }
        default:
            break;
    }
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    switch (_settingsType)
    {
        case EOAOnlineSourceSettingMercatorProjection:
        {
            
            [data addObject:@{
                                @"text": OALocalizedString(@"res_elliptic_mercator"),
                                @"img": _isEllipticYTile ? @"menu_cell_selected.png" : @""
            }];
            [data addObject:@{
                                @"text": OALocalizedString(@"res_pseudo_mercator"),
                                @"img": !_isEllipticYTile ? @"menu_cell_selected.png" : @""
            }];
            break;
        }
        case EOAOnlineSourceSettingSourceFormat:
        {
            [data addObject:@{
                                @"text": OALocalizedString(@"res_source_sqlite"),
                                @"img": _sourceFormat == EOASourceFormatSQLite ? @"menu_cell_selected.png" : @""
            }];
            [data addObject:@{
                                @"text": OALocalizedString(@"res_source_one_per_tile"),
                                @"img": _sourceFormat == EOASourceFormatOnline ? @"menu_cell_selected.png" : @""
            }];
            break;
        }
        default:
            break;
    }
    _data = [NSArray arrayWithArray:data];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    OASettingsTitleTableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
    
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        [cell.textView setText: item[@"text"]];
        if (item[@"img"])
            [cell.iconView setImage:[UIImage imageNamed:item[@"img"]].imageFlippedForRightToLeftLayoutDirection];
        else
            [cell.iconView setImage:nil];
    }
    return cell;
}

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (_settingsType)
       {
           case EOAOnlineSourceSettingMercatorProjection:
           {
               if ((indexPath.row == 0 && _isEllipticYTile) || (indexPath.row == 1 && !_isEllipticYTile))
                   break;
               _isEllipticYTile = indexPath.row == 0 ? YES : NO;
               if (_delegate)
                   [_delegate onMercatorChanged:_isEllipticYTile];
               [self generateData];
               [_tableView reloadData];
               break;
           }
           case EOAOnlineSourceSettingSourceFormat:
           {
               if ((indexPath.row == 0 && _sourceFormat == EOASourceFormatSQLite) || (indexPath.row == 1 && _sourceFormat == EOASourceFormatOnline))
                   break;
               _sourceFormat = indexPath.row == 0 ? EOASourceFormatSQLite : EOASourceFormatOnline;
               if (_delegate)
                   [_delegate onStorageFormatChanged:_sourceFormat];
               [self generateData];
               [_tableView reloadData];
               break;
           }
           default:
               break;
       }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
