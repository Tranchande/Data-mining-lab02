# test/test_correctness_image.jl
# Bản in kết quả PASS/FAIL dễ đọc (dùng để chụp màn hình minh họa cho báo cáo),
# đối chiếu FP-Growth* với brute-force trên các CSDL nhỏ.
# Kiểm thử "chính thức" (không phụ thuộc SPMF) dùng test/runtests.jl với macro @test.
# Đối chiếu với SPMF (mục 3.4.2a) dùng test/test_correctness.jl.
#
# Chạy: julia --project test/test_correctness_image.jl

include(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))
using .FPGrowthStar

# ------------------------------------------------------------------
# Brute-force FIM: liệt kê mọi tập con và đếm support (ground truth)
# Chỉ dùng được với |items| <= 20
# ------------------------------------------------------------------
function brute_force_fim(transactions::Vector{Vector{Int}},
                          minsup::Int)::Vector{Tuple{Vector{Int},Int}}
    all_items = sort(unique(vcat(transactions...)))
    n_items   = length(all_items)
    result    = Tuple{Vector{Int},Int}[]

    for mask in 1:((1 << n_items) - 1)
        itemset = [all_items[i] for i in 1:n_items if (mask >> (i - 1)) & 1 == 1]
        support = count(t -> all(x -> x in t, itemset), transactions)
        support >= minsup && push!(result, (itemset, support))
    end
    return result
end

function normalize(res::Vector{Tuple{Vector{Int},Int}})
    return Set((sort(is), s) for (is, s) in res)
end

function run_test(name::String,
                  transactions::Vector{Vector{Int}},
                  minsup::Int)::Bool
    expected = normalize(brute_force_fim(transactions, minsup))
    actual   = normalize(fpgrowth_star(transactions, minsup))
    miss     = setdiff(expected, actual)
    extra    = setdiff(actual, expected)
    if isempty(miss) && isempty(extra)
        println("  PASS  $name  ($(length(expected)) itemsets)")
        return true
    else
        print("  FAIL  $name")
        !isempty(miss)  && print(" thieu=$(length(miss))")
        !isempty(extra) && print(" thua=$(length(extra))")
        println()
        return false
    end
end

# ==================================================================
println("=" ^ 55)
println("  Kiem tra tinh dung dan: FP-Growth*")
println("=" ^ 55)

pass = 0; total = 0

# Test 1: Vi du co ban (Chapter 2.1)
total += 1
t1 = [[1,2,3],[1,2,4],[1,3,4],[2,3,4],[1,2,3,4],[1,3],[2,4]]
pass += run_test("Vi du 1 co ban (minsup=3)", t1, 3) ? 1 : 0

# Test 2: Nhanh don (Chapter 2.2) - 2^5-1 = 31 itemsets
total += 1
t2  = [[1,2,3,4,5],[1,2,3,4],[1,2,3],[1,2],[1]]
bf2 = normalize(brute_force_fim(t2, 1))
r2s = normalize(fpgrowth_star(t2, 1))
ok2 = r2s == bf2
println("  $(ok2 ? "PASS" : "FAIL")  Vi du 2 nhanh don (expect 31, got $(length(r2s)))")
pass += ok2 ? 1 : 0

# Test 3: Classic FP-Growth (Han et al. 2000)
total += 1
t3 = [[1,2,3,5,6],[1,2,3,4,5],[1,4],[2,4,6],[1,2,3,5,6]]
pass += run_test("Han et al. 2000 (minsup=3)", t3, 3) ? 1 : 0

# Test 4: Giao dich giong nhau
total += 1
t4 = [[1,2,3],[1,2,3],[1,2,3]]
pass += run_test("Giao dich giong nhau (minsup=2)", t4, 2) ? 1 : 0

# Test 5: Khong co 2-itemset pho bien
total += 1
t5 = [[1,2],[3,4],[5,6]]
pass += run_test("Khong co 2-itemset pho bien (minsup=2)", t5, 2) ? 1 : 0

# Test 6: Chi mot giao dich
total += 1
t6 = [[1,2,3,4,5]]
pass += run_test("1 giao dich (minsup=1)", t6, 1) ? 1 : 0

# Test 7: minsup cao -> rong
total += 1
t7   = [[1,2],[1,3],[2,3]]
ok7  = isempty(fpgrowth_star(t7, 10))
println("  $(ok7 ? "PASS" : "FAIL")  minsup qua cao -> rong")
pass += ok7 ? 1 : 0

# Test 8: Doc tu file example1.txt
total += 1
file1 = joinpath(@__DIR__, "..", "data", "toy", "example1.txt")
if isfile(file1)
    tf = read_spmf(file1)
    pass += run_test("File example1.txt (minsup=3)", tf, 3) ? 1 : 0
else
    println("  SKIP  File example1.txt khong tim thay")
end

# Test 9: Doc tu file example2.txt
total += 1
file2 = joinpath(@__DIR__, "..", "data", "toy", "example2.txt")
if isfile(file2)
    tf2  = read_spmf(file2)
    r9s  = fpgrowth_star(tf2, 1)
    ok9  = length(r9s) == 31
    println("  $(ok9 ? "PASS" : "FAIL")  File example2.txt nhanh don (expect 31, got $(length(r9s)))")
    pass += ok9 ? 1 : 0
else
    println("  SKIP  File example2.txt khong tim thay")
end

# Test 10: Item ID khong lien tuc
total += 1
t10 = [[10,20,30],[10,20],[10,30],[20,30]]
pass += run_test("Item IDs khong lien tuc (minsup=2)", t10, 2) ? 1 : 0

println("=" ^ 55)
println("  Ket qua: $pass/$total PASS")
println("=" ^ 55)

pass == total || exit(1)
