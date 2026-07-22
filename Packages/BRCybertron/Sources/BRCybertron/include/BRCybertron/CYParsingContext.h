//
//  CYParsingContext.h
//  BRCybertron
//
//  Created by Matt on 8/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <Foundation/Foundation.h>

#import <libxml/tree.h>

@protocol CYEntityResolver;
@protocol CYInputSource;

NS_ASSUME_NONNULL_BEGIN

/**
 Object used to help with keeping track of state during parsing.
 */
@interface CYParsingContext : NSObject

@property (nonatomic, weak, readonly) id<CYInputSource> inputSource;

@property (nonatomic, strong) NSArray<NSError *> *errors;
@property (nonatomic, strong) id<CYEntityResolver> entityResolver;
@property (nonatomic, assign, nullable) getEntitySAXFunc getEntityFn;

/**
 Initialize with an input source.
 
 @param inputSource The input source.
 
 @return The initialized instance.
 */
- (instancetype)initWithInputSource:(id<CYInputSource>)inputSource NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
