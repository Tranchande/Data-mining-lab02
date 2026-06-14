# src/utils.jl
# Các hàm tiện ích: đọc/ghi file SPMF, in cây, đo thời gian
# (Cấu trúc dữ liệu được định nghĩa trong structures.jl, nạp sẵn bởi module FPGrowthStar)

# ------------------------------------------------------------------
# Đọc file định dạng SPMF (.txt): mỗi dòng là một giao dịch,
# các item là số nguyên dương cách nhau bởi khoảng trắng.
# Dòng trống và dòng bắt đầu bằng '#' bị bỏ qua.
# ------------------------------------------------------------------
function read_spmf(filepath::String)::Vector{Vector{Int}}
    transactions = Vector{Vector{Int}}()
    open(filepath, "r") do f
        for line in eachline(f)
            line = strip(line)
            (isempty(line) || startswith(line, "#")) && continue
            items = [parse(Int, x) for x in split(line) if !isempty(x)]
            isempty(items) || push!(transactions, items)
        end
    end
    return transactions
end

# ------------------------------------------------------------------
# Ghi kết quả ra IO stream theo định dạng SPMF:
#   <item1> <item2> ... #SUP: <support>
# ------------------------------------------------------------------
function write_results(io::IO, results::Vector{Tuple{Vector{Int},Int}})
    sorted = sort(results, by = x -> (length(x[1]), x[1]))
    for (itemset, sup) in sorted
        println(io, join(sort(itemset), " ") * " #SUP: $sup")
    end
end

write_results(filepath::String, results::Vector{Tuple{Vector{Int},Int}}) =
    open(f -> write_results(f, results), filepath, "w")

# ------------------------------------------------------------------
# In FP-tree ra console (dùng để debug / báo cáo)
# ------------------------------------------------------------------
function print_tree(node::FPNode, depth::Int = 0)
    prefix = "  "^depth
    label = node.item == 0 ? "root" : "item=$(node.item) count=$(node.count)"
    println(prefix * label)
    for child in sort(collect(values(node.children)), by = n -> n.item)
        print_tree(child, depth + 1)
    end
end

# ------------------------------------------------------------------
# Tính % khớp giữa hai tập kết quả (dùng trong unit test)
# ------------------------------------------------------------------
function match_ratio(expected::Vector{Tuple{Vector{Int},Int}},
                     actual::Vector{Tuple{Vector{Int},Int}})::Float64
    norm(res) = Set((sort(is), s) for (is, s) in res)
    e = norm(expected)
    a = norm(actual)
    isempty(e) && return isempty(a) ? 1.0 : 0.0
    return length(intersect(e, a)) / length(e)
end
