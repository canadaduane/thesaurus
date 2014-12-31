using Morsel

include("WordMatrix.jl")

m = WordMatrix("crawl300-100k")

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

get(app, "/hot-or-cold/<word::String>") do req, res
    word = req.params[:word]
    ranked = nearest(hotcold, m[word])
    ranked[1][1]
end

get(app, "/") do req, res
    "Duane's Thesaurus"
end

start(app, 8000)