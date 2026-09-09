//
//  OAQuickActionAppearanceViewController.mm
//  OsmAnd Maps
//
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

#import "OAQuickActionAppearanceViewController.h"
#import "OsmAndSharedWrapper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAQuickActionAppearanceViewController ()

@property (nonatomic, readwrite) BOOL isNewItem;

@end

@implementation OAQuickActionAppearanceViewController

@synthesize isNewItem = _isNewItem;

- (nullable instancetype)initWithColor:(UIColor *)color
                               iconName:(nullable NSString *)iconName
                     backgroundIconName:(nullable NSString *)backgroundIconName
{
    OASGpxUtilitiesPointsGroup *group = [[OASGpxUtilitiesPointsGroup alloc] initWithName:@""
                                                                                  iconName:iconName
                                                                            backgroundType:backgroundIconName
                                                                                     color:(int32_t) [color toARGBNumber]];
    self = [super initWithGroup:group];
    if (self)
        self.isNewItem = YES;
    return self;
}

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_appearance");
}

- (void)generateDescriptionSection
{
    // The Quick Action config screen already has a dedicated "Group" row for the folder name;
    // this screen only edits color / icon / shape.
}

- (BOOL)isValidText
{
    // There's no name field on this screen (see generateDescriptionSection above), so the
    // base class's name-validity gate on the Done button doesn't apply here.
    return YES;
}

- (void)onRightNavbarButtonPressed
{
    [[self getPoiIconCollectionHandler] addIconToLastUsed:self.editIconName];
    NSString *iconName = self.editIconName;
    UIColor *color = self.editColor;
    NSString *backgroundIconName = self.editBackgroundIconName;
    id<OAEditorDelegate> delegate = self.delegate;
    [self dismissViewController];
    [delegate addNewItemWithName:nil
                         iconName:iconName
                            color:color
               backgroundIconName:backgroundIconName];
}

@end
