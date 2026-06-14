# test/test_benchmark.jl
# Chay: julia --project test/test_benchmark.jl
# Ket qua in ra man hinh + ghi vao:
#   results/benchmark_minsup.csv     
#   results/benchmark_scalability.csv 

include(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))
using .FPGrowthStar
using Printf

const RESULT_DIR = joinpath(@__DIR__, "..", "results")


# (dataset, n_trans, minsup_pct, minsup_abs, n_itemsets, time_ms, alloc_mb)
const MINSUP_ROWS = NamedTuple[]
# (dataset, frac_pct, sub_n, minsup_abs, n_itemsets, time_ms)
const SCAL_ROWS   = NamedTuple[]

function run_timed(f::Function)
    GC.gc()
    t = @timed f()
    return t.value, t.time * 1000, t.bytes / 1024 / 1024
end


function benchmark(name::String, filepath::String,
                   minsup_levels::Vector{Float64})
    if !isfile(filepath)
        println("\n[SKIP] $name - file khong ton tai: $filepath")
        return
    end

    transactions = read_spmf(filepath)
    n = length(transactions)

    println("\n" * "=" ^ 60)
    @printf("  Dataset: %-20s  #Trans: %d\n", name, n)
    println("=" ^ 60)
    @printf("  %-9s | %-9s | %-12s %-10s\n", "minsup%", "#sets", "time(ms)", "alloc(MB)")
    println("  " * "-" ^ 48)

    for ms_rel in minsup_levels
        ms_abs = ceil(Int, ms_rel * n)
        res, t_ms, m_mb = run_timed(() -> fpgrowth_star(transactions, ms_abs))
        @printf("  %-9.4f | %-9d | %-12.1f %-10.2f\n", ms_rel, length(res), t_ms, m_mb)
        push!(MINSUP_ROWS, (dataset=name, n_trans=n, minsup_pct=ms_rel,
            minsup_abs=ms_abs, n_itemsets=length(res),
            time_ms=round(t_ms, digits=2), alloc_mb=round(m_mb, digits=3)))
    end
end
# Scalability: do thoi gian theo % kich thuoc CSDL
function scalability_test(name::String, filepath::String, minsup_rel::Float64)
    if !isfile(filepath)
        println("\n[SKIP] Scalability $name - file khong ton tai")
        return
    end

    all_trans = read_spmf(filepath)
    n = length(all_trans)

    println("\n" * "=" ^ 50)
    @printf("  Scalability: %-15s (minsup=%.1f%%)\n", name, minsup_rel * 100)
    println("=" ^ 50)
    @printf("  %-10s %-12s %-14s\n", "subset%", "#sets", "time(ms)")
    println("  " * "-" ^ 38)

    for frac in [0.10, 0.25, 0.50, 0.75, 1.00]
        sub_n  = ceil(Int, frac * n)
        sub    = all_trans[1:sub_n]
        ms_abs = ceil(Int, minsup_rel * sub_n)
        res, t_ms, _ = run_timed(() -> fpgrowth_star(sub, ms_abs))
        @printf("  %-10.0f %-12d %-14.1f\n", frac * 100, length(res), t_ms)
        push!(SCAL_ROWS, (dataset=name, frac_pct=frac * 100, sub_n=sub_n,
            minsup_abs=ms_abs, n_itemsets=length(res), time_ms=round(t_ms, digits=2)))
    end
end
# Ghi danh sach NamedTuple ra CSV
function write_csv(path::String, rows::Vector{NamedTuple})
    isempty(rows) && return
    open(path, "w") do io
        println(io, join(string.(keys(rows[1])), ","))
        for r in rows
            println(io, join(string.(values(r)), ","))
        end
    end
    println("  -> Da ghi $(length(rows)) dong: $path")
end

bench_dir = joinpath(@__DIR__, "..", "data", "benchmark")

benchmark("Chess",
    joinpath(bench_dir, "chess.txt"),
    [0.90, 0.80, 0.70, 0.60, 0.50, 0.40, 0.30])

benchmark("Mushroom",
    joinpath(bench_dir, "mushroom.txt"),
    [0.50, 0.30, 0.20, 0.10, 0.05, 0.02])

benchmark("Retail",
    joinpath(bench_dir, "retail.txt"),
    [0.10, 0.05, 0.02, 0.01, 0.005, 0.001])

benchmark("Accidents",
    joinpath(bench_dir, "accidents.txt"),
    [0.90, 0.80, 0.70, 0.60, 0.50])

benchmark("T10I4D100K",
    joinpath(bench_dir, "T10I4D100K.txt"),
    [0.05, 0.02, 0.01, 0.005, 0.002])

scalability_test("Retail",   joinpath(bench_dir, "retail.txt"),   0.01)
scalability_test("Mushroom", joinpath(bench_dir, "mushroom.txt"), 0.10)

# --- Xuat CSV ---
println("\n" * "=" ^ 60)
isdir(RESULT_DIR) || mkdir(RESULT_DIR)
write_csv(joinpath(RESULT_DIR, "benchmark_minsup.csv"), MINSUP_ROWS)
write_csv(joinpath(RESULT_DIR, "benchmark_scalability.csv"), SCAL_ROWS)
println("\nBenchmark hoan tat.")
