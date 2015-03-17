using Distances
using GZip

type WordMatrix
    relationships::Array{Float64}
    words::Array{String}
end

type WordNotFound <: Exception
    word :: String
end
Base.showerror(io::IO, e::WordNotFound) = print(io, "WordNotFound() '", e.word, "'");

function isGzipFilename(path::String)
    return ismatch(r"\.gz$"i, path)
end

function getWordAndValuesFromLine(line)
    word, remainder = split(chomp(line), ' ', 2)
    values = split(remainder, ' ')
    return (word, map(float, values))
end

function loadGzipFile(path::String)
    stream = GZip.gzopen(path)
    relationships = Float64[]
    words = String[]
    rows = 0
    cols = 0
    for line in eachline(stream)
        try
            word, values = getWordAndValuesFromLine(line)
            if length(values) > rows
                rows = length(values)
            end
            push!(words, word)
            append!(relationships, values)
            cols += 1
        catch e
            println("Unable to load line ", line)
        end
    end
    return (reshape(relationships, rows, cols), words)
end

function isIdxFilename(path::String)
    return ismatch(r"\.idx$"i, path)
end

function loadVecIdxFile(idxPath::String)
    vecPath = replace(idxPath, r"\.idx$"i, ".vec")
    relationships = transpose(readdlm(vecPath, ' ', Float64, quotes=false, comments=false))
    words = [chomp(l) for l in readlines(open(idxPath))]
    return (relationships, words)
end

function WordMatrix(corpusPath::String)
    if isfile(corpusPath)
        if isIdxFilename(corpusPath)
            relationships, words = loadVecIdxFile(corpusPath)
        elseif isGzipFilename(corpusPath)
            relationships, words = loadGzipFile(corpusPath)
        else
            error("Unknown file format or suffix: $(corpusPath). I can read .gz and .idx (text).")
        end
        WordMatrix(relationships, words)
    else
        error("Corpus not found: $(corpusPath)")
    end
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

function topnPaginated(m :: WordMatrix, wordOrVector, page=1, perPage=30)
    startOfPage = perPage * (page - 1) + 1
    endOfPage = startOfPage + perPage - 1
    # println("startOfPage ", startOfPage, ", endOfPage ", endOfPage)
    if endOfPage > length(m.words)
        endOfPage = length(m.words)
    end
    if startOfPage >= 1 && endOfPage <= length(m.words)
        ranked = nearest(m, wordOrVector)
        numbers = range(startOfPage, endOfPage-startOfPage+1)
        zipped = zip(numbers, ranked[startOfPage:endOfPage])
        [
            { "rank" => n, "word" => word, "distance" => dist}
            for (n, (word, dist)) in zipped
        ]
    else
        []
    end 
end

function topIndexed(m :: WordMatrix, wordOrVector, n=30)
    top = topn(m, wordOrVector, n)
    [(i, r) for (i,r) in zip(1:length(top), top)]
end

function categorize(m :: WordMatrix, v)
     pairwise(Euclidean(), m.relationships, v)
end

function vectorSumOfWords(m :: WordMatrix, words :: Vector{ASCIIString})
    lookup = t -> m[t]
    mapreduce(lookup, +, words)
end

function vectorAvgOfWords(m :: WordMatrix, words :: Vector{ASCIIString})
    lookup = t -> m[t]
    mapreduce(lookup, +, words) / length(words)
end
