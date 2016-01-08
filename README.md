# nhb-balance

This service is designed for connecting a RaspberryPi directly to the serial interface of a NHB300 precision balance and get the weight changes.

## Installation

```
npm install --save nhb-balance
```

## Wiring

On the mother board, connect the GND and the TX from the U5 connector directly to the GND and the RX of the GPIO.
Don't forget to free the uart of the Rpi by using the `raspi-config` tool.

## Usage

```
# Load libs
NHB300 = require('nhb-balance')

# Configure manager
balance = new NHB300(
    id: 'balance001'
    serial:
        port: '/dev/ttyAMA0'
        baudrate: 9600
, false)

# Bind events
balance.on 'open', ->
    @logger.info("Serial link is up!")
balance.on 'close', ->
    @logger.info("Serial link is closed!")
balance.on 'data', (datas) ->
    @logger.debug(JSON.stringify(datas))
balance.on 'error', (err) ->
    @logger.error(err.toString())

# Start manager
balance.start()

```

## Options

```
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
```
