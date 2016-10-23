_ = require 'underscore'
React = require 'react'
fetch$ = require 'kefir-fetch'
KefirBus = require 'kefir-bus'

{distanceBtw} = require '../../../helpers'

Map = require './map'

Dispatcher =
    findResults: (results_key) ->
        fetch$ 'get', "/results/#{results_key}.json"
    findModelResults: (model_id) ->
        console.log model_id
        fetch$ 'get', "/models/#{model_id}/results.json"

    results$: new KefirBus()

Store =
    results: []

ResultsPage = React.createClass
    
    getInitialState: ->
        results: []

    componentDidMount: ->
        Map.initializeMap()
        if @props.params.results_key?
            @loadResults(@props.params.results_key)

    componentWillReceiveProps: (new_props) ->
        if new_props.params.results_key != @props.params.results_key
            @loadResults(new_props.params.results_key)

    loadResults: (results_key) ->
        console.log results_key.split(':')[0]
        results$?.offValue @handleResults
        if results_key.split(':')[0] == 'model'
            results$ = Dispatcher.findModelResults(results_key.split(':')[1])
        else
            results$ = Dispatcher.findResults(results_key)
        results$.onValue @handleResults

    handleResults: (results) ->
        Map.clearMarkers()
        Store.results = results
        results.map (r) ->
            Map.addPoint r
        Dispatcher.results$.emit {test_jones: 'test'}
        # Map.setMarkers results
        @setState {results}
        Map.zoomToBounds()


    render: ->
        <div className='results-page'>
            <div id='map-canvas' />
            <h5>{@state.results.length} Results</h5>
            <PointComparer />
        </div>

ProcessPoints = (points) ->
    lats_and_lngs = Store.results.map (r) ->
        r.geometry.location
    points.map (p) ->
        p_dists = lats_and_lngs.map (l) -> distanceBtw l, p
        p.min_distance = _.min p_dists

    console.log 'The prcoessed points are', points
    return points

binPoints = (points, n=10, key) ->

    values = points.map (p) -> p[key]
    console.log values
    min = _.min(values) - 0.0000001
    max = _.max(values) + 0.0000001
    delta = (max - min) / n

    bins = [0..n-1].map (b) ->
        return {
            min: min + (b * delta)
            max: min + ((b+1) * delta)
            points: []
        }

    points.map (p) ->
        p_index = Math.floor((p[key] - min) / delta)
        bins[p_index].points.push p

    return bins


PointComparer = React.createClass

    getInitialState: ->
        points_str: ''
        points_json: {}
        bins: []

    measurePoints: ->
        points = JSON.parse?(@state.points_str)
        if points?
            i = 0
            points.map (p) ->
                shim = {geometry: {location: p}, place_id: i++}
                Map.addPoint shim

        _points = ProcessPoints points
        _points = _points.filter (p) -> p.min_distance < 25
        bins = binPoints _points, 10, 'min_distance'
        @setState {bins}

    componentDidMount: ->
        # Dispatcher.results$.onValue @measurePoints

    changePoints: (e) ->
        points_str = e.target.value
        @setState {points_str}

    render: ->
        <div className='point-comparer'>
            <h3>Enter some points to compare</h3>
            <textarea value=@state.points_str onChange=@changePoints />
            <button onClick=@measurePoints >Measure</button>
            {@state.bins.map (b, i) ->
                <div className='bin' key=i>{b.min.toFixed(1)} - {b.max.toFixed(1)}: {b.points.length}</div>
            }
        </div>

module.exports = ResultsPage