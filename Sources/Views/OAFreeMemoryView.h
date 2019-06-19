//
//  OAFreeMemoryView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 17/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAFreeMemoryView : UIView

- (instancetype) initWithFrame:(CGRect)frame localResourcesSize:(unsigned long long)localResourcesSize;

- (void) update;
- (void) setLocalResourcesSize:(unsigned long long)size;

@end
