cordova-plugin-empatica
=====================

WORK IN PROGRESS!

Implementation of the Empatica SDK for Cordova.

### Usage ###

From your project's root, add the plugin:

```cordova plugin add git@github.com:patte/cordova-plugin-empatica.git```

The Empatica API wants to be informed when the app enters background
unfortunately listening to background notifications and
inform the empatica api does not work (empatica API 0.7.2).
The Empatica API enforces this to be done in the AppDelegate.
So you need to manually add the following lines to the
generated project's AppDelegate:
``` 
#import <EmpaLink-ios-0.7-full/EmpaticaAPI-0.7.h>

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [EmpaticaAPI prepareForBackground];
}
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [EmpaticaAPI prepareForResume];
}
```

Set the API key of your empatica connect account: 

```javascript
window.plugins.Empatica.authenticateWithAPIKey('<your-empatica-api-key>',
    function(description) {
        alert('Empatica API authentication successful: '+description);
    }
    function(description) {
        alert('Empatica API authentication NOT successful: '+description);
    }
);
```

Connect to the first device and register callbacks for connect/disconnect events:
```javascript
window.plugins.Empatica.connectFirstDevice(
    function(info){
        alert("Empatica device "+info.name+" connected!");
    },
    function(info){
        alert("Empatica device "+info.name+" disconnected!");
    }
);
```

### Thanks ###
This is a fork of [https://github.com/jbeuckm/cordova-plugin-pebble](cordova-plugin-pebble). Thank you [https://github.com/jbeuckm](joe beuckman)!
