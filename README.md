# Đồ Án 2: Khai thác Tập Phổ Biến (Frequent Itemset Mining)
**Thuật toán:** FP-Growth* **Ngôn ngữ triển khai:** Julia ($\ge 1.9$)

## 1. Giới thiệu Bài toán
Khai thác tập phổ biến (FIM) là cốt lõi của các hệ thống khai phá dữ liệu như phân tích giỏ hàng (Market Basket Analysis). Mục tiêu là tìm ra các tập hợp phần tử (itemsets) xuất hiện cùng nhau trong một cơ sở dữ liệu giao dịch với tần suất lớn hơn hoặc bằng một ngưỡng cho trước gọi là **Độ hỗ trợ tối thiểu** ($min\_sup$).

## 2. Nền tảng Thuật toán

### 2.1. FP-Growth (Frequent Pattern Growth)
Được đề xuất bởi Han et al. (2000), FP-Growth giải quyết nút thắt cổ chai lớn nhất của thuật toán Apriori trước đó: **Phải sinh ra một lượng khổng lồ các tập ứng viên**. 

**Cơ chế hoạt động:**
1. Thuật toán nén toàn bộ cơ sở dữ liệu thành một cấu trúc cây tiền tố gọi là **FP-Tree**, chỉ lưu giữ những mặt hàng phổ biến.
2. Từ FP-Tree, nó trích xuất các **cơ sở mẫu điều kiện (Conditional Pattern Base)** cho từng mặt hàng (bắt đầu từ mặt hàng ít phổ biến nhất).
3. Thuật toán tiếp tục xây dựng các **cây điều kiện (Conditional FP-Tree)** nhỏ hơn từ các cơ sở mẫu này và gọi đệ quy để tìm ra tất cả các tập phổ biến.

*Nhược điểm:* Việc liên tục phải duyệt dữ liệu hai lần (một lần để đếm, một lần để tạo cây) và cấp phát bộ nhớ cho hàng loạt cây điều kiện con khiến FP-Growth truyền thống tiêu tốn nhiều tài nguyên khi dữ liệu thưa thớt hoặc ngưỡng $min\_sup$ quá nhỏ.

### 2.2. FP-Growth* (Bản Tối ưu hóa)
Được đề xuất bởi Grahne & Zhu (2003), FP-Growth* là phiên bản cải tiến trực tiếp nhằm tối ưu hóa quá trình đệ quy khai phá dữ liệu.

**Điểm khác biệt cốt lõi (Array-based Technique):**
Thay vì phải quét các cơ sở mẫu điều kiện hai lần như thuật toán gốc, FP-Growth* sử dụng cấu trúc mảng (hoặc bảng băm - Hash Table) ngay trong bộ nhớ để đếm và lưu vết tần suất của các item. 
- Nhờ việc đếm trực tiếp này, thuật toán loại bỏ hoàn toàn bước quét lặp lại. 
- Các tập phổ biến mới có thể được sinh ra ngay lập tức từ dữ liệu mảng mà không cần phải thực sự xây dựng cấu trúc node vật lý của cây điều kiện trong một số trường hợp, giúp giảm đáng kể chi phí cấp phát bộ nhớ và thời gian CPU.

## 3. Cấu trúc Dự Án

```text
itemset/
├── README.md                    # Tài liệu hướng dẫn & Lý thuyết
├── Project.toml                 # Môi trường & dependency (Julia)
├── src/
│   ├── FPGrowthStar.jl          # Module gói toàn bộ cài đặt (điểm vào của package)
│   ├── structures.jl            # Cấu trúc dữ liệu: FPNode, HeaderEntry, FPTree
│   ├── utils.jl                 # Hàm phụ trợ (đọc/ghi SPMF, in cây, kiểm thử)
│   ├── rules.jl                 # Sinh luật kết hợp (Chương 5: Market Basket Analysis)
│   ├── main.jl                  # CLI: julia src/main.jl <input> <minsup> [output]
│   └── algorithm/
│       └── fpgrowth_star.jl     # Thuật toán nhóm chọn: FP-Growth* (array-based)
├── test/
│   ├── runtests.jl              # Bộ unit test chính thức, brute-force (julia --project test/runtests.jl)
│   ├── test_correctness.jl      # Mục 4(a): đối chiếu #itemset & support với SPMF (100% khớp)
│   ├── test_correctness_image.jl # Bản in PASS/FAIL (brute-force) để chụp ảnh báo cáo
│   ├── test_benchmark.jl        # Đo thời gian/bộ nhớ FP-Growth*, xuất CSV (mục 4 b,c,e)
│   ├── spmf.jl                  # Tiện ích gọi SPMF (cần Java ≥ 21 + SPMF/spmf.jar)
│   ├── test_benchmark_spmf.jl   # Mục 4(b,d): so thời gian & bộ nhớ với SPMF
│   ├── test_txnlen.jl           # Mục 4(f): ảnh hưởng độ dài giao dịch (CSDL tổng hợp)
│   ├── test_rules.jl            # Mục 5: luật kết hợp trên Retail (Market Basket)
│   └── plot_results.py          # Vẽ đồ thị từ results/*.csv (Python + matplotlib)
├── data/
│   ├── toy/                     # CSDL nhỏ cho ví dụ tay (có sẵn)
│   └── benchmark/               # CSDL benchmark (tự tải, xem mục 4)
├── results/                     # CSV số liệu thực nghiệm (tự sinh khi chạy)
├── SPMF/                        # spmf.jar (công cụ tham chiếu — không commit nếu >25MB)
├── notebooks/
│   └── demo.ipynb               # Jupyter Notebook demo
└── docs/                        # Báo cáo PDF
```

