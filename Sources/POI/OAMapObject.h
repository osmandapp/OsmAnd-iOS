//
//  OAMapObject.h
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAMapObject : NSObject

@property (nonatomic) unsigned long long obfId;

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *enName;
@property (nonatomic) NSString *nameLocalized;
@property (nonatomic) NSDictionary<NSString *, NSString *> *localizedNames;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic) NSMutableArray<NSNumber *> *x;
@property (nonatomic) NSMutableArray<NSNumber *> *y;

- (void) addLocation:(int)x y:(int)y;
- (void) setName:(NSString *)lang name:(NSString *)name;

@end
