# test/test_benchmark_spmf.jl
# MUC 3.4.2(b) + (d): So sanh FP-Growth* voi SPMF ve THOI GIAN va BO NHO.
# (d2: dung SPMF lam moc so sanh thay cho "ban co ban").
#
# Xuat:
#   results/compare_time.csv    (dataset, minsup_pct, n_itemsets, time_mine_ms, time_spmf_ms)
#   results/compare_memory.csv  (dataset, minsup_pct, n_itemsets, peak_mine_mb, peak_spmf_mb)
#
# - Thoi gian: cua minh do bang @elapsed (chi thuat toan); cua SPMF lay tu
#   thong ke SPMF tu in (cung chi thuat toan, khong tinh khoi dong JVM).
# - Bo nho: cua minh do peak RSS bang Sys.maxrss() trong tien trinh con rieng;
#   cua SPMF lay "Max memory usage" SPMF tu bao. Luu y: RSS cua Julia gom
#   ~150MB runtime nen so cua minh co nen cao hon doi chut.
#
# Chay: julia --project test/test_benchmark_spmf.jl
# Yeu cau: Java >= 21 + SPMF/spmf.jar.

include(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))
using .FPGrowthStar
include(joinpath(@__DIR__, "spmf.jl"))
using Printf

const RESULT_DIR = joinpath(@__DIR__, "..", "results")
const PROJECT    = abspath(joinpath(@__DIR__, ".."))
const MODULE_JL  = abspath(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))

const TIME_ROWS = NamedTuple[]
const MEM_ROWS  = NamedTuple[]

# Do peak RSS (MB) trong tien trinh Julia rieng (Sys.maxrss).
# do_mine=false: chi nap module + doc data (baseline) de tru phan runtime+DB.
function mine_peak_mb(file::String, ms_abs::Int; do_mine::Bool=true)::Float64
    work = do_mine ? "fpgrowth_star(t, $ms_abs)" : "t"
    code = """
    include(raw"$MODULE_JL"); using .FPGrowthStar
    t = read_spmf(raw"$file")
    $work
    println("PEAK_MB=", Sys.maxrss() / 1024 / 1024)
    """
    out = read(`$(Base.julia_cmd()) --project=$PROJECT -e $code`, String)
    m = match(r"PEAK_MB=([\d.]+)", out)
    return m === nothing ? NaN : parse(Float64, m.captures[1])
end

# So sanh THOI GIAN + dem itemset o nhieu muc minsup (muc b)
function compare_time(name::String, file::String, levels::Vector{Float64})
    isfile(file) || (println("\n[SKIP] $name (chua co $file)"); return)
    t = read_spmf(file); n = length(t)
    println("\n" * "=" ^ 64)
    @printf("  %s  (#Trans=%d)\n", name, n)
    println("=" ^ 64)
    @printf("  %-9s | %-9s | %-12s %-12s\n", "minsup%", "#sets", "mine(ms)", "spmf(ms)")
    println("  " * "-" ^ 50)
    out = tempname()
    for rel in levels
        ms_abs = ceil(Int, rel * n)
        GC.gc()
        t_mine = @elapsed res = fpgrowth_star(t, ms_abs)
        _, t_spmf, _, cnt = run_spmf(file, out, rel * 100)
        flag = cnt == length(res) ? "" : "  [!] lech: spmf=$cnt"
        @printf("  %-9.4f | %-9d | %-12.1f %-12.1f%s\n",
                rel, length(res), t_mine * 1000, t_spmf, flag)
        push!(TIME_ROWS, (dataset=name, minsup_pct=rel, n_itemsets=length(res),
            time_mine_ms=round(t_mine * 1000, digits=2), time_spmf_ms=round(t_spmf, digits=2)))
    end
    rm(out; force=true)
end

# So sanh BO NHO o 1 muc minsup trung binh (muc d)
#   peak_mine = RSS dinh khi mining (gom ~150MB runtime Julia + DB)
#   base_mine = RSS dinh khi chi nap module + doc DB (chua mining)
#   net_mine  = peak - base  (phan bo nho rieng cho khai pha)
function compare_memory(name::String, file::String, rel::Float64)
    isfile(file) || return
    t = read_spmf(file); n = length(t)
    ms_abs = ceil(Int, rel * n)
    peak_mine = mine_peak_mb(file, ms_abs; do_mine=true)
    base_mine = mine_peak_mb(file, ms_abs; do_mine=false)
    net_mine  = max(0.0, peak_mine - base_mine)
    out = tempname()
    _, _, mem_spmf, cnt = run_spmf(file, out, rel * 100)
    rm(out; force=true)
    @printf("  %-14s minsup=%-7.4f #sets=%-8d | peak=%-7.1f base=%-7.1f net=%-7.1f | spmf=%-7.1f MB\n",
            name, rel, cnt, peak_mine, base_mine, net_mine, mem_spmf)
    push!(MEM_ROWS, (dataset=name, minsup_pct=rel, n_itemsets=cnt,
        peak_mine_mb=round(peak_mine, digits=1), base_mine_mb=round(base_mine, digits=1),
        net_mine_mb=round(net_mine, digits=1), peak_spmf_mb=round(mem_spmf, digits=1)))
end

function write_csv(path::String, rows::Vector{NamedTuple})
    isempty(rows) && return
    open(path, "w") do io
        println(io, join(string.(keys(rows[1])), ","))
        for r in rows; println(io, join(string.(values(r)), ",")); end
    end
    println("  -> ", length(rows), " dong: ", path)
end

# ==================================================================
bdir = joinpath(@__DIR__, "..", "data", "benchmark")
datasets = [
    ("Chess",      joinpath(bdir, "chess.txt"),      [0.90, 0.85, 0.80, 0.75, 0.70], 0.80),
    ("Mushroom",   joinpath(bdir, "mushroom.txt"),   [0.50, 0.40, 0.30, 0.20, 0.15], 0.30),
    ("Retail",     joinpath(bdir, "retail.txt"),     [0.10, 0.05, 0.02, 0.01, 0.005], 0.01),
    ("Accidents",  joinpath(bdir, "accidents.txt"),  [0.90, 0.80, 0.70, 0.60, 0.50], 0.70),
    ("T10I4D100K", joinpath(bdir, "T10I4D100K.txt"), [0.05, 0.02, 0.01, 0.005, 0.002], 0.01),
]

const ONLY_MEM = haskey(ENV, "ONLY_MEM")

if !ONLY_MEM
    println("MUC 4(b): SO SANH THOI GIAN  (Java: ", JAVA_BIN, ")")
    for (name, file, levels, _) in datasets
        compare_time(name, file, levels)
    end
end

println("\n" * "=" ^ 64)
println("MUC 4(d): SO SANH BO NHO (peak) o minsup trung binh")
println("=" ^ 64)
for (name, file, _, rel_mem) in datasets
    compare_memory(name, file, rel_mem)
end

println("\n" * "=" ^ 64)
isdir(RESULT_DIR) || mkdir(RESULT_DIR)
ONLY_MEM || write_csv(joinpath(RESULT_DIR, "compare_time.csv"), TIME_ROWS)
write_csv(joinpath(RESULT_DIR, "compare_memory.csv"), MEM_ROWS)
println("\nHoan tat so sanh voi SPMF.")
