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

- (void)updateData:(NSArray *)data type:(EOAWeatherToolbarDelegateType)type index:(NSInteger)index;

@end

@interface OAWeatherToolbarLayersHandler : NSObject<OAFoldersCellDelegate>

@property (nonatomic, weak) id<OAWeatherToolbarDelegate> delegate;

- (void)updateData;
- (NSArray<NSMutableDictionary *> *)getData;
- (BOOL)isAllLayersDisabled;

@end

@interface OAWeatherToolbarDatesHandler : NSObject<OAFoldersCellDelegate>

@property (nonatomic, weak) id<OAWeatherToolbarDelegate> delegate;

- (void)updateData;
- (NSArray<NSMutableDictionary *> *)getData;

@end
