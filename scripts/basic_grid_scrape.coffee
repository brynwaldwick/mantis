_ = require 'underscore'
async = require 'async'
h = require '../helpers'
request = require 'request'
somata = require 'somata'

client = new somata.Client()

MapService = client.bindRemote 'mantis:map'

all_results = []

to_query =
    loc:
        lat: 37.7576171
        lng: -122.5776844
    radius: 50000
    keyword: 'school'

queryAndSavePlaces = (query, cb) ->

    MapService 'findPlaces', query, (err, resp) ->

        if resp.results
            resp.results.map (r) -> r.distance = h.distanceBtw query.loc, r.geometry.location; return r

        all_results = all_results.concat(resp.results)

        cb null, resp.results

scrapeGrid = (grid, done) ->

    async.series (
        grid.map (lat_lng) ->
            return (cb) ->
                grid_query = _.extend {}, to_query, loc: lat_lng
                console.log "Querying", grid_query

                queryAndSavePlaces grid_query, (err, results) ->
                    cb err, results
        )
    , ->
        console.log 'Done'
        done()

test_grid = h.buildGrid {lat1: 40.8054473, lng1: -74.2959454, lat2: 39.4054473, lng2: -73.7959454}, 2

scrapeGrid test_grid, ->
    console.log all_results.map (r) -> {name, vicinity, distance} = r; {name, vicinity, distance}
    process.exit()