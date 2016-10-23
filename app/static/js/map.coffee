React = require 'react'
ReactDOM = require 'react-dom'
KefirBus = require 'kefir-bus'
_ = require 'underscore'
{divideByN} = require '../../../helpers'

sf_lat_lng = new google.maps.LatLng 37, -122.0915525
sf_lat_lng = new google.maps.LatLng 41.0531356, -73.5027429

Map =
    markers: []
    scrapes: []
    boxes: []
    bounds: null
    selection$: KefirBus()

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

Map.initializeMap = (canvas, coordinates, size) ->
    mapOptions =
        disableDefaultUI: true
        fullscreenControl: true
        mapTypeControl: true
        scrollwheel: true
        zoomControl: true
        draggable: true
        scaleControl: true
        center: sf_lat_lng
        zoom: 8
    Map.google_map = new google.maps.Map document.getElementById("map-canvas"), mapOptions
    Map.bounds = new google.maps.LatLngBounds()

Map.centerOn = (marker) ->
    Map.google_map.panTo(marker.getPosition())

MIN_ZOOM = 16
MAX_ZOOM = 18

Map.zoomOn = (marker) ->
    zoom = Map.google_map.getZoom()
    if zoom < MIN_ZOOM
        Map.minZoom()
    else if zoom < MAX_ZOOM
        Map.google_map.setZoom(zoom + 2)
    else
        Map.showPopover marker

Map.minZoom = ->
    zoom = Map.google_map.getZoom()
    if zoom < MIN_ZOOM
        Map.google_map.setZoom(MIN_ZOOM)

Map.zoomAndCenterOn = (marker) ->
    Map.zoomOn marker
    Map.centerOn marker

Map.zoomToBounds = () ->
     Map.google_map.fitBounds Map.bounds

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

Map.renderField = (field) ->
    energies = _.pluck field, 'energy'
    lats = _.uniq _.pluck(field, 'lat')
    lngs = _.uniq _.pluck(field, 'lng')
    max_energy = _.max energies
    min_energy = _.min energies
    d_lng = field[0].lng - field[1].lng
    d_lat = field[lngs.length].lat - field[0].lat

    lats.map (lat, i) ->
        lngs.map (lng, j) ->
    cubeRt = (x) ->
        if x = 0
            sign = 0
        else if x > 0
            sign
        return sign * Math.pow(Math.abs(x), 1 / 3)

    field.map (f, i) ->

        rectangle = new google.maps.Rectangle {
            strokeColor: (if f.energy < 0 then '#FF0000' else 'blue'),
            strokeOpacity: if (f.energy > 0) then (0.5 * f.energy/(max_energy)) else (0.65 * f.energy/(min_energy) + 0.02),
            strokeWeight: 1,
            fillColor: (if f.energy < 0 then '#FF0000' else 'blue'),
            fillOpacity: if (f.energy > 0) then (0.9 * f.energy/(max_energy) + 0.02) else (0.98 * f.energy/(max_energy) + 0.1),
            map: Map.google_map,
            bounds: {
                north: field[i+lngs.length]?.lat || f.lat + d_lat,
                south: f.lat,
                east: if (field[i+1]?.lng > f.lng) then (field[i+1].lng) else f.lng - d_lng,
                west: f.lng
            }
        }
        background = new google.maps.Rectangle {
            strokeColor: if (Math.abs(f.energy) > 0.8) then (if f.energy < 0 then '#FF0000' else '#90cc43') else "#aaa",
            strokeOpacity: Math.abs(0.25 * cubeRt(f.energy/max_energy)),
            strokeWeight: 1,
            fillOpacity: 0.1,
            fillColor: "#bbb"
            map: Map.google_map,
            bounds: {
                north: field[i+lngs.length]?.lat || f.lat + d_lat,
                south: f.lat,
                east: if (field[i+1]?.lng > f.lng) then (field[i+1].lng) else f.lng - d_lng,
                west: f.lng
            }
        }
        Map.boxes.push background
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
            console.log 'did it work'
            window.location = "/#/fields/#{f.model_id}"
        rect.addListener 'click', redirectTo

        Map.bounds.extend {lat: f.scrape.bounds[0].lat, lng: f.scrape.bounds[0].lng}
        Map.bounds.extend {lat: f.scrape.bounds[1].lat, lng: f.scrape.bounds[1].lng}

    Map.zoomToBounds()

Map.addPoint = (place, options) ->

    marker = new google.maps.Marker
        id: place.place_id
        position: place.geometry.location
        map: Map.google_map
        zIndex: 0
        title: place.name
        icon: "/icons/place.svg?text=#{place.kind[0..3]}"
        labelClass: 'amarker'
        title: place.name
        optimized: true

    marker.addListener 'click', Map.zoomAndCenterOn.bind(null, marker)

    Map.markers.push marker
    Map.bounds.extend marker.position

module.exports = Map