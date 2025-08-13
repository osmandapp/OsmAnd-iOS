//
//  OAWeatherToolbarHandlers.h
//  OsmAnd
//
//  Created by Skalii on 17.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAFoldersCollectionView.h"

@protocol OAWeatherToolbarDelegate

- (void)updateData:(NSArray *)data index:(NSInteger)index;

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
