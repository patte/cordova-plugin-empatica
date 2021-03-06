
#import "Empatica.h"

@implementation Empatica

@synthesize connectionCallbackId;
@synthesize recordingCallbackId;

/* The Empatica API wants to be informed when the app enters background
 unfortunately listening to background notifications and
 inform the empatica api does not work (empatica API 0.7.2).
 The Empatica API enforces this to be done in the AppDelegate.
 So you need to manually add the following lines to the
 generated project's AppDelegate:
 
 #import <EmpaLink-ios-0.7-full/EmpaticaAPI-0.7.h>

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [EmpaticaAPI prepareForBackground];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [EmpaticaAPI prepareForResume];
}
*/

-(void)pluginInitialize {
    /*[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    */
    NSString *beepPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:beepPath], &_beepSoundID);

    _dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    [_dateFormatter setLocale:enUSPOSIXLocale];
    [_dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSSZZZZZ"];
    
    _discoveredDevices = [NSMutableDictionary dictionary];
    _connectedDevices = [NSMutableDictionary dictionary];
    
    self.isAuthenticated = false;
    self.connectNumDevices = 0;
    self.isRecording = false;
}


-(NSString *)recordsDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *recordsPath = [paths.firstObject stringByAppendingPathComponent:@"/records/"];
    if(![[NSFileManager defaultManager] fileExistsAtPath:recordsPath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:recordsPath withIntermediateDirectories:NO attributes:nil error:nil];
    }
    return recordsPath;
}


#pragma mark our cordova api

-(void)authenticateWithAPIKey:(CDVInvokedUrlCommand *)command {
    if(self.isAuthenticated) {
        NSLog(@"ignoring authenticateWithAPIKey while isAuthenticated!");
        return;
    }
    if(self.isRecording) {
        NSLog(@"ignoring authenticateWithAPIKey while isRecording!");
        return;
    }
    NSString *apiKey = [command.arguments objectAtIndex:0];
    NSLog(@"Empatica authenticateWithAPIKey: %@", apiKey);
    [EmpaticaAPI authenticateWithAPIKey:apiKey
                   andCompletionHandler:^(BOOL success, NSString *description) {
                       if(success) {
                           NSLog(@"Empatica API authentication successful: %@", description);
                           self.isAuthenticated = true;
                           CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:description];
                           [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                       } else {
                           NSLog(@"Empatica API authentication NOT successful: %@", description);
                           self.isAuthenticated = false;
                           CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:description];
                           [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                       }
                   }];
}

-(BOOL)enforceAuthentication:(NSString*)callbackId {
    if(!self.isAuthenticated) {
        NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        [returnInfo setObject:@"API not authenticated!" forKey:@"message"];
        [returnInfo setObject:@"api_not_authenticated" forKey:@"code"];
        CDVPluginResult* result = nil;
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnInfo];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        return false;
    }
    return true;
}

-(void)discoverDevices:(CDVInvokedUrlCommand *)command {
    self.discoverCallbackId = command.callbackId;
    if(![self enforceAuthentication:self.discoverCallbackId]) { return; }
    if(self.isRecording) {
        NSLog(@"ignoring discoverDevices while isRecording!");
        return;
    }
    [EmpaticaAPI discoverDevicesWithDelegate:self];
}

-(void)connectDevices:(CDVInvokedUrlCommand *)command {
    self.connectionCallbackId = command.callbackId;
    if(![self enforceAuthentication:self.connectionCallbackId]) { return; }
    if(self.isRecording) {
        NSLog(@"ignoring discoverDevices while isRecording!");
        return;
    }
    NSArray *deviceNames = [command.arguments objectAtIndex:0];
    self.connectNumDevices = (int)deviceNames.count;
    for (NSString *deviceName in deviceNames) {
        EmpaticaDeviceManager *device = [_discoveredDevices objectForKey:deviceName];
        if(device != nil && device.deviceStatus!=kDeviceStatusConnected) {
            [device connectWithDeviceDelegate:self];
        }
    }
}

-(BOOL)allDevicesConnected {
    return (self.connectNumDevices == _connectedDevices.count);
}

