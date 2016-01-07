winston = require('winston')

module.exports = (obj={}) ->

    levels =
        'trace': 6
        'debug': 5
        'info': 4
        'success': 3
        'warning': 2
        'important': 1
        'error': 0

    colors =
        'trace': 'grey'
        'debug': 'gray'
        'info': 'cyan'
        'success': 'green'
        'warning': 'yellow'
        'important': 'magenta'
        'error': 'red'

    return new winston.Logger({
        levels: levels
        colors: colors
        transports: [
            new winston.transports.Console({
                label: obj.label or false
                level: obj.loglevel or 'trace'
                handleExceptions: false
                json: false
                colorize: true
                timestamp: ->
                    return new Date().toISOString()
                formatter: (options) ->
                    fields = [];
                    fields.push(options.timestamp())
                    if (options.label != null)
                        fields.push('[' + options.label.toUpperCase() + ']')
                    fields.push((if options.colorize then winston.config.colorize(options.level, options.level) else options.level) + ':')
                    if (options.message)
                        fields.push(options.message)
                    if (options.meta && Object.keys(options.meta).length)
                        fields.push(JSON.stringify(options.meta))
                    return fields.join(' ')

            })
        ]

        exitOnError: true
    })
