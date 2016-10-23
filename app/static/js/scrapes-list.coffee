React = require 'react'

SearchItem = require './search-item'

ScrapesList = React.createClass

    render: ->

        <div className='scrapes-list' key=@props.scrape.name >
            <h3>{@props.scrape.name}</h3>
            <div className='items'>
                {@props.items.map (t) ->
                    <SearchItem search=t />
                }
            </div>
        </div>

module.exports = ScrapesList