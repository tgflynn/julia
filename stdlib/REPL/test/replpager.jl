using Test
using REPL
using Random
import REPL.LineEdit
using Markdown

const BASE_TEST_PATH = joinpath(Sys.BINDIR, "..", "share", "julia", "test")
isdefined(Main, :FakePTYs) || @eval Main include(joinpath($(BASE_TEST_PATH), "testhelpers", "FakePTYs.jl"))
import .Main.FakePTYs: with_fake_pty, open_fake_pty

julia_exepath() = joinpath(Sys.BINDIR, Base.julia_exename())

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

@testset "pager functionality: interactive tests" begin
    # open(`./julia`, read=true, write=true) do io
    #     println(io, "isa(stdout, Base.TTY)")
    #     response = readline(io)
    #     println("response = ", response)
    # end


    pty_slave, pty_master = open_fake_pty()
    jpath = julia_exepath()
    run(pipeline(`$jpath`, stdin=pty_slave, stdout=pty_slave, stderr=pty_slave))
    output_copy = Base.BufferStream()
    tee = @async try
        while !eof(pty_master)
            l = readavailable(pty_master)
            write(debug_output, l)
            Sys.iswindows() && (sleep(0.1); yield(); yield()) # workaround hang - probably a libuv issue?
            write(output_copy, l)
        end
        close(output_copy)
        close(pty_master)
    catch ex
        close(output_copy)
        close(pty_master)
        if !(ex isa Base.IOError && ex.code == Base.UV_EIO)
            rethrow() # ignore EIO on pty_master after pty_slave dies
        end
    end
    # wait for the definitive prompt before start writing to the TTY
    readuntil(output_copy, "julia>")
    sleep(0.1)
    readavailable(output_copy)
    println(pty_master, "isa(stdout, Base.TTY)")
    response = readline(output_copy)
    println("response = ", response)
end
