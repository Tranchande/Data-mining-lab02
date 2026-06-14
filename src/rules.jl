# src/rules.jl
# Sinh luat ket hop (association rules) tu tap pho bien — phuc vu Chuong 5
# (Ung dung: Market Basket Analysis).
#
# Tu moi tap pho bien Z (|Z| >= 2), xet moi cach chia Z = X ∪ Y (X,Y khac rong):
#   luat  X => Y  voi
#     support(X=>Y) = support(Z)
#     confidence    = support(Z) / support(X)
#     lift          = confidence / (support(Y) / n_trans)
# Giu lai cac luat co confidence >= minconf.
#
# (support cua moi tap con X, Y deu co san trong tap pho bien nho tinh chat
#  Apriori: X, Y ⊆ Z frequent => X, Y cung frequent.)

# Mot luat ket hop
struct AssocRule
    antecedent::Vector{Int}   # X
    consequent::Vector{Int}   # Y
    support::Int              # support(X ∪ Y)
    confidence::Float64
    lift::Float64
end

# ------------------------------------------------------------------
# Sinh luat tu ket qua FP-Growth* (Vector{(itemset, support)}).
# Tra ve danh sach AssocRule, sap xep theo lift giam dan.
# ------------------------------------------------------------------
function association_rules(results::Vector{Tuple{Vector{Int},Int}},
                           n_trans::Int;
                           minconf::Float64 = 0.5)::Vector{AssocRule}
    # Tra cuu support O(1) theo tap item
    sup = Dict{Set{Int},Int}()
    for (is, s) in results
        sup[Set(is)] = s
    end

    rules = AssocRule[]
    for (itemset, s_z) in results
        k = length(itemset)
        k < 2 && continue
        full = Set(itemset)
        # Duyet moi tap con X khac rong va khac toan bo (mask 1 .. 2^k-2)
        for mask in 1:((1 << k) - 2)
            X = Int[]
            for i in 1:k
                (mask >> (i - 1)) & 1 == 1 && push!(X, itemset[i])
            end
            setX = Set(X)
            conf = s_z / sup[setX]
            conf < minconf && continue
            Y = collect(setdiff(full, setX))
            lift = conf / (sup[Set(Y)] / n_trans)
            push!(rules, AssocRule(sort(X), sort(Y), s_z, conf, lift))
        end
    end

    sort!(rules, by = r -> -r.lift)
    return rules
end
