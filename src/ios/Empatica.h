
#import <Cordova/CDVPlugin.h>
#import <EmpaLink-ios-0.7-full/EmpaticaAPI-0.7.h>

@interface Empatica : CDVPlugin <EmpaticaDelegate, EmpaticaDeviceDelegate>
{
    EmpaticaDeviceManager *_connectedDevice;
}

@property (nonatomic, strong) NSString* connectionCallbackId;
@property (nonatomic, strong) NSString* messageCallbackId;

@end
