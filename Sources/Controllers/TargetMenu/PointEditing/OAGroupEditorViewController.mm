//
//  OAGroupEditorViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 11.10.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAGroupEditorViewController.h"
#import "OATextInputFloatingCell.h"
#import "OAGPXDocumentPrimitives.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAFavoritesHelper.h"
#import "Localization.h"

#define kInputNameKey @"kInputNameKey"

@interface OAGroupEditorViewController ()

@property(nonatomic) NSString *originalName;
@property(nonatomic) NSString *editName;
@property(nonatomic) UIColor *editColor;
@property(nonatomic) NSString *editIconName;
@property(nonatomic) NSString *editBackgroundIconName;

@end

@implementation OAGroupEditorViewController
{
    OATextInputFloatingCell *_nameTextField;
}

@synthesize editName = _editName, originalName = _originalName, editColor = _editColor, editIconName = _editIconName, editBackgroundIconName = _editBackgroundIconName;

#pragma mark - Initialization

- (instancetype)initWithGroup:(OASGpxUtilitiesPointsGroup *)group
{
    self = [super init];
    if (self)
    {
        _group = group;
        [self postInit];
    }
    return self;
}

- (void)postInit
{
    if (!self.isNewItem)
    {
        self.originalName = _group.name;
        self.editName = _group.name;
        self.editIconName = _group.iconName;
        self.editColor = UIColorFromRGB(_group.color);
        self.editBackgroundIconName = _group.backgroundType;
    }

    [super postInit];

    if (self.isNewItem)
    {
        _group = [[OASGpxUtilitiesPointsGroup alloc] initWithName:self.editName
                                            iconName:self.editIconName
                                      backgroundType:self.editBackgroundIconName
                                               color:_group.color];
    }

    _nameTextField = [self getInputCellWithHint:OALocalizedString(@"shared_string_name")
                                           text:self.editName
                                            tag:0];
}

#pragma mark - UIViewController

- (void)generateDescriptionSection
{
    OATableSectionData *descriptionSection = [self.tableData createNewSection];
    descriptionSection.headerText = OALocalizedString(@"favorite_group_name");
    descriptionSection.footerText = OALocalizedString(@"default_appearance_desc");

    OATableRowData *groupNameRow = [descriptionSection createNewRow];
    groupNameRow.cellType = [OATextInputFloatingCell getCellIdentifier];
    groupNameRow.key = kInputNameKey;
    [groupNameRow setObj:_nameTextField forKey:@"cell"];
}

@end
