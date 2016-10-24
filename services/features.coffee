async = require 'async'
_ = require 'underscore'
h = require '../helpers'

somata = require 'somata'
client = new somata.Client
DataService = client.bindRemote 'mantis:data'
ScrapeService = client.bindRemote 'mantis:scrape'

# A service for calculating qualitative aspects of data based on previously
# scraped information

calculateDistancesFeatureVector = (loc, cb) ->
    # Find the closest Place of each desired type
    Data 'findNearestPlaces', loc, (err, places) ->
        # calculate the distance between each place and loc
        places.map (p) -> p.distance = h.distanceBtw query.loc, p.geometry.location; return p
        
        # return {starbucks: 12.12, school: 5.2}

Models =
    # closest_n
    # n_th neighbor
    # count_within (distance)
    min_distance: (lat_lng, results, result_keys) ->
        keyed_results = result_keys.map (r_k) -> key: r_k, results: results.filter((r) -> r.key == r_k)
        keyed_distances = keyed_results.map (k) ->
            distances = k.results.map((r) -> r.geometry.location).map (loc) -> h.distanceBtw lat_lng, loc
            return {key: k.key.split(':')[1], distance: (_.min(distances) || 0)}
        return keyed_distances

    nearest_neighbors: (lat_lng, results, result_keys) ->
        keyed_results = result_keys.map (r_k) -> key: r_k, results: results.filter((r) -> r.key == r_k)
        keyed_distances = keyed_results.map (k) ->
            distances = k.results.map((r) -> r.geometry.location).map((loc) -> h.distanceBtw lat_lng, loc).sort()
            distances = _.sortBy distances

            return {key: k.key.split(':')[1], closest_4: distances[0..3]}

        return keyed_distances

    closest_10: (lat_lng, results) ->
        distances = results.map((r) -> r.geometry.location).map (loc) -> h.distanceBtw lat_lng, loc
        closest = _.sortBy results, ((r) ->
            r.distance = h.distanceBtw lat_lng, r.geometry.location
            return r.distance)
        result = closest.map (p) ->
            {distance, name, key} = p
            {lat, lng} = p.geometry.location
            kind = key.split(':')[1]
            return {distance, name, kind}
        return result[0..9]

    count_within_n_km: (lat_lng, results, result_keys, n) ->
        keyed_results = result_keys.map (r_k) -> key: r_k, results: results.filter((r) -> r.key == r_k)

        result = keyed_results.map (k) ->
            n_within = k.results.filter((r) -> r.distance < n)
            return {key: k.key.split(':')[1], n_within: n_within.length}

        return result

    nth_neighbor_distance: (lat_lng, results, result_keys, n) ->
        keyed_results = result_keys.map (r_k) -> key: r_k, results: results.filter((r) -> r.key == r_k)
        results = []
        keyed_results.map (k_r) ->
            k_r.results = _.sortBy k_r.results, ((r) ->
                r.distance = h.distanceBtw lat_lng, r.geometry.location
                return r.distance)
            results.push {key: k_r.key.split(':')[1], n, distance: k_r.results[n-1].distance}

        return results

    n_closest: (lat_lng, results, result_keys, n) ->
        distances = results.map((r) -> r.geometry.location).map (loc) -> h.distanceBtw lat_lng, loc
        closest = _.sortBy results, ((r) ->
            r.distance = h.distanceBtw lat_lng, r.geometry.location
            return r.distance)
        result = closest.map (p) ->
            {distance, name, key, types} = p
            {lat, lng} = p.geometry.location
            kind = key.split(':')[1]
            return {distance, name, kind, types}

        return result[0..n-1]

cached_results = {}

loadResults = (result_key, cb) ->
    ScrapeService 'findResultsForScrape', result_key, (err, results) ->
        results.filter((r) -> r != 'undefined').map (r) ->
            r.key = result_key
        cb null, _.compact results

