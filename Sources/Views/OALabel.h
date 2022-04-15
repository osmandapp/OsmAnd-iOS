//
//  OALabel.h
//  OsmAnd
//
//  Created by Skalii on 15.04.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OALabelDelegate <NSObject>

@optional

- (void) onCopy;

@end

@interface OALabel : UILabel

@property (nonatomic) id<OALabelDelegate> delegate;

@end
