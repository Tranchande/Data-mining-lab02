# src/FPGrowthStar.jl
# Module gói toàn bộ cài đặt thuật toán FP-Growth*.
#
# Cách dùng:
#   include("src/FPGrowthStar.jl"); using .FPGrowthStar
# hoặc khi môi trường đã kích hoạt (julia --project):
#   using FPGrowthStar

module FPGrowthStar

# Thứ tự nạp quan trọng: cấu trúc dữ liệu trước, rồi tiện ích, rồi thuật toán.
include("structures.jl")
include("utils.jl")
include("algorithm/fpgrowth_star.jl")
include("rules.jl")

# --- API công khai ---
export fpgrowth_star                     # thuật toán FP-Growth*
export read_spmf, write_results          # I/O định dạng SPMF
export print_tree, match_ratio           # tiện ích debug / kiểm thử
export build_fptree                      # dựng FP-tree (dùng trong demo)
export FPNode, HeaderEntry, FPTree       # cấu trúc dữ liệu
export association_rules, AssocRule       # luật kết hợp (Chương 5)

end # module
