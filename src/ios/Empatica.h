
#import <Cordova/CDVPlugin.h>
#import <EmpaLink-ios-0.7-full/EmpaticaAPI-0.7.h>

@interface Empatica : CDVPlugin <EmpaticaDelegate, EmpaticaDeviceDelegate> {
    NSMutableDictionary *_discoveredDevices;
    NSMutableDictionary *_connectedDevices;
    NSDateFormatter *_dateFormatter;
}

@property (nonatomic, strong) NSString* discoverCallbackId;
@property (nonatomic, strong) NSString* connectionCallbackId;
@property (nonatomic, strong) NSString* recordingCallbackId;
@property BOOL isAuthenticated;
@property int connectNumDevices;
@property BOOL isRecording;
@property (nonatomic, strong) NSString* sessionId;

@end
