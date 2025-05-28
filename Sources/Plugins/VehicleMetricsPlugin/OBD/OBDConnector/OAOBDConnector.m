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
}

- (void)onConnectionFailed
{
    NSLog(@"[OAOBDConnector] -> onConnectionFailed");
}

- (void)onConnectionSuccess
{
    NSLog(@"[OAOBDConnector] -> onConnectionSuccess");
}

@end

@implementation OAOkioSource

int64_t int64FromStringSafe(NSString *string)
{
    static NSNumberFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = NSNumberFormatterDecimalStyle;
    });

    NSNumber *number = [formatter numberFromString:string];
    if (number != nil)
    {
        return [number longLongValue];
    }
    else
    {
        return 0;
    }
}

- (BOOL)closeAndReturnError:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    NSLog(@"[OAOkioSource] -> closeAndReturnError");
    
    return NO;
}

- (int64_t)readSink:(OASOkioBuffer *)sink byteCount:(int64_t)byteCount error:(NSError * _Nullable __autoreleasing *)error {
    if ([[OBDService shared] isReadyBufferResponse])
    {
        NSData *bufferResponse = [[OBDService shared] bufferResponse];
        if (bufferResponse)
        {
            [[OBDService shared] clearBuffer];
            NSString *bufferToRead = [[NSString alloc] initWithData:bufferResponse encoding:NSUTF8StringEncoding];
            if (bufferToRead.length > 0) {
                NSInteger readCount = MIN(byteCount, bufferToRead.length);
                if (readCount > 0) {
                    NSString *dataToWrite = [bufferToRead substringToIndex:readCount];
                    bufferToRead = [bufferToRead substringFromIndex:readCount];
                    // FIXME: ?
        //            NSData *utf8Data = [dataToWrite dataUsingEncoding:NSUTF8StringEncoding];
        //            [sink appendData:utf8Data];
        //
                    return readCount;
                }
            }
        }
    }
    return 0;
}


- (int64_t)readSink:(nonnull OASOkioBuffer *)sink
          byteCount:(int64_t)byteCount
              error:(NSError * _Nullable __autoreleasing * _Nullable)error
{
    // INFO: [Obd2Connection] runImpl(010C) returned 410C1F40
    // convert buff to int64_t (respons)
    //
    NSLog(@"[OAOkioSource] -> readSink");
  //  [sink writeUtf8String:<#(nonnull NSString *)#>]
    if ([[OBDService shared] isReadyBufferResponse])
    {
        
        NSData *bufferResponse = [[OBDService shared] bufferResponse];
        if (bufferResponse)
        {
            NSString *string = [[NSString alloc] initWithData:bufferResponse encoding:NSUTF8StringEncoding];
            NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
            
//            NSString *str = @"9876543210";
//            int64_t value = int64FromStringSafe(str);
//            NSLog(@"Parsed value: %lld", value);
            
            [[OBDService shared] clearBuffer];
            
            return 0;
            
//            if (bufferResponse.length == sizeof(int64_t)) {
//                int64_t value;
//                [bufferResponse getBytes:&value length:sizeof(int64_t)];
//                
//                // Optional: if the data was encoded in network byte order (big endian), convert it
//                value = CFSwapInt64BigToHost(value);
//                
//                NSLog(@"Converted value: %lld", value);
//                return value;
//            } else {
//                NSLog(@"Invalid NSData length: expected %lu bytes, got %lu", sizeof(int64_t), (unsigned long)bufferResponse.length);
//            }
        }
    }
    
    return 0;
}

- (NSString *)toNormalizedHex:(NSInteger)data {
    NSString *hexString = [[NSString stringWithFormat:@"%lX", (unsigned long)data] uppercaseString];
    if (hexString.length % 2 != 0) {
        return [@"0" stringByAppendingString:hexString];
    } else {
        return hexString;
    }
}

