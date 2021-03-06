#Playcorder.Core.AS3

Audio Player and Recorder written in ActionScript3 with intuitive JavaScript interface.

<http://normanzb.github.io/playcorder-core-as3/>

#Features

##Recording

* Client-side audio recording without server support.
* RTMP server-side recording.

##Playing

* Playback remote audio file.
* Local playback, both recorded or bytearray audio.

##Audio Encoding

* Wave
* MP3
* Speex (WIP)
* Flac (WIP)
* Non-blocking fast encoding
* Plugin system (WIP)

##Javascript APIs

* Intuitive Javascript APIs.
* Access raw or encoded audio byte array.
* Sampling data access (WIP).
* HTTP Post or multipart upload.

##Security

* No privacy leaking when swf is hosted on CDN, microphone permission will be prompted again when page domain name changed. (This prevent any 3rd party to reuse the hosted SWF and hence gaining the microphone access permission WITHOUT actual user approval.)

##Other

* SWF file can be hosted on CDN server to off load some traffic to main server.
* Multiple recording instance


##Versions

###Flash Player Version

11.9

###mxmlc Version

4.10.0

##Download

<https://github.com/normanzb/playcorder-core-as3/blob/master/dist/Playcorder.swf?raw=true>

##Build

* Install Nodejs
* Install Flex SDK, make sure mxmlc can be found in your $PATH.
* Install dependencies

        npm install

* Clone all submodules

        git submodule update --init --recursive

* Run Grunt

        grunt
   
##Debug

To see logs from Playcorder, install MonsterDebugger <http://www.monsterdebugger.com>

##API

###Playcorder

####Properties

1. loaded - true to indicate the SWF is fully loaded.
2. ready - true to indicate the onReady event is fired and user accepted the microphone acesss.

####Methods

1. getID - get the instance ID of current playcorder.

####Events

1. onloaded - fire when playcorder is downloaded.
2. onready - fire when playcorder is ready for use (user accepted microphone access).


###Player

####Config

    {
        type: 'auto', // player type, default to 'auto', can also be 'local', 'bytearray' or 'file'
    }

####Methods

0. player.initialize() - init the player.
1. player.start(pathToMedia:String) - start playing the specified file.
2. player.stop() - stop the playback

####Events

1. player.onstarted - fired when playback started
2. player.onstoppped - fire when playback stoppped

###Recorder

####Config

    {
        gain:50, 
        rate:44, 
        silence:0, 
        quality: 9,
        type:'local', // recorder type, can be 'local', 'rtmp'
        server: 'rtmpt://speechtest.englishtown.com:1935/asrstreaming', // server addr if rtmp recorder is choosen
    }
    
####Methods

0. recorder.initialize(config) - init recorder with specified config.
1. recorder.start()
2. recorder.stop()
3. recorder.activity() - return 0 - 100, indicates microphone volumn.
4. recorder.muted() - return true indicates that the microphone is muted
5. recorder.connect(...args) - do the pre-connection (if appilcable), currently only works on rtmpt protocol (if you are on rtmp, server may disconnect it quickly when timeout). 'args' will be passed as is to corresponding internal connect method. For example, if it is rtmp recorder, args will be passed to NetConnection.connect();
6. recorder.disconnect() - disconnect (if applicable)
7. recorder.result.type() - get type of result
8. recorder.result.duration() - get duration of the result
9. recorder.result.download(type) - extract result as specified type, could be 'raw' or 'wave' or 'mp3'
10. recorder.result.upload(type, url, options) - upload result to remote url (using POST by default)
    * type - raw, wave or mp3
    * url - url of remote server
    * options - the option object looks like this {format: 'post' or 'multipart', fieldname: 'abcd', filename: 'abcd.mp3', params:{ param1: 1, param2: 2 ... } }
    * multipart upload restrictions: see <https://github.com/normanzb/Multipart.as/blob/master/README.md> 

####Events

1. recorder.onconnected - (only available when it is RTMP recorder)
2. recorder.ondisconnected - (only available when it is RTMP recorder)
3. recorder.onstarted
4. recorder.onstopped
5. recorder.onchange -  possible event code are:
    * microphone.not_found - trigger when microphone is unplugged
    * microphone.found - trigger when microphone is plugged
    * microphone.muted - trigger when microphone is muted
    * microphone.unmuted - trigger when microphone is unmuted
6. recorder.onerror - possible event code are:
    * connection.fail - fire when the connection failed.
7. recorder.result.onuploaded - trigger when uploading is done.
8. recorder.result.onuploadfailed - trigger when uploading is failed.
9. recorder.result.ondownloaded - trigger when downloading is done.
10. recorder.result.ondownloadfailed - trigger when downloading is failed.

##TODO

see <https://github.com/normanzb/playcorder-core-as3/issues?labels=todo&page=1&state=open>

##Contribute

You can contribute the project by:

* Submitting pull request
* Git tipping me: <https://www.gittip.com/normanzb/>
* Send bitcoin to 1Normpp1objMYw18Hz4UsL6Gu735kNYM2M pls!

##Acknowledge

This library internally used or is using below 3rd party libraries, playcorder cannot work as what we have nowaday without the efforts from the authors.

Shine MP3 Encoder:  Gabriel Bouvigne <http://gabriel.mp3-tech.org/>

Crossbridged Shine MP3 Encoder is inspired by: kikko <https://github.com/sri-soham/Shine-MP3-Encoder-on-AS3-Alchemy>
