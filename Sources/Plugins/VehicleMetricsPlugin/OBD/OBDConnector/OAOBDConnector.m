//
//  OAOBDConnector.m
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 23.05.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAOBDConnector.h"
#import "OsmAndSharedWrapper.h"

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

- (OASKotlinPair<id<OASOkioSource>,id<OASOkioSink>> * _Nullable)connect {
    NSLog(@"[OAOBDConnector] -> connect");
// NOTE: real device
//    auto itemSource = [OATestOkioSource new];
//    auto itemSink = [OATestOkioSink new];
//    auto pair = [[OASKotlinPair alloc] initWithFirst:itemSource second:itemSink];
    
    OASKotlinPair *pair = [[OASKotlinPair alloc] initWithFirst:_simulator.reader second:_simulator.writer];
    
    return pair;
}

- (void)disconnect {
    NSLog(@"[OAOBDConnector] -> disconnect");
}

- (void)onConnectionFailed {
    NSLog(@"[OAOBDConnector] -> onConnectionFailed");
}

- (void)onConnectionSuccess {
    NSLog(@"[OAOBDConnector] -> onConnectionSuccess");
}

@end

@implementation OAOkioSource

- (BOOL)closeAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSLog(@"[OAOkioSource] -> closeAndReturnError");
    
    return NO;
}

- (int64_t)readSink:(nonnull OASOkioBuffer *)sink
          byteCount:(int64_t)byteCount
              error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    // INFO: [Obd2Connection] runImpl(010C) returned 410C1F40
    // convert buff to int64_t (respons)
    //
    NSLog(@"[OAOkioSource] -> readSink");
    return 0;
}

- (nonnull OASOkioTimeout *)timeout {
    NSLog(@"[OAOkioSource] -> timeout");
    return OASOkioTimeout.companion.NONE;
}

@end


@implementation OAOkioSink

- (BOOL)flushAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSLog(@"[OAOkioSink] -> flushAndReturnError");
    return NO;
}

- (BOOL)writeSource:(nonnull OASOkioBuffer *)source
          byteCount:(int64_t)byteCount
              error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSLog(@"[OAOkioSink] -> writeSource");
    
    // source == 010C -> Device write command
    
//
//    guard let data = "\(command)\r".data(using: .ascii) else {
//        NSLog("[BLEManager] -> sendCommand | Error: data is empty ")
//        throw BLEManagerError.isEmptyData
//    }
//    return try await Timeout(seconds: 3) {
//        try await withCheckedThrowingContinuation { [weak self] (continuation: CheckedContinuation<[String], Error>) in
//            // Set up a timeout timer
//            self?.sendMessageCompletion = { response, error in
//                if let response = response {
//                    continuation.resume(returning: response)
//                } else if let error = error {
//                    continuation.resume(throwing: error)
//                }
//                self?.sendMessageCompletion = nil
//            }
//            if let device = DeviceHelper.shared.connectedDevices.first(where: { $0.deviceType == .OBD_VEHICLE_METRICS }) as? OBDVehicleMetricsDevice {
//                guard device.peripheral.state == .connected else {
//                    NSLog("[BLEManager] -> Error: state != .connected ")
//                    BLEManager.shared.sendMessageCompletion?(nil, BLEManagerError.noData)
//                    return
//                }
//                guard let characteristic = device.ecuWriteCharacteristic else {
//                    NSLog("[BLEManager] -> Error: ecuWriteCharacteristic is empty ")
//                    return
//                }
//                device.peripheral.writeValue(ofCharac: characteristic, value: data, completion: { _ in })
//            }
//        }
    
    // write to ble device
    return NO;
}

- (nonnull OASOkioTimeout *)timeout {
    NSLog(@"[OAOkioSink] -> timeout");
    return OASOkioTimeout.companion.NONE;
}

- (BOOL)closeAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSLog(@"[OAOkioSink] -> closeAndReturnError");
    return NO;
}

@end
