_ = require 'underscore'
async = require 'async'
h = require '../helpers'
request = require 'request'
somata = require 'somata'
redis = require('redis').createClient()

client = new somata.Client()

MapService = client.bindRemote 'mantis:map'
DataService = client.bindRemote 'mantis:data'

queryPlaces = (query, cb) ->
    # TODO: paginate through to end
    all_results = []

    queryAndProcess = (_query) ->
        MapService 'findPlaces', _query, (err, resp) ->
            all_results = all_results.concat resp.results
            # TODO: defeat the delay in paginating through this
            # if resp.next_page_token?
            #     query.pagetoken = resp.next_page_token
            #     queryAndProcess query
            # else
            console.log resp
            if err?
                cb err
            else if resp.results?
                {results, next_page_token} = resp
                cb null, {results, next_page_token}

    queryAndProcess query

processResults = (places, search, cb) ->
    if search.filter?
        places = places.filter (p) -> search.filter p

    DataService 'upsertPlacesChunk', places, cb

saveResults = (search, scrape, results, cb) ->
    # TODO: push into results set
    result_ids = _.pluck results, '_id' #TODO: perhaps just do the place_id
    results_key = "search:#{search._id}:scrape:#{scrape._id}:results"
    if result_ids.length
        redis.sadd results_key, result_ids...
    cb null, result_ids

doScrapedSearch = (search, scrape, done) ->

    paginations = []

    grid = h.buildGrid scrape.bounds[0], scrape.bounds[1], scrape.x_by_y, 15

    async.series (
        grid.map (lat_lng) ->
            return (cb) ->
                this_query = _.extend {}, search.query_parts, loc: lat_lng, radius: scrape.radius
                console.log "Querying", this_query

                queryPlaces this_query, (err, maps_results) ->
                    return cb err if err?
                    {results, next_page_token} = maps_results
                    if next_page_token
                        page_query = _.extend {}, this_query, pagetoken: next_page_token
                        console.log 'Ill paginate this query', page_query
                        paginations.push page_query
                    console.log 'got', results.length, 'results'

                    processResults results, search, (err, places) ->
                        console.log 'upserted', places.length
                        saveResults search, scrape, places, cb
        )
    , ->
        processPaginations = (_paginations) ->
            console.log 'going to paginate these', _paginations
            remaining_paginations = []
            async.series (
                _paginations.map (_query) ->
                    return (cb) ->
                        queryPlaces _query, (err, maps_results) ->
                            return cb err if err?
                            {results, next_page_token} = maps_results
                            if next_page_token
                                page_query = _.extend {}, _query, pagetoken: next_page_token
                                remaining_paginations.push page_query

                            console.log 'got', results.length, 'results'
                            processResults results, search, (err, places) ->
                                console.log 'upserted', places.length
                                saveResults search, scrape, places, cb
            ), ->
                if remaining_paginations.length
                    console.log 'Ill pause to paginate some things'
                    setTimeout ->
                        processPaginations remaining_paginations
                    , 2000
                else
                    console.log 'Done'
                    done()

        if paginations.length
            console.log 'Ill pause to paginate some things'
            setTimeout ->
                processPaginations(paginations)
            , 2000
        else
            console.log 'Done'
            done()

DataService 'findScrapes', {}, (err, scrapes) ->
    DataService 'findSearches', {}, (err, searches) ->
        console.log scrapes, scrapes.length
        console.log searches, searches.length
    #     err, resp
        # doScrapedSearch searches[26], scrapes[10], ->
            # process.exit()

findResultsForScrape = (scrape_key, cb) ->

    if scrape_key.indexOf('*') > -1
        redis.keys scrape_key, (err, keys) ->
            async.map keys, (k, _cb) ->
                redis.smembers k, (err, resp) ->
                    DataService 'findPlacesById', resp, (err, places) ->
                        places?.map (p) ->
                            p.key = k
                            p.kind = k.split(':')[1]
                        _cb err, places
            , (err, resp) ->
                places = _.flatten resp
                cb err, places
    else
        redis.smembers scrape_key, (err, resp) ->
            console.log err, resp
            DataService 'findPlacesById', resp, (err, places) ->
                places?.map (p) ->
                    p.key = scrape_key
                    p.kind = scrape_key.split(':')[1]
                cb err, places

loadResults = (result_key, cb) ->
    findResultsForScrape result_key, cb

cached_models = {}
findResultsForModel = (model_id, cb) ->
    all_results = []
    if cached_models[model_id]?
        return cb null, cached_models[model_id]
    DataService 'getModel', {_id: model_id}, (err, model) ->
        # console.log 'the model', model
        async.map model.result_keys, (k, _cb) ->
            loadResults k, _cb
        , (err, resp) ->
            all_results = _.compact _.flatten(resp)
            cached_models[model_id] = all_results
            cb null, all_results

service = new somata.Service 'mantis:scrape', {
    findResultsForScrape
    findResultsForModel
}