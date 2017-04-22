React = require 'react'
{Link} = require 'react-router'
fetch$ = require 'kefir-fetch'
KefirBus = require 'kefir-bus'

Map = require './map'
{LatLng} = require './common'

Dispatcher = require './dispatcher'

FieldsPage = React.createClass
    
    getInitialState: ->
        field: []
        fields: []

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

        @fields$?.offValue @foundFields
        @fields$ = Dispatcher.findFields(props.params.field_id)
        @fields$.onValue @foundFields

    foundFields: (fields) ->
        console.log fields
        Map.renderFieldSkeletons(fields)
        @setState {fields}

    render: ->
        <div className='fields-page'>
            <div id='map-canvas' />
            <div className='fields'>
                {@state.fields.map (f, i) ->
                    <Link key=i activeClassName='active' to="/fields/#{f.model_id}">{f.scrape._id} - {f.name}</Link>
                }
            </div>
        </div>

module.exports = FieldsPage