async = require 'async'
_ = require 'underscore'
somata = require 'somata'
config = require '../config'
generic = require 'data-service/generic'
orm = require('data-service/orm')(config.mongodb)

class User extends orm.Collection
    @collection: 'users'
    @singular: 'user'

# A set of locations (single, array over an area, radius (?))
class Scrape extends orm.Collection
    @collection: 'scrapes'
    @singular: 'scrape'

# A named set of query parameters (or an array of these)
class Search extends orm.Collection
    @collection: 'searches'
    @singular: 'search'

# Cached Google Place (maybe slightly "picked")
class Place extends orm.Collection
    @collection: 'places'
    @singular: 'place'

# An array of place ids resulting from a Search over a Scrape
class Result extends orm.Collection
    @collection: 'results'
    @singular: 'result'

class Model extends orm.Collection
    @collection: 'models'
    @singular: 'model'

schema = {User, Scrape, Search, Place, Model}

generic_methods = generic(schema)

data_methods = _.extend {}, generic_methods

data_methods.findNearestPlaces = (loc, cb) ->

    # TODO: query for the nearest Place of each kind

    cb null, loc

upsertPlace = (place, cb) ->
    Place.findAndModify
        place_id: place.place_id
    , $set: place, {new: true, upsert: true}, (err, resp) ->
        cb err, resp

data_methods.upsertPlacesChunk = (places, cb) ->
    async.map places, upsertPlace, (err, resp) ->
        cb err, resp

scrapes = [
    _id: 'roseland-manhattan'
    bounds: [{lat: 40.9054473, lng: -74.2959454}, {lat: 40.8054473, lng: -73.7959454}]
    x_by_y: [5, 3]
    radius: 5000
,
    _id: 'sf-bay'
    # bounds: [{lat: 37.7824742, lng: -122.5142652}, {lat: 37.284985, lng: -121.8502178}]
    bounds: [{lat: 37.968378, lng: -122.5903596}, {lat: 37.2785229, lng: -121.6586587}]
    x_by_y: [13, 11]
    radius: 5000
,
    _id: 'south-nh'
    bounds: [{lat: 43.3374274, lng: -72.4366317}, {lat: 42.7113678, lng: -70.5810596}]
    x_by_y: [11, 8]
    radius: 8800
,
    _id: 'suffolk'
    bounds: [{lat: 41.0531356, lng: -73.5027429}, {lat: 40.7856414, lng: -71.9845888}]
    x_by_y: [10, 4]
    radius: 7000
,
    _id: 'greater_hartford'
    bounds: [{lat: 41.9951767, lng: -73.4229957}, {lat: 41.307627, lng: -71.8268264}]
    x_by_y: [13, 9]
    radius: 7000,
,
    _id: 'rhode_island'
    bounds: [{lat: 42.0066019, lng: -71.8054587}, {lat: 41.3887271, lng: -71.1217799}]
    x_by_y: [6, 8]
    radius: 7000
,
    _id: 'western_ma'
    bounds: [{lat: 42.7452693, lng: -73.3886255}, {lat: 42.0189877, lng: -71.3830477}]
    x_by_y: [12, 7]
    radius: 9050
,
    _id: 'east_of_nyc'
    bounds: [{lat: 40.9776543, lng: -74.005442}, {lat: 40.6061055, lng: -73.4466227}]
    x_by_y: [11, 9]
    radius: 3250
,
    _id: 'newburgh_to_newhaven'
    bounds: [{lat: 41.5933918, lng: -74.191853}, {lat: 40.9912858, lng: -72.7750609}]
    x_by_y: [13, 8]
    radius: 6500
,
    _id: 'greater_boston'
    bounds: [{lat: 42.8976389, lng: -71.7524307}, {lat: 41.557141, lng: -70.4045467}]
    x_by_y: [11, 15]
    radius: 7200
]

data_methods.findScrapes = (query, cb) ->
    cb null, scrapes

searches = [
    _id: 'schools'
    query_parts:
        type: 'school'
,

    _id: 'casinos'
    query_parts:
        type: 'casino'
,
    _id: 'cafes'
    query_parts:
        type: 'cafe'
,
    _id: 'nice_cafes'
    query_parts:
        type: 'cafe'
        minprice: 3
,
    _id: 'cheap_bars'
    query_parts:
        type: 'bar'
        maxprice: 1
,
    _id: 'starbucks'
    query_parts:
        keyword: 'starbucks'
    filter: (p) ->
        return p.name.match(/dunkin/i)?
,
    _id: 'yoga'
    query_parts:
        keyword: 'yoga'
,
    _id: 'dunkin'
    query_parts:
        keyword: 'dunkin donuts'
    filter: (p) ->
        return p.name.match(/dunkin/i)?
,
    _id: 'nice_bars'
    query_parts:
        type: 'bar'
        minprice: 3
,
    _id: 'nice_restaurants'
    query_parts:
        type: 'restaurant'
        minprice: 3
,
    _id: 'cheap_restaurants'
    query_parts:
        type: 'restaurant'
        maxprice: 1
,
    _id: 'churches'
    query_parts:
        type: 'church'
,
    _id: 'parks'
    query_parts:
        type: 'park'
,
    _id: 'liquor_stores'
    query_parts:
        type: 'liquor_store'
,
    _id: 'car_repairs'
    query_parts:
        type: 'car_repair'
,
    _id: '7_eleven'
    query_parts:
        keyword: '7 eleven'
        type: 'convenience_store'
    filter: (p) ->
        return p.name.match(/eleven/i)?
,
    _id: 'walmart'
    query_parts:
        keyword: 'Walmart'
        type: 'department_store'
    filter: (p) ->
        return (p.name.match(/walmart/i)? && (p.name.indexOf('harmacy') == -1))
,
    _id: 'tesla'
    query_parts:
        keyword: 'tesla'
        type: 'car_dealer'
    filter: (p) ->
        return p.name.match(/mcdonald/i)?
,
    _id: 'whole_foods'
    query_parts:
        keyword: 'whole foods'
    filter: (p) ->
        return p.name.match(/whole foods/i)?
,
    _id: 'dollar_stores'
    query_parts:
        keyword: 'dollar store'
        type: 'store'
,
    _id: 'trader_joes'
    query_parts:
        keyword: 'trader joes'
,
    _id: 'western_union'
    query_parts:
        keyword: 'western union'
        type: 'finance'
,
    _id: 'golf_courses'
    query_parts:
        keyword: 'golf course'
,
    _id: 'mcdonalds'
    query_parts:
        keyword: 'mcdonalds'
        maxprice: 1
        type: 'restaurant'
    filter: (p) ->
        return p.name.match(/mcdonald/i)?
,
    _id: 'kfc'
    query_parts:
        keyword: 'kfc'
        maxprice: 1
        type: 'restaurant'
    filter: (p) ->
        return p.name.match(/mcdonald/i)?
]

data_methods.findSearches = (query, cb) ->
    cb null, searches

Service = new somata.Service 'mantis:data', data_methods