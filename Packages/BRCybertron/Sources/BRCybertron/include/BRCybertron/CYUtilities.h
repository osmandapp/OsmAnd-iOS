//
//  CYUtilities.h
//  BRCybertron
//
//  Created by Matt on 6/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <Foundation/Foundation.h>

#import <libxml/tree.h>
#import "CYParsingContext.h"

@protocol CYInputSource;

NS_ASSUME_NONNULL_BEGIN

/**
 Utilities to help with XML/XSLT handling.
 */
@interface CYUtilities : NSObject

/**
 Handle parsing XML with support for capturing parsing errros and handling entity resolution. The @c block function
 will be invoked on the calling thread and passed a new parsing context instance. When the block returns, the 
 @c callback block will be invoked (also on the calling thread) and passed any errors captured from @c libxml during
 the execution of @c block.
 
 @param input    The input source that is going to be parsed in @c block.
 @param block    The block that exercises libxml functions and might generate errors in the process. The block will be passed a @c CYParsingContext
                 with properties configuerd to aid parsing.
 @param callback A block that will be invoked after the completion of @c block, with an array of errors or @c nil if no errors were generated.
 */
+ (void)handlePrasing:(id<CYInputSource>)input
			inContext:(xmlParserCtxtPtr)parserContext
				block:(void (^)(CYParsingContext *context))block
			 finished:(void (^)(NSArray<NSError *> * _Nullable errors))callback;

@end

NS_ASSUME_NONNULL_END
