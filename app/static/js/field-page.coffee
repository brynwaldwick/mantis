d3 = require 'd3'
_ = require 'underscore'
React = require 'react'
{Link, hashHistory} = require 'react-router'
fetch$ = require 'kefir-fetch'
KefirBus = require 'kefir-bus'
_Dispatcher = require './dispatcher'

Map = require './map'
{LatLng} = require './common'
ScrapeSummary = require './scrape-summary'
PlaceSummary = require './place-summary'


add = (a, b) -> a + b
sum = (l) -> l.reduce(add, 0)

Dispatcher =
    loadField: (field_id) ->
        fetch$ 'get', "/fields/#{field_id}/energies.json?start=0&end=10000"

    getField: (field_id) ->
        fetch$ 'get', "/fields/#{field_id}.json"

    findFields: ->
        fetch$ 'get', "/fields.json?start=0&end=10000"

    findPlacesNear: (field_id, lat, lng) ->
        fetch$ 'get', "/models/#{field_id}/n_closest/100.json?lat=#{lat}&lng=#{lng}"

    results$: new KefirBus()

FieldPage = React.createClass
    
    getInitialState: ->
        field: {}
        energies: []
        places: []
        selected: {}

    componentDidMount: ->
        Map.initializeMap()
        @findField()
        _Dispatcher.map_clicks$.onValue (click) =>
            hashHistory.push "/fields/#{@props.params.field_id}?lat=#{click.f.lat}&lng=#{click.f.lng}"
            {lat, lng} = @props.location.query
            @loadPlaces {lat, lng}

    loadPlaces: ({lat, lng}) ->
        Map.clearMarkers()
        # TODO: make sure this works with new props
        @places$ = Dispatcher.findPlacesNear @props.params.field_id, lat, lng
        @places$.onValue @foundPlaces

    componentWillReceiveProps: (new_props) ->

        if @props.params.field_id != new_props.params.field_id
            @findField(new_props)

    foundPlaces: (places) ->
        places.map (r) ->
            Map.addPoint r
        @setState {places}

    findField: (props) ->
        Map.clearField()

        if !props
            props = @props

        @field$?.offValue @gotField
        @field$ = Dispatcher.getField(props.params.field_id)
        @field$.onValue @gotField

    loadFieldEnergies: ->
        results$?.offValue @foundField
        results$ = Dispatcher.loadField(@state.field.model_id)
        results$.onValue @foundField

    gotField: (field) ->
        selected = Object.keys(field.weights)
        @setState {field, selected}, =>
            @loadFieldEnergies()

    foundField: (energies) ->
        selected = @state.selected
        Map.renderField energies, selected
        Map.google_map.addListener('click', (e) ->
            console.log e
            )
        @setState {energies}

    toggleSelected: (selected) -> =>
        Map.clearField()
        if @state.selected.indexOf(selected) > -1
            _selected = @state.selected.filter (s) -> s != selected
        else
            _selected = @state.selected.concat [selected]

        @setState {selected: _selected}, =>
            Map.renderField @state.energies, @state.selected

    render: ->
        <div className='field-page'>
            <div className='page-nav'>
                <Link to="/fields" className='back' ><i className='fa fa-arrow-left' /></Link>
                <h3>{@state.field.name}</h3>
                {if @state.field.scrape then <div className='scrape-summary'>in {@state.field.scrape._id}</div>}
            </div>
            <div className='map-w-sidebar'>
                <div className='field-places sidebar'>
                    {if @state.places.length == 0
                        <div className='help'>Click a square to see nearby places</div>
                    else
                        @state.places.map (p, i) ->
                            <PlaceSummary key=i place=p />
                    }
                </div>
                <div id='map-canvas' styles={'width':'100%';'height':'600px'} />
            </div>
            <div className='field-details'>
                {if @state.places?.length
                    {lat, lng} = @props.location.query
                    loc = {lat, lng}
                    <ConcentrationGraph places=@state.places loc=loc />
                }
                {if @state.field.weights?
                    <div className='section'>
                        <h3>Weights</h3>
                        {@renderWeights(@state.field)}
                    </div>}
                {if @state.field.scrape?
                    <div className='section'>
                        <ScrapeSummary scrape=@state.field.scrape />
                    </div>}
            </div>
        </div>

    renderWeights: (field_spec) ->
        <div className='field-weights'>
            {Object.keys(field_spec.weights).map (w_k, i) =>
                weight = field_spec.weights[w_k]
                color = if weight == 0.5 then "rgba(33, 33, 33, 1)" else if weight < 0.5 then "rgba(255, 0, 0, 1)" else "rgba(0, 0, 255, 1)"
                opacity = Math.abs(weight - 0.5) + 0.27

                styles = {
                    backgroundColor: color.replace('1)',"#{opacity})")
                    # opacity: 
                    color: "white"
                }

                color = if weight < 0.5 then field_spec.weights[w_k]
                console.log w_k
                active = if w_k in @state.selected then '' else 'inactive'
                <div className="card model-aspect #{active}" key=i >
                    <div className='swatch' onClick=@toggleSelected(w_k) style={styles} >{field_spec.weights[w_k].toFixed(2)}</div>
                    <Link to="/results/#{w_k}" className='result-key'>
                        <div className='key'>{w_k}</div>
                    </Link>
                </div>
            }
        </div>

