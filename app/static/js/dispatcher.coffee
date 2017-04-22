fetch$ = require 'kefir-fetch'
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

    loadFieldEnergies: (field_id) ->
        fetch$ 'get', "/fields/#{field_id}/energies.json?start=0&end=10000"

    getField: (field_id) ->
        fetch$ 'get', "/fields/#{field_id}.json"

    findFields: ->
        fetch$ 'get', "/fields.json?start=0&end=10000"

    findPlacesNear: (field_id, lat, lng) ->
        fetch$ 'get', "/models/#{field_id}/n_closest/250.json?lat=#{lat}&lng=#{lng}"

    results$: new KefirBus()
    loadField: (field_id) ->
        fetch$ 'get', "/fields/#{field_id}.json?start=0&end=10000"

    # loadField: (field_id) ->
    #     fetch$ 'get', "/fields/#{field_id}/energies.json?start=0&end=10000"

    # getField: (field_id) ->
    #     fetch$ 'get', "/fields/#{field_id}.json"

    # findFields: ->
    #     fetch$ 'get', "/fields.json?start=0&end=10000"

    # findPlacesNear: (field_id, lat, lng) ->
    #     fetch$ 'get', "/models/#{field_id}/n_closest/250.json?lat=#{lat}&lng=#{lng}"

    # results$: new KefirBus()

module.exports = Dispatcher

