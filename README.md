cordova-plugin-empatica
=====================

WORK IN PROGRESS!

Implementation of the Empatica SDK for Cordova.

### Usage ###

From your project's root, add the plugin:

```cordova plugin add git@github.com:patte/cordova-plugin-empatica.git```

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
