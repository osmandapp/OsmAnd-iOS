//
//  OAQuickActionRegistry.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAQuickActionRegistry.h"
#import "OAQuickActionFactory.h"
#import "OAAppSettings.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAQuickAction.h"
#import "OAIAPHelper.h"
#import "OAMapStyleAction.h"

@implementation OAQuickActionRegistry
{
    OAQuickActionFactory *_factory;
    OAAppSettings *_settings;
    
    NSArray<OAQuickAction *> *_quickActions;
}

+ (OAQuickActionRegistry *) sharedInstance
{
    static OAQuickActionRegistry *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAQuickActionRegistry alloc] init];
    });
    return _sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        _factory = [[OAQuickActionFactory alloc] init];
        _settings = [OAAppSettings sharedManager];
        
        _quickActions = [_factory parseActiveActionsList:_settings.quickActionsList];
        _quickActionListChangedObservable = [[OAObservable alloc] init];
    }
    return self;
}

//public void setUpdatesListener(QuickActionUpdatesListener updatesListener) {
//    this.updatesListener = updatesListener;
//}
//
//public void notifyUpdates() {
//    if (updatesListener != null) updatesListener.onActionsUpdated();
//}

- (NSArray<OAQuickAction *> *) getQuickActions
{
    return [NSArray arrayWithArray:_quickActions];
}

- (NSArray<OAQuickAction *> *) getFilteredQuickActions
{
    NSArray<OAQuickAction *> *actions = [self getQuickActions];
    NSMutableArray<OAQuickAction *> *filteredActions = [NSMutableArray new];
    
    for (OAQuickAction *action in actions)
    {
        BOOL skip = NO;
//        if (OsmandPlugin.getEnabledPlugin(AudioVideoNotesPlugin.class) == null) {
//
//            if (action.type == TakeAudioNoteAction.TYPE || action.type == TakePhotoNoteAction.TYPE
//                || action.type == TakeVideoNoteAction.TYPE) {
//                skip = true;
//            }
//        }
        
        if (![OAPlugin getEnabledPlugin:OAParkingPositionPlugin.class])
            skip = action.type == EOAQuickActionTypeParking;
        
        if (![[OAIAPHelper sharedInstance].nautical isActive])
        {
            if (action.type == EOAQuickActionTypeMapStyle)
            {
                if (((OAMapStyleAction *)[OAQuickActionFactory produceAction:action]).getFilteredStyles.count == 0)
                    skip = YES;
            }
        }
//        if (OsmandPlugin.getEnabledPlugin(OsmandRasterMapsPlugin.class) == null) {
//            if (action.type == MapSourceAction.TYPE) {
//                skip = true;
//            }
//        }
        if (![OAPlugin getEnabledPlugin:OAOsmEditingPlugin.class])
            skip = action.type == EOAQuickActionTypeAddPOI || action.type == EOAQuickActionTypeAddNote;
        
        if (!skip)
            [filteredActions addObject:action];
    }
    
    return filteredActions;
}

- (void) addQuickAction:(OAQuickAction *)action
{
    _quickActions = [_quickActions arrayByAddingObject:action];
    [_settings setQuickActionsList:[_factory quickActionListToString:_quickActions]];
}

//TODO implement!!!
//
//-(void) deleteQuickAction:(OAQuickAction *) action
//{
//    NSInteger index = [_quickActions indexOfObject:action];
//    if (index != NSNotFound)
//    {
//        NSMutableArray<OAQuickAction *> *mutableActions = [NSMutableArray arrayWithArray:_quickActions];
//        [mutableActions removeObjectAtIndex:index];
//        _quickActions = [NSArray arrayWithArray:mutableActions];
//    }
//    [_settings setQuickActionsList:_factory quickActionListToString:_quickActions];
//}


- (void) updateQuickAction:(OAQuickAction *)action
{
    NSInteger index = [_quickActions indexOfObject:action];
    if (index != NSNotFound)
    {
        NSMutableArray<OAQuickAction *> *mutableActions = [NSMutableArray arrayWithArray:_quickActions];
        [mutableActions setObject:action atIndexedSubscript:index];
        _quickActions = [NSArray arrayWithArray:mutableActions];
    }
    [_settings setQuickActionsList:[_factory quickActionListToString:_quickActions]];
}

-(void) updateQuickActions:(NSArray<OAQuickAction *> *) quickActions
{
    _quickActions = [NSArray arrayWithArray:quickActions];
    [_settings setQuickActionsList:[_factory quickActionListToString:_quickActions]];
}

- (OAQuickAction *) getQuickAction:(long)identifier
{
    for (OAQuickAction *action in _quickActions)
    {
        if (action.identifier == identifier)
            return action;
    }
    return nil;
}

- (BOOL) isNameUnique:(OAQuickAction *)action
{
    for (OAQuickAction *a in _quickActions)
    {
        if (action.identifier != a.identifier)
        {
            if ([action.getName isEqualToString:a.getName])
                return NO;
        }
    }
    return YES;
}

- (OAQuickAction *) generateUniqueName:(OAQuickAction *)action
{
    NSInteger number = 0;
    NSString *name = action.getName;
    while (YES)
    {
        number++;
        [action setName:[NSString stringWithFormat:@"%@(%ld)", name, number]];
        if ([self isNameUnique:action])
            return action;
    }
}

- (OAQuickAction *) newActionByStringType:(NSString *)actionType
{
//    TODO refactor quick actions!
//
//    QuickActionType quickActionType = quickActionTypesStr.get(actionType);
//    if (quickActionType != null) {
//        return quickActionType.createNew();
//    }
    return nil;
}

- (OAQuickAction *) newActionByType:(int)type
{
//    TODO refactor quick actions!
//
//    QuickActionType quickActionType = quickActionTypesInt.get(type);
//    if (quickActionType != null) {
//        return quickActionType.createNew();
//    }
    return nil;
}

@end
