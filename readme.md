# GloVe Thesaurus

This is a Julia web app that uses the [GloVe](http://nlp.stanford.edu/projects/glove/) word vector data to look up similarities among word meanings.

# Installation

- Download the CommonCrawl 300-dimension data set: [Common Crawl (840B tokens): 300d](http://www-nlp.stanford.edu/data/glove.840B.300d.txt.gz)
- Separate it into a .vec and a .idx file:

```bash
wget http://www-nlp.stanford.edu/data/glove.840B.300d.txt.gz

gunzip -c glove.840B.300d.txt.gz \
| awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' >crawl300-100k.vec

gunzip -c glove.840B.300d.txt.gz \
| awk '{print $1}' >crawl300-100k.idx
```

The .vec file is the large file--it contains only floating point values, one row per word, with 300 dimensions per row. The .idx file is simply an index of all of the words, each word listed per line, in the same order as the .vec file.

You'll probably need these dependencies:

```bash
julia -e 'Pkg.add("Distances")'
julia -e 'Pkg.add("Morsel")'
```


# Running

```julia
$ julia 

               _
   _       _ _(_)_     |  A fresh approach to technical computing
  (_)     | (_) (_)    |  Documentation: http://docs.julialang.org
   _ _   _| |_  __ _   |  Type "help()" for help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 0.3.3 (2014-11-23 20:19 UTC)
 _/ |\__'_|_|_|\__'_|  |  'Official http://julialang.org/ release'
|__/                   |  x86_64-apple-darwin13.3.0

julia> include("WordMatrix.jl")

julia> m = WordMatrix("/path/to/crawl300-100k")
```

Note that the file path has no suffix--the ".idx" and ".vec" are added automatically.

# Example

```julia
julia> topn(m, m["laser"] + m["science"], 12)
12-element Array{(String,Float64),1}:
 ("laser",6.939878264355364)     
 ("science",7.804343256488264)   
 ("lasers",8.240093239632245)    
 ("scientific",8.946992980586012)
 ("physics",9.008729968872023)   
 ("technology",9.193295956585269)
 ("sciences",9.426696189473054)  
 ("astronomy",9.54593972112149)  
 ("imaging",9.547669144832966)   
 ("research",9.627897577880903)  
 ("optics",9.651007849517955)    
 ("Laser",9.724459820355438)     
```
