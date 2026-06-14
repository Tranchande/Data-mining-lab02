# src/algorithm/fpgrowth_star.jl
#
# Cài đặt thuật toán FP-Growth* (Grahne & Zhu, 2003)
# "Efficiently Using Prefix-trees in Mining Frequent Itemsets"
#
# Điểm khác biệt so với FP-Growth gốc:
#   - Kỹ thuật Array-based: dùng mảng đếm (count_arr) để xác định
#     các item phổ biến trong conditional pattern base CHỈ TRONG
#     MỘT LẦN DUYỆT, thay vì hai lần quét như FP-Growth gốc.
#   - Tối ưu Single-path: nếu cây điều kiện là một nhánh đơn,
#     liệt kê trực tiếp tất cả tập con mà không cần đệ quy thêm.
#
# Cấu trúc dữ liệu (FPNode/HeaderEntry/FPTree) được định nghĩa trong
# structures.jl, nạp sẵn bởi module FPGrowthStar.

# ------------------------------------------------------------------
# Nội bộ: thêm node vào cuối danh sách liên kết của header entry
# ------------------------------------------------------------------
function _link_node!(entry::HeaderEntry, node::FPNode)
    if entry.head === nothing
        entry.head = node
        entry.tail = node
    else
        entry.tail.node_link = node
        entry.tail = node
    end
end

# ------------------------------------------------------------------
# Nội bộ: chèn một giao dịch (đã sắp xếp) vào FP-tree với số lần
# xuất hiện = count (mặc định 1). Dùng chung cho cây gốc và cây
# điều kiện.
# ------------------------------------------------------------------
function _insert_transaction!(root::FPNode,
                               header::Dict{Int,HeaderEntry},
                               transaction::Vector{Int},
                               count::Int = 1)
    node = root
    for item in transaction
        if haskey(node.children, item)
            node.children[item].count += count
        else
            child = FPNode(item, count, node)
            node.children[item] = child
            _link_node!(header[item], child)
        end
        node = node.children[item]
    end
end

# ------------------------------------------------------------------
# Xây dựng FP-tree từ tập giao dịch và ngưỡng minsup.
# Trả về nothing nếu không có item nào phổ biến.
# ------------------------------------------------------------------
function build_fptree(transactions::Vector{Vector{Int}}, minsup::Int)::Union{FPTree,Nothing}
    # Lần 1: đếm tần số từng item
    item_count = Dict{Int,Int}()
    for trans in transactions
        for item in trans
            item_count[item] = get(item_count, item, 0) + 1
        end
    end

    frequent = Dict(k => v for (k, v) in item_count if v >= minsup)
    isempty(frequent) && return nothing

    # Sắp xếp: tần số giảm dần, tie-break theo item ID tăng dần (deterministic)
    ordered_items = sort(collect(keys(frequent)), by = i -> (-frequent[i], i))
    rank = Dict(item => idx for (idx, item) in enumerate(ordered_items))

    header = Dict{Int,HeaderEntry}(item => HeaderEntry(frequent[item]) for item in ordered_items)
    root   = FPNode(0, 0, nothing)

    # Lần 2: chèn từng giao dịch (lọc item không phổ biến, sắp xếp theo rank)
    for trans in transactions
        filtered = sort(filter(i -> haskey(frequent, i), trans), by = i -> rank[i])
        isempty(filtered) && continue
        _insert_transaction!(root, header, filtered)
    end

    return FPTree(root, header, ordered_items)
end

# ------------------------------------------------------------------
# Kiểm tra cây có phải nhánh đơn không (dừng sớm ở 61 để tránh
# tràn số nguyên khi liệt kê bitmask 2^n).
# ------------------------------------------------------------------
function _is_single_path(root::FPNode)::Bool
    node  = root
    depth = 0
    while !isempty(node.children)
        length(node.children) > 1 && return false
        node   = first(values(node.children))
        depth += 1
        depth > 60 && return false
    end
    return true
end

# Thu thập đường đi từ root → lá của nhánh đơn
function _collect_path(root::FPNode)::Vector{Tuple{Int,Int}}
    path = Tuple{Int,Int}[]
    node = root
    while !isempty(node.children)
        child = first(values(node.children))
        push!(path, (child.item, child.count))
        node = child
    end
    return path
end

# ------------------------------------------------------------------
# Liệt kê tất cả tập con khác rỗng của path, kết hợp với prefix.
# Support của mỗi tập con = min count của các node được chọn
# (vì trong nhánh đơn, count không tăng từ cha xuống con).
# ------------------------------------------------------------------
function _enumerate_path!(path::Vector{Tuple{Int,Int}},
                           prefix::Vector{Int},
                           result::Vector{Tuple{Vector{Int},Int}})
    n = length(path)
    for mask in 1:((1 << n) - 1)
        pattern = copy(prefix)
        support = typemax(Int)
        for i in 1:n
            if (mask >> (i - 1)) & 1 == 1
                push!(pattern, path[i][1])
                support = min(support, path[i][2])
            end
        end
        push!(result, (pattern, support))
    end
