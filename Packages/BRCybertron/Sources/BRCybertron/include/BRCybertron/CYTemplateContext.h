//
//  CYTemplateContext.h
//  BRCybertron
//
//  Created by Matt on 10/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <Foundation/Foundation.h>

@class CYTemplate;
@protocol CYInputSourceResolver;

NS_ASSUME_NONNULL_BEGIN

/**
 Object used to help with keeping track of state during XSLT execution.
 */
@interface CYTemplateContext : NSObject

@property (nonatomic, weak, readonly) CYTemplate *xslt;
@property (nonatomic, strong) NSArray<NSError *> *errors;
@property (nonatomic, strong) id<CYInputSourceResolver> inputSourceResolver;

/**
 Initialize with an XSLT template.
 
 @param xslt The template.
 
 @return The initialized instance.
 */
- (instancetype)initWithTemplate:(CYTemplate *)xslt NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
