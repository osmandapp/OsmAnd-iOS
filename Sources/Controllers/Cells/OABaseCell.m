//
//  OABaseCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 06.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@implementation OABaseCell

- (NSString *) getCellIdentifier
{
    @throw [NSException exceptionWithName:@"OABaseCell error" reason:@"Cell identifier is not defined in cell class" userInfo:nil];
}

@end
