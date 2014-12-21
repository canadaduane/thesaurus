using Distances

defaultWorkDir = "/Users/duane/Projects/thesaurus"

typealias WordVector Array{Float64}

type WordMatrix
    relationships::Array{Float64}
    words::Array{String}

    WordMatrix(r, w) = new(r, w)
    function WordMatrix(corpusName::String, workDir = defaultWorkDir)
        relationships = transpose(readdlm("$(workDir)/$(corpusName).vec", ' ', Float64, quotes=false, comments=false))
        words = [chomp(l) for l in readlines(open("$(workDir)/$(corpusName).idx"))]
        new(relationships, words)
    end
end

m = WordMatrix("crawl300-100k")

# workDir = "/Users/duane/Projects/thesaurus"
# corpusName = "crawl300-100k"
# corpusName = "wiki50"
# corpusName = "short"
# headwords = [chomp(l) for l in readlines(open("$(workDir)/$(corpusName).idx"))]
# matrix = transpose(readdlm("$(workDir)/$(corpusName).vec", ' ', Float64, quotes=false, comments=false))


# Get the words out of the
# headwords = [v[:,i][1] for i in 1:size(v)[2]]
# matrixAny = v[2:end,1:end]
# matrix = reshape(Float64[x for x in matrixAny], size(matrixAny)[1], size(matrixAny)[2])

# vecmat = [vec(Float64[j for j in matrixAny[i,1:end]]) for i in 1:size(matrixAny)[1]]

function indexOfWord(m :: WordMatrix, word :: String)
  findin(m.words, [word])[1]
end

function getindex(m :: WordMatrix, idx :: Integer)
    (m.words[idx], m.relationships[:,idx])
end

function getindex(m :: WordMatrix, word :: String)
    m.relationships[:,indexOfWord(word)]
end

function mOne(size, i, value)
    z = zeros(size, 1)
    z[i] = value
    return z
end

function vectorExtrema(dim)
    m = transpose(matrix)
    low = minimum(m, 1)[dim]
    high = maximum(m, 1)[dim]
    range = (high - low)
    step = range / 10
    [findTop(mOne(300, dim, x))[1] for x in low:step:high]
#     (headwords[findin(m[:,dim], low)[1]],
#      headwords[findin(m[:,dim], high)[1]])
end

vectorExtrema(200)

function vectorForWord(word)
  index = indexOfWord(word)
  matrix[1:end,index:index]
end
word = vectorForWord

function vectorCompare(v::WordVector)
  pairwise(Euclidean(), matrix, v)
end
function vectorCompare(word::String)
  vectorCompare(vectorForWord(word))
end

function vectorComparePairs(wordOrVector)
  hws = transpose(headwords)
  scores = transpose(vectorCompare(wordOrVector))
  zip(hws, scores)
end

function findTop(wordOrVector)
  results = [(a,b) for (a,b) in vectorComparePairs(wordOrVector)]
  second = x -> x[2]
  sort(results, by=second)
end

function find30(wordOrVector)
  findTop(wordOrVector)[1:30]
end

function findTopIndexed(wordOrVector)
    top = findTop(wordOrVector)
    [(i, r) for (i,r) in zip(1:length(top), top)]
end

function categoryOf(wordOrVector)
  categoryNames = [
    "animal",     "animals",
    "shape",      "shapes",
    "color",      "colors",
    "job",        "jobs",
    "place",      "places",
    "object",     "objects",
    "company",    "companies",
    "event",      "events",
    "material",   "materials",
    "direction",  "directions",
    "food",       "foods",
    "movie",      "movies",
    "time",       "times",
    "person",     "people",
    "resource",   "resources",
    "product",    "products",
    "month",      "months",
    "date",       "dates",
    "number",     "numbers",
    "tool",       "tools",
    "occupation", "occupations"]

#     category = foldl(+, zeros(300), map(word, categoryNames))
end

function *(x :: WordVector, y :: WordVector)
    reshape([a * b  for (a,b) in zip(x, y)], 300, 1)
