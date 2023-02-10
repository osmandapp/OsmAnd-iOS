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

- (NSString *)getTitle
{
    return _parameter.title;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _parameter.possibleValues.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _parameter.value = _parameter.possibleValues[indexPath.row].name;
    [_styleSettings save:_parameter];
    if (self.depthDelegate)
        [self.depthDelegate onValueSelected:_parameter];
    [self dismissViewController];
}

@end
