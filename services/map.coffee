helpers = require '../helpers'
request = require 'request'
somata = require 'somata'

config = require '../config'
api_key = config.maps.api_key

findPlaces = (query, cb) ->
    all_results = []
    {loc, radius, type, keyword, minprice, maxprice, pagetoken} = query
    console.log loc
    near_string = loc.lat + ',' + loc.lng + '&radius=' + radius
    if type?
        type_string = "&type=#{type}"
    if minprice?
        minprice = "&minprice=#{minprice}"
    if maxprice?
        maxprice = "&maxprice=#{maxprice}"
    if keyword?
        keyword = "&keyword=#{keyword}"
    # TODO: add keyword
        
    url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=' + near_string + '&sensor=false' + (type_string || '') + (minprice || '') + (maxprice || '') + (keyword || '') + '&key=' + api_key
    if query.pagetoken?
        url += '&pagetoken=' + query.pagetoken

    console.log '[findPlaces] url is', url

    request url, (err, response, results) ->

        console.log err if err?

        places = JSON.parse results

        if places.results.length > 0
            console.log places.results.length
            cb null, places

        else
            console.log places
            console.log '[findPlaces] none found'
            cb null, places

Service = new somata.Service 'mantis:map', {findPlaces}