## 4. Môi trường & Cách chạy

**Yêu cầu:** Julia ≥ 1.9. Không cần cài thêm package ngoài (chỉ dùng stdlib: `Printf`, `Random`, `Test`).

```bash
# (Tùy chọn) cài đặt môi trường lần đầu
julia --project -e 'using Pkg; Pkg.instantiate()'

# Khai phá tập phổ biến — minsup là số nguyên (tuyệt đối) HOẶC số thực trong (0,1] (tương đối)
julia src/main.jl data/toy/example1.txt 3
julia src/main.jl data/toy/example2.txt 0.5 out.txt    # ghi kết quả ra file

# Chạy bộ kiểm thử tự động (phải PASS toàn bộ)
julia --project test/runtests.jl
#   hoặc: julia --project -e 'using Pkg; Pkg.test()'

# Bản in PASS/FAIL dễ đọc (brute-force, để chụp màn hình cho báo cáo)
julia --project test/test_correctness_image.jl

# Benchmark hiệu năng (cần đặt dataset vào data/benchmark/, nếu thiếu sẽ tự SKIP)
julia --project test/test_benchmark.jl
```

### Thực nghiệm Chương 4 (đối chiếu & đo với SPMF)

Cần **Java ≥ 21** và `SPMF/spmf.jar` (bản release tải từ trang tác giả). Kết quả ghi vào `results/*.csv` để vẽ đồ thị.

```bash
# (a) Đối chiếu tính đúng đắn với SPMF (#itemset & support) — phải 100% khớp
julia --project test/test_correctness.jl

# (b,d) So thời gian & bộ nhớ với SPMF (xuất results/compare_time.csv, compare_memory.csv)
julia --project test/test_benchmark_spmf.jl
#   chỉ chạy lại phần bộ nhớ:  ONLY_MEM=1 julia --project test/test_benchmark_spmf.jl

# (c,e) Số itemset & thời gian theo minsup + scalability (xuất results/benchmark_*.csv)
julia --project test/test_benchmark.jl

# (f) Ảnh hưởng độ dài giao dịch (CSDL tổng hợp có seed → results/txnlen.csv)
julia --project test/test_txnlen.jl

# Vẽ đồ thị từ tất cả CSV → results/plot_*.png  (cần: pip install matplotlib)
python test/plot_results.py
```

### Ứng dụng Chương 5 — Market Basket Analysis

```bash
# Sinh luật kết hợp từ frequent itemset trên Retail → results/rules_retail.csv
julia --project test/test_rules.jl
```

**Định dạng vào/ra (SPMF):** mỗi dòng input là một giao dịch gồm các item (số nguyên dương)
cách nhau bởi khoảng trắng; dòng trống và dòng bắt đầu bằng `#` bị bỏ qua. Output có dạng
`<item1> <item2> ... #SUP: <support>`.

> **Dữ liệu benchmark:** Chess, Mushroom, Retail, Accidents, T10I4D100K — tải từ
> [SPMF Datasets](https://www.philippe-fournier-viger.com/spmf/index.php?link=datasets.php)
> hoặc [FIMI Repository](http://fimi.uantwerpen.be/data/), đặt vào `data/benchmark/`
> với tên `chess.txt`, `mushroom.txt`, `retail.txt`, `accidents.txt`, `T10I4D100K.txt`.

## 5. Kết quả chạy test (lần chạy cuối)

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