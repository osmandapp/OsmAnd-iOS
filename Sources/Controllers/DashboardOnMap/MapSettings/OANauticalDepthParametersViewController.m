//
//  OANauticalDepthParametersViewController.mm
//  OsmAnd
//
//  Created by Skalii on 11.11.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OANauticalDepthParametersViewController.h"
#import "OARightIconTableViewCell.h"
#import "OAMapStyleSettings.h"
#import "OAColors.h"

@implementation OANauticalDepthParametersViewController
{
    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_parameter;
}

#pragma mark - Initialization

- (instancetype)initWithParameter:(OAMapStyleParameter *)parameter
{
    self = [super init];
    if (self)
    {
        _parameter = parameter;
        _styleSettings = [OAMapStyleSettings sharedInstance];
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _parameter.title;
}

#pragma mark - Table data

- (NSInteger)rowsCount:(NSInteger)section
{
    return _parameter.possibleValues.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
    if (!cell)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OARightIconTableViewCell *) nib[0];
        [cell descriptionVisibility:NO];
        [cell leftIconVisibility:NO];
    }
    if (cell)
    {
        OAMapStyleParameterValue *value = _parameter.possibleValues[indexPath.row];
        cell.titleLabel.text = value.title;
        cell.rightIconView.image = [_parameter.value isEqualToString:value.name] ? [UIImage templateImageNamed:@"ic_checkmark_default"] : nil;
        cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
    }
    return cell;
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (void)onRowPressed:(NSIndexPath *)indexPath
{
    _parameter.value = _parameter.possibleValues[indexPath.row].name;
    [_styleSettings save:_parameter];
    if (self.depthDelegate)
        [self.depthDelegate onValueSelected:_parameter];
    [self dismissViewController];
}

@end
