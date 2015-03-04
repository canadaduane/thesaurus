include("./helper.jl")

Test.with_handler(custom_handler) do
  @test !isGzipFilename("top10.idx")
  @test isGzipFilename("top10.txt.gz")

  @test !isIdxFilename("top10.txt")
  @test isIdxFilename("top10.idx")

  gzipVecs, gzipWords = loadGzipFile(fixture("top10.txt.gz"))
  @test gzipVecs[1][1] == 0.418
  @test gzipWords == ["the",",",".","of","to","and","in","a","\"","'s"]

  idxVecs, idxWords = loadVecIdxFile(fixture("top10.idx"))
  @test idxVecs[1][1] == 0.418
  @test idxWords == ["the",",",".","of","to","and","in","a","\"","'s"]

end

printTestTotals()