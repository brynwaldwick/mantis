# Mantis

Scrape and operate on Google Places and Google Maps

## Schema

### Place

A local representation of a Google Place.

### Search

A set of query parameters and filtering mechanisms to use Google Maps.

    _id: 'car_repairs'
    query_parts:
        type: 'car_repair'

    _id: 'cheap_restaurants'
    query_parts:
        type: 'restaurant'
        maxprice: 1

    _id: '7_eleven'
    query_parts:
        keyword: '7 eleven'
        type: 'convenience_store'
    filter: (p) ->
        return p.name.match(/eleven/i)?

    _id: 'walmart'
    query_parts:
        keyword: 'Walmart'
        type: 'department_store'
    filter: (p) ->
        return (p.name.match(/walmart/i)? && (p.name.indexOf('harmacy') == -1))

### Scrapes

Geographic regions defined by square bounds and a granularity. Granularity can be tuned for more efficient search in less dense regions. Mantis' scraper will automatically paginate in locations where there were many results. Hopefully one day it will automatically search with more granularity if the original wide scrape saturates (5 pages).

    _id: 'roseland-manhattan'
    bounds: [{lat: 40.9054473, lng: -74.2959454}, {lat: 40.8054473, lng: -73.7959454}]
    x_by_y: [5, 3]
    radius: 5000

    _id: 'sf-bay'
    # bounds: [{lat: 37.7824742, lng: -122.5142652}, {lat: 37.284985, lng: -121.8502178}]
    bounds: [{lat: 37.968378, lng: -122.5903596}, {lat: 37.2785229, lng: -121.6586587}]
    x_by_y: [13, 11]
    radius: 5000

### Results

An array of Google Place ids found by applying a Search to a Scrape. These are keyed like `search:kfc:scrape:greater_boston:results` and cached in redis.


### Model

A set of Results and weights that are used as a set to characterize a region.

The model holds a weight on each species of Place included in the Results, which parametrizes the radial effects of a Place on the Model in the surrounding area. Results are pluggable in and out of a model.


## A Physical Model for characterizing a general location by distance to nearby Places.

Consider correlation between instances of retailers, restaurants, schools, and other locations represented by Google Places, and the demographics or other societal or cultural characteristics at a given latitude and longitude.

We will use a model inspired by atomistics that considers distance in 3 regimes: neighbors, neighborhoods, and areas. We parametrize the neighbor radius, neighborhood radius, and area radius to fit a variety of local densities. We also parameterize the neighbor energy, neighborhood energy, and area energy, to capture nonlinearities between the relative effects of a nearby Place as a neighbor or from way across town. Olive Gardens and prisons may behave differently in this sense.

Place < r_neighbor > < r_neighborhood > < r_area >

![Mantis Model](http://i.imgur.com/Xn8kvP4.png)

Given a latitude and longitude, we query all Places within r_area, sum their effect (based on a per-species parameterization) on a latitude and longitude to calculate the Model's energy for a given point. This energy function applied over a range of latitude and longitude is called a Field.

By testing positive and negative trials against these Fields we hope to train the energy model's parameters and identify correlations between positive trials and nearby species. We can then apply this model to unexplored regions to generate locations that will give a higher rate of positive trials.
