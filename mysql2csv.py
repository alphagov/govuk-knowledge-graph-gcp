#!/usr/bin/env python3
import gzip
import re
import sys

def sql_to_csv(input_stream):
    current_table = None
    output_file = None

    for line in input_stream:
        line = line.decode('utf-8')  # Decode bytes to string if reading from stdin
        table_match = re.match(r"^-- Dumping data for table `([^`]*)`$", line)
        if table_match:
            if output_file:
                output_file.close()
            current_table = table_match.group(1)
            gzip_filename = f"{current_table}.csv.gz"
            print(f"Processing table and writing to: {gzip_filename}")
            output_file = gzip.open(gzip_filename, 'wt', encoding='utf-8')
            continue

        if current_table and line.startswith("INSERT INTO `"):
            values_match = re.match(r"^INSERT INTO `[^`]*` VALUES (.*);$", line)
            if values_match:
                data = values_match.group(1)
                rows = re.findall(r"\((.*?)\)", data)
                for row in rows:
                    values = []
                    in_quotes = False
                    escaped = False
                    current_value = ""
                    for char in row:
                        if char == "'" and not escaped:
                            in_quotes = not in_quotes
                        elif char == "\\" and not escaped:
                            escaped = True
                        elif char == "," and not in_quotes:
                            values.append(current_value)
                            current_value = ""
                        else:
                            current_value += char
                            escaped = False
                    values.append(current_value)

                    csv_row = []
                    for value in values:
                        value = value.replace('"', '""')
                        if ',' in value or '"' in value:
                            csv_row.append(f'"{value}"')
                        else:
                            csv_row.append(value)
                    output_file.write(",".join(csv_row) + "\n")

    if output_file:
        output_file.close()

if __name__ == "__main__":
    if not sys.stdin.isatty():
        # Input is being piped from stdin
        sql_to_csv(sys.stdin.buffer)  # Read from stdin as bytes
    elif len(sys.argv) == 2:
        # Input is a file specified as a command-line argument
        input_sql_file = sys.argv[1]
        with open(input_sql_file, 'r', encoding='utf-8') as infile:
            sql_to_csv(infile)
    else:
        print("Usage: python sql_to_csv.py <input_sql_file> (or pipe input to stdin)")
        sys.exit(1)
