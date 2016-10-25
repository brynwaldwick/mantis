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
        selected: {}

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



module.exports = FieldPage