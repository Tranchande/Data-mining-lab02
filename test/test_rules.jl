# test/test_rules.jl
# Chay: julia --project test/test_rules.jl

include(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))
using .FPGrowthStar
using Printf

const MINSUP_REL = 0.001   # 0.1% so giao dich
const MINCONF    = 0.50
const TOP_N      = 15

file = joinpath(@__DIR__, "..", "data", "benchmark", "retail.txt")
if !isfile(file)
    println("[SKIP] Khong tim thay $file"); exit(0)
end

trans = read_spmf(file)
n = length(trans)
ms_abs = ceil(Int, MINSUP_REL * n)

println("=" ^ 78)
@printf("  MUC 5: Market Basket Analysis - Retail (%d giao dich)\n", n)
@printf("  minsup = %.3f%% (>= %d giao dich),  minconf = %.0f%%\n",
        MINSUP_REL * 100, ms_abs, MINCONF * 100)
println("=" ^ 78)

t_fim = @elapsed itemsets = fpgrowth_star(trans, ms_abs)
t_rul = @elapsed rules    = association_rules(itemsets, n; minconf = MINCONF)

@printf("  Frequent itemsets : %d  (%.1f ms)\n", length(itemsets), t_fim * 1000)
@printf("  Association rules : %d  (%.1f ms)\n", length(rules), t_rul * 1000)

println("\n  TOP $TOP_N luat theo LIFT:")
@printf("  %-22s %-10s %8s %8s %8s\n", "X (mua)", "=> Y (kem)", "sup", "conf", "lift")
println("  " * "-" ^ 64)
for r in first(rules, min(TOP_N, length(rules)))
    @printf("  %-22s => %-10s %8d %7.2f %8.2f\n",
            join(r.antecedent, ","), join(r.consequent, ","),
            r.support, r.confidence, r.lift)
end

# Xuat toan bo luat ra CSV (sap theo lift giam dan)
isdir(joinpath(@__DIR__, "..", "results")) || mkdir(joinpath(@__DIR__, "..", "results"))
out = joinpath(@__DIR__, "..", "results", "rules_retail.csv")
open(out, "w") do io
    println(io, "antecedent,consequent,support,confidence,lift")
    for r in rules
        @printf(io, "%s,%s,%d,%.4f,%.4f\n",
                join(r.antecedent, " "), join(r.consequent, " "),
                r.support, r.confidence, r.lift)
    end
end
println("\n  -> Da ghi $(length(rules)) luat: results/rules_retail.csv")
