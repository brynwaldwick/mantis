_ = require 'underscore'
React = require 'react'
ReactDOM = require 'react-dom'
{IndexRoute, Route, Router, hashHistory, Link} = require 'react-router'

{Overlay} = require './common'

ScrapesPage = require './scrapes-page'
FieldPage = require './field-page'
FieldsPage = require './fields-page'
SearchesPage = require './searches-page'
ResultsPage = require './results-page'

AppView = React.createClass

    render: ->
        <div className='app'>
            <NavBar />
            <div className='content'>
                {@props.children}
            </div>
        </div>

NavBar = React.createClass
    
    render: ->
        <div id='nav'>
            <img className='logo' src='/icons/mantis-logo.png' />
            <div className='brand'>mantis</div>
            <Link to='/searches' activeClassName='active' >Searches</Link>
            <Link to='/scrapes' activeClassName='active' >Scrapes</Link>
            <Link to='/results' activeClassName='active' >Results</Link>
            <Link to='/fields' activeClassName='active' >Fields</Link>
            <SearchBar />
        </div>
            # <Link to='/fields' activeClassName='active' >Models</Link>#Collection of searches over a scrape
            # you operate on this to learn, and then use the output of the learning to produce a field to 
            # inform future operations

SearchBar = React.createClass

    render: ->
        <div className='search-bar'>
            <input name='q' placeholder='search mantis results' />
        </div>

HomePage = React.createClass

    render: ->
        <div className='home-page'>
            Hello
        </div>

PlaceDetails = React.createClass

    render: ->
        <div className='place-details-page'>
            This is a place
        </div>

SearchPage = React.createClass

    render: ->
        <div className='search-page'>
            This is the result of a query
        </div>


# Routes
# ------------------------------------------------------------------------------

routes =
    <Route path="/" component=AppView>
        <IndexRoute component=HomePage >
        <Route path="/scrapes" component=ScrapesPage />
        <Route path="/fields" component=FieldsPage />
        <Route path="/fields/:field_id" component=FieldPage />
        <Route path="/searches" component=SearchesPage />
        <Route path="/results" component=ResultsPage />
        <Route path="/results/:results_key" component=ResultsPage />
        <Route path="/places/search" component=SearchPage />
        <Route path="/places/:place_id" component=PlaceDetails />
    </Route>

ReactDOM.render(<Router routes={routes} history={hashHistory} />, document.getElementById('app'))
