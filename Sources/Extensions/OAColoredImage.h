//
//  OAColoredImage.h
//  OsmAnd
//
//  Created by Max Kojin on 06/02/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@interface OAColoredImage : UIImage

@property(nonatomic) UIColor *color;

- (instancetype)initWithImage:(UIImage *)image color:(UIColor *)color;
- (instancetype)initWithName:(NSString *)name color:(UIColor *)color;

@end


@interface OAColoredImageView : UIImageView

- (void) updateAppeance;

@end
