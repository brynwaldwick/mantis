React = require 'react'

{LatLng} = require './common'

ScrapeSummary = React.createClass

    clickScrape: (s) -> =>
        @props.Map.renderScrape s

    render: ->
        s = @props.scrape

        <div className='scrape' key=s.id onClick=@clickScrape(s) >
            <h3 className='name'>{s._id}</h3>
            <div className='field'>
                <h5>Bounds</h5>
                <div className='bounds'>[ <LatLng lat_lng=s.bounds[0] /> , <LatLng lat_lng=s.bounds[1] /> ]</div>
            </div>
            <div className='field third'>
                <h5>n_x</h5>
                <div className='value'>{s.x_by_y[0]}</div>
            </div>
            <div className='field third'>
                <h5>n_y</h5>
                <div className='value'>{s.x_by_y[1]}</div>
            </div>
            <div className='field third'>
                <h5>radius</h5>
                <div className='value'>{s.radius}</div>
            </div>
        </div>

module.exports = ScrapeSummary
