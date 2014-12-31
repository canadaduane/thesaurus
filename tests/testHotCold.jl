using Base.Test
using AnsiColor

include("../WordMatrix.jl")

println(yellow("Loading data..."))
m = WordMatrix("crawl300-100k")

# hotness = vectorSumOfWords(m, [
#   "hot", "warm", "sun", "sunshine", "rays",
#   "shining", "light", "burn", "heat", "fire",
#   "radiation", "summer", "summertime", "springtime",
#   "boiling", "day", "heat", "molten", "reddish",
#   "crimson", "fuchsia", "mammal", "hell", "damned",
#   "mad", "soft", "yellow", "yellowish", "fuel",
#   "powerplant"])

# coldness = vectorSumOfWords(m, [
#   "cold", "cool", "moon", "moons",
#   "frozen", "freeze", "froze", "ice", "solid", 
#   "winter", "night", "chilly", "polar", "frigid",
#   "blizzard", "darkness", "white", "gray", "grey",
#   "black", "turquoise", "reptile", "hard", "green",
#   "ground", "clay", "soil", "jupiter", "power"])

hotness = vectorSumOfWords(m, [
  "hot", "warm", "sun", "sunshine", "rays", "shining", "light", "burn", 
  "heat", "fire", "radiation", "summer", "boiling", "day", "heat", "molten", 
  "reddish", "crimson", "fuchsia"])

coldness = vectorSumOfWords(m, [
  "cold", "cool", "moon", "frozen", "freeze", "froze", "ice", "solid", 
  "winter", "night", "chilly", "polar", "frigid", "blizzard", "darkness", 
  "white", "gray", "grey", "black", "clay", "soil"])

hotcold = WordMatrix({"hot" => hotness, "cold" => coldness})

hotWords = readdlm("hot.txt", ' ', String, quotes=false, comments=false)

for word in hotWords
  try
    top = nearest(hotcold, m[word])
    if top[1][1] == "hot"
      println(" ", green("ok "), word, " ", top[1])
    else
      println(" ", red("FAIL "), word, " should be hot ", top[1], " ", top[2])
    end
  catch e
    if isa(e, WordNotFound)
      println(" '", word, "' ", yellow("not found"))
    end
  end
end
println(yellow("---------"))

coldWords = readdlm("cold.txt", ' ', String, quotes=false, comments=false)

for word in coldWords
  try
    top = nearest(hotcold, m[word])
    if top[1][1] == "cold"
      println(" ", green("ok "), word, " ", top[1])
    else
      println(" ", red("FAIL "), word, " should be cold ", top[1], " ", top[2])
    end
  catch e
    if isa(e, WordNotFound)
      println(" '", word, "' ", yellow("not found"))
    end
  end
end
