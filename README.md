# Đồ Án 2: Khai thác Tập Phổ Biến — FP-Growth\*
**Môn:** CSC14004 — Khai thác Dữ liệu và Ứng dụng &nbsp;|&nbsp; **Ngôn ngữ:** Julia ($\ge$ 1.9)

## Thành viên nhóm

| Họ và tên | MSSV | Phân công |
|-----------|------|-----------|
|           |      |           |
|           |      |           |
|           |      |           |

## Cài đặt môi trường

- **Julia $\ge$ 1.9** (bắt buộc). Chỉ dùng thư viện chuẩn `Printf`, `Random`, `Test` — **không** cần package ngoài.
- *(Tùy chọn)* Phần đối chiếu/đo với **SPMF** cần **Java $\ge$ 21** và `SPMF/spmf.jar` (bản release tải từ trang tác giả).
- *(Tùy chọn)* Vẽ đồ thị cần **Python + matplotlib** (`pip install matplotlib`).

```bash
# Cài đặt môi trường Julia (lần đầu)
julia --project -e 'using Pkg; Pkg.instantiate()'
```

## Cách chạy & ví dụ sử dụng

### 1) Khai phá tập phổ biến (CLI)
```bash
# Cú pháp: julia src/main.jl <input_file> <minsup> [output_file]
#   minsup: số nguyên (tuyệt đối) HOẶC số thực trong (0,1] (tương đối)
julia src/main.jl data/toy/example1.txt 3                 # minsup tuyệt đối = 3
julia src/main.jl data/benchmark/chess.txt 0.8 out.txt    # minsup 80%, ghi ra file
```
**Định dạng vào/ra (SPMF):** mỗi dòng input là một giao dịch gồm các item (số nguyên dương) cách nhau bởi khoảng trắng; dòng trống và dòng bắt đầu bằng `#` bị bỏ qua. Output có dạng `1 2 3 #SUP: <support>`.

### 2) Kiểm thử
```bash
julia --project test/runtests.jl                # unit test tự động (đối chiếu brute-force)
julia --project test/test_correctness.jl        # đối chiếu SPMF: #itemset & support (cần Java 21)
julia --project test/test_correctness_image.jl  # bản in PASS/FAIL dễ đọc
```

### 3) Thực nghiệm & đồ thị
```bash
julia --project test/test_benchmark.jl          # thời gian / #itemset / scalability -> results/*.csv
julia --project test/test_benchmark_spmf.jl     # so thời gian & bộ nhớ với SPMF
julia --project test/test_txnlen.jl             # ảnh hưởng độ dài giao dịch
julia --project test/test_rules.jl              # luật kết hợp (Market Basket) trên Retail
python test/plot_results.py                     # vẽ đồ thị từ CSV -> results/plot_*.png
```

## Cấu trúc thư mục
```text
├── src/                # Cài đặt thuật toán
│   ├── FPGrowthStar.jl  #   module gói toàn bộ (điểm vào)
│   ├── structures.jl    #   FPNode, HeaderEntry, FPTree
│   ├── utils.jl         #   đọc/ghi SPMF, in cây
│   ├── rules.jl         #   sinh luật kết hợp
│   ├── main.jl          #   CLI
│   └── algorithm/fpgrowth_star.jl
├── test/               # Unit test, benchmark, vẽ đồ thị
├── data/  (toy/, benchmark/)   # CSDL ví dụ tay & benchmark
├── results/            # Số liệu CSV + đồ thị PNG (sinh khi chạy test)
├── notebooks/demo.ipynb
└── docs/               # Báo cáo PDF
```
*Dữ liệu benchmark (chess, mushroom, retail, accidents) nguồn từ [SPMF Datasets](https://www.philippe-fournier-viger.com/spmf/index.php?link=datasets.php) / [FIMI Repository](http://fimi.uantwerpen.be/data/).*

## Kết quả chạy test (lần chạy cuối)

_Môi trường: Julia 1.12.6, Windows; SPMF chạy bằng JDK 21. Ngày chạy: 2026-06-14._

### Unit test tự động — `julia --project test/runtests.jl`

```text
Test Summary:          | Pass  Total  Time
FP-Growth* correctness |   10     10  0.3s
```

### Đối chiếu tính đúng đắn (bản đọc PASS/FAIL) — `julia --project test/test_correctness_image.jl`

```text
=======================================================
  Kiem tra tinh dung dan: FP-Growth*
=======================================================
  PASS  Vi du 1 co ban (minsup=3)  (10 itemsets)
  PASS  Vi du 2 nhanh don (expect 31, got 31)
  PASS  Han et al. 2000 (minsup=3)  (18 itemsets)
  PASS  Giao dich giong nhau (minsup=2)  (7 itemsets)
  PASS  Khong co 2-itemset pho bien (minsup=2)  (0 itemsets)
  PASS  1 giao dich (minsup=1)  (31 itemsets)
  PASS  minsup qua cao -> rong
  PASS  File example1.txt (minsup=3)  (10 itemsets)
  PASS  File example2.txt nhanh don (expect 31, got 31)
  PASS  Item IDs khong lien tuc (minsup=2)  (6 itemsets)
=======================================================
  Ket qua: 10/10 PASS
=======================================================
```

### Đối chiếu với SPMF (Chương 4a) — `julia --project test/test_correctness.jl`

```text
================================================================================
  MUC 4(a): DOI CHIEU FP-Growth* vs SPMF
================================================================================

[1] CSDL nho / vi du tay:
  Vi du 1 co ban             k=3       | mine=10        spmf=10        khop=10        | 100.00% OK
  Han et al. 2000            k=3       | mine=18        spmf=18        khop=18        | 100.00% OK
  Nhanh don (single)         k=1       | mine=31        spmf=31        khop=31        | 100.00% OK
  Giao dich giong nhau       k=2       | mine=7         spmf=7         khop=7         | 100.00% OK
  Item ID khong lien tuc     k=2       | mine=6         spmf=6         khop=6         | 100.00% OK

[2] File toy (data/toy):
  example1.txt               k=3       | mine=10        spmf=10        khop=10        | 100.00% OK
  example2.txt               k=2       | mine=15        spmf=15        khop=15        | 100.00% OK
  example3.txt               k=2       | mine=20        spmf=20        khop=20        | 100.00% OK

[3] Benchmark (doi chieu o minsup cao):
  chess.txt (80%)            k=2557    | mine=8227      spmf=8227      khop=8227      | 100.00% OK
  mushroom.txt (30%)         k=2525    | mine=2587      spmf=2587      khop=2587      | 100.00% OK
  retail.txt (1%)            k=882     | mine=159       spmf=159       khop=159       | 100.00% OK
  accidents.txt (80%)        k=272147  | mine=149       spmf=149       khop=149       | 100.00% OK

================================================================================
  KET QUA: 100% KHOP SPMF tren moi CSDL.
================================================================================
```
