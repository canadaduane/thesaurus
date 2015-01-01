using Morsel
import JSON

include("WordMatrix.jl")

m = WordMatrix("/Users/duane/tmp/thesaurus/crawl300-100k")
# m = WordMatrix("/Users/duane/Projects/thesaurus/short")

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

# get(app, "/hot-cold/<word::String>") do req, res
#   word = req.params[:word]
#   ranked = nearest(hotcold, m[word])
#   println("hot-cold: ", word, " ", ranked[1][1])
#   ranked[1][1]
# end

get(app, "/lookup") do req, res
  if haskey(req.state, :url_params)
    params = req.state[:url_params]
    n = int(get(params, "n", "30"))
    if haskey(params, "words")
      spacedWords = replace(get(params, "words", ""), r"[:;., ]+", " ")
      words = convert(Array{ASCIIString}, split(spacedWords, ' '))
      println("lookup: ", words, " ", n)
      try
        quality = vectorSumOfWords(m, words)
        ranked = topn(m, quality, n)
        jsonResponse(res, ranked)
      catch e
        if isa(e, WordNotFound)
          return jsonError(res, "'$(e.word)' not in dataset")
        else
          return jsonError(res, "unable to find vector sum of words $(e)")
        end
      end
    else
      jsonError(res, "'words' is a required param")
    end
  else
    jsonError(res, "params required")
  end
end

function cssResponse(res, css)
  res.headers["Content-Type"] = "text/css"
  return css
end

get(app, "/css/<css::String>") do req, res
  css = readall(open(joinpath(dirname(@__FILE__), "public", "css", req.params[:css])))
  cssResponse(res, css)
end

function jsResponse(res, js)
  res.headers["Content-Type"] = "text/javascript"
  return js
end

get(app, "/js/<js::String>") do req, res
  js = readall(open(joinpath(dirname(@__FILE__), "public", "js", req.params[:js])))
  jsResponse(res, js)
end


get(app, "/") do req, res
"""
<!DOCTYPE html>
<html lang="en">
<head>

  <!-- Basic Page Needs
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <meta charset="utf-8">
  <title>GloVe Thesaurus</title>
  <meta name="description" content="A thesaurus-like tool based on GloVe word vectorization">
  <meta name="author" content="Duane Johnson">

  <!-- Mobile Specific Metas
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <!-- FONT
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <link href="//fonts.googleapis.com/css?family=Raleway:400,300,600" rel="stylesheet" type="text/css">

  <!-- CSS
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <link rel="stylesheet" href="/css/normalize.css">
  <link rel="stylesheet" href="/css/skeleton.css">
  <link rel="stylesheet" href="/css/styles.css">

  <!-- JS
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <script src="/js/jquery.js"></script>
  <script src="/js/react.js"></script>
  <script src="/js/WordSearch.js"></script>
  <script src="/js/ResultTable.js"></script>
  <script src="/js/App.js"></script>

</head>
<body>

  <!-- Primary Page Layout
  –––––––––––––––––––––––––––––––––––––––––––––––––– -->
  <div class="container">
    <section class="header">
      <div class="row">
        <h4>Duane's <a href="http://nlp.stanford.edu/projects/glove/">GloVe</a> Thesaurus</h4>
      </div>
    </section>
    <section class="search" id="search"></section>
  </div>

  <script>
    var app = new App({"lookupUrl": "/lookup"})
    React.render(app, \$('#search')[0]);
  </script>
</body>
</html>
"""
end

start(app, 8000)