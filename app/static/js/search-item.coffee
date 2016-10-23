React = require 'react'

SearchItem = React.createClass

    render: ->
        <div key=@props.search.name className='search item'>
            <div className='field'><i className='fa fa-search' />{@props.search.query}</div>
            <div className='field'><i className='fa fa-filter' />{@props.search.kind}</div>
            {if typeof @props.loc == 'object'

                <div className='field'><i className='fa fa-map-marker' />{@props.loc?.lat}, {@props.loc?.lng}</div>
            else
                console.log typeof(@props.loc)
            }
        </div>

module.exports = SearchItem