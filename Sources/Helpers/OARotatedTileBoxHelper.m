////
////  OARotatedTileBoxHelper.m
////  OsmAnd Maps
////
////  Created by Max Kojin on 21/03/24.
////  Copyright © 2024 OsmAnd. All rights reserved.
////
//
///*
//    In IOS we don't have RotatedTileBox class like in java.
//    This is just a wrapper for helping quickly find and use some methods from this java class.
//    And for storing all that methods in one place.
//*/
//
//#import "OARotatedTileBoxHelper.h"
//#import "OAMapUtils.h"
//
//@implementation OARotatedTileBoxHelper
//
////TODO: implement
//+ (double) zoom
//{
//    
//}
//
////TODO: implement
//+ (double) pixWidth
//{
//    
//}
//
////TODO: implement
//+ (double) pixHeight
//{
//    
//}
//
////TODO: implement
//+ (double) cx
//{
//    
//}
//
////TODO: implement
//+ (double) cy
//{
//    
//}
//
////TODO: implement
//+ (double) ratioCX
//{
//    
//}
//
////TODO: implement
//+ (double) ratioCY
//{
//    
//}
//
////TODO: implement
//+ (double) rotateSin
//{
//    
//}
//
////TODO: implement
//+ (double) rotateCos
//{
//    
//}
//
////TODO: implement
//+ (double) zoomFactor
//{
//    
//}
//
////TODO: implement
//+ (double) oxTile
//{
//    
//}
//
////TODO: implement
//+ (double) oyTile
//{
//    
//}
//   
//
////TODO: implement
//+ (BOOL) isMapRotateEnabled
//{
//    
//}
//
////TODO: implement
//+ (double) getDensity
//{
//    
//}
//
//+ (double) getPixDensity
//{
//    double dist = [OAMapUtils getDistance:0 pixY:([self pixHeight] / 2) pixX2:[self pixWidth] pixY2:([self pixHeight] / 2)];
//    return [self pixWidth] / dist;
//}
//
//+ (double) getLatFromPixel:(float)x y:(float)y
//{
//    return [OAMapUtils getLatitudeFromTile:[self zoom] y:[self getTileYFromPixel:x y:y]];
//}
//
//+ (double) getLonFromPixel:(float)x y:(float)y
//{
//    return [OAMapUtils getLongitudeFromTile:[self zoom] x:[self getTileXFromPixel:x y:y]];
//}
//
//+ (double) getTileXFromPixel:(float)x y:(float)y
//{
//    double dx = x - [self cx];
//    double dy = y - [self cy];
//    double dtilex;
//    if ([self isMapRotateEnabled])
//    {
//        dtilex = [self rotateCos] * dx + [self rotateSin] * dy;
//    }
//    else
//    {
//        dtilex = dx;
//    }
//    return dtilex / [self zoomFactor] + [self oxTile];
//}
//
//+ (double) getTileYFromPixel:(float)x y:(float)y
//{
//    double dx = x - [self cx];
//    double dy = y - [self cy];
//    double dtiley;
//    if ([self isMapRotateEnabled])
//    {
//        dtiley = -[self rotateSin] * dx + [self rotateCos] * dy;
//    }
//    else
//    {
//        dtiley = dy;
//    }
//    return dtiley / [self zoomFactor] + [self oyTile];
//}
//
//+ (BOOL) isCenterShifted
//{
//    return [self ratioCX] != 0.5 || [self ratioCY] != 0.5;
//}
//
//
//
////TODO: implement and delete
////public void setCenterLocation(float ratiocx, float ratiocy) {
////    this.cx = (int) (pixWidth * ratiocx);
////    this.cy = (int) (pixHeight * ratiocy);
////    this.ratiocx = ratiocx;
////    this.ratiocy = ratiocy;
////    calculateDerivedFields();
////}
//
//+ (void) setCenterLocation:(float)ratiocx ratiocy:(float)ratiocy
//{
//    
//}
//
//@end
