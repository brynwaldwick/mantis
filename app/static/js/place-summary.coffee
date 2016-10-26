React = require 'react'
Dispatcher = require './dispatcher'

PlaceSummary = React.createClass

    render: ->
        p = @props.place
        color = Dispatcher.getColor(p.kind[0..3]).replace('#','')
        <div className='place place-summary'>
            <div className='row-1'>
                <img src="/icons/place.svg?text=#{p.kind[0..3].toLowerCase()}&color=#{color}" />
                <div className='name'>{p.name}</div>
                <div className='distance'>{p.distance?.toFixed(2)} km</div>
            </div>
            <div>
                <div className='vicinity'>{p.vicinity}</div>
            </div>
        </div>

module.exports = PlaceSummary
