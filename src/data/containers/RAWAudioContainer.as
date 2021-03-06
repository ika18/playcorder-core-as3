package data.containers
{
    import flash.utils.ByteArray;
    import flash.media.Microphone;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    import flash.net.URLRequest;
    import flash.net.URLRequestHeader;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.system.Worker;

    import tickets.GUIDTicket;
    import tickets.Ticket;
    import data.encoders.WaveEncoder;
    import data.encoders.MP3Encoder;
    import events.EncoderEvent;
    import workers.messages.Message;
    import helpers.Constants;

    import com.jonas.net.Multipart;
    import com.codecatalyst.promise.Deferred;
    import com.codecatalyst.promise.Promise;
    import com.codecatalyst.util.*;
    import com.demonsters.debugger.MonsterDebugger;

    public class RAWAudioContainer
        extends Container
    {
        private var _mic:Microphone;

        private function extract( type:String ):Ticket
        {
            var me:Container = this;
            var dfd:Deferred = new Deferred();
            var ticket:GUIDTicket = new GUIDTicket(dfd.promise);

            if ( type == null ) 
            {
                // default to use byte array rather than binary string is because
                // there is a bug in externalinterface.call that prevents String.fromCharCode(0x0) to be passed.
                type = "raw";
            }

            MonsterDebugger.trace( me, 'try to download data: ' + type );

            nextTick(function():void
            {
                var dfdEncoding:Deferred = new Deferred();

                if ( data is ByteArray )
                {
                    MonsterDebugger.trace( me, 'data is byte array');

                    var ba:ByteArray = ByteArray(data);
                    var encoder:data.encoders.Encoder;

                    if ( type == "raw" )
                    {
                        dfdEncoding.resolve( ba );
                    }
                    else if ( type == "wave" || type == "mp3" )
                    {
                        if ( type == "wave" )
                        {
                            encoder = new data.encoders.WaveEncoder();
                        }
                        else if ( type == "mp3" )
                        {
                            encoder = new data.encoders.MP3Encoder();
                        }

                        encoder
                            .encode( ba, {
                                rate: Constants.sampleRates[ _mic.rate ],
                                numberOfChannels: 1
                            })
                            .then(
                                function(result:*):void
                                {
                                    MonsterDebugger.trace( me, 'async ' + type + ' encoding finished' );

                                    if ( !(result is ByteArray) )
                                    {
                                        dfdEncoding.reject('result is not ByteArray');
                                        return;
                                    }

                                    dfdEncoding.resolve( result );
                                });
                    }
                    else
                    {
                        dfdEncoding.reject("download type is not supported");
                        return;
                    }

                    dfdEncoding
                        .promise
                        .then(
                            function(ba:ByteArray):void
                            {
                                MonsterDebugger.trace( me, 'encoding all done, now returning.' );

                                dfd.resolve( 
                                {
                                    guid: ticket.guid,
                                    data: ba,
                                    length: ba.length,
                                    rate: _mic.rate,
                                    // always 1 input source from flash:
                                    // http://stackoverflow.com/questions/9380499/recording-audio-works-playback-way-too-fast
                                    channels: [true]
                                });
                            }, 
                            dfd.reject
                        );
                }
                else 
                {
                    dfd.reject("data format is not supported");
                }
            });

            return ticket;
        }

        function RAWAudioContainer(mic:Microphone)
        {
            _type = 'raw-audio';
            _mic = mic;
        }

        public override function download(type:String):Ticket
        {
            return extract( type );
        }

        public override function upload(type:String, url:String, options:Object = null ):Ticket
        {
            var me:Container = this;
            var dfd:Deferred = new Deferred();
            var ticket:GUIDTicket = new GUIDTicket(dfd.promise);
            var format:String = 'post';
            var params:Object = null;
            var fieldname:String = 'result';
            var filename:String = 'result' + type.substr(0, 3);
            var urlHasParams:Boolean = false;

            if ( url.indexOf('?') >= 0 )
            {
                urlHasParams = true;
            }

            var tcktDownload:Ticket = extract( type );

            if ( options != null )
            {
                if ( typeof options['format'] == 'string' )
                {
                    format = options['format'];
                }

                if ( typeof options['params'] == 'object' )
                {
                    params = options['params'];
                }

                if ( typeof options['fieldname'] == 'string')
                {
                    fieldname = options['fieldname']
                }

                if ( typeof options['filename'] == 'string')
                {
                    filename = options['filename']
                }
            }

            tcktDownload
                .promise
                .then(function(obj:Object):*
                {
                    var handleUpload:Function = function():void
                    {
                        var loader:URLLoader = new URLLoader();
                        var request:URLRequest;
                        var key:String;

                        MonsterDebugger.trace( me, 'uploading... ' );

                        if ( format == 'multipart' )
                        {
                            MonsterDebugger.trace( me, 'in multipart...' );

                            var mltUploader:Multipart = new Multipart(url);

                            if ( params != null )
                            {
                                for( key in params )
                                {
                                    mltUploader.addField( key, params[key] );
                                }
                            }

                            mltUploader.addFile(fieldname, obj.data, 'application/octet-stream', filename);

                            request = mltUploader.request;
                        }
                        else
                        {
                            MonsterDebugger.trace( me, 'in plain post...' );

                            // try uploading
                            if ( params != null )
                            {
                                var uv:URLVariables = new URLVariables();

                                for( key in params )
                                {
                                    uv[key] = params[key];
                                }

                                if ( urlHasParams )
                                {
                                    url += '&' + uv.toString();
                                }
                                else
                                {
                                    url += '?' + uv.toString();
                                }
                            }
                            
                            request = new URLRequest(url);

                            var contentTypeFound:Boolean = false;

                            request.method = URLRequestMethod.POST;
                            request.data = obj.data;

                            for( var l:int = request.requestHeaders.length; l--; )
                            {
                                if ( request.requestHeaders[l].name.toLowerCase == 'content-type' )
                                {
                                    contentTypeFound = true;
                                    request.requestHeaders[l].value = 'application/octet-stream';
                                }
                            }

                            if ( !contentTypeFound )
                            {
                                request.requestHeaders.push(new URLRequestHeader("Content-Type", 'application/octet-stream'));
                            }
                        }

                        loader.addEventListener(
                            Event.COMPLETE, 
                            function(evt:Event):void
                            {
                                dfd.resolve( null );
                            });
                        
                        loader.addEventListener(IOErrorEvent.IO_ERROR, 
                            function(evt:IOErrorEvent):void
                            {
                                dfd.reject('fail to upload, ex: ' + evt.toString())
                            });

                        MonsterDebugger.trace( me, 'loading... ' );

                        try
                        {
                            loader.load(request);
                        }
                        catch(ex:*)
                        {
                            MonsterDebugger.trace( me, 'failed to load ... ' );
                            MonsterDebugger.trace( me, ex );
                            dfd.reject(ex.toString());
                        }
                    };

                    // commented out since it is fixed by https://github.com/normanzb/Multipart.as/commit/1c05781137b4c928fee25a065b3c19ee192c47f0
                    // // because of the limitation of flash
                    // // user interaction is required before actual uploading
                    // if ( format == 'multipart' )
                    // {
                    //     var dfdInteraction:Deferred = new Deferred();
                    //     var retDfd:Deferred = new Deferred();

                    //     dfd.resolve
                    //     ({
                    //         requireInteraction: true, 
                    //         deferred: 
                    //         {
                    //             resolve: function():void
                    //             {
                    //                 handleUpload.call(me);
                    //             }
                    //         },
                    //         promise: retDfd.promise
                    //     });

                    //     dfd = retDfd;
                    // }
                    // else
                    // {
                         handleUpload.call(me);
                    // }

                }, dfd.reject);
            
            return ticket;   
        }

        /*
         * Return the length of the audio (in seconds)
         */
        public function get duration():int
        {
            var ret:int = 0;

            if ( data is ByteArray )
            {
                var ba:ByteArray = ByteArray(data);

                // each sample is a 32bit float == 4 bytes
                ret = ba.length / ( Constants.sampleRates[ _mic.rate ] * 4 );
            }

            return ret;
        }
    }
}