//
//  OAMapRulerView.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 19.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kMapRulerMinWidth 70
#define kMapRulerMaxWidth 150

@interface OAMapRulerView : UIView


-(void)setRulerData:(struct RulerData)data;

@end
