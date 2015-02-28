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

function words2list(words)
  convert(Array{ASCIIString}, split(replace(words, r"[:;., ]+", " "), ' '))
end

get(app, "/") do req, res
  jsonResponse(res, {
    "service" => "Related Words",
    "routes" => [
      "GET /lookup",
      "GET /categorize"
    ]
  })
end

function listDictionaries(prefix)
  function(req, res)
    jsonResponse(res, {
      "dictionaries" => [{ "dictid" => id, "name" => dict.name } for (id, dict) in dictionaries],
      "routes" => [
        "GET /$(prefix)/:dictid"
      ]
    })
  end
end

get(listDictionaries("lookup"), app, "/lookup")
get(listDictionaries("categorize"), app, "/categorize")

function getDictionary(routes)
  function(req, res)
    dictid = req.params[:dictid]

    if !haskey(dictionaries, dictid)
      return jsonError(res, "'$(dictid)' dictionary not found")
    end

    dict = dictionaries[dictid]
    jsonResponse(res, {
      "dictid" => dictid,
      "name" => dict.name,
      "size" => length(dict.m.words),
      "routes" => routes
    })
  end
end

get(getDictionary(["GET /lookup/:dictid/:words?page=:P&per_page=:PP"]),
    app, "/lookup/<dictid::String>")
get(getDictionary(["GET /categorize/:dictid/:wordset1/:wordset2/:testword"]),
    app, "/categorize/<dictid::String>")


get(app, "/lookup/<dictid::String>/<words::String>") do req, res
  dictid = req.params[:dictid]
  words = req.params[:words]

  if !haskey(dictionaries, dictid)
    return jsonError(res, "'$(dictid)' dictionary not found")
  end

  perPage = boundedPerPage(urlparam(req, :per_page, int))
  page = boundedPage(urlparam(req, :page, int))

  m = dictionaries[dictid].m

  wordsList = words2list(words)
  println("lookup: ", wordsList, ", page: ", page, ", per_page: ", perPage)
  try
    quality = vectorSumOfWords(m, wordsList)
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

# hotness = vectorSumOfWords(m, [
#   "hot", "warm", "sun", "sunshine", "rays", "shining", "light", "burn", 
#   "heat", "fire", "radiation", "summer", "boiling", "day", "heat", "molten", 
#   "reddish", "crimson", "fuchsia"])

# coldness = vectorSumOfWords(m, [
#   "cold", "cool", "moon", "frozen", "freeze", "froze", "ice", "solid", 
#   "winter", "night", "chilly", "polar", "frigid", "blizzard", "darkness", 
#   "white", "gray", "grey", "black", "clay", "soil"])

# hotcold = WordMatrix({"hot" => hotness, "cold" => coldness})

# get(app, "/hot-cold/<word::String>") do req, res
#   word = req.params[:word]
#   ranked = nearest(hotcold, m[word])
#   println("hot-cold: ", word, " ", ranked[1][1])
#   ranked[1][1]
# end

get(app,
  "/categorize/<dictid::String>" *
  "/<wordset1::String>/<wordset2::String>" *
  "/<testword::String>") do req, res

  dictid = req.params[:dictid]
  wordset1 = req.params[:wordset1]
  wordset2 = req.params[:wordset2]
  testword = req.params[:testword]

  if !haskey(dictionaries, dictid)
    return jsonError(res, "'$(dictid)' dictionary not found")
  end

  m = dictionaries[dictid].m

  set1 = vectorSumOfWords(m, words2list(wordset1))
  set2 = vectorSumOfWords(m, words2list(wordset2))

  matrix = WordMatrix({"set1" => set1, "set2" => set2})

  ranked = nearest(matrix, m[testword])
  println("categorize: ", testword, " ", ranked[1][1], " : ", wordset1, " / ", wordset2)
  # ranked[1][1]
  jsonResponse(res, {
    "testword" => testword,
    "category" => ranked[1][1],
    "set1" => wordset1,
    "set2" => wordset2  
  })
end

start(app, 8000)