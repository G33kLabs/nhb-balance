# Libs
_ = require('lodash')
serialPort = require('serialport')
{EventEmitter} = require 'events'
Logger = require('./logger.coffee')

# NHB 300 : precision electronic balance Serial display
module.exports = class NHB300 extends EventEmitter

    # Default options
    defaults:

        # Balance ID
        type: 'balance'
        id: 'nhb300'

        # Serial options
        serial:
            baudrate: 9600
            port: null
            parser: serialPort.parsers.readline("\r\n")

        # Logger
        logger:
            loglevel: 'trace'
            label: 'balance'

        # Events emission config
        emitOnChange: true              # Emit datas only on changes (false will emit continiously)
        emitInterval: 300               # Wait interval between 2 datas emits (0 will fire emit without delay)

        # Watchdog
        watchdog: 10000                 # Watchdog event interval

    # Init manager
    constructor: (options={}, startSerial=true) ->

        # Set options
        _.defaultsDeep(@options={}, options, @defaults)

        # Debug
        @logger = Logger(@options.logger)

        # Launch watchdog
        setInterval =>
            @watchdog()
        , @options.watchdog if @options.watchdog

        # Start serial
        @start() if startSerial is true


    # Open serial link
    start: ->

        # Declare link
        @serial = new serialPort.SerialPort(@options.serial.port, {
            parser: @options.serial.parser
            baudrate: @options.serial.baudrate
        }, false)

        # Bind events
        @serial.on 'data', @onDatas.bind(@)
        @serial.on 'close', @onClose.bind(@)
        @serial.on 'error', @onError.bind(@)

        # Bind default error as we use streams
        @on 'error', (err) =>
            # Void error handler

        # Try to open serial
        @serial.open (err) =>
            @watchdog() if @options.watchdog
            if err
                @onError(err)
                @listSerial()
            else
                @onLinkup()

    # Watchdogou
    watchdog: ->
        # return if @lastUpdate and @options.watchdog and ((Date.now() - @lastUpdate) < @options.watchdog)
        @emitDatas(_.extend({}, JSON.parse(@lastDatas or null), {
            watchdog: true
        }))

    # List serial
    listSerial: (next) ->
        @logger.info('List of connected Serial Ports')
        serialPort.list (err, ports) =>
            _.each(ports, (p) =>
                @logger.info("-> SERIAL PORT", p)
            )

    # Serial is up
    onLinkup: ->
        @emit('open')

    # Serial receive fresh datas
    # -> Parse row and build an object to emit
    onDatas: (row) ->
        row = row.toString()
        datas = {
            value: parseFloat(row.slice(5, 13).replace(/\ /g, ''))
            stable: row.slice(0, 2) is 'ST'
            net: row.slice(3, 5) is 'NT'
            unit: _.trim(row.slice(13, 15))
        }
        @emitDatas(datas)

    # Throttled version for emitting datas
    emitDatas: (datas) ->

        # Create the throttled func if no yet done
        @_emitDatas = _.throttle (datas) =>

            # Emit nothing if no changes, depends on config
            unless datas.watchdog
                return if datas and JSON.stringify(datas) is @lastDatas and @options.emitOnChange
                return if !_.isObject(datas) or _.isNaN(datas.value) or !datas.unit

            # Prepare the opbject to emit
            @lastUpdate = Date.now()
            @lastDatas = JSON.stringify(datas)
            _.extend(datas, {
                id: @options.id
                type: @options.type
                connected: if @serial then @serial.isOpen() else false
            })

            # Emit Datas
            @emit('data', datas)

        , @options.emitInterval unless @_emitDatas

        # Call the throttled func
        @_emitDatas(datas)

    # Serial link is closed
    onClose: ->
        @emit('close')

    # Serial link error
    onError: (err) ->
        @emit('error', err)
