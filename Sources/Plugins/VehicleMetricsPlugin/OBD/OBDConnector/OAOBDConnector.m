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
@property (nonatomic, strong, nullable) OASOBDSimulationSource *simulator;
@end

@interface OAOkioSource() <OASOkioSource>
@end

@interface OAOkioSink() <OASOkioSink>
@end

@implementation OAOBDConnector

- (OASOBDSimulationSource *)simulator {
    if (!_simulator) {
        _simulator = [[OASOBDSimulationSource alloc] init];
    }
    return _simulator;
}

- (OASKotlinPair<id<OASOkioSource>,id<OASOkioSink>> * _Nullable)connect
{
    NSLog(@"[OAOBDConnector] -> connect");
    
    // NOTE: real device
    OAOkioSource *itemSource = [OAOkioSource new];
    OAOkioSink *itemSink = [OAOkioSink new];
    OASKotlinPair *pair = [[OASKotlinPair alloc] initWithFirst:itemSource second:itemSink];
    
    // NOTE: obd Simulator
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

@end

@implementation OAOkioSource
{
    OBDService *_OBDService;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _OBDService = [OBDService shared];
    }
    return self;
}


- (BOOL)closeAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSLog(@"[OAOkioSource] -> closeAndReturnError");
    
    return NO;
}

- (int64_t)readSink:(OASOkioBuffer *)sink
          byteCount:(int64_t)byteCount
              error:(NSError * _Nullable __autoreleasing *)error {
    if (![_OBDService isBufferReadyForRead])
        return 0;
    
    NSString *buffer = [_OBDService readObdBuffer];
    if (buffer.length == 0)
        return 0;
    
    NSLog(@"readSink: %@", buffer);
    [_OBDService isProcessingReadingWithIsReading:YES];
    if (buffer.length <= byteCount) {
        [_OBDService clearBuffer];
        [sink writeUtf8String:buffer];
        [_OBDService isProcessingReadingWithIsReading:NO];
        return buffer.length;
    } else {
        NSString *substring = [buffer substringToIndex:byteCount];
        NSLog(@"substring: %@", substring);
        NSString *bufferToWrite = [buffer substringFromIndex:byteCount];
        NSLog(@"bufferToWrite: %@", bufferToWrite);
        
        if (bufferToWrite.length > 0)
            [_OBDService writeObdBuffer:bufferToWrite];
        else
            [_OBDService clearBuffer];
        
        [sink writeUtf8String:substring];
        
        [_OBDService isProcessingReadingWithIsReading:NO];
        
        return byteCount;
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
