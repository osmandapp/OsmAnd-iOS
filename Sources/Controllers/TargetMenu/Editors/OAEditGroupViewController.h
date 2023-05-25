//
//  OAEditGroupViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@protocol OAEditGroupViewControllerDelegate <NSObject>

@optional
- (void) groupChanged;

@end

@interface OAEditGroupViewController : OABaseNavbarViewController<UITextFieldDelegate>

@property (strong, nonatomic) NSString* groupName;
@property (nonatomic, readonly) BOOL saveChanges;

@property (nonatomic, weak) id<OAEditGroupViewControllerDelegate> delegate;

-(instancetype)initWithGroupName:(NSString *)groupName groups:(NSArray *)groups;

@end
