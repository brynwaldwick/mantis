React = require 'react'
ReactDOM = require 'react-dom'
KefirBus = require 'kefir-bus'
_ = require 'underscore'
{divideByN} = require '../../../helpers'

Map = require 'zamba-map'

Dispatcher = require './dispatcher'

sf_lat_lng = new google.maps.LatLng 37, -122.0915525
sf_lat_lng = new google.maps.LatLng 41.0531356, -73.5027429

Map.scrapes = []
Map.boxes = []

Map.clearMarkers = () ->
    Map.markers.map (m) -> m.setMap(null)
    Map.markers = []
    Map.bounds = new google.maps.LatLngBounds()

Map.clearScrapes = () ->
    Map.scrapes.map (m) -> m.setMap(null)
    Map.scrapes = []
    Map.bounds = new google.maps.LatLngBounds()

Map.clearField = () ->
    Map.boxes.map (b) -> b.setMap(null)
    Map.boxes = []
    Map.bounds = new google.maps.LatLngBounds()

Map.renderScrape = (scrape) ->
    Map.clearScrapes()
    {bounds} = scrape
    nw = bounds[0]
    se = bounds[1]
    array_1 = divideByN se.lat, nw.lat, scrape.x_by_y[1]
    array_2 = divideByN nw.lng, se.lng, scrape.x_by_y[0]
    array_1.map (lats) ->
        array_2.map (lngs) ->
            scrapeCircle = new google.maps.Circle {
                strokeColor: "#1ca968"
                strokeOpacity: 0.8
                strokeWeight: 2
                fillColor: "#90cc43"
                fillOpacity: 0.35
                map: Map.google_map
                center: {lat: lats, lng: lngs}
                radius: scrape.radius
            }
            Map.scrapes.push scrapeCircle
            Map.bounds.extend scrapeCircle.center
    Map.zoomToBounds()

Map.renderField = (field, selected) ->
    energies = _.pluck(field, 'energies').map (e_object) ->
        _result = 0
        Object.keys(e_object).map (v) ->
            if v in selected
                _result += e_object[v]
        return _result


    energies = _.flatten energies
    # energies = _.pluck(field, 'energy')
    lats = _.uniq _.pluck(field, 'lat')
    lngs = _.uniq _.pluck(field, 'lng')
    max_energy = _.max energies
    min_energy = _.min energies
    console.log max_energy
    console.log min_energy
    console.log lats.length, lngs.length
    d_lng = field[0].lng - field[1].lng
    d_lat = field[lngs.length].lat - field[0].lat

    lats.map (lat, i) ->
        lngs.map (lng, j) ->
    cubeRt = (x) ->
        if x == 0
            sign = 0
        else if x > 0
            sign
        return sign * Math.pow(Math.abs(x), 1 / 3)

    field.map (f, i) ->
        # f.energy = 0
        _energy = 0
        # _energy = f.energy
        # console.log f.energies
        Object.keys(f.energies).map (e) ->
            if e in selected
                _energy += f.energies[e]
        rectangle = new google.maps.Rectangle {
            strokeColor: (if _energy < 0 then '#FF0000' else '#0000ff'),
            strokeOpacity: if (_energy > 0) then (0.5 * _energy/(max_energy)) else (0.65 * _energy/(min_energy) + 0.02),
            strokeWeight: 1,
            fillColor: (if _energy < 0 then '#FF0000' else '#0000ff'),
            fillOpacity: if (_energy > 0) then (0.9 * _energy/(max_energy) + 0.02).toFixed(2) else (0.98 * _energy/(max_energy) + 0.1).toFixed(2),
            map: Map.google_map,
            bounds: {
                north: field[i+lngs.length]?.lat || (f.lat + d_lat),
                south: f.lat,
                east: if (field[i+1]?.lng > f.lng) then (field[i+1].lng) else (f.lng - d_lng),
                west: f.lng
            }
        }

        _handleClick = () ->
            _lat = f.lat + d_lat/2
            _lng = f.lng - d_lng/2
            Dispatcher.map_clicks$.emit {kind: 'field', f: {lat: _lat, lng: _lng}}

        rectangle.addListener 'click', _handleClick
        Map.boxes.push rectangle

        Map.bounds.extend {lat: f.lat, lng: f.lng}
    Map.zoomToBounds()

Map.renderFieldSkeletons = (field_specs) ->

    field_specs.map (f, i) ->
        rect = new google.maps.Rectangle {
            strokeColor: "#1CA968",
            strokeOpacity: 0.8,
            strokeWeight: 1,
            fillOpacity: 0.3,
            fillColor: "#ccc"
            map: Map.google_map,
            bounds: {
                north: f.scrape.bounds[0].lat,
                south: f.scrape.bounds[1].lat,
                east: f.scrape.bounds[1].lng,
                west: f.scrape.bounds[0].lng
            }
        }

        redirectTo = ->
            window.location = "/#/fields/#{f.model_id}"
        rect.addListener 'click', redirectTo

        Map.bounds.extend {lat: f.scrape.bounds[0].lat, lng: f.scrape.bounds[0].lng}
        Map.bounds.extend {lat: f.scrape.bounds[1].lat, lng: f.scrape.bounds[1].lng}

    Map.zoomToBounds()

Map.addColoredPoint = (place, options) ->
    options ||= {}
    color = Dispatcher.getColor(place.kind[0..3]).replace('#','')
    options.color = color
    Map.addPoint place, options

module.exports = Map