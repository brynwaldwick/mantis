fs = require 'fs'

_ = require 'underscore'
d3 = require 'd3'
config = require '../config'
polar = require 'polar'
somata = require 'somata'

client = new somata.Client

Engine = client.bindRemote 'mantis:engine'
DataService = client.bindRemote 'mantis:data'
Scrape = client.bindRemote 'mantis:scrape'
FeaturesService = client.bindRemote 'mantis:features'

localsMiddleware = (req, res, next) ->
    Object.keys(config._locals).map (_l) ->
        res.locals[_l] = config._locals[_l]
    next()

app = polar config.app, middleware: [localsMiddleware]

app.get '/', (req, res) ->
    res.render 'app'

app.get '/places.json', (req, res) ->
    DataService 'findPlaces', {}, (err, places) ->
        res.json places

app.get '/results/:scrape_key.json', (req, res) ->
    console.log req.params.scrape_key
    Scrape 'findResultsForScrape', req.params.scrape_key, (err, resp) ->
        res.json resp

app.get '/scrapes.json', (req, res) ->
    DataService 'findScrapes', {}, (err, scrapes) ->
        res.json scrapes

app.get '/models/:model_id/results.json', (req, res) ->
    Scrape 'findResultsForModel', req.params.model_id, (err, resp) ->
        res.json resp

app.get '/models/:model_id/:model_kind.json', (req, res) ->
    {lat, lng} = req.query
    FeaturesService 'buildFeaturesForModel', req.params.model_id, req.params.model_kind, {lat, lng}, (err, resp) ->
        res.json resp

app.get '/models/:model_id/:model_kind/:model_arg.json', (req, res) ->
    if req.params.model_arg < 1
        return res.send 502
    {lat, lng} = req.query
    FeaturesService 'buildFeaturesForModelWArg', req.params.model_id, req.params.model_kind, {lat, lng}, req.params.model_arg, (err, resp) ->
        res.json resp

colors = {}
i = 0

app.get '/icons/:icon.svg', (req, res) ->
    {icon} = req.params
    {color, text} = req.query
    slug = text
    if colors[slug]
        color = colors[slug]
    else
        color = d3.schemeCategory20[i%20].replace('#','')
        i++
        color[slug] = color.replace('#','')

    text ||= ''
    marker_icon_template = fs.readFileSync("static/icons/#{icon}.svg").toString()
    res.setHeader 'content-type', 'image/svg+xml'
    res.end marker_icon_template.replace('{color}', color).replace('{text}', text)

app.get '/fields.json', (req, res) ->
    {start, end} = req.query
    FeaturesService 'findFields', {}, (err, resp) ->
        res.json resp

app.get '/fields/:field_id.json', (req, res) ->
    FeaturesService 'getField', req.params.field_id, (err, resp) ->
        res.json resp

app.get '/fields/:field_id/energies.json', (req, res) ->
    {start, end} = req.query
    FeaturesService 'loadField', req.params.field_id, {start, end}, (err, resp) ->
        res.json resp

app.start()
