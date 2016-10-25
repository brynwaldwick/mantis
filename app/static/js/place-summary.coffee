React = require 'react'

PlaceSummary = React.createClass

    render: ->
        p = @props.place
        <div className='place place-summary'>
            <div className='row-1'>
                <img src="/icons/place.svg?text=#{p.kind[0..3].toLowerCase()}" />
                <div className='name'>{p.name}</div>
                <div className='distance'>{p.distance?.toFixed(2)} km</div>
            </div>
            <div>
                <div className='vicinity'>{p.vicinity}</div>
            </div>
        </div>

module.exports = PlaceSummary
