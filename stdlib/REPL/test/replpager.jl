using Test
using REPL
using Random
import REPL.LineEdit
using Markdown

const BASE_TEST_PATH = joinpath(Sys.BINDIR, "..", "share", "julia", "test")
isdefined(Main, :FakePTYs) || @eval Main include(joinpath($(BASE_TEST_PATH), "testhelpers", "FakePTYs.jl"))
import .Main.FakePTYs: with_fake_pty

# For curmod_*
include(joinpath(BASE_TEST_PATH, "testenv.jl"))

include("FakeTerminals.jl")
import .FakeTerminals.FakeTerminal

# Test pager functionality

@testset "pager functionality: getdefaultpager" begin
    for val in [ "n", "no", "f", "false", "0" ]
        withenv("JULIA_PAGER" => val) do
            @test isnothing(REPL.getdefaultpager())
        end
        withenv("JULIA_PAGER" => uppercase(val)) do
            @test isnothing(REPL.getdefaultpager())
        end
    end

    sysdefaultpager = Sys.iswindows() ? "more" : "less"
    for val in [ "y", "yes", "t", "true", "1" ]
        withenv("JULIA_PAGER" => val) do
            @test basename(REPL.getdefaultpager()) == sysdefaultpager
        end
        withenv("JULIA_PAGER" => uppercase(val)) do
            @test basename(REPL.getdefaultpager()) == sysdefaultpager
        end
    end
end
