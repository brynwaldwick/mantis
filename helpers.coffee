

# Utility functions

toRadians = (degrees) ->
    degrees * Math.PI / 180

distanceBtw = (p_1, p_2) ->

    p_1_lat = toRadians p_1.lat
    p_1_lng = toRadians p_1.lng

    p_2_lat = toRadians p_2.lat
    p_2_lng = toRadians p_2.lng

    delta_lat = p_1_lat - p_2_lat
    delta_lng = p_1_lng - p_2_lng
    a = Math.sin(delta_lat/2)*Math.sin(delta_lat/2) + Math.cos(p_1_lat)*Math.cos(p_2_lat) * Math.sin(delta_lng/2)*Math.sin(delta_lng/2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))

    # return 3958.76 * c
    return 6371 * c

# TODO: name mathematically (like "bisect" but N # of times)
divideByN = (n_1, n_2, N) ->
    Delta = n_2 - n_1
    step_size = Delta / N
    # Add a step until you reach the 2nd bound
    result = []
    ind = n_1

    while ind < n_2
        result.push ind
        ind += step_size

    return result

# bounds are a box of {lat1, lng1, lat2, lng2}, defining a rectangle in which to scrape
buildGrid = (top_left_latlng, bottom_right_latlng, x_by_y) ->
    scrape_radius = 20000
    # scrape_interval = scrape_radius / 2

    {lat, lng} = top_left_latlng
    lat1 = lat
    lng1 = lng
    {lat, lng} = bottom_right_latlng
    lat2 = lat
    lng2 = lng

    results = []

    console.log {lat1, lng1, lat2, lng2}

    # Low to high
    lat_tics = divideByN lat2, lat1, x_by_y[1]
    lng_tics = divideByN lng1, lng2, x_by_y[0]

    lat_tics.map (lat) ->
        lng_tics.map (lng) ->
            results.push {lat, lng}

    return results
    # returns [...{lat_n, lng_n}...]

# TODO: build a grid of points that will fully scrape an area with each scrape having radius
# http://gis.stackexchange.com/questions/64118/find-latlngs-that-are-some-x-distance-away-from-a-point-to-south-to-north-to-eas
_buildGrid = (top_left_latlng, bottom_right_latlng, scrape_radius) ->
    return results

module.exports = {
    divideByN
    toRadians
    buildGrid
    distanceBtw
}