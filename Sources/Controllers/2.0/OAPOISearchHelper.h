//
//  OAPOISearchHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    EPOIScopeUndefined = 0,
    EPOIScopeCategory,
    EPOIScopeFilter,
    EPOIScopeType,
    EPOIScopeUIFilter,
    
} EPOIScope;

@interface OAPOISearchHelper : NSObject

+ (CGFloat)getHeightForHeader;
+ (CGFloat)getHeightForFooter;

+ (NSInteger)getNumberOfRows:(NSArray *)dataArray dataPoiArray:(NSArray *)dataPoiArray currentScope:(EPOIScope)currentScope showCoordinates:(BOOL)showCoordinates showTopList:(BOOL)showTopList poiInList:(BOOL)poiInList searchRadiusIndex:(int)searchRadiusIndex searchRadiusIndexMax:(int)searchRadiusIndexMax;

+ (CGFloat)getHeightForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView dataArray:(NSArray *)dataArray dataPoiArray:(NSArray *)dataPoiArray showCoordinates:(BOOL)showCoordinates;

+ (UITableViewCell *)getCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView dataArray:(NSArray *)dataArray dataPoiArray:(NSArray *)dataPoiArray currentScope:(EPOIScope)currentScope poiInList:(BOOL)poiInList showCoordinates:(BOOL)showCoordinates foundCoords:(NSArray *)foundCoords showTopList:(BOOL)showTopList searchRadiusIndex:(int)searchRadiusIndex searchRadiusIndexMax:(int)searchRadiusIndexMax searchNearMapCenter:(BOOL)searchNearMapCenter;

@end
