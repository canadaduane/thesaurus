using Distances

defaultWorkDir = "/Users/duane/Projects/thesaurus"

type WordMatrix
    relationships::Array{Float64}
    words::Array{String}
end

type WordNotFound <: Exception
    word :: String
end
Base.showerror(io::IO, e::WordNotFound) = print(io, "WordNotFound() '", e.word, "'");

function WordMatrix(corpusName::String, workDir = defaultWorkDir)
    relationships = transpose(readdlm("$(workDir)/$(corpusName).vec", ' ', Float64, quotes=false, comments=false))
    words = [chomp(l) for l in readlines(open("$(workDir)/$(corpusName).idx"))]
    WordMatrix(relationships, words)
end

function WordMatrix(m :: WordMatrix, subset :: Array{String})
    subsetIndices = findin(m.words, subset)
    subsetRels = [m.relationships[:,i] for i in subsetIndices]
    rows = size(m.relationships)[1]
    cols = length(subset)
    relationships = reshape(vcat(subsetRels...), rows, cols)
    WordMatrix(relationships, subset)
end
WordMatrix(m :: WordMatrix, subset :: Array{ASCIIString}) = WordMatrix(m, convert(Array{String}, subset))

function WordMatrix(d :: Dict{Any, Any})
    relationships = Vector{Float64}[]
    words = String[]
    for (k, v) in d
        push!(relationships, v)
        push!(words, k)
    end
    rows = length(first(relationships))
    cols = length(relationships)
    WordMatrix(reshape(vcat(relationships...), rows, cols), words)
end

function indexOfWord(m :: WordMatrix, word :: String)
  findin(m.words, [word])[1]
end

function getindex(m :: WordMatrix, idx :: Integer)
    (m.words[idx], m.relationships[:,idx])
end

function getindex(m :: WordMatrix, word :: String)
    try
        m.relationships[:,indexOfWord(m, word)]
    catch e
        throw(WordNotFound(word))
    end
end

function compare(m :: WordMatrix, v :: Vector{Float64})
    pairwise(Euclidean(), m.relationships, reshape(v, size(v)[1], 1))
end

function compare(m :: WordMatrix, word :: String)
    compare(m, m[word])
end

function nearest(m :: WordMatrix, wordOrVector)
    sort([(x,y) for (x,y) in zip(m.words, compare(m, wordOrVector))], by = x -> x[2])
end

function topn(m :: WordMatrix, wordOrVector, n=30)
  nearest(m, wordOrVector)[1:n]
end

function topIndexed(wordOrVector, n=30)
    top = topn(wordOrVector, n)
    [(i, r) for (i,r) in zip(1:length(top), top)]
end

function categorize(m :: WordMatrix, v)
     pairwise(Euclidean(), m.relationships, v)
end

function vectorSumOfWords(m :: WordMatrix, words :: Vector{ASCIIString})
    lookup = t -> m[t]
    mapreduce(lookup, +, words) / length(words)
end
