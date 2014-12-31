using Morsel
import JSON

include("WordMatrix.jl")

m = WordMatrix("/Users/duane/tmp/thesaurus/crawl300-100k")

hotness = vectorSumOfWords(m, [
  "hot", "warm", "sun", "sunshine", "rays", "shining", "light", "burn", 
  "heat", "fire", "radiation", "summer", "boiling", "day", "heat", "molten", 
  "reddish", "crimson", "fuchsia"])

coldness = vectorSumOfWords(m, [
  "cold", "cool", "moon", "frozen", "freeze", "froze", "ice", "solid", 
  "winter", "night", "chilly", "polar", "frigid", "blizzard", "darkness", 
  "white", "gray", "grey", "black", "clay", "soil"])

hotcold = WordMatrix({"hot" => hotness, "cold" => coldness})


app = Morsel.app()

function jsonResponse(res, data)
  res.headers["Content-Type"] = "application/json"
  JSON.json(data)
end

get(app, "/hot-cold/<word::String>") do req, res
  word = req.params[:word]
  ranked = nearest(hotcold, m[word])
  println("hot-cold: ", word, " ", ranked[1][1])
  ranked[1][1]
end

get(app, "/lookup") do req, res
  if haskey(req.state, :url_params)
    params = req.state[:url_params]
    n = int(get(params, "n", "30"))
    if haskey(params, "words")
      spacedWords = replace(get(params, "words", ""), r"[:;., ]+", " ")
      words = convert(Array{ASCIIString}, split(spacedWords, ' '))
      println("lookup: ", words)
      try
        quality = vectorSumOfWords(m, words)
        ranked = topn(m, quality, n)
        jsonResponse(res, ranked)
      catch e
        if isa(e, WordNotFound)
          return jsonResponse(res, {"error" => "'$(e.word)' not in dataset"})
        else
          return jsonResponse(res, {"error" => "unable to find vector sum of words"})
        end
      end
    else
      jsonResponse(res, {"error" => "'words' is a required param"})
    end
  else
    jsonResponse(res, {"error" => "params required"})
  end
end

get(app, "/") do req, res
"""
<html>
<head><title>GloVe Thesaurus</title></head>
<body>
  <h2>Duane's <a href="http://nlp.stanford.edu/projects/glove/">GloVe</a> Thesaurus</h2>

  <form method="GET" action="/lookup">
    <div><label for="words">Words (separated by spaces or commas):</label></div>
    <input type="text" name="words" value="" />
    <input type="submit" value="Lookup" />
  </form>
</body>
</html>
"""
end

start(app, 8000)