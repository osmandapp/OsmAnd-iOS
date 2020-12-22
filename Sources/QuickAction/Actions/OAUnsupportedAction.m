//
//  OAUnsupportedAction.m
//  OsmAnd
//
//  Created by nnngrach on 18.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAUnsupportedAction.h"
#import "OAQuickActionType.h"
#import "OARootViewController.h"

#define kName @"name"
#define kActionType @"actionType"
#define kParams @"params"

static OAQuickActionType *TYPE;

@implementation OAUnsupportedAction

- (instancetype) initWithJSON:(NSDictionary *)json
{
    self = [super init];
    if (self) {
        self.identifier = [self hashFromJSON:json];
        if (json[kName])
            self.name = json[kName];
        if (json[kActionType])
            self.actionType = [OAUnsupportedAction CUSTOMCTYPE:json[kName] stringId:json[kActionType]];
        if (json[kParams])
            self.params = json[kParams];
    }
    return self;
}

- (long) hashFromJSON:(NSDictionary *)json
{
    NSMutableString *comapringString = [NSMutableString new];
    if (json[kName])
        [comapringString appendString:json[kName]];
    if (json[kActionType])
        [comapringString appendString:json[kActionType]];
    if (json[kParams])
        [comapringString appendString:json[kParams]];
    return [comapringString hash];
}

-(NSString *) getIconResName
{
    return @"ic_custom_alert";
}

-(NSString *) getDefaultName
{
    return OALocalizedString(@"unsupported_action");
}

- (NSString *)getActionText
{
    return OALocalizedString(@"unsupported_action_descr");
}

- (NSString *)getActionStateName
{
    return self.name.length > 0 ? self.name : OALocalizedString(@"unsupported_action");
}

-(NSInteger) getType
{
    return -1;
}

- (void)execute
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"unsupported_action_descr") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
    [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
}

+ (OAQuickActionType *) TYPE
{
    if (!TYPE)
        TYPE = [OAUnsupportedAction CUSTOMCTYPE:OALocalizedString(@"unsupported_action") stringId:@"unsupported_string_default"];
    return TYPE;
}

+ (OAQuickActionType *) CUSTOMCTYPE:(NSString *)name stringId:(NSString *)stringId
{
    return [[OAQuickActionType alloc] initWithIdentifier:42 stringId:stringId class:self.class name:name category:NAVIGATION iconName:@"ic_custom_alert" secondaryIconName:nil];
}

@end
