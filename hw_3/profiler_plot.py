def print_summary(input_csv):
    # Initialize variables
    data = []
    current_section = None

    # Read the file line by line
    with open(input_csv, 'r') as file:
        for line in file:
            line = line.strip()
            if not line:  # Skip empty lines
                continue
            if not ',' in line:  # Identify section headers
                current_section = line
            elif current_section:  # Append data with section title
                metric, value = line.split(',')
                data.append([current_section, metric, value])

    # Group data by category and print
    grouped_data = {}
    for category, metric, value in data:
        if category not in grouped_data:
            grouped_data[category] = []
        grouped_data[category].append((metric, value))

    # Print data in formatted form
    for category, items in grouped_data.items():
        print(f"{category}")
        print("-" * 40)
        for metric, value in items:
            # Add units based on metric
            if "time" in metric:
                value = f"{value} s"
            elif "tick" in metric:
                value = f"{int(value):,} ticks"
            elif "Inst." in metric:
                value = f"{int(value):,} instructions"
            elif "cycle" in metric:
                value = f"{int(value):,} cycles"
            elif "rate" in metric:
                value = f"{float(value):.2%} miss rate"
            elif "count" in metric:
                value = f"{int(value):,} counts"

            # Adjust spacing for alignment
            print(f"{metric:<25} | {value}")
        print()  # Blank line after each category


# Main execution
if __name__ == "__main__":
    input_csv = "program_info.csv"  # Replace with your CSV file path
    print_summary(input_csv)
