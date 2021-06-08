//
//  OAGpxWptEditingHandler.h
//  OsmAnd Maps
//
//  Created by Skalii on 02.06.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABasePointEditingHandler.h"

@class OAGpxWptItem;

NS_ASSUME_NONNULL_BEGIN

struct CLLocationCoordinate2D;

@interface OAGpxWptEditingHandler : OABasePointEditingHandler

- (NSArray<NSDictionary<NSString *, NSString *> *> *)getGroups;
- (NSDictionary<NSString *, NSString *> *)getGroupsWithColors;
- (NSString *)getAddress;
- (void)setGroup:(NSString *)groupName color:(UIColor *)color save:(BOOL)save;

- (instancetype)initWithItem:(OAGpxWptItem *)gpxWpt;
- (instancetype)initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)formattedTitle gpxFileName:(NSString*)gpxFileName;

@end

NS_ASSUME_NONNULL_END