buildFeaturesForModel = (model_id, model_transform, lat_lng, cb) ->
    DataService 'getModel', {_id: model_id}, (err, model) ->
        console.log 'the model', model
        if !cached_results[model_id]?
            async.map model.result_keys, loadResults, (err, results) ->
                results = _.flatten results
                cached_results[model_id] ||= []
                cached_results[model_id] = results
                results.map (r) -> r.distance = h.distanceBtw lat_lng, r.geometry.location

                cb null, Models[model_transform](lat_lng, results, model.result_keys)
        else
            results = cached_results[model_id]
            cb null, Models[model_transform](lat_lng, results, model.result_keys)

buildFeaturesForModelWArg = (model_id, model_transform, lat_lng, arg, cb) ->
    DataService 'getModel', {_id: model_id}, (err, model) ->
        console.log 'the model', model
        async.map model.result_keys, loadResults, (err, results) ->
            results = _.flatten results
            results.map (r) -> r.distance = h.distanceBtw lat_lng, r.geometry.location
            cb null, Models[model_transform](lat_lng, results, model.result_keys, arg)


# stabucks vs kfc - two queries applied to a scrape and weighted into a field

fields = {
    "580af41c10976aaab20bd0d9": {
        name: "SWPL"

        model_id: '580af41c10976aaab20bd0d9'
        scrape: {
            _id: 'western_ma'
            bounds: [{lat: 42.7452693, lng: -73.3886255}, {lat: 42.0189877, lng: -71.3830477}]
            x_by_y: [12, 7]
            radius: 9050
        }

        weights: {
            'search:schools:scrape:western_ma:results': 0.52
            # 'search:dunkin:scrape:western_ma:results': 0.5#0.78
            'search:yoga:scrape:western_ma:results': 0.9#0.95
            'search:mcdonalds:scrape:western_ma:results': 0.35#0.95
            'search:walmart:scrape:western_ma:results': 0.1#0.1
            'search:churches:scrape:western_ma:results': 0.5#0.65
            'search:nice_restaurants:scrape:western_ma:results': 0.99
            'search:golf_courses:scrape:western_ma:results': 0.61
        }
        NEIGHBORHOOD_THRESHOLD: 5
        AREA_THRESHOLD: 30
        GRID_RESOLUTION: 3
    }

    # '580a92d05217628480b5ca53': {
    #     name: "SWPL"

    #     model_id: '580a92d05217628480b5ca53'
    #     scrape: {
    #         _id: 'suffolk'
    #         bounds: [{lat: 41.0531356, lng: -73.5027429}, {lat: 40.7856414, lng: -71.9845888}]
    #         x_by_y: [10, 4]
    #         radius: 7000
    #     }
    #     weights: {
    #         'search:schools:scrape:suffolk:results': 0.55
    #         'search:dunkin:scrape:suffolk:results': 0.5#0.78
    #         'search:yoga:scrape:suffolk:results': 0.5#0.95
    #         'search:walmart:scrape:suffolk:results': 0.2#0.1
    #         # 'search:churches:scrape:suffolk:results': 0.5#0.65
    #         'search:nice_restaurants:scrape:suffolk:results': 0.85
    #         'search:nice_bars:scrape:suffolk:results': 0.8
    #         'search:cheap_bars:scrape:suffolk:results': 0.3
    #         # 'search:golf_courses:scrape:suffolk:results': 0.9
    #     }
    #     NEIGHBORHOOD_THRESHOLD: 3
    #     AREA_THRESHOLD: 15
    #     GRID_RESOLUTION: 5
    # }

    '580a92d05217628480b5ca53': {
        name: "starbucks vs kfc"

        model_id: '580a92d05217628480b5ca53'
        scrape: {
            _id: 'suffolk'
            bounds: [{lat: 41.0531356, lng: -73.5027429}, {lat: 40.7856414, lng: -71.9845888}]
            x_by_y: [10, 4]
            radius: 7000
        }
        weights: {
            'search:starbucks:scrape:suffolk:results': 0.61
            'search:kfc:scrape:suffolk:results': 0.1
            # 'search:golf_courses:scrape:suffolk:results': 0.9
        }
        NEIGHBORHOOD_THRESHOLD: 3
        AREA_THRESHOLD: 7
        GRID_RESOLUTION: 5
    }

    '580d2fbbb938becb39d68a23': {
        name: "starbucks vs kfc"

        model_id: '580d2fbbb938becb39d68a23'
        scrape: {
            _id: 'greater_boston'
            bounds: [{lat: 42.8976389, lng: -71.7524307}, {lat: 41.557141, lng: -70.4045467}]
            x_by_y: [11, 15]
            radius: 7200
        }
        weights: {
            'search:starbucks:scrape:greater_boston:results': 0.8
            'search:kfc:scrape:greater_boston:results': 0.2
            # 'search:whole_foods:scrape:greater_boston:results':0.8
            # 'search:golf_courses:scrape:suffolk:results': 0.9
        }
        NEIGHBORHOOD_THRESHOLD: 2.5
        AREA_THRESHOLD: 10
        GRID_RESOLUTION: 7
    }

    # '580d2fbbb938becb39d68a23': {
    #     name: "starbucks vs kfc"

    #     model_id: '580d2fbbb938becb39d68a23'
    #     scrape: {
    #         _id: 'just_boston'
    #         # bounds: [{lat: 42.8976389, lng: -71.7524307}, {lat: 41.557141, lng: -70.4045467}]
    #         bounds: [{lat: 42.5197093, lng: -71.2477462}, {lat: 42.264938, lng: -70.8863561}]
    #         x_by_y: [11, 15]
    #         radius: 7200
    #     }
    #     weights: {
    #         'search:starbucks:scrape:greater_boston:results': 0.8
    #         'search:kfc:scrape:greater_boston:results': 0.2
    #         'search:whole_foods:scrape:greater_boston:results':0.8
    #         # 'search:golf_courses:scrape:suffolk:results': 0.9
    #     }
    #     NEIGHBORHOOD_THRESHOLD: 1
    #     AREA_THRESHOLD: 4
    #     GRID_RESOLUTION: 8
    # }

    '580ae1c710976aaab20bd0d8': {
        model_id: '580ae1c710976aaab20bd0d8'
        name: "wealthy"

        scrape: {
            _id: 'greater_hartford'
            bounds: [{lat: 41.9951767, lng: -73.4229957}, {lat: 41.307627, lng: -71.8268264}]
            x_by_y: [13, 9]
            radius: 7000,
        }

        weights: {
            # "search:tesla:scrape:greater_hartford:results": 0.5
            # "search:trader_joes:scrape:greater_hartford:results": 0.5
            # "search:western_union:scrape:greater_hartford:results": 0.5
            # "search:dunkin:scrape:greater_hartford:results": 0.5
            'search:mcdonalds:scrape:greater_hartford:results': 0.31
            'search:kfc:scrape:greater_hartford:results': 0.20
            "search:7_eleven:scrape:greater_hartford:results": 0.23
            "search:whole_foods:scrape:greater_hartford:results": 0.82
            "search:walmart:scrape:greater_hartford:results": 0.21
            "search:schools:scrape:greater_hartford:results": 0.62
            "search:cheap_bars:scrape:greater_hartford:results": 0.2
            "search:nice_bars:scrape:greater_hartford:results": 0.71
        }

        NEIGHBORHOOD_THRESHOLD: 5
        AREA_THRESHOLD: 35
        GRID_RESOLUTION: 5
    }

    '580bca6274123b782cfd7adc': {
        model_id: '580bca6274123b782cfd7adc'
        name: "SWPL"
        scrape: {   
            _id: 'south-nh'
            bounds: [{lat: 43.3374274, lng: -72.4366317}, {lat: 42.7113678, lng: -70.5810596}]
            x_by_y: [11, 8]
            radius: 8800
        }

        weights: {
            "search:trader_joes:scrape:south-nh:results": 0.85
            "search:churches:scrape:south-nh:results": 0.5
            "search:cafes:scrape:south-nh:results": 0.62
            "search:walmart:scrape:south-nh:results": 0.31
            "search:nice_restaurants:scrape:south-nh:results": 0.95
        }

        NEIGHBORHOOD_THRESHOLD: 8
        AREA_THRESHOLD: 20
        GRID_RESOLUTION: 5
        
    }

    # '580bd3be4a38b994f39ad8b4': {
    #     model_id: '580bd3be4a38b994f39ad8b4'
    #     name: "bar scene"
    #     scrape: {
    #         _id: 'sf-bay'
    #         # bounds: [{lat: 37.7824742, lng: -122.5142652}, {lat: 37.284985, lng: -121.8502178}]
    #         bounds: [{lat: 37.968378, lng: -122.5903596}, {lat: 37.2785229, lng: -121.6586587}]
    #         x_by_y: [13, 11]
    #         radius: 5000
    #     }

    #     weights: {
    #         "search:cheap_bars:scrape:sf-bay:results": 0.2
    #         "search:nice_bars:scrape:sf-bay:results": 0.99
    #     }

    #     NEIGHBORHOOD_THRESHOLD: 1.5
    #     AREA_THRESHOLD: 6
    #     GRID_RESOLUTION: 5
    # }

    '580cf74911fb34f516d87b24': {
        model_id: '580cf74911fb34f516d87b24'
        name: 'middle class+ families'

        scrape: {
            _id: 'east_of_nyc'
            bounds: [{lat: 40.9776543, lng: -74.005442}, {lat: 40.6061055, lng: -73.4466227}]
            x_by_y: [11, 9]
            radius: 3250
        }   

        weights: {
            'search:7_eleven:scrape:east_of_nyc:results': 0.11
            'search:kfc:scrape:east_of_nyc:results': 0.2
            'search:mcdonalds:scrape:east_of_nyc:results': 0.4
            # 'search:dollar_stores:scrape:east_of_nyc:results': 0.21
            'search:cheap_restaurants:scrape:east_of_nyc:results': 0.3
            'search:cheap_bars:scrape:east_of_nyc:results': 0.3
            # 'search:walmart:scrape:east_of_nyc:results': 0.4
            # # 'search:schools:scrape:east_of_nyc:results': 0.5
            'search:trader_joes:scrape:east_of_nyc:results': 0.6
            'search:starbucks:scrape:east_of_nyc:results': 0.8
            # 'search:yoga:scrape:east_of_nyc:results': 0.53
            'search:whole_foods:scrape:east_of_nyc:results': 0.8
            'search:nice_restaurants:scrape:east_of_nyc:results': 0.91
            # 'search:churches:scrape:east_of_nyc:results': 0.5
            # 'search:dunkin:scrape:east_of_nyc:results': 0.5
        }

        NEIGHBORHOOD_THRESHOLD: 4
        AREA_THRESHOLD: 8
        GRID_RESOLUTION: 3
    }

    '580cf74911fb34f516d87b24': {
        model_id: '580cf74911fb34f516d87b24'
        name: 'starbucks vs kfc'

        scrape: {
            _id: 'east_of_nyc'
            bounds: [{lat: 40.9776543, lng: -74.005442}, {lat: 40.6061055, lng: -73.4466227}]
            x_by_y: [11, 9]
            radius: 3250
        }   

        weights: {
            # 'search:7_eleven:scrape:east_of_nyc:results': 0.11
            'search:kfc:scrape:east_of_nyc:results': 0.2
            # 'search:mcdonalds:scrape:east_of_nyc:results': 0.4
            # 'search:dollar_stores:scrape:east_of_nyc:results': 0.21
            # 'search:cheap_restaurants:scrape:east_of_nyc:results': 0.3
            # 'search:cheap_bars:scrape:east_of_nyc:results': 0.3
            # 'search:walmart:scrape:east_of_nyc:results': 0.4
            # # 'search:schools:scrape:east_of_nyc:results': 0.5
            # 'search:trader_joes:scrape:east_of_nyc:results': 0.6
            'search:starbucks:scrape:east_of_nyc:results': 0.8
            # 'search:yoga:scrape:east_of_nyc:results': 0.53
            # 'search:whole_foods:scrape:east_of_nyc:results': 0.8
            # 'search:nice_restaurants:scrape:east_of_nyc:results': 0.91
            # 'search:churches:scrape:east_of_nyc:results': 0.5
            # 'search:dunkin:scrape:east_of_nyc:results': 0.5
        }

        NEIGHBORHOOD_THRESHOLD: 2
        AREA_THRESHOLD: 8
        GRID_RESOLUTION: 3
    }

    '580d0e619c4d782e8cd16065': {
        model_id: '580d0e619c4d782e8cd16065'
        name: 'wealthy'

        scrape: {
            _id: 'newburgh_to_newhaven'
            bounds: [{lat: 41.5933918, lng: -74.191853}, {lat: 40.9912858, lng: -72.7750609}]
            x_by_y: [13, 8]
            radius: 6500
        }   

        weights: {
            'search:7_eleven:scrape:newburgh_to_newhaven:results': 0.11
            'search:kfc:scrape:newburgh_to_newhaven:results': 0.20#0.95
            'search:dollar_stores:scrape:newburgh_to_newhaven:results': 0.21
            'search:mcdonalds:scrape:newburgh_to_newhaven:results': 0.31#0.95
            'search:cheap_restaurants:scrape:newburgh_to_newhaven:results': 0.38
            'search:walmart:scrape:newburgh_to_newhaven:results': 0.15
            'search:schools:scrape:newburgh_to_newhaven:results': 0.55
            'search:starbucks:scrape:newburgh_to_newhaven:results': 0.67
            'search:yoga:scrape:newburgh_to_newhaven:results': 0.81
            'search:nice_restaurants:scrape:newburgh_to_newhaven:results': 0.95
        }

        NEIGHBORHOOD_THRESHOLD: 4
        AREA_THRESHOLD: 20
        GRID_RESOLUTION: 3
    }
}