//
//- (void)writeWithSource:(NSString *)source byteCount:(int64_t)byteCount {
//    NSString *fullCommand = source;
//    
//    NSMutableArray<NSString *> *split = [NSMutableArray array];
//    for (NSUInteger i = 0; i < fullCommand.length; i += 2) {
//        NSUInteger len = MIN(2, fullCommand.length - i);
//        [split addObject:[fullCommand substringWithRange:NSMakeRange(i, len)]];
//    }
//    NSString *commandCode = split.count > 0 ? split[0] : @"";
//    NSString *command = split.count > 1 ? split[1] : @"";
//    
//    NSString *trimmed = [[fullCommand stringByReplacingOccurrencesOfString:@"\r" withString:@""]
//                          stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
//    if ([OASObd2Connection.companion isInitCommandCommand:trimmed]) {
//      //  self.bufferToRead = @">";
//        return;
//    }
//    
//    NSString *commandTypeCode;
//    if ([commandCode isEqualToString:@"01"]) {
//        commandTypeCode = @"41";
//    } else if ([commandCode isEqualToString:@"09"]) {
//        commandTypeCode = @"49";
//    } else {
//        @throw [NSException exceptionWithName:NSInvalidArgumentException
//                                       reason:[NSString stringWithFormat:@"Not supported command group %@", commandCode]
//                                     userInfo:nil];
//    }
//    
//    NSUInteger codeValue = strtoul(commandCode.UTF8String, NULL, 16);
//    NSUInteger paramValue = strtoul(command.UTF8String,    NULL, 16);
//    
//    OASOBDCommand *obdCommand = [OASOBDCommand.companion getByCodeCommandGroup:(int)codeValue commandId:(int)paramValue];
//    if (obdCommand.ordinal == OASOBDCommand.entries.count - 1) {
//        [NSThread sleepForTimeInterval:2000 / 1000.0];
//    }
//    
//   
//    NSString *response = @"";
//    if (obdCommand == OASOBDCommand.obdVinCommand) {
//        response = @"";
//    } else if (obdCommand == OASOBDCommand.obdCalculatedEngineLoadCommand) {
//        response = [self toNormalizedHex:102];
//    } else if (obdCommand == OASOBDCommand.obdThrottlePositionCommand) {
//        response = [self toNormalizedHex:66];
//    } else if (obdCommand == OASOBDCommand.obdEngineOilTemperatureCommand) {
//        response = [self toNormalizedHex:130];
//    } else if (obdCommand == OASOBDCommand.obdFuelPressureCommand) {
//        int randomVal = arc4random_uniform(35000 - 24500) + 24500;
//        response = [self toNormalizedHex:randomVal];
//    } else if (obdCommand == OASOBDCommand.obdBatteryVoltageCommand) {
//        response = [self toNormalizedHex:12700];
//    } else if (obdCommand == OASOBDCommand.obdAmbientAirTemperatureCommand) {
//        response = [self toNormalizedHex:45];
//    } else if (obdCommand == OASOBDCommand.obdRpmCommand) {
//        response = [self toNormalizedHex:8000];
//    } else if (obdCommand == OASOBDCommand.obdEngineRuntimeCommand) {
//        response = [self toNormalizedHex:2000];
//    } else if (obdCommand == OASOBDCommand.obdSpeedCommand) {
//        response = [self toNormalizedHex:99];
//    } else if (obdCommand == OASOBDCommand.obdAirIntakeTempCommand) {
//        response = [self toNormalizedHex:100];
//    } else if (obdCommand == OASOBDCommand.obdEngineCoolantTempCommand) {
//        response = [self toNormalizedHex:80];
//    } else if (obdCommand == OASOBDCommand.obdFuelConsumptionRateCommand) {
//       // self.bufferToRead = @"NODATA>";
//        return;
//    } else if (obdCommand == OASOBDCommand.obdFuelTypeCommand) {
//        response = @"01";
//    } else if (obdCommand == OASOBDCommand.obdFuelLevelCommand) {
////        int64_t now = (int64_t)([[NSDate date] timeIntervalSince1970] * 1000);
////        if (now - self.lastFuelChangedTime > CHANGE_FUEL_LV_TIMEOUT) {
////            self.lastFuelChangedTime = now;
////            self.fuelLeftLvl = MAX(0, self.fuelLeftLvl - 1);
////            if (self.fuelLeftLvl < 255 * 0.8) {
////                self.fuelLeftLvl = 250;
////                self.showFuelPeak = YES;
////            }
////        }
////        if (self.fuelLeftLvl < 255 * 0.9 && self.showFuelPeak) {
////            self.showFuelPeak = NO;
////            response = [self toNormalizedHex:250];
////        } else {
////            response = [self toNormalizedHex:self.fuelLeftLvl];
////        }
//    }
//
//   // self.bufferToRead = [NSString stringWithFormat:@"%@%@%@>", commandTypeCode, command, response];
//}

//- (NSString *)toNormalizedHex:(NSInteger)data {
//    NSString *hex = [[NSString stringWithFormat:@"%lX", (unsigned long)data] uppercaseString];
//    return (hex.length % 2 != 0) ? [@"0" stringByAppendingString:hex] : hex;
//}


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
