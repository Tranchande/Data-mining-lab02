#!/usr/bin/env python3
# test/plot_results.py
# Ve do thi Chuong 4 tu cac file results/*.csv, xuat PNG vao results/.
#
# Chay: python test/plot_results.py
# Yeu cau: matplotlib (numpy co san). Khong can pandas.

import csv
import math
import os

import matplotlib
matplotlib.use("Agg")  # headless -> ghi PNG khong can man hinh
import matplotlib.pyplot as plt

RDIR = os.path.join(os.path.dirname(__file__), "..", "results")


def read_csv(name):
    """Doc results/<name> -> list[dict]. So duoc parse sang float khi co the."""
    rows = []
    with open(os.path.join(RDIR, name), newline="") as f:
        for r in csv.DictReader(f):
            conv = {}
            for k, v in r.items():
                try:
                    conv[k] = float(v)
                except (ValueError, TypeError):
                    conv[k] = v
            rows.append(conv)
    return rows


def datasets_in(rows):
    seen = []
    for r in rows:
        if r["dataset"] not in seen:
            seen.append(r["dataset"])
    return seen


def grp(rows, d):
    return [r for r in rows if r["dataset"] == d]


def exists(name):
    return os.path.isfile(os.path.join(RDIR, name))


def save(fig, name):
    path = os.path.join(RDIR, name)
    fig.tight_layout(rect=(0, 0, 1, 0.96))  # chua khoang cho suptitle, tranh chong chu
    fig.savefig(path, dpi=130, bbox_inches="tight")
    plt.close(fig)
    print("  ->", name)


# ==================================================================
# (b) Thoi gian theo minsup: FP-Growth* vs SPMF  (1 panel / dataset)
# ==================================================================
def plot_time_vs_minsup():
    if not exists("compare_time.csv"):
        return
    rows = read_csv("compare_time.csv")
    ds = datasets_in(rows)
    ncol = 2
    nrow = math.ceil(len(ds) / ncol)
    fig, axes = plt.subplots(nrow, ncol, figsize=(10, 3.4 * nrow), squeeze=False)
    for i, d in enumerate(ds):
        ax = axes[i // ncol][i % ncol]
        g = grp(rows, d)
        x = [r["minsup_pct"] * 100 for r in g]
        ax.plot(x, [r["time_mine_ms"] for r in g], "o-", label="FP-Growth*")
        ax.plot(x, [r["time_spmf_ms"] for r in g], "s--", label="SPMF")
        ax.set_title(d)
        ax.set_xlabel("minsup (%)")
        ax.set_ylabel("time (ms)")
        ax.legend()
        ax.grid(True, alpha=0.3)
    for j in range(len(ds), nrow * ncol):
        axes[j // ncol][j % ncol].axis("off")
    fig.suptitle("(b) Thoi gian theo minsup: FP-Growth* vs SPMF")
    save(fig, "plot_time_vs_minsup.png")


# ==================================================================
# (c) So luong frequent itemset theo minsup  (log y, 1 panel / dataset)
# ==================================================================
def plot_itemsets_vs_minsup():
    if not exists("benchmark_minsup.csv"):
        return
    rows = read_csv("benchmark_minsup.csv")
    ds = datasets_in(rows)
    ncol = 2
    nrow = math.ceil(len(ds) / ncol)
    fig, axes = plt.subplots(nrow, ncol, figsize=(10, 3.4 * nrow), squeeze=False)
    for i, d in enumerate(ds):
        ax = axes[i // ncol][i % ncol]
        g = grp(rows, d)
        x = [r["minsup_pct"] * 100 for r in g]
        ax.plot(x, [r["n_itemsets"] for r in g], "o-")
        ax.set_yscale("log")
        ax.set_title(d)
        ax.set_xlabel("minsup (%)")
        ax.set_ylabel("#itemsets (log)")
        ax.grid(True, which="both", alpha=0.3)
    for j in range(len(ds), nrow * ncol):
        axes[j // ncol][j % ncol].axis("off")
    fig.suptitle("(c) So frequent itemset theo minsup")
    save(fig, "plot_itemsets_vs_minsup.png")


# ==================================================================
# (d) Bo nho peak: FP-Growth* (net) vs SPMF  (grouped bar)
# ==================================================================
def plot_memory():
    if not exists("compare_memory.csv"):
        return
    rows = read_csv("compare_memory.csv")
    ds = [r["dataset"] for r in rows]
    net = [r["net_mine_mb"] for r in rows]
    spmf = [r["peak_spmf_mb"] for r in rows]
    x = range(len(ds))
    w = 0.38
    fig, ax = plt.subplots(figsize=(7, 4.5))
    ax.bar([i - w / 2 for i in x], net, w, label="FP-Growth* (net)")
    ax.bar([i + w / 2 for i in x], spmf, w, label="SPMF")
    ax.set_xticks(list(x))
    ax.set_xticklabels(ds)
    ax.set_ylabel("peak memory (MB)")
    ax.set_title("(d) Bo nho khai pha: FP-Growth* (net) vs SPMF")
    ax.legend()
    ax.grid(True, axis="y", alpha=0.3)
    save(fig, "plot_memory.png")


# ==================================================================
# (e) Scalability: thoi gian theo % kich thuoc CSDL
# ==================================================================
def plot_scalability():
    if not exists("benchmark_scalability.csv"):
        return
    rows = read_csv("benchmark_scalability.csv")
    fig, ax = plt.subplots(figsize=(7, 4.5))
    for d in datasets_in(rows):
        g = grp(rows, d)
        ax.plot([r["frac_pct"] for r in g], [r["time_ms"] for r in g], "o-", label=d)
    ax.set_xlabel("subset (%)")
    ax.set_ylabel("time (ms)")
    ax.set_title("(e) Scalability: thoi gian theo kich thuoc CSDL")
    ax.legend()
    ax.grid(True, alpha=0.3)
    save(fig, "plot_scalability.png")


# ==================================================================
# (f) Anh huong do dai giao dich trung binh
# ==================================================================
def plot_txnlen():
    if not exists("txnlen.csv"):
        return
    rows = read_csv("txnlen.csv")
    x = [r["avg_len"] for r in rows]
    fig, (a1, a2) = plt.subplots(1, 2, figsize=(10, 3.6))
    a1.plot(x, [r["time_ms"] for r in rows], "o-")
    a1.set_xlabel("do dai giao dich")
    a1.set_ylabel("time (ms)")
    a1.set_title("Thoi gian")
    a1.grid(True, alpha=0.3)
    a2.plot(x, [r["n_itemsets"] for r in rows], "s-", color="tab:orange")
    a2.set_yscale("log")
    a2.set_xlabel("do dai giao dich")
    a2.set_ylabel("#itemsets (log)")
    a2.set_title("So itemset")
    a2.grid(True, which="both", alpha=0.3)
    fig.suptitle("(f) Anh huong do dai giao dich")
    save(fig, "plot_txnlen.png")


if __name__ == "__main__":
    plot_time_vs_minsup()
    plot_itemsets_vs_minsup()
    plot_memory()
    plot_scalability()
    plot_txnlen()
    print("\nDa xuat do thi vao results/")
