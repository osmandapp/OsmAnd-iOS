//
//  OAPublicTransportShieldCell.h
//  OsmAnd
//
//  Created by Paul on 12/03/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAPublicTransportShieldCell : UITableViewCell

@property (nonatomic, readonly) NSArray<NSString *> *titles;

-(void) setData:(NSNumber *)data;
-(void) needsSafeAreaInsets:(BOOL)needsInsets;

+ (CGFloat) getCellHeight:(CGFloat)width shields:(NSArray<NSString *> *)shields;
+ (CGFloat) getCellHeight:(CGFloat)width shields:(NSArray<NSString *> *)shields needsSafeArea:(BOOL)needsSafeArea;

@end
