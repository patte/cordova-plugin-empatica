var Empatica = {

    authenticateWithAPIKey: function(key, success, failure) {
        cordova.exec(
            success,
            failure,
            'Empatica',
            'authenticateWithAPIKey',
            [ key ]
        );
    },

    discoverDevices: function(success, failure) {
        cordova.exec(
            success,
            failure,
            'Empatica',
            'discoverDevices',
            [ ]
        );
    },

    connectDevices: function(deviceNames, success, failure) {
        cordova.exec(
            success,
            failure,
            'Empatica',
            'connectDevices',
            [ deviceNames ]
        );
    },

    disconnectAllDevices: function(success, failure) {
        cordova.exec(
            success,
            failure,
            'Empatica',
            'disconnectAllDevices',
            [ ]
        );
    },

    startRecording: function(sessionId, success, failure) {
        cordova.exec(
            success,
            failure,
            'Empatica',
            'startRecording',
            [ sessionId ]
        );
    },

    stopRecording: function(success, failure) {
        cordova.exec(
            success,
            failure,
            'Empatica',
            'stopRecording',
            [ ]
        );
    }

};


module.exports = Empatica;
