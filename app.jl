using Morsel
import JSON

include("WordMatrix.jl")

type Dictionary
  name::String
  m::WordMatrix
end

function tojson(ds::Dict{String,Dictionary})
  JSON.json([ {"abbrev" => k, "name" => d.name} for (k, d) in ds])
end

function DictionaryFromSource(source)
  if haskey(source, "path")
    Dictionary(
      get(source, "name", "Default"),
      WordMatrix(source["path"]))
  else
    error("Dictionary source must have a file path")
  end
end

configfile = joinpath(dirname(@__FILE__()), "config.json")
config = JSON.parse(readall(open(configfile)))

dictionaries = (String => Dictionary)[
  get(s, "abbrev", "default") => DictionaryFromSource(s) for s in get(config, "sources", [])
]

println(typeof(dictionaries))
println(tojson(dictionaries))

# hotness = vectorSumOfWords(m, [
#   "hot", "warm", "sun", "sunshine", "rays", "shining", "light", "burn", 
#   "heat", "fire", "radiation", "summer", "boiling", "day", "heat", "molten", 
#   "reddish", "crimson", "fuchsia"])

# coldness = vectorSumOfWords(m, [
#   "cold", "cool", "moon", "frozen", "freeze", "froze", "ice", "solid", 
#   "winter", "night", "chilly", "polar", "frigid", "blizzard", "darkness", 
#   "white", "gray", "grey", "black", "clay", "soil"])

# hotcold = WordMatrix({"hot" => hotness, "cold" => coldness})


app = Morsel.app()

function jsonResponse(res, data)
  res.headers["Content-Type"] = "application/json"
  return JSON.json(data)
end

function jsonError(res, msg, status = 202)
  res.status = status
  jsonResponse(res, {"error" => msg})
end

function constrain(value, min, max = nothing)
  if value < min
    min
  elseif !is(max, nothing) && value > max
    max
  else
    value
  end
end

function boundedPerPage(perPage, defaultPerPage = 100, maxPerPage = 1000)
  if is(perPage, nothing)
    defaultPerPage
  else
    constrain(perPage, 1, maxPerPage)
  end
end

function boundedPage(page, defaultPage = 1)
  if is(page, nothing)
    defaultPage
  else
    constrain(page, 1)
  end
end

# get(app, "/hot-cold/<word::String>") do req, res
#   word = req.params[:word]
#   ranked = nearest(hotcold, m[word])
#   println("hot-cold: ", word, " ", ranked[1][1])
#   ranked[1][1]
# end

get(app, "/") do req, res
  jsonResponse(res, {
    "service" => "Related Words",
    "routes" => [
      "GET /lookup"
    ]
  })
end

get(app, "/lookup") do req, res
  jsonResponse(res, {
    "dictionaries" => [{ "dictid" => id, "name" => dict.name } for (id, dict) in dictionaries],
    "routes" => [
      "GET /lookup/:dictid"
    ]
  })
end

get(app, "/lookup/<dictid::String>") do req, res
  dictid = req.params[:dictid]

  if !haskey(dictionaries, dictid)
    return jsonError(res, "'$(dictid)' dictionary not found")
  end

  dict = dictionaries[dictid]
  jsonResponse(res, {
    "dictid" => dictid,
    "name" => dict.name,
    "size" => length(dict.m.words),
    "routes" => [
      "GET /lookup/$(dictid)/:words?page=:P&per_page=:PP"
    ]
  })
end

get(app, "/lookup/<dictid::String>/<words::String>") do req, res
  dictid = req.params[:dictid]
  words = req.params[:words]

  if !haskey(dictionaries, dictid)
    return jsonError(res, "'$(dictid)' dictionary not found")
  end

  perPage = boundedPerPage(urlparam(req, :per_page, int))
  page = boundedPage(urlparam(req, :page, int))

  m = dictionaries[dictid].m

  spacedWords = replace(words, r"[:;., ]+", " ")
  words = convert(Array{ASCIIString}, split(spacedWords, ' '))
  println("lookup: ", spacedWords, ", page: ", page, ", per_page: ", perPage)
  try
    quality = vectorSumOfWords(m, words)
    ranked = topnPaginated(m, quality, page, perPage)
    jsonResponse(res, ranked)
  catch e
    if isa(e, WordNotFound)
      return jsonError(res, "'$(e.word)' not in dataset")
    else
      # rethrow(e)
      return jsonError(res, "unable to find vector sum of words: $(e)")
    end
  end
end

start(app, 8000)