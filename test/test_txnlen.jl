# test/test_txnlen.jl
# Xuat: results/txnlen.csv (avg_len, n_itemsets, time_ms)
# Chay: julia --project test/test_txnlen.jl

include(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))
using .FPGrowthStar
using Random, Printf

const RESULT_DIR = joinpath(@__DIR__, "..", "results")

# Tham so co dinh (de chi co do dai giao dich thay doi)
const N_TRANS    = 2000      # so giao dich
const N_ITEMS    = 20        # kich thuoc kho item (1..20)
const MINSUP_REL = 0.15      # nguong tuong doi
const LENGTHS    = [5, 7, 9, 11, 13, 15]   # do dai giao dich tang dan

# Sinh N_TRANS giao dich, moi giao dich gom 'len' item phan biet lay tu 1..N_ITEMS
function gen_db(len::Int, rng::AbstractRNG)::Vector{Vector{Int}}
    [sort(randperm(rng, N_ITEMS)[1:len]) for _ in 1:N_TRANS]
end

rows = NamedTuple[]
println("=" ^ 60)
@printf("  MUC 4(f): Anh huong do dai giao dich (n=%d, |I|=%d, minsup=%.0f%%)\n",
        N_TRANS, N_ITEMS, MINSUP_REL * 100)
println("=" ^ 60)
@printf("  %-10s %-12s %-12s\n", "avg_len", "#sets", "time(ms)")
println("  " * "-" ^ 34)

ms_abs = ceil(Int, MINSUP_REL * N_TRANS)
for len in LENGTHS
    rng = MersenneTwister(42)          # cung seed -> CSDL tai lap duoc
    db  = gen_db(len, rng)
    GC.gc()
    t = @elapsed res = fpgrowth_star(db, ms_abs)
    @printf("  %-10d %-12d %-12.1f\n", len, length(res), t * 1000)
    push!(rows, (avg_len=len, n_itemsets=length(res), time_ms=round(t * 1000, digits=2)))
end

isdir(RESULT_DIR) || mkdir(RESULT_DIR)
open(joinpath(RESULT_DIR, "txnlen.csv"), "w") do io
    println(io, "avg_len,n_itemsets,time_ms")
    for r in rows; println(io, join(values(r), ",")); end
end
println("\n  -> results/txnlen.csv")
