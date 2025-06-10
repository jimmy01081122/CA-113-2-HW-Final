import csv
import math

def log2_kb(byte_size):
    return math.log2(byte_size / 1024)

csv_file = "results.csv"  # 你的轉置格式 CSV（可改名）

# --- 1. 讀取 CSV 為轉置格式 dict[row_name] = [v1, v2, v3...]
with open(csv_file, newline='') as f:
    reader = csv.reader(f)
    data_rows = list(reader)

data = {}
for row in data_rows:
    if not row or not row[0].strip(): continue
    key = row[0].strip()
    data[key] = row[1:]

# --- 2. 取出資料欄位
ticks_list      = list(map(int,   data["simulated tick"]))
l1i_size_list   = list(map(int,   data["L1-I size"]))
l1i_assoc_list  = list(map(int,   data["L1-I assoc"]))
l1d_size_list   = list(map(int,   data["L1-D size"]))
l1d_assoc_list  = list(map(int,   data["L1-D assoc"]))
l2_size_list    = list(map(int,   data["L2 size"]))
l2_assoc_list   = list(map(int,   data["L2 assoc"]))

# --- 3. 計算每組分數
results = []
for i in range(len(ticks_list)):
    ticks = ticks_list[i]
    l1i = l1i_size_list[i]
    l1d = l1d_size_list[i]
    l2  = l2_size_list[i]

    score = ticks - log2_kb(l1i) - log2_kb(l1d) - log2_kb(l2)
    results.append({
        "score": score,
        "ticks": ticks,
        "l1i_size": l1i,
        "l1i_assoc": l1i_assoc_list[i],
        "l1d_size": l1d,
        "l1d_assoc": l1d_assoc_list[i],
        "l2_size": l2,
        "l2_assoc": l2_assoc_list[i],
        "index": i
    })

# --- 4. 找出前五名
results.sort(key=lambda x: x["score"])

print("🔝 Top 5 Configurations (Lowest Score First):\n")
for rank, r in enumerate(results[:5], 1):
    print(f"[#{rank}] Score = {r['score']:,.2f} | Ticks = {r['ticks']:,}")
    print(f"     L1-I: {r['l1i_size']//1024}kB {r['l1i_assoc']}-way")
    print(f"     L1-D: {r['l1d_size']//1024}kB {r['l1d_assoc']}-way")
    print(f"     L2  : {r['l2_size']//1024}kB {r['l2_assoc']}-way\n")
