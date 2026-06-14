include(joinpath(@__DIR__, "..", "src", "FPGrowthStar.jl"))
using .FPGrowthStar
using Test
#Brute-force để so sánh kết quả
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

normalize(res::Vector{Tuple{Vector{Int},Int}}) =
    Set((sort(is), s) for (is, s) in res)

# Mỗi case: (tên, transactions, minsup)
const CASES = [
    ("Ví dụ 1 cơ sở",            [[1,2,3],[1,2,4],[1,3,4],[2,3,4],[1,2,3,4],[1,3],[2,4]], 3),
    ("Ví dụ 2 nhánh đơn",        [[1,2,3,4,5],[1,2,3,4],[1,2,3],[1,2],[1]],                1),
    ("Han et al. 2000",          [[1,2,3,5,6],[1,2,3,4,5],[1,4],[2,4,6],[1,2,3,5,6]],      3),
    ("Giao dịch giống nhau",     [[1,2,3],[1,2,3],[1,2,3]],                                2),
    ("Không có 2-itemset",       [[1,2],[3,4],[5,6]],                                      2),
    ("Một giao dịch",            [[1,2,3,4,5]],                                            1),
    ("Item ID không liên tục",   [[10,20,30],[10,20],[10,30],[20,30]],                     2),
]

@testset "FP-Growth* correctness" begin
    @testset "$name (minsup=$minsup)" for (name, trans, minsup) in CASES
        expected = normalize(brute_force_fim(trans, minsup))
        @test normalize(fpgrowth_star(trans, minsup)) == expected
    end

    @testset "minsup quá cao -> rỗng" begin
        t = [[1,2],[1,3],[2,3]]
        @test isempty(fpgrowth_star(t, 10))
    end

    @testset "minsup tương đối (Float64)" begin
        # 0.5 * 4 giao dịch = 2 (tuyệt đối) -> phải trùng kết quả minsup=2
        t = [[1,2,3],[1,2],[1,3],[2,3]]
        @test normalize(fpgrowth_star(t, 0.5)) == normalize(fpgrowth_star(t, 2))
    end

    @testset "Đọc & khai phá từ file SPMF" begin
        f1 = joinpath(@__DIR__, "..", "data", "toy", "example1.txt")
        if isfile(f1)
            tf = read_spmf(f1)
            @test normalize(fpgrowth_star(tf, 3)) == normalize(brute_force_fim(tf, 3))
        else
            @test_skip isfile(f1)
        end
    end
end
