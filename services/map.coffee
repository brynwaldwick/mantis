helpers = require '../helpers'
request = require 'request'
somata = require 'somata'

config = require '../config'
api_key = config.maps.api_key

findPlaces = (query, cb) ->

    {loc, radius, keyword} = query

    near_string = loc.lat + ',' + loc.lng + '&radius=' + radius
    types_string = "types=#{keyword}"
        
    url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=' + near_string + '&sensor=false&' + types_string + '&key=' + api_key
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
            cb null, []

query =
    loc:
        lat: 37.7576171
        lng: -122.5776844
    radius: 10000
    keyword: 'school'

Service = new somata.Service 'mantis:map', {findPlaces}