donutArea = (r_1, r_2) ->
    Math.PI * Math.pow(r_2,2) - Math.PI * Math.pow(r_1, 2)

ConcentrationGraph = React.createClass

    getDefaultProps: ->
        height: 120
        width: (window.innerWidth - 32) * 0.79
        bar_gap: 0
        data: []

    getInitialState: ->
        active: 'density'

    color_keys: []

    componentWillMount: ->
        @x = d3.scaleLinear().range([0, @props.width])
        @y = d3.scaleLinear().range([0, @props.height])

    binPlaces: (places) ->
        @color_keys = []
        results = []

        distances = _.pluck places, 'distance'
        min_distance = distances[0]
        max_distance = distances.slice(-1)[0]
        delta_d = (max_distance - min_distance) / 10

        all_keyed_places = _.groupBy places, 'key'

        [0..9].map (i) =>
            r_1 = min_distance + i*delta_d
            r_2 = min_distance + (i+1)*delta_d
            _places = places.filter (p) ->
                (p.distance > r_1) && (p.distance < r_2)
            total_places = _places.length

            keyed_places = _.groupBy _places, 'key'
            # density = _places.length / donutArea(r_1, r_2)

            densities = Object.keys(keyed_places).map (p_s, i) =>
                @color_keys[i] = p_s.split(':')[1][0..3]
                keyed_places[p_s].length / (donutArea(r_1, r_2) * all_keyed_places[p_s].length)
                {key: p_s.split(':')[1][0..3], _key: p_s, value: keyed_places[p_s].length / (donutArea(r_1, r_2))}# * all_keyed_places[p_s].length)}
            densities = _.sortBy densities, (c) -> all_keyed_places[c._key].length * -1
            concentrations = Object.keys(keyed_places).map (p_s, i) =>
                @color_keys[i] = p_s.split(':')[1][0..3]
                {key: p_s.split(':')[1][0..3], _key: p_s, value: keyed_places[p_s].length / total_places}
            concentrations = _.sortBy concentrations, (c) -> all_keyed_places[c._key].length * -1

            if @state.active == 'density'
                results.push {x: r_1, ys: densities}
            else
                results.push {x: r_1, ys: concentrations}
        return results

    isSelected: (k) -> (e) =>
        return @state.active == k

    handleSelected: (k) -> (e) =>
        @setState active: k

    choseActive: (k) -> (e) =>
        @setState active: k

    render: ->
        {places, point} = @props
        # console.log places

        data = @binPlaces places

        bar_w = @props.width / (data.length)
        color = d3.scaleOrdinal d3.schemeCategory20
        bar_w = @props.width / (data.length)
        @x.range([bar_w/2, @props.width-bar_w/2])

        # Calculate axis domains
        xext = d3.extent(data, (point) -> point.x)
        yext = d3.extent(data, (point) -> sum(point.ys.map((y) -> y.value)))
        @x.domain(xext)
        @y.domain([0, yext[1]])
        # <div>Div</div>
        <div className='graph'>
            <div className='toggle'>
                {[{kind: 'density', display: 'density (n / km^2)'}, {kind: 'concentration', display: 'concentration (n / N)'}].map (k) =>
                    <div className='field' onClick=@choseActive(k.kind) >
                        <input key=k.kind type='radio' checked=@isSelected(k.kind)() onChange=@handleSelected(k.kind) />
                        {k.display}
                    </div>
                }
            </div>
            <svg height=@props.height width=@props.width ref='svg' >
                <g className='bars'>
                    {data.map (point, i) =>
                        <g className='bar' key=point.x>
                            {_y = 0; point.ys.map (y, yi) =>
                                _y += y.value
                                    # onClick=@clickPoint(point)
                                <rect key=yi
                                    y={@props.height-@y(_y)}
                                    width={bar_w - @props.bar_gap}
                                    x={@x(point.x)-bar_w/2}
                                    height={@y(y.value)}
                                    fill={if @state?.selected?.x == point.x then '#f00' else _Dispatcher.getColor(y.key)}
                                />
                            }
                        </g>
                    }
                </g>
                <g className='x axis' transform="translate(0, #{@props.height + 20})">
                    {@x.ticks(5).map (tick, i) =>
                        <g style={{transform: "translate(#{@x(tick)}px, 0)"}} key=tick>
                            <text>{tick}</text>
                        </g>
                    }
                </g>
                <g className='y axis' transform="translate(-35, 5)">
                    {@y.ticks(5).map (tick, i) =>
                        <g style={{transform: "translate(0, #{@props.height - @y(tick)}px)", color: "rgba(#888, 0.7)"}} key=tick>
                            <text>{tick.toFixed(2)}</text>
                        </g>
                    }
                    </g>
            </svg>
        </div>
                # <g className='y axis' transform="translate(#{@props.width + 15}, 0)">

module.exports = FieldPage