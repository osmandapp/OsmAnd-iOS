//
//  OAUnsupportedAction.m
//  OsmAnd
//
//  Created by nnngrach on 18.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAUnsupportedAction.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

static QuickActionType *TYPE;

@implementation OAUnsupportedAction
{
    NSString *_actionTypeId;
}

- (instancetype) initWithActionTypeId:(NSString *)actionTypeId;
{
    self = [super initWithActionType:self.class.TYPE];
    if (self)
        _actionTypeId = actionTypeId;

    return self;
}

+ (void)initialize
{
    TYPE = [[[[[[QuickActionType alloc] initWithId:EOAQuickActionIdsUnsupportedId
                                            stringId:@"unsupported.action"
                                                  cl:self.class]
               name:OALocalizedString(@"unsupported_action")]
              iconName:@"ic_custom_alert"]
             category:QuickActionTypeCategoryUnsupported]
            nonEditable];
}

- (NSString *)getActionTypeId
{
    return _actionTypeId;
}

- (NSString *) getIconResName
{
    return @"ic_custom_alert";
}

- (NSString *) getDefaultName
{
    return [NSString stringWithFormat:OALocalizedString(@"unsupported_action_title"), _actionTypeId];
}

- (NSString *) getActionText
{
    return OALocalizedString(@"unsupported_action_descr");
}

- (NSString *) getActionStateName
{
    NSString *name = self.getName;
    return name.length > 0 ? name : OALocalizedString(@"unsupported_action");
}

- (void) execute
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"unsupported_action_descr") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
}

+ (QuickActionType *) TYPE
{
    return TYPE;
}

@end
