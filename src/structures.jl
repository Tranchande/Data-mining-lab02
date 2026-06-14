# src/structures.jl
# Định nghĩa cấu trúc dữ liệu cho FP-Growth*

mutable struct FPNode
    item::Int                        # ID của item (0 = nút gốc sentinel)
    count::Int                       # Số lần xuất hiện tích lũy
    parent::Union{FPNode,Nothing}
    children::Dict{Int,FPNode}
    node_link::Union{FPNode,Nothing} # Con trỏ đến nút kế tiếp cùng item trong header table
end

FPNode(item::Int, count::Int, parent::Union{FPNode,Nothing}) =
    FPNode(item, count, parent, Dict{Int,FPNode}(), nothing)

# -------------------------------------------------------
# Header table entry: lưu support và danh sách liên kết
# các nút có cùng item trên FP-tree
# -------------------------------------------------------
mutable struct HeaderEntry
    support::Int
    head::Union{FPNode,Nothing}  # Đầu danh sách liên kết
    tail::Union{FPNode,Nothing}  # Đuôi (để thêm O(1))
end

HeaderEntry(sup::Int) = HeaderEntry(sup, nothing, nothing)

# -------------------------------------------------------
# FP-Tree: gom nút gốc, header table, và thứ tự item
# -------------------------------------------------------
mutable struct FPTree
    root::FPNode
    header::Dict{Int,HeaderEntry}
    ordered_items::Vector{Int}   # Items sắp xếp giảm dần theo support toàn cục
end
