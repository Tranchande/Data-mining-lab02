# test/test_correctness.jl
# Chay: julia --project test/test_correctness.jl
# (Bo unit test khong phu thuoc SPMF: test/runtests.jl - doi chieu brute-force.
#  Ban in PASS/FAIL de doc: test/test_correctness_image.jl.)

include(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))
using .FPGrowthStar
include(joinpath(@__DIR__, "spmf.jl"))
using Printf

norm(r) = Set((sort(is), s) for (is, s) in r)

# So sanh 1 truong hop: tra ve (n_mine, n_spmf, n_khop, thieu, thua)
function compare(transactions::Vector{Vector{Int}}, minsup_abs::Int)
    mine = norm(fpgrowth_star(transactions, minsup_abs))
    spmf = spmf_fim(transactions, minsup_abs)
    khop  = length(intersect(mine, spmf))
    thieu = length(setdiff(spmf, mine))   # SPMF co, minh thieu
    thua  = length(setdiff(mine, spmf))   # minh co, SPMF khong
    return length(mine), length(spmf), khop, thieu, thua
end

function report(label::String, transactions::Vector{Vector{Int}}, minsup_abs::Int)
    nm, ns, kh, thieu, thua = compare(transactions, minsup_abs)
    ratio = ns == 0 ? (nm == 0 ? 100.0 : 0.0) : 100kh / ns
    status = (thieu == 0 && thua == 0) ? "OK  " : "LECH"
    @printf("  %-26s k=%-7d | mine=%-9d spmf=%-9d khop=%-9d | %6.2f%% %s",
            label, minsup_abs, nm, ns, kh, ratio, status)
    (thieu > 0 || thua > 0) && @printf("  (thieu=%d thua=%d)", thieu, thua)
    println()
    return thieu == 0 && thua == 0
end

println("=" ^ 80)
println("  MUC 4(a): DOI CHIEU FP-Growth* vs SPMF")
println("  Java: ", JAVA_BIN)
println("=" ^ 80)

ok_all = true

# ---- 1) Cac CSDL nho (gom ca CSDL vi du tay Chuong 2) ----
println("\n[1] CSDL nho / vi du tay:")
small = [
    ("Vi du 1 co ban",        [[1,2,3],[1,2,4],[1,3,4],[2,3,4],[1,2,3,4],[1,3],[2,4]], 3),
    ("Han et al. 2000",       [[1,2,3,5,6],[1,2,3,4,5],[1,4],[2,4,6],[1,2,3,5,6]],      3),
    ("Nhanh don (single)",    [[1,2,3,4,5],[1,2,3,4],[1,2,3],[1,2],[1]],                1),
    ("Giao dich giong nhau",  [[1,2,3],[1,2,3],[1,2,3]],                                2),
    ("Item ID khong lien tuc",[[10,20,30],[10,20],[10,30],[20,30]],                     2),
]
for (name, t, k) in small
    global ok_all &= report(name, Vector{Vector{Int}}(t), k)
end

# ---- 2) Cac file toy ----
println("\n[2] File toy (data/toy):")
for fn in ["example1.txt", "example2.txt", "example3.txt"]
    path = joinpath(@__DIR__, "..", "data", "toy", fn)
    isfile(path) || (println("  SKIP $fn"); continue)
    t = read_spmf(path)
    global ok_all &= report(fn, t, max(1, ceil(Int, 0.4 * length(t))))
end

# ---- 3) Benchmark that o minsup cao (chay nhanh) ----

println("\n[3] Benchmark (doi chieu o minsup cao):")
bench = [
    ("chess.txt",       0.80),
    ("mushroom.txt",    0.30),
    ("retail.txt",      0.01),
    ("accidents.txt",   0.80),
    ("T10I4D100K.txt",  0.02),
]
bdir = joinpath(@__DIR__, "..", "data", "benchmark")
for (fn, rel) in bench
    path = joinpath(bdir, fn)
    isfile(path) || (println("  SKIP $fn (chua co file)"); continue)
    t = read_spmf(path)
    k = ceil(Int, rel * length(t))
    global ok_all &= report("$fn ($(round(Int,rel*100))%)", t, k)
end

println("\n" * "=" ^ 80)
println(ok_all ? "  KET QUA: 100% KHOP SPMF tren moi CSDL." :
                 "  CO TRUONG HOP LECH — xem dong 'LECH' o tren.")
println("=" ^ 80)
ok_all || exit(1)