field_energies = {}

# Proximity and max energy of a neighbor
NEIGHBOR_THRESHOLD = 0.2
NEIGHBOR_ENERGY = 6

# Proximity and max energy of something in the same area
AREA_THRESHOLD = 10
AREA_ENERGY = 1

buildFieldForModel = (model_id, arg, cb) ->
    DataService 'getModel', {_id: model_id}, (err, model) ->
        field = fields[model_id]
        console.log 'the field is', field
        {scrape, weights, NEIGHBORHOOD_THRESHOLD, AREA_THRESHOLD, GRID_RESOLUTION} = field
        async.map Object.keys(weights), loadResults, (err, results) ->
            # console.log results

            delta_lat = Math.abs(scrape.bounds[0].lat - scrape.bounds[1].lat)/scrape.x_by_y[1]*GRID_RESOLUTION
            delta_lng = Math.abs(scrape.bounds[0].lng - scrape.bounds[1].lng)/scrape.x_by_y[0]*GRID_RESOLUTION

            results = _.flatten(results)

            _grid = h.buildGrid scrape.bounds[0], scrape.bounds[1], [scrape.x_by_y[0]*GRID_RESOLUTION, scrape.x_by_y[1]*GRID_RESOLUTION]

            i = 0

            _grid.map (g) ->
                if i++ % 1000 == 0
                    console.log i

                mid_point = {lat: (g.lat + delta_lat / (2*GRID_RESOLUTION)), lng: (g.lng + delta_lng/(2*GRID_RESOLUTION))}
                top_right = {lat: (g.lat + delta_lat), lng: (g.lng + delta_lng)}
                top_center = {lat: (g.lat + delta_lat), lng: (g.lng + delta_lng/(2*GRID_RESOLUTION))}
                top_left = {lat: (g.lat + delta_lat), lng: (g.lng)}
                bottom_right = {lat: (g.lat), lng: (g.lng + delta_lng)}
                bottom_center = {lat: (g.lat), lng: (g.lng + delta_lng/(2*GRID_RESOLUTION))}
                center_left = {lat: (g.lat + delta_lat/(2*GRID_RESOLUTION)), lng: (g.lng)}
                center_right = {lat: (g.lat + delta_lat/(2*GRID_RESOLUTION)), lng: (g.lng + delta_lng)}


                # physical name for parameter which I think is "loss function"
                closest_results = _.sortBy results, (r) -> h.distanceBtw r.geometry?.location, mid_point

                _energy_1 = 0
                _energy_2 = 0
                _energy_3 = 0
                _energy_4 = 0
                _energy_5 = 0
                _energy_6 = 0
                _energy_7 = 0
                _energy_8 = 0
                _energy_9 = 0
                
                prefactor = ((NEIGHBOR_ENERGY - AREA_ENERGY) / (NEIGHBORHOOD_THRESHOLD - NEIGHBOR_THRESHOLD))

                calculateEnergy = (distance, r) ->
                    _weight = (weights[r.key] || 0.5) - 0.5
                    if Number(distance) < NEIGHBOR_THRESHOLD
                        return NEIGHBOR_ENERGY * _weight

                    # Close-range (neighbors -> in the same)
                    else if Number(distance) < NEIGHBORHOOD_THRESHOLD
                        # if weights[r.key] > 0.5
                        return _weight * (AREA_ENERGY + prefactor * 1/(Math.pow(1 + (distance - NEIGHBOR_THRESHOLD), 2)))

                    # Mid-range
                    else if Number(distance) < AREA_THRESHOLD
                        return _weight * AREA_ENERGY * 1/(Math.pow(1 + (distance - NEIGHBORHOOD_THRESHOLD), 1))

                    else
                        return 0

                calculateCellEnergy = (r) ->

                    calculateDistance = (_r, point) ->
                        if r.geometry?.location?
                            distance = h.distanceBtw r.geometry?.location, point
                        else
                            distance = 10000
                        if distance == 0
                            distance = 1000
                        return distance

                    distance = calculateDistance r, g
                    _energy_1 += calculateEnergy distance, r

                    distance = calculateDistance r, mid_point
                    _energy_2 += calculateEnergy distance, r

                    distance = calculateDistance r, top_right
                    _energy_3 += calculateEnergy distance, r

                    distance = calculateDistance r, bottom_right
                    _energy_4 += calculateEnergy distance, r

                    distance = calculateDistance r, top_left
                    _energy_5 += calculateEnergy distance, r

                    distance = calculateDistance r, top_center
                    _energy_6 += calculateEnergy distance, r

                    distance = calculateDistance r, bottom_center
                    _energy_7 += calculateEnergy distance, r

                    distance = calculateDistance r, center_right
                    _energy_8 += calculateEnergy distance, r

                    distance = calculateDistance r, center_left
                    _energy_9 += calculateEnergy distance, r

                # Calculating at bottom-left and midpoint of each square to avg. out
                # lucky binks of very close locations.
                closest_results[0..100].map (r) ->

                    calculateCellEnergy r

                g.energy = ((_energy_1 / 2) + (_energy_2 * 2) + (_energy_3 / 2) + (_energy_4 / 2) + (_energy_5 / 2) + _energy_6 + _energy_7 + _energy_8 + _energy_9) / 8
            field_energies[model_id] ||= []
            field_energies[model_id] = _grid
            cb null, _grid


setTimeout =>
    model_ids = _.keys(fields)

    buildModelField = (i) -> 
        buildFieldForModel model_ids[i], 'tes', (err, resp) -> #...
            console.log err, resp
            if model_ids[i+1]
                buildModelField i + 1

    buildModelField 0
, 2000
# buildFeaturesForModel {lat: 40.9, lng: -73.1}, '', (err, resp) ->
#     console.log err, resp

loadField = (field_id, query, cb) ->
    console.log field_id
    {start, end} = query
    cb null, field_energies[field_id][start..end]

findFields = (query, cb) ->
    cb null, _.values fields

getField = (field_id, cb) ->
    cb null, fields[field_id]

Service = new somata.Service 'mantis:features', {
    buildFeaturesForModel
    buildFeaturesForModelWArg
    calculateDistancesFeatureVector
    loadField
    findFields
    getField
}



# workflow is
# define query
# define scrape

# run scrape for various queries

# learn w/ data off model