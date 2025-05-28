//
//  OAOBDConnector.m
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 23.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAOBDConnector.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAOBDConnector() <OASOBDConnector>
@end

@interface OAOkioSource() <OASOkioSource>
@end

@interface OAOkioSink() <OASOkioSink>
@end

@implementation OAOBDConnector
{
    OASOBDSimulationSource *_simulator;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _simulator = [[OASOBDSimulationSource alloc] init];
    }
    return self;
}

- (OASKotlinPair<id<OASOkioSource>,id<OASOkioSink>> * _Nullable)connect
{
    NSLog(@"[OAOBDConnector] -> connect");
    
    // NOTE: real device
    OAOkioSource *itemSource = [OAOkioSource new];
    OAOkioSink *itemSink = [OAOkioSink new];
    OASKotlinPair *pair = [[OASKotlinPair alloc] initWithFirst:itemSource second:itemSink];
    
    // NOTE: Simulator
    // OASKotlinPair *pair = [[OASKotlinPair alloc] initWithFirst:_simulator.reader second:_simulator.writer];
    
    return pair;
}

- (void)disconnect
{
    NSLog(@"[OAOBDConnector] -> disconnect");
    if (self.disconnectHandler)
        self.disconnectHandler();
}

- (void)onConnectionFailed
{
    NSLog(@"[OAOBDConnector] -> onConnectionFailed");
    if (self.failureHandler)
        self.failureHandler();
}

- (void)onConnectionSuccess
{
    NSLog(@"[OAOBDConnector] -> onConnectionSuccess");
}

#pragma mark - Public Setters

- (void)setDisconnectHandler:(void (^)(void))handler
{
    self.disconnectHandler = handler;
}

- (void)setFailureHandler:(void (^)(void))handler
{
    self.failureHandler = handler;
}

@end

@implementation OAOkioSource


- (BOOL)closeAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSLog(@"[OAOkioSource] -> closeAndReturnError");
    
    return NO;
}

- (int64_t)readSink:(OASOkioBuffer *)sink byteCount:(int64_t)byteCount error:(NSError * _Nullable __autoreleasing *)error {
    NSString *buffer = [[OBDService shared] readObdBuffer];
    if ([[OBDService shared] isReadyBufferResponse] && buffer && buffer.length > 0)
    {
        NSInteger readCount = MIN(byteCount, buffer.length);
        if (readCount > 0)
        {
            NSString *firstChar = [buffer substringToIndex:readCount];
            NSString *bufferToWrite = [buffer substringFromIndex:readCount];
            if (bufferToWrite.length > 0)
            {
                [[OBDService shared] writeObdBuffer:bufferToWrite];
            } else {
                [[OBDService shared] clearBuffer];
            }
            [sink writeUtf8String:firstChar];
            
            return readCount;
        }
    }
    return 0;
}

- (nonnull OASOkioTimeout *)timeout
{
    NSLog(@"[OAOkioSource] -> timeout");
    return OASOkioTimeout.companion.NONE;
}

@end


@implementation OAOkioSink

- (BOOL)flushAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSLog(@"[OAOkioSink] -> flushAndReturnError");
    return NO;
}

- (BOOL)writeSource:(nonnull OASOkioBuffer *)source
          byteCount:(int64_t)byteCount
              error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSLog(@"[OAOkioSink] -> writeSource"); // [text=ATD\r]
    NSString *raw = source.description;

    NSString *command = [raw stringByReplacingOccurrencesOfString:@"[text=" withString:@""];
    command = [command stringByReplacingOccurrencesOfString:@"\\r]" withString:@"\r"];
    NSLog(@"Extracted value: %@", command);
    return [[OBDService shared] sendCommand:command];
}

- (nonnull OASOkioTimeout *)timeout
{
    NSLog(@"[OAOkioSink] -> timeout");
    return OASOkioTimeout.companion.NONE;
}

- (BOOL)closeAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSLog(@"[OAOkioSink] -> closeAndReturnError");
    return NO;
}

@end
