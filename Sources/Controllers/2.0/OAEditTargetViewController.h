//
//  OAEditTargetViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import <CoreLocation/CoreLocation.h>

@interface OAEditTargetViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (assign, nonatomic) CLLocationCoordinate2D location;
@property (assign, nonatomic) BOOL newItem;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger savedColorIndex;
@property (nonatomic, copy) NSString *savedGroupName;
@property (nonatomic, copy) NSString *desc;

- (id)initWithItem:(id)item;
- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString *)formattedLocation;

- (void)deleteItem;

- (BOOL) isItemExists:(NSString *)name;

- (void)saveItemToStorage;
- (void)removeExistingItemFromCollection;
- (void)removeNewItemFromCollection;

- (NSString *)getItemName;
- (void)setItemName:(NSString *)name;

- (UIColor *)getItemColor;
- (void)setItemColor:(UIColor *)color;

- (NSString *)getItemGroup;
- (void)setItemGroup:(NSString *)groupName;
- (NSArray *)getItemGroups;

- (NSString *)getItemDesc;
- (void)setItemDesc:(NSString *)desc;

@end