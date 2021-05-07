//
//  OABaseHeaderFooterCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 07.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseHeaderFooterCell.h"

@implementation OABaseHeaderFooterCell

- (NSString *) getCellIdentifier
{
    @throw [NSException exceptionWithName:@"OABaseHeaderFooterCell error" reason:@"Cell identifier is not defined in cell class" userInfo:nil];
}

@end
