# src/main.jl
# CLI entry point
# Cách dùng:
#   julia src/main.jl <input_file> <minsup> [output_file]
#
# minsup: số nguyên (absolute) hoặc số thực (0,1] (relative)
# Ví dụ:
#   julia src/main.jl data/toy/example1.txt 3
#   julia src/main.jl data/benchmark/chess.txt 0.8 out.txt

include("FPGrowthStar.jl")
using .FPGrowthStar

function main()
    if length(ARGS) < 2
        println(stderr, "Cách dùng: julia src/main.jl <input_file> <minsup> [output_file]")
        println(stderr, "  minsup: số nguyên tuyệt đối hoặc số thực trong (0,1] (tương đối)")
        exit(1)
    end

    input_file  = ARGS[1]
    minsup_arg  = ARGS[2]
    output_file = length(ARGS) >= 3 ? ARGS[3] : nothing

    if !isfile(input_file)
        println(stderr, "Lỗi: không tìm thấy file: $input_file")
        exit(1)
    end

    transactions = read_spmf(input_file)
    n = length(transactions)

    # Phân tích minsup: nếu có dấu chấm thập phân → tương đối
    minsup_val = parse(Float64, minsup_arg)
    minsup = (minsup_val > 0 && minsup_val < 1) ?
             ceil(Int, minsup_val * n) :
             Int(round(minsup_val))

    println("File       : $input_file")
    println("Giao dịch  : $n")
    println("minsup     : $minsup (tuyệt đối)")

    elapsed = @elapsed results = fpgrowth_star(transactions, minsup)

    println("Tập phổ biến: $(length(results))")
    println("Thời gian   : $(round(elapsed * 1000, digits=2)) ms")

    if output_file !== nothing
        write_results(output_file, results)
        println("Kết quả ghi vào: $output_file")
    else
        println("\n--- KẾT QUẢ ---")
        write_results(stdout, results)
    end
end

main()
