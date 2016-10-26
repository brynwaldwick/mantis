
KefirBus = require 'kefir-bus'
d3 = require 'd3'

i = 0

Dispatcher =
    map_clicks$: new KefirBus()

    colors: {}

    getColor: (slug) ->
        if Dispatcher.colors[slug]?
            return Dispatcher.colors[slug]
        else
            color = d3.schemeCategory20[(i++)%19]
            Dispatcher.colors[slug] = color
            return color

module.exports = Dispatcher

