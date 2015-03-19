//
//  OAPOIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAPOIHelper : NSObject

@property (nonatomic, readonly) NSArray *poiTypes;
@property (nonatomic, readonly) NSDictionary *poiCategories;

+ (OAPOIHelper *)sharedInstance;

- (void)updatePhrases;
- (NSArray *)poiTypesForCategory:(NSString *)categoryName;
+ (UIImage *)categoryIcon:(NSString *)categoryName;

@end
