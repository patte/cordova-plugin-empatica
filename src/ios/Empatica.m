
#import "Empatica.h"

@implementation Empatica

@synthesize connectionCallbackId;
@synthesize messageCallbackId;

-(void)authenticateWithAPIKey:(CDVInvokedUrlCommand *)command {
  NSString *apiKey = [command.arguments objectAtIndex:0];

  NSLog(@"Empatica authenticateWithAPIKey: %@", apiKey);
  [EmpaticaAPI authenticateWithAPIKey:apiKey
     andCompletionHandler:^(BOOL success, NSString *description) {
       if(success) {
         NSLog(@"Empatica API authentication successful: %@", description);
         CDVPluginResult *pluginResult = [ CDVPluginResult
                                           resultWithStatus : CDVCommandStatus_OK
                                           messageAsString  : description
                                         ];
         [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
       } else {
         NSLog(@"Empatica API authentication NOT successful: %@", description);
         CDVPluginResult *pluginResult = [ CDVPluginResult
                                           resultWithStatus : CDVCommandStatus_ERROR
                                           messageAsString  : description
                                         ];
         [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
       }
  }];

}

-(void)connectFirstDevice:(CDVInvokedUrlCommand *)command {
  self.connectionCallbackId = command.callbackId;
  [EmpaticaAPI discoverDevicesWithDelegate:self];
}

#pragma mark empatica delegate methods
- (void)didDiscoverDevices:(NSArray *)devices {
  if (devices.count > 0) {
    for (EmpaticaDeviceManager *device in devices) {
      NSLog(@"Device: %@", device.name);
    }
        
    // Connect to first available device
    [[devices objectAtIndex:0] connectWithDeviceDelegate:self];
  } else {
    NSLog(@"No device found in range");
  }
}

- (void)didUpdateDeviceStatus:(DeviceStatus)status forDevice:(EmpaticaDeviceManager *)device {
  switch (status) {
    case kDeviceStatusConnecting: {
      NSLog(@"Empatica device connecting");
      break; 
    }
    case kDeviceStatusConnected: {
      _connectedDevice = device;

      NSLog(@"Empatica device connected");
      NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:1];
      [returnInfo setObject:device.name forKey:@"name"];

      CDVPluginResult* result = nil;
      result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:returnInfo];
      [result setKeepCallbackAsBool:YES];

      [self.commandDelegate sendPluginResult:result callbackId:self.connectionCallbackId];
      break; 
    }
    case kDeviceStatusDisconnecting: {
      NSLog(@"Empatica device disconnecting");
      break; 
    }
    case kDeviceStatusDisconnected: {
      _connectedDevice = nil;

      NSLog(@"Empatica device disconnected");
      NSMutableDictionary* returnInfo = [NSMutableDictionary dictionaryWithCapacity:1];
      [returnInfo setObject:device.name forKey:@"name"];

      CDVPluginResult* result = nil;
      result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:returnInfo];
      [result setKeepCallbackAsBool:YES];

      [self.commandDelegate sendPluginResult:result callbackId:self.connectionCallbackId];
      break; 
    }
    default:
    break;
  }
}


@end
