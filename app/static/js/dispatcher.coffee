
KefirBus = require 'kefir-bus'

Dispatcher =
    map_clicks$: new KefirBus()

module.exports = Dispatcher

