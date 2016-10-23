React = require 'react'
fetch$ = require 'kefir-fetch'
KefirBus = require 'kefir-bus'
ScrapeSummary = require './scrape-summary'

Map = require './map'
{LatLng} = require './common'

Dispatcher =
    findScrapes: ->
        fetch$ 'get', "/scrapes.json"

    results$: new KefirBus()

ScrapesPage = React.createClass
    
    getInitialState: ->
        scrapes: []

    componentDidMount: ->
        Map.initializeMap()
        @findScrapes()

    findScrapes: ->
        results$?.offValue @foundScrapes
        results$ = Dispatcher.findScrapes()
        results$.onValue @foundScrapes

    foundScrapes: (scrapes) ->
        @setState {scrapes}

    render: ->
        <div className='scrapes-page'>
            <div className='scrapes'>
                {@state.scrapes.map (s, i) =>
                    <ScrapeSummary scrape=s key=i />
                }
            </div>
            <div id='map-canvas' />
        </div>

module.exports = ScrapesPage