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

    connectFirstDevice: function(connected, disconnected) {

        cordova.exec(
            connected,
            disconnected,
            'Empatica',
            'connectFirstDevice',
            []
        );
    }

};


module.exports = Empatica;
