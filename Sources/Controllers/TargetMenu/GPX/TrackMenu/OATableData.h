//
//  OATableData.h
//  OsmAnd
//
//  Created by Skalii on 07.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OATableCellData : NSObject

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
                  title:(NSString *)title
                   desc:(NSString *)desc
               leftIcon:(NSString *)leftIcon
              rightIcon:(NSString *)rightIcon
                 toggle:(BOOL)toggle;

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
                  title:(NSString *)title;

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                  title:(NSString *)title;

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values;

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
                 toggle:(BOOL)toggle;

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                 values:(NSDictionary *)values
                   desc:(NSString *)desc
               leftIcon:(NSString *)leftIcon;

+ (instancetype)withKey:(NSString *)key
               cellType:(NSString *)cellType
                  title:(NSString *)title
              rightIcon:(NSString *)rightIcon
                 toggle:(BOOL)toggle;

@property (nonatomic) NSString *key;
@property (nonatomic) NSString *cellType;
@property (nonatomic) NSDictionary *values;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *desc;
@property (nonatomic) NSString *leftIcon;
@property (nonatomic) NSString *rightIcon;
@property (nonatomic) BOOL toggle;

@end

@interface OATableSectionData : NSObject

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells
                 header:(NSString *)header
                 footer:(NSString *)footer;

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells
                 header:(NSString *)header;

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells
                 footer:(NSString *)footer;

+ (instancetype)withKey:(NSString *)key
                  cells:(NSArray<OATableCellData *> *)cells;

+ (instancetype)withKey:(NSString *)key;

@property (nonatomic) NSString *key;
@property (nonatomic) NSArray<OATableCellData *> *cells;
@property (nonatomic) NSString *header;
@property (nonatomic) NSString *footer;

- (BOOL)containsCell:(NSString *)key;

@end

@interface OATableData : NSObject

+ (instancetype)withSections:(NSArray<OATableSectionData *> *)sections;

@property (nonatomic) NSArray<OATableSectionData *> *sections;

- (void)setCells:(NSArray<OATableCellData *> *)cells inSection:(NSString *)key;
- (void)setCell:(OATableCellData *)cell inSection:(NSString *)key;
- (void)removeCell:(NSString *)key;
- (NSInteger)getSectionPosition:(NSString *)key;
- (OATableSectionData *)findSection:(NSString *)key;

@end
