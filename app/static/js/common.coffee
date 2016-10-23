React = require 'react'

Overlay = React.createClass

    stopClick: (e) ->
        e.stopPropagation()

    render: ->
        clickBackdrop = @props.clickBackdrop || @stopClick
        <div className="overlay #{@props.className}">
            <div className='backdrop' onClick=clickBackdrop />
            <div className={'contents ' + (if @props.narrow then 'narrow' else null)}>
                {@props.children}
            </div>
        </div>

ReloadableList = React.createClass
    
    getInitialState: ->
        items: []

    componentDidMount: ->
        @loadItems()

    reload: ->
        @loadItems()

    loadItems: ->
        @props.fetch().onValue @setItems

    setItems: (items) ->
        @setState {items}

    render: ->
        Item = @props.item_component
        <div className='items'>
            {@state.items.map (i) =>
                <Item item=i />
            }
        </div>

LatLng = React.createClass

    render: ->
        <span className='lat-lng'>
            {@props.lat_lng.lat}, {@props.lat_lng.lng}
        </span>

module.exports = {Overlay, ReloadableList, LatLng}