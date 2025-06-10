import csv
import json
import re
import os
import argparse

# Define the target data keys and their corresponding CSV column headers
fields_mapping = {
    "simSeconds": "simulated time",
    "simTicks": "simulated tick",
    "simInsts": "total Inst.",
    "system.cpu.numCycles": "total cycle",
    "system.cpu.cpi": "CPI",
    "system.cpu.ipc": "IPC",
    "system.cpu.commitStats0.numIntInsts": "Int-Inst. count",
    "system.cpu.commitStats0.numLoadInsts": "Load-Inst. count",
    "system.cpu.commitStats0.numStoreInsts": "Store-Inst. count",
    "system.cpu.commitStats0.numVecInsts": "Vector-Inst. count",
    "system.l1icache.overallHits::total": "$L1-I hit count",
    "system.l1icache.overallMisses::total": "$L1-I miss count",
    "system.l1icache.overallAccesses::total": "$L1-I access count",
    "system.l1icache.overallMissRate::total": "$L1-I miss rate",
    "system.l1dcache.overallHits::total": "$L1-D hit count",
    "system.l1dcache.overallMisses::total": "$L1-D miss count",
    "system.l1dcache.overallAccesses::total": "$L1-D access count",
    "system.l1dcache.overallMissRate::total": "$L1-D miss rate",
    "system.l2cache.overallHits::total": "$L2 hit count",
    "system.l2cache.overallMisses::total": "$L2 miss count",
    "system.l2cache.overallAccesses::total": "$L2 access count",
    "system.l2cache.overallMissRate::total": "$L2 miss rate"
}

# Category definitions for CSV section headers
categories = {
    "Program summary": [
        "simulated time", "simulated tick", "total Inst.", "total cycle", "CPI", "IPC",
        "Int-Inst. count", "Load-Inst. count", "Store-Inst. count", "Vector-Inst. count"
    ],
    "L1-Instruction-Cache summary": [
        "$L1-I hit count", "$L1-I miss count", "$L1-I access count", "$L1-I miss rate", "L1-I assoc", "L1-I size"
    ],
    "L1-Data-Cache summary": [
        "$L1-D hit count", "$L1-D miss count", "$L1-D access count", "$L1-D miss rate", "L1-D assoc", "L1-D size"
    ],
    "L2-Cache summary": [
        "$L2 hit count", "$L2 miss count", "$L2 access count", "$L2 miss rate", "L2 assoc", "L2 size"
    ]
}

def extract_stats(file_path):
    """
    Read stats.txt and extract target fields.
    """
    extracted_data = {}
    with open(file_path, 'r') as file:
        content = file.read()
        for key, field_name in fields_mapping.items():
            match = re.search(rf"{key}\s+([\d\.]+)", content)
            extracted_data[field_name] = match.group(1) if match else "N/A"
    return extracted_data

def extract_config_data(config_path):
    """
    Read config.json and extract L1/L2 cache configurations.
    """
    with open(config_path, 'r', encoding='utf-8') as file:
        config = json.load(file)

    extracted_data = {
        "L1-I assoc": str(config['system']['l1icache']['assoc']),
        "L1-I size": str(config['system']['l1icache']['size']),
        "L1-D assoc": str(config['system']['l1dcache']['assoc']),
        "L1-D size": str(config['system']['l1dcache']['size']),
        "L2 assoc": str(config['system']['l2cache']['assoc']),
        "L2 size": str(config['system']['l2cache']['size'])
    }
    return extracted_data

def merge_values(field, stats_data, config_data):
    """
    Prefer value from stats_data; if not available, fall back to config_data.
    Return empty string if both are unavailable.
    """
    val_stats = stats_data.get(field, "N/A")
    val_config = config_data.get(field, "N/A")

    if val_stats != "N/A":
        return val_stats
    elif val_config != "N/A":
        return val_config
    else:
        return ""

def save_to_csv(stats_data, config_data, csv_path):
    """
    Create a new CSV file.
    Skip fields missing in both stats and config data.
    """
    with open(csv_path, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)

        for category, fields in categories.items():
            # Write category as a single-row header
            writer.writerow([category])

            # Write each field if it has a value
            for field in fields:
                val = merge_values(field, stats_data, config_data)
                if val:
                    writer.writerow([field, val])

            # Separate sections with a blank line
            writer.writerow([])

def append_to_csv(stats_data, config_data, csv_path):
    """
    Read existing CSV and append a column of new values to each field row.
    Leave blank if no value is available.
    """
    file_exists = os.path.exists(csv_path)
    if not file_exists:
        # If CSV does not exist, create a new one
        save_to_csv(stats_data, config_data, csv_path)
        return

    # Read current contents
    with open(csv_path, 'r', newline='', encoding='utf-8') as csvfile:
        rows = list(csv.reader(csvfile))

    # Append new value to valid data rows
    for i, row in enumerate(rows):
        # Skip category or empty rows
        if len(row) <= 1:
            continue

        field = row[0]
        val = ""
        # Check if the row is one of our defined fields
        for fields_in_cat in categories.values():
            if field in fields_in_cat:
                val = merge_values(field, stats_data, config_data)
                break

        row.append(val)

    # Write updated content back
    with open(csv_path, 'w', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerows(rows)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--add", "-a", default=False, action="store_true", help="append data to existing CSV file")
    args = parser.parse_args()

    # Set file paths according to your environment
    input_file = "m5out/stats.txt"
    config_file = "m5out/config.json"
    output_file = "program_info.csv"

    # Extract data
    stats_data = extract_stats(input_file)
    config_data = extract_config_data(config_file)

    # Decide whether to append or create new
    if args.add:
        append_to_csv(stats_data, config_data, output_file)
    else:
        save_to_csv(stats_data, config_data, output_file)

    print(f"Data has been extracted and saved to {output_file}")

if __name__ == "__main__":
    main()