end

# ------------------------------------------------------------------
# Xây dựng cây điều kiện (conditional FP-tree) cho item α.
#
# Kỹ thuật Array-based của FP-Growth*:
#   count_arr đã được tính TRƯỚC (1 lần duyệt duy nhất), nên ở đây
#   chỉ cần 1 lần duyệt nữa để chèn các path vào cây — tổng cộng
#   2 lần duyệt thay vì 3 lần như FP-Growth gốc (2 lần đếm + 1 xây).
# ------------------------------------------------------------------
function _build_conditional_tree(entry::HeaderEntry,
                                  cond_items::Vector{Int},
                                  count_arr::Vector{Int})::Union{FPTree,Nothing}
    ordered = sort(cond_items, by = i -> (-count_arr[i], i))
    rank    = Dict(item => idx for (idx, item) in enumerate(ordered))
    header  = Dict{Int,HeaderEntry}(item => HeaderEntry(count_arr[item]) for item in ordered)
    root    = FPNode(0, 0, nothing)

    node = entry.head
    while node !== nothing
        path_count = node.count

        # Thu thập ancestor nằm trong cond_items (từ cha của α lên root)
        raw_path = Int[]
        anc = node.parent
        while anc.item != 0
            haskey(rank, anc.item) && push!(raw_path, anc.item)
            anc = anc.parent
        end

        if !isempty(raw_path)
            sort!(raw_path, by = i -> rank[i])  # sắp xếp theo freq desc
            _insert_transaction!(root, header, raw_path, path_count)
        end

        node = node.node_link
    end

    isempty(root.children) && return nothing
    return FPTree(root, header, ordered)
end

# ------------------------------------------------------------------
# Hàm đệ quy chính của FP-Growth*
#
# tree       : FP-tree hiện tại (gốc hoặc điều kiện)
# minsup     : ngưỡng support tuyệt đối
# prefix     : tập item đã chọn từ các bước trước
# result     : danh sách kết quả (itemset, support)
# max_item   : ID item lớn nhất toàn cục (để cấp phát count_arr)
# ------------------------------------------------------------------
function fpgrowth_star!(tree::FPTree,
                         minsup::Int,
                         prefix::Vector{Int},
                         result::Vector{Tuple{Vector{Int},Int}},
                         max_item::Int)
    isempty(tree.ordered_items) && return

    # === Tối ưu nhánh đơn ===
    if _is_single_path(tree.root)
        path = _collect_path(tree.root)
        isempty(path) && return
        _enumerate_path!(path, prefix, result)
        return
    end

    # === Duyệt theo thứ tự tần số tăng dần (từ cuối ordered_items) ===
    for i in length(tree.ordered_items):-1:1
        α     = tree.ordered_items[i]
        entry = tree.header[α]

        # Phát sinh pattern: prefix ∪ {α}
        new_prefix = vcat(prefix, [α])
        push!(result, (new_prefix, entry.support))

        # ----------------------------------------------------------
        # Kỹ thuật Array-based (điểm cốt lõi của FP-Growth*):
        # Duyệt danh sách liên kết của α MỘT LẦN DUY NHẤT để
        # đếm tần số tất cả ancestor vào count_arr (O(1) tra cứu).
        # ----------------------------------------------------------
        count_arr = zeros(Int, max_item)
        node = entry.head
        while node !== nothing
            path_count = node.count
            anc = node.parent
            while anc.item != 0
                @inbounds count_arr[anc.item] += path_count
                anc = anc.parent
            end
            node = node.node_link
        end

        # Lọc item phổ biến trong conditional DB (chỉ lấy item có rank < i)
        cond_items = Int[]
        for j in 1:(i - 1)
            item = tree.ordered_items[j]
            @inbounds count_arr[item] >= minsup && push!(cond_items, item)
        end

        isempty(cond_items) && continue

        # Xây cây điều kiện và đệ quy
        cond_tree = _build_conditional_tree(entry, cond_items, count_arr)
        cond_tree === nothing && continue

        fpgrowth_star!(cond_tree, minsup, new_prefix, result, max_item)
    end
end

# ------------------------------------------------------------------
# API công khai: nhận transactions và minsup, trả về tập kết quả
# ------------------------------------------------------------------
function fpgrowth_star(transactions::Vector{Vector{Int}},
                        minsup::Int)::Vector{Tuple{Vector{Int},Int}}
    tree = build_fptree(transactions, minsup)
    tree === nothing && return Tuple{Vector{Int},Int}[]

    max_item = maximum(tree.ordered_items)
    result   = Tuple{Vector{Int},Int}[]
    fpgrowth_star!(tree, minsup, Int[], result, max_item)
    return result
end

# Overload: nhận minsup tương đối (0 < minsup_rel ≤ 1)
function fpgrowth_star(transactions::Vector{Vector{Int}},
                        minsup_rel::Float64)::Vector{Tuple{Vector{Int},Int}}
    minsup = ceil(Int, minsup_rel * length(transactions))
    return fpgrowth_star(transactions, minsup)
end
