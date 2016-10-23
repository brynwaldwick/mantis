React = require 'react'
{Link} = require 'react-router'
fetch$ = require 'kefir-fetch'
KefirBus = require 'kefir-bus'

Map = require './map'
{LatLng} = require './common'
ScrapeSummary = require './scrape-summary'

Dispatcher =
    loadField: (field_id) ->
        fetch$ 'get', "/fields/#{field_id}/energies.json?start=0&end=10000"

    getField: (field_id) ->
        fetch$ 'get', "/fields/#{field_id}.json"

    findFields: ->
        fetch$ 'get', "/fields.json?start=0&end=10000"

    results$: new KefirBus()

FieldPage = React.createClass
    
    getInitialState: ->
        field: {}
        energies: []

    componentDidMount: ->
        Map.initializeMap()
        @findField()

    componentWillReceiveProps: (new_props) ->
        if @props.params.field_id != new_props.params.field_id
            @findField(new_props)

    findField: (props) ->
        Map.clearField()

        if !props
            props = @props

        results$?.offValue @foundField
        results$ = Dispatcher.loadField(props.params.field_id)
        results$.onValue @foundField


        @field$?.offValue @gotField
        @field$ = Dispatcher.getField(props.params.field_id)
        @field$.onValue @gotField

    gotField: (field) ->
        @setState {field}

    foundField: (energies) ->
        Map.renderField energies
        @setState {energies}

    render: ->
        <div className='field-page'>
            <div className='page-nav'>
                <Link to="/fields" ><i className='fa fa-arrow-left' /></Link>
                <h3>{@state.field.name}</h3>
            </div>
            <div id='map-canvas' />
            <div className='field-details'>
                {if @state.field.weights?
                    <div className='section'>
                        <h3>Weights</h3>
                        {@renderWeights(@state.field)}
                    </div>}
                {if @state.field.scrape?
                    <div className='section'>
                        <ScrapeSummary scrape=@state.field.scrape />
                    </div>}
                <div className='field'>
                    {JSON.stringify(@state.field)}
                </div>
            </div>
        </div>

    renderWeights: (field_spec) ->
        <div className='field-weights'>
            {Object.keys(field_spec.weights).map (w_k, i) ->
                weight = field_spec.weights[w_k]
                color = if weight == 0.5 then "rgba(33, 33, 33, 1)" else if weight < 0.5 then "rgba(255, 0, 0, 1)" else "rgba(0, 0, 255, 1)"
                opacity = Math.abs(weight - 0.5) + 0.27

                styles = {
                    backgroundColor: color.replace('1)',"#{opacity})")
                    # opacity: 
                    color: "white"
                }

                color = if weight < 0.5 then field_spec.weights[w_k]
                <div className='card model-aspect' key=i >
                    <div className='swatch' style={styles} >{field_spec.weights[w_k].toFixed(2)}</div>
                    <Link to="/results/#{w_k}">
                        <div className='result-key'>{w_k}</div>
                    </Link>
                </div>
            }
        </div>



module.exports = FieldPage