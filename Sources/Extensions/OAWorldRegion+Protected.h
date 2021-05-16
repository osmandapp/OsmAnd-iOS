//
//  OAWorldRegion+Protected.h
//  OsmAnd Maps
//
//  Created by Paul on 24.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWorldRegion.h"

@interface OAWorldRegion (hidden)

@property (nonatomic) NSString* nativeName;
@property (nonatomic) NSString* localizedName;

@end

@implementation OAWorldRegion (hidden)

@dynamic nativeName, localizedName;

@end