-(void)disconnectAllDevices:(CDVInvokedUrlCommand *)command {
    if(self.isRecording) {
        NSLog(@"ignoring disconnectAllDevices while isRecording!");
        return;
    }
    self.connectNumDevices = 0;
    for (EmpaticaDeviceManager *device in _connectedDevices) {
        [device disconnect];
    }
    
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"done"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void)startRecording:(CDVInvokedUrlCommand *)command {
    if(self.isRecording) {
        NSLog(@"ignoring startRecording while isRecording!");
        return;
    }
    self.recordingCallbackId = command.callbackId;
    if(![self enforceAuthentication:self.recordingCallbackId]) { return; }
    if(![self allDevicesConnected]) {
        NSLog(@"Can't start recording: not all devices connected!");
        NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:2];
        [returnInfo setObject:@"Can't start recording, missing device!" forKey:@"message"];
        [returnInfo setObject:@"missing_device" forKey:@"code"];
        CDVPluginResult* result = nil;
        result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnInfo];
        [result setKeepCallbackAsBool:YES];
        [self.commandDelegate sendPluginResult:result callbackId:self.recordingCallbackId];
        return;
    }
    
    self.sessionId = [command.arguments objectAtIndex:0];
    AudioServicesPlaySystemSound(_beepSoundID);
    self.isRecording = true;
    
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"done"];
    [self.commandDelegate sendPluginResult:result callbackId:self.recordingCallbackId];
}

-(void)stopRecording:(CDVInvokedUrlCommand *)command {
    AudioServicesPlaySystemSound(_beepSoundID);
    self.isRecording = false;
    
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"done"];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

-(void)listRecords:(CDVInvokedUrlCommand *)command {
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[self recordsDirectory] error:NULL];
    NSString *recordsDirectory = [self recordsDirectory];
    NSMutableArray *records = [NSMutableArray array];
    for (NSString* item in directoryContent){
        [records addObject:[NSString stringWithFormat:@"%@/%@", recordsDirectory, item]];
    }
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:records];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}

#pragma mark empatica signaling delegate methods
- (void)didUpdateBLEStatus:(BLEStatus)status {
    switch (status) {
        case kBLEStatusNotAvailable: {
            NSLog(@"Bluetooth low energy not available");
            NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:2];
            [returnInfo setObject:@"Bluetooth not available!" forKey:@"message"];
            [returnInfo setObject:@"bluetooth_not_available" forKey:@"code"];
            CDVPluginResult* result = nil;
            result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnInfo];
            [result setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:result callbackId:self.discoverCallbackId];
            [self disconnectAllDevices:nil];
        } break;
        case kBLEStatusReady: {
            NSLog(@"Bluetooth low energy ready");
        } break;
        case kBLEStatusScanning: {
            NSLog(@"Bluetooth low energy scanning for devices");
        } break;
        default:
            break;
    }
}

- (void)didDiscoverDevices:(NSArray *)devices {
    if (devices.count > 0) {
        for (EmpaticaDeviceManager *device in devices) {
            NSLog(@"Discovered device: %@", device.name);
            if([_discoveredDevices objectForKey:device.name]==nil) {
                [_discoveredDevices setObject:device forKey:device.name];
            }
        }
    } else {
        NSLog(@"No device found in range.");
    }
    NSMutableArray* discoveredDevices = [[NSMutableArray alloc] init];
    for (NSString* deviceName in _discoveredDevices) {
        //EmpaticaDeviceManager *device = [_discoveredDevices objectForKey:deviceName];
        [discoveredDevices addObject:deviceName];
    }
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:discoveredDevices];
    [result setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:result callbackId:self.discoverCallbackId];
}

