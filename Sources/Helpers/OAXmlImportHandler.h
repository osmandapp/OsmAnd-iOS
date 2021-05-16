//
//  OAXmlImportHandler.h
//  OsmAnd Maps
//
//  Created by Paul on 12.05.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAXmlImportHandler : NSObject

- (instancetype) initWithUrl:(NSURL *)url;
- (void) handleImport;

@end

NS_ASSUME_NONNULL_END
