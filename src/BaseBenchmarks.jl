module BaseBenchmarks

using BenchmarkTools
using JLD
using Compat

BenchmarkTools.DEFAULT_PARAMETERS.time_tolerance = 0.10
BenchmarkTools.DEFAULT_PARAMETERS.memory_tolerance = 0.01

const PARAMS_PATH = joinpath(Pkg.dir("BaseBenchmarks"), "etc", "params.jld")
const SUITE = BenchmarkGroup()
const MODULES = Dict("array" => :ArrayBenchmarks,
                     "io" => :IOBenchmarks,
                     "linalg" => :LinAlgBenchmarks,
                     "micro" => :MicroBenchmarks,
                     "parallel" => :ParallelBenchmarks,
                     "problem" => :ProblemBenchmarks,
                     "scalar" => :ScalarBenchmarks,
                     "shootout" => :ShootoutBenchmarks,
                     "simd" => :SIMDBenchmarks,
                     "sort" => :SortBenchmarks,
                     "sparse" => :SparseBenchmarks,
                     "string" => :StringBenchmarks,
                     "tuple" => :TupleBenchmarks)

load!(id::AbstractString; kwargs...) = load!(SUITE, id, tune)

function load!(group::BenchmarkGroup, id::AbstractString; tune::Bool = true)
    modsym = MODULES[id]
    modpath = joinpath(Pkg.dir("BaseBenchmarks"), "src", id, "$(modsym).jl")
    eval(BaseBenchmarks, :(include($modpath)))
    modsuite = eval(BaseBenchmarks, modsym).SUITE
    group[id] = modsuite
    tune && loadparams!(modsuite, JLD.load(PARAMS_PATH, id))
    return group
end

loadall!(; kwargs...) = loadall!(SUITE; kwargs...)

function loadall!(group::BenchmarkGroup; verbose::Bool = true, tune::Bool = true)
    for id in keys(MODULES)
        verbose && print("loading group $(repr(id))..."); tic();
        load!(group, id; tune = false)
        verbose && println("done (took $(toq()) seconds)")
    end
    if tune
        jldopen(PARAMS_PATH, "r") do file
            for (id, suite) in group
                loadparams!(suite, read(file, id))
            end
        end
    end
    return group
end

end # module
