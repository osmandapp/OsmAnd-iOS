//
//  NavigationItem.h
//  OsmAnd
//
//  Created by egloff on 23/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface NavigationItem : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceImage *bearingImage;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *nameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *distanceLabel;

@end
