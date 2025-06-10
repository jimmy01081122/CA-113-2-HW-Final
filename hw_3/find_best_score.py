import csv
import math

def log2_kb(byte_size):
    return math.log2(byte_size / 1024)

csv_file = "results.csv"  # 你的轉置 CSV
output_file = "gem5_args.conf"

# 1. 讀檔並轉成 dict（key: row 名，value: 數列）
with open(csv_file, newline='') as f:
    reader = csv.reader(f)
    data_rows = list(reader)

data = {}
for row in data_rows:
    if not row or not row[0].strip(): continue
    key = row[0].strip()
    values = row[1:]
    data[key] = values

# 2. 拿出所有欄位，並轉成 int（或 float）
ticks_list = list(map(int, data["simulated tick"]))
l1i_size_list = list(map(int, data["L1-I size"]))
l1i_assoc_list = list(map(int, data["L1-I assoc"]))
l1d_size_list = list(map(int, data["L1-D size"]))
l1d_assoc_list = list(map(int, data["L1-D assoc"]))
l2_size_list = list(map(int, data["L2 size"]))
l2_assoc_list = list(map(int, data["L2 assoc"]))

# 3. 掃描每組，計算分數並找出最佳組合
best_idx = -1
best_score = float("inf")

for i in range(len(ticks_list)):
    tick = ticks_list[i]
    penalty = (
        log2_kb(l1i_size_list[i]) +
        log2_kb(l1d_size_list[i]) +
        log2_kb(l2_size_list[i])
    )
    score = tick - penalty

    if score < best_score:
        best_score = score
        best_idx = i

# 4. 印出與儲存最佳參數
print("✅ Best config with score =", round(best_score))
print(f"  L1-I size   : {l1i_size_list[best_idx]} B")
print(f"  L1-I assoc  : {l1i_assoc_list[best_idx]}")
print(f"  L1-D size   : {l1d_size_list[best_idx]} B")
print(f"  L1-D assoc  : {l1d_assoc_list[best_idx]}")
print(f"  L2 size     : {l2_size_list[best_idx]} B")
print(f"  L2 assoc    : {l2_assoc_list[best_idx]}")
print(f"  Ticks       : {ticks_list[best_idx]:,}")

# 5. 輸出 gem5_args.conf
with open(output_file, "w") as f:
    f.write("--isa_type 32 "
            f"--l1i_size {l1i_size_list[best_idx]//1024}kB "
            f"--l1i_assoc {l1i_assoc_list[best_idx]} "
            f"--l1d_size {l1d_size_list[best_idx]//1024}kB "
            f"--l1d_assoc {l1d_assoc_list[best_idx]} "
            f"--l2_size {l2_size_list[best_idx]//1024}kB "
            f"--l2_assoc {l2_assoc_list[best_idx]}\n")

print(f"\n▶︎ 已將最佳組態寫入 {output_file}")