- (void)didUpdateDeviceStatus:(DeviceStatus)status forDevice:(EmpaticaDeviceManager *)device {
    switch (status) {
        case kDeviceStatusConnecting: {
            NSLog(@"Empatica device connecting");
            break;
        }
        case kDeviceStatusConnected: {
            NSLog(@"Empatica device connected");
            [_connectedDevices setObject:device forKey:device.name];
            
            if ([self allDevicesConnected]) {
                NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:2];
                [returnInfo setObject:@"All devices connected! Ready to start recording." forKey:@"message"];
                [returnInfo setObject:@"all_devices_connected" forKey:@"code"];
                CDVPluginResult* result = nil;
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnInfo];
                [result setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:result callbackId:self.connectionCallbackId];
            }
            break;
        }
        case kDeviceStatusDisconnecting: {
            NSLog(@"Empatica device disconnecting");
            break;
        }
        case kDeviceStatusDisconnected: {
            NSLog(@"Empatica device disconnected");
            [_connectedDevices removeObjectForKey:device.name];
            
            if (self.isRecording) {
                NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:2];
                [returnInfo setObject:@"Unexpected device disconnect!" forKey:@"message"];
                [returnInfo setObject:@"unexpected_device_disconnect" forKey:@"code"];
                CDVPluginResult* result = nil;
                result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnInfo];
                [result setKeepCallbackAsBool:YES];
                [self.commandDelegate sendPluginResult:result callbackId:self.recordingCallbackId];
                //TODO
                //[self disconnectAllDevices:nil];
            }
            
            break;
        }
        default:
            break;
    }
}

#pragma mark empatica data delegate methods
- (void)didReceiveBVP:(float)bvp withTimestamp:(double)timestamp fromDevice:(EmpaticaDeviceManager *)device {
    if(self.isRecording) {
        //NSLog(@"BVP: %.2f", bvp);
        NSString* filename = [NSString stringWithFormat:@"%@_%@_BVP.csv", self.sessionId, device.name];
        [self saveFloat:bvp withTimestamp:timestamp toFilename:filename];
    }
}
- (void)didReceiveGSR:(float)gsr withTimestamp:(double)timestamp fromDevice:(EmpaticaDeviceManager *)device {
    if(self.isRecording) {
        //NSLog(@"GSR: %.2f", gsr);
        NSString* filename = [NSString stringWithFormat:@"%@_%@_GSR.csv", self.sessionId, device.name];
        [self saveFloat:gsr withTimestamp:timestamp toFilename:filename];
    }
}
- (void)didReceiveIBI:(float)ibi withTimestamp:(double)timestamp fromDevice:(EmpaticaDeviceManager *)device {
    if(self.isRecording) {
        //NSLog(@"IBI: %.2f", ibi);
        NSString* filename = [NSString stringWithFormat:@"%@_%@_IBI.csv", self.sessionId, device.name];
        [self saveFloat:ibi withTimestamp:timestamp toFilename:filename];
    }
}
- (void)didReceiveAccelerationX:(char)x y:(char)y z:(char)z withTimestamp:(double)timestamp fromDevice:(EmpaticaDeviceManager *)device {
    //TODO
}
- (void)didReceiveTemperature:(float)temp withTimestamp:(double)timestamp fromDevice:(EmpaticaDeviceManager *)device {
    if(self.isRecording) {
        //NSLog(@"Temp: %.2f", temp);
        NSString* filename = [NSString stringWithFormat:@"%@_%@_TEMP.csv", self.sessionId, device.name];
        [self saveFloat:temp withTimestamp:timestamp toFilename:filename];
    }
}
-(void)didReceiveTagAtTimestamp:(double)timestamp fromDevice:(EmpaticaDeviceManager *)device {
    if(self.isRecording) {
        NSString* filename = [NSString stringWithFormat:@"%@_%@_TAG.csv", self.sessionId, device.name];
        [self saveFloat:1 withTimestamp:timestamp toFilename:filename];
    }
}

- (void)didReceiveBatteryLevel:(float)level withTimestamp:(double)timestamp fromDevice:(EmpaticaDeviceManager *)device {
    //TODO
}


-(void)saveFloat:(float)f withTimestamp:(double)timestamp toFilename:(NSString*)filename {
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timestamp];
    NSString *dateString = [_dateFormatter stringFromDate:date];
    
    NSString *filePath = [[self recordsDirectory] stringByAppendingPathComponent:filename];
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if(fileHandle == nil) {
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
        fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    }
    [fileHandle seekToEndOfFile];
    [fileHandle writeData:[[NSString stringWithFormat:@"%@; %f; %f\n", dateString, timestamp, f] dataUsingEncoding:NSUTF8StringEncoding]];
    [fileHandle closeFile];
}

@end
