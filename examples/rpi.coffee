# Load libs
NHB300 = require('../index.js')

# Configure manager
balance = new NHB300(
    id: 'balance001'
    serial:
        port: '/dev/ttyAMA0'
        baudrate: 9600
, false)

# Bind events
balance.on 'open', ->
    console.log("Serial link is up!")
balance.on 'close', ->
    @logger.info("Serial link is closed!")
balance.on 'data', (datas) ->
    @logger.debug(JSON.stringify(datas))
balance.on 'error', (err) ->
    @logger.error(err.toString())

# Start manager
balance.start()

