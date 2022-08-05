//
//  OAWeatherToolbarHandlers.h
//  OsmAnd
//
//  Created by Skalii on 17.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAFoldersCollectionView.h"

typedef NS_ENUM(NSInteger, EOAWeatherToolbarDelegateType)
{
    EOAWeatherToolbarLayers = 0,
    EOAWeatherToolbarDates,
};

@protocol OAWeatherToolbarDelegate

- (void)updateData:(NSArray *)data type:(EOAWeatherToolbarDelegateType)type;

@end

@interface OAWeatherToolbarLayersHandler : NSObject<OAFoldersCellDelegate>

@property (nonatomic, weak) id<OAWeatherToolbarDelegate> delegate;

- (void)updateData;
- (NSArray *)getData;

@end

@interface OAWeatherToolbarDatesHandler : NSObject<OAFoldersCellDelegate>

- (instancetype)initWithAvailable:(BOOL)available date:(NSDate *)date;

@property (nonatomic, weak) id<OAWeatherToolbarDelegate> delegate;

- (void)updateData:(BOOL)available date:(NSDate *)date;
- (NSArray<NSMutableDictionary *> *)getData;

@end