end

catWeights = 3*(-1/60)*(word("dancing")*2 - word("recreation") + word("red")*2-word("color")+word("sparrow")*2-word("bird")+word("Mars")*2-word("planet")+word("couch")*2-word("furniture")+word("square")*2-word("shape")+word("iron")*2-word("metal")+word("ant")*2 - word("insect") + word("walking")*2-word("action")+word("Peru")*2-word("country")+word("banana")*2-word("fruit")+word("house")*2-word("building")+word("plumber")*2-word("occupation")+word("celery")*2-word("vegetable")+word("two")*2 - word("number") + word("blue")*2-word("color")+word("eagle")*2-word("bird")+word("Venus")*2-word("planet")+word("table")*2-word("furniture")+word("triangle")*2-word("shape")+word("silver")*2-word("metal")+word("hammer")*2-word("tool")+word("pine")*2-word("tree")+word("water")*2-word("liquid")+word("student")*2-word("person")+word("Islam")*2-word("religion")+word("baseball")*2-word("sport")+word("wood")*2-word("material")+word("Asian")*2-word("race")+word("pizza")*2-word("food")+word("dog")*2 - word("mammal") + word("sadness")*2-word("emotion")+word("cancer")*2-word("disease")+word("murder")*2-word("crime")+word("weight")*2-word("measurement")+word("fridge")*2-word("appliance")+word("sweet")*2-word("flavor")+word("skull")*2 - word("bone") + word("arm")*2-word("limb")+word("Paris")*2-word("city")+word("village")*2-word("place")+word("building")*2-word("structure")+word("oxygen")*2-word("gas")+word("electricity")*2-word("energy")+word("piano")*2 - word("instrument") + word("English")*2-word("language")+word("boat")*2-word("vehicle")+word("sight")*2-word("sense")+word("birthday")*2-word("event")+word("jogging")*2-word("exercise")+word("bucket")*2-word("container")+word("doll")*2-word("toy")+word("cement")*2-word("material")+word("carbon")*2-word("element")+word("girl")*2-word("female")+word("steak")*2-word("meat")+word("hamster")*2-word("pet")+word("gun")*2-word("weapon")+word("chess")*2-word("game")+word("bible")*2-word("book"))
findTopIndexed(catWeights + (word("chicken"))*1.5 - word("food"))[1:3000]
findTopIndexed("chicken")
filter(x -> lowercase(x[2][1]) == "animal", findTopIndexed("chicken"))
findTopIndexed("cheetah")
# findTop("elephant")

t = (
    (word("hippo")    + word("tiger")    + word("lizard"))/3        - word("animal") +
    (word("baseball") + word("football") + word("swimming"))/3      - word("sport") +
    (word("bucket")   + word("bag")      + word("tupperware"))/3    - word("container") +
    (word("piano")    + word("flute")    + word("guitar"))/3        - word("instrument") +
    (word("iron")     + word("silver")   + word("gold"))/3          - word("metal") +
    (word("Mars")     + word("Earth")    + word("Neptune"))/3       - word("planet") +
    (word("couch")    + word("chair")    + word("table"))/3         - word("furniture") )/7

findTopIndexed(t + word("cow") + word("gorilla") + word("dog"))

findTopIndexed(word("jump"))

hotness = word("hot")+word("warm")+word("burn")+word("heat")+word("fire")+word("radiation")+word("summer")+word("boiling")+word("day")
coldness = word("cold")+word("frozen")+word("freeze")+word("froze")+word("ice")+word("solid")+word("winter")+word("night")+word("chilly")+word("polar")+word("frigid")+word("blizzard")

categories = transpose([transpose(hotness-coldness), transpose(coldness-hotness)])

function categorize(v::WordVector, categories)
     pairwise(Euclidean(), categories, v)
end
function categorize(w::String, categories)
    categorize(vectorForWord(w), categories)
end

categorize("hot", categories)
