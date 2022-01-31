//
//  OATableViewCustomHeaderView.h
//  OsmAnd
//
//  Created by Paul on 7/3/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OATableViewCustomHeaderView : UITableViewHeaderFooterView

@property (nonatomic, readonly) UITextView *label;

- (void) setXOffset:(CGFloat)xOffset;
- (void) setYOffset:(CGFloat)yOffset;

+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width;
+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width yOffset:(CGFloat)yOffset font:(UIFont *)font;
+ (CGFloat) getHeight:(NSString *)text width:(CGFloat)width xOffset:(CGFloat)xOffset yOffset:(CGFloat)yOffset font:(UIFont *)font;

@end

