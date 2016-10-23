React = require 'react'

ScrapesList = require './scrapes-list'
scrapes = [
    project: {name: 'Cheap restaurants'}
    searches: [
        query: "Jimmy Bob's"
        kind: 'restaurants'
    ,
        query: 'Pizza Hut'
        loc: {lat: 45.25, lng: 122.22}
        kind: 'restaurants'

    ]
    loc: {lat: 45.25, lng: 122.22}
,
    project: {name: "SWPL Things"}
    searches: [
    ]
    loc: {lat: 41.25, lng: 135.22}
,
    project: {name: "Stats"}
    searches: [
        name: 'Verify and/or rectify pod <-> all ambassador discrepancies'
    ]
,
    project: {name: "General"}
    searches: [
        name: 'Set up a flag to trigger Outgoing Messages when Contact is installed'
    ]
    loc: [{lat: 45.25, lng: 122.22}, {lat: 50.33, lng: 120.22}]
]

in_prog = [
    project: {name: "Closer"}
    searches: [
        name: 'Update to new version'
    ]
,
    project: {name: 'HYFR'}
    searches: [
        name: 'Refine emails'
    ]
]
scrapes = [
    project: {name: 'Cheap restaurants'}
    searches: [
        query: "Jimmy Bob's"
        kind: 'restaurants'
    ,
        query: 'Pizza Hut'
        loc: {lat: 45.25, lng: 122.22}
        kind: 'restaurants'

    ]
    loc: {lat: 45.25, lng: 122.22}
,
    project: {name: "SWPL Things"}
    searches: [
    ]
    loc: {lat: 41.25, lng: 135.22}
,
    project: {name: "Stats"}
    searches: [
        name: 'Verify and/or rectify pod <-> all ambassador discrepancies'
    ]
,
    project: {name: "General"}
    searches: [
        name: 'Set up a flag to trigger Outgoing Messages when Contact is installed'
    ]
    loc: [{lat: 45.25, lng: 122.22}, {lat: 50.33, lng: 120.22}]
]

in_prog = [
    project: {name: "Closer"}
    searches: [
        name: 'Update to new version'
    ]
,
    project: {name: 'HYFR'}
    searches: [
        name: 'Refine emails'
    ]
]

SearchesPage = React.createClass

    render: ->
        <div className='scrapes-page'>
            <div className='scrapes'>
                {scrapes.map (i) ->
                    <ScrapesList scrape=i.project items=i.searches />
                }
            </div>
        </div>

module.exports = SearchesPage