cordova-plugin-empatica
=======================

WORK IN PROGRESS!

Implementation of the Empatica SDK for Cordova.

### Installation ###

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

Prior to calling any other functions, you have to authenticate with Empatica.

```coffeescript
window.plugins.Empatica.authenticateWithAPIKey('<your-empatica-api-key>',
  (description) ->
    alert('Empatica API authentication successful: '+description)
  (error) -> 
    alert('Empatica API authentication NOT successful: '+description)
)
```

### Usage ###
See the complete API in [cordova_plugin_empatica.js](www/cordova_plugin_empatica.js)

First discoverDevices which returns an array of the discovered device names.
```coffeescript
discover = ->
  window.plugins.Empatica.discoverDevices( (devices)->
    console.log "empatica discovered devices:"
    console.log devices
    connect(devices)
  , (error) ->
    console.log "empatica discovery error:"
    console.log error
  )
  false
```

To connect to devices, provide the list with device names (from discoverDevices) to connectDevices.
```coffeescript
connect = (devices)->
  window.plugins.Empatica.connectDevices(devices,
  (msg)->
    console.log "empatica connected to all devices!"
    console.log msg
  , (error) ->
    console.log "empatica connect error:"
    console.log error
  )
  false

```

If devices are connected you are free to go to startRecording.
```coffeescript
startRecording = ->
  sessionId = "asdf"
  window.plugins.Empatica.startRecording(sessionId, 
  (msg)->
    console.log "recording: "
    console.log msg
  , (error) ->
    console.log "recording error:"
    console.log error
  )
  false
```

During recording or after stopRecording you can call listRecords to get absolute file paths of all the present records on the device. These URLs you could for example pass to [cordova-plugin-file-transfer](https://github.com/apache/cordova-plugin-file-transfer) to get them PUT to your server.
```coffeescript
listRecords = ->
  window.plugins.Empatica.listRecords( (records)->
    console.log "listRecords: "
    _.each records, (record) ->
      upload(record)
  , (error) ->
    console.log "listRecords error:"
    console.log error
  )
  false
```

### TODO ###
- [ ] deleteRecords(records)

### Thanks ###
This is a fork of [https://github.com/jbeuckm/cordova-plugin-pebble](cordova-plugin-pebble). Thank you [https://github.com/jbeuckm](joe beuckman)!

### License ###
MIT
