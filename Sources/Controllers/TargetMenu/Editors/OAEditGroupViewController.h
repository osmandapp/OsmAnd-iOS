//
//  OAEditGroupViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OAEditGroupViewControllerDelegate <NSObject>

@optional
- (void) groupChanged;

@end

@interface OAEditGroupViewController : OABaseNavbarViewController<UITextFieldDelegate>

@property (strong, nonatomic) NSString *groupName;
@property (nonatomic, readonly) BOOL saveChanges;

@property (nonatomic, weak, nullable) id<OAEditGroupViewControllerDelegate> delegate;

- (nullable instancetype)initWithGroupName:(nullable NSString *)groupName groups:(NSArray *)groups;

@end

NS_ASSUME_NONNULL_END
