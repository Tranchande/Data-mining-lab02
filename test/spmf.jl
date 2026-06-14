# test/spmf.jl
# Tien ich goi SPMF (cong cu tham chieu cua tac gia) de doi chieu ket qua
# va hieu nang voi cai dat FP-Growth* cua nhom.
#
# SPMF la cong cu Java; jar dat tai SPMF/spmf.jar (can Java >= 21).
# Lenh: java -jar spmf.jar run FPGrowth_itemsets <in> <out> <minsup>%

# ------------------------------------------------------------------
# Tim Java >= 21 (jar SPMF moi can class version 21).
# Uu tien bien moi truong JAVA21, roi cac thu muc JDK pho bien.
# ------------------------------------------------------------------
function find_java()::String
    haskey(ENV, "JAVA21") && isfile(ENV["JAVA21"]) && return ENV["JAVA21"]
    bases = [
        "C:/Program Files/Eclipse Adoptium",
        "C:/Program Files/Microsoft",
        "C:/Program Files/Java",
    ]
    for base in bases
        isdir(base) || continue
        for d in readdir(base; join=true)
            occursin("jdk-21", lowercase(basename(d))) || continue
            cand = joinpath(d, "bin", "java.exe")
            isfile(cand) && return cand
        end
    end
    return "java"   # fallback (canh bao neu < 21)
end

const JAVA_BIN = find_java()
const SPMF_JAR = abspath(joinpath(@__DIR__, "..", "SPMF", "spmf.jar"))

# ------------------------------------------------------------------
# Doc file ket qua SPMF: moi dong "item1 item2 ... #SUP: count"
# Tra ve Vector{(itemset, support)}.
# ------------------------------------------------------------------
function read_spmf_output(path::String)::Vector{Tuple{Vector{Int},Int}}
    res = Tuple{Vector{Int},Int}[]
    open(path, "r") do f
        for line in eachline(f)
            line = strip(line)
            isempty(line) && continue
            parts = split(line, "#SUP:")
            length(parts) == 2 || continue
            items = [parse(Int, x) for x in split(parts[1]) if !isempty(x)]
            sup   = parse(Int, strip(parts[2]))
            push!(res, (items, sup))
        end
    end
    return res
end

# ------------------------------------------------------------------
# Chay SPMF FPGrowth_itemsets tren mot file input co san.
# Tra ve (itemsets, time_ms, mem_mb, count) — time/mem/count lay tu
# thong ke ma SPMF tu in ra.
# ------------------------------------------------------------------
function run_spmf(input_file::String, output_file::String, minsup_pct::Float64)
    cmd = `$JAVA_BIN -jar $SPMF_JAR run FPGrowth_itemsets $input_file $output_file "$(minsup_pct)%"`
    statsf = tempname()
    run(pipeline(ignorestatus(cmd); stdout=statsf, stderr=statsf))
    stats = read(statsf, String); rm(statsf; force=true)

    m_time = match(r"Total time ~\s*([\d.]+)", stats)
    m_mem  = match(r"Max memory usage:\s*([\d.]+)", stats)
    m_cnt  = match(r"Frequent itemsets count\s*:\s*(\d+)", stats)
    time_ms = m_time === nothing ? NaN : parse(Float64, m_time.captures[1])
    mem_mb  = m_mem  === nothing ? NaN : parse(Float64, m_mem.captures[1])
    count   = m_cnt  === nothing ? -1  : parse(Int, m_cnt.captures[1])

    itemsets = isfile(output_file) ? read_spmf_output(output_file) : Tuple{Vector{Int},Int}[]
    return itemsets, time_ms, mem_mb, count
end

# ------------------------------------------------------------------
# Tien ich: chay SPMF tren tap giao dich (in-memory) voi minsup TUYET DOI k.
# Tu dong quy doi sang phan tram sao cho nguong cua SPMF = k:
#   SPMF dung nguong = ceil(pct/100 * n); chon pct = (k-0.5)/n*100
#   => ceil(k-0.5) = k (on dinh, tranh lech lam tron o bien).
# Tra ve tap chuan hoa Set{(sorted_itemset, support)}.
# ------------------------------------------------------------------
function spmf_fim(transactions::Vector{Vector{Int}}, minsup_abs::Int)
    n = length(transactions)
    pct = (minsup_abs - 0.5) / n * 100
    inf  = tempname(); outf = tempname()
    open(inf, "w") do io
        for t in transactions
            println(io, join(t, " "))
        end
    end
    itemsets, _, _, _ = run_spmf(inf, outf, pct)
    rm(inf; force=true); rm(outf; force=true)
    return Set((sort(is), s) for (is, s) in itemsets)
end
