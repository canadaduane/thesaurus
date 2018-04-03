using Base.Test
using Crayons.Box

include("../WordMatrix.jl")

successful = 0
failed = 0

function lineIndent(level=2)
  function(line)
    (" " ^ level) * line
  end
end

function indent(paragraph, level=2)
  join(map(lineIndent(level), split(paragraph, "\n")), "\n")
end

function failWithBacktrace(r::Test.Failure)
  io = IOBuffer()
  Base.show_backtrace(io, backtrace()[5:end])
  seekstart(io)
  println("  ", RED_FG("fail"), " $(r.expr) $(indent(readall(io), 3))")
end

function printTestTotals()
  if failed == 0
    println("success: $(GREEN_FG(string(successful))), failed: $(failed)")
  else
    failedString = RED_FG("failed: $(failed)")
    println("success: $(successful), $(failedString)")
  end
end

function fixture(path::String)
  joinpath(dirname(@__FILE__), "fixtures", path)
end

custom_handler(r::Test.Success) = (global successful; successful += 1; println("  ", GREEN_FG("ok"), " $(r.expr)"))
custom_handler(r::Test.Failure) = (global failed; failed += 1; failWithBacktrace(r))
custom_handler(r::Test.Error)   = rethrow(r)
