//
//  OAQuickActionType.h
//  OsmAnd
//
//  Created by Paul on 27.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/quickaction/QuickActionType.java
//  git revision 908544e5608bda9e17973b313d6787032d35032d

#import <Foundation/Foundation.h>

#define UNSUPPORTED -1
#define CREATE_CATEGORY 0
#define CONFIGURE_MAP 1
#define NAVIGATION 2
#define CONFIGURE_SCREEN 3

@class OAQuickAction;

@interface OAQuickActionType : NSObject

@property (nonatomic, readonly) NSInteger identifier;
@property (nonatomic, readonly) NSString *stringId;
@property (nonatomic, readonly) BOOL actionEditable;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *iconName;
@property (nonatomic, readonly) NSString *secondaryIconName;
@property (nonatomic, readonly) NSInteger category;

- (instancetype) initWithIdentifier:(NSInteger) identifier stringId:(NSString *) stringId;

- (instancetype) initWithIdentifier:(NSInteger) identifier
                           stringId:(NSString *) stringId
                              class:(id) cl
                            name:(NSString *) name
                           category:(NSInteger) category
                            iconName:(NSString *) iconName
                   secondaryIconName:(NSString *)secondaryIconName;

- (instancetype) initWithIdentifier:(NSInteger) identifier
                           stringId:(NSString *) stringId
                              class:(id) cl
                               name:(NSString *) name
                           category:(NSInteger) category
                           iconName:(NSString *) iconName;

- (instancetype) initWithIdentifier:(NSInteger) identifier
                           stringId:(NSString *) stringId
                              class:(id) cl
                               name:(NSString *) name
                           category:(NSInteger) category
                           iconName:(NSString *) iconName
                  secondaryIconName:(NSString *)secondaryIconName
                           editable:(BOOL) editable;

- (OAQuickAction *) createNew;
- (OAQuickAction *) createNew:(OAQuickAction *) q;

- (BOOL) hasSecondaryIcon;

@end
