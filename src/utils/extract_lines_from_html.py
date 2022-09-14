# Extract lines of plain text from an html column of a CSV file.  See the
# argparse description below for more explanation.

import argparse
import sys
import csv
import json
import re

from bs4 import BeautifulSoup


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="""Extract lines of text from an html field of single-line JSON documents, via stdin, to stdout.

Example usage:
    cat myfile.json | \\
      parallel \
        --pipe \
        --round-robin \
        --line-buffer \
        python src/data/extract_lines_from_html.py \
        --input_col=col_containing_html \\
        --id_cols=base_path,slug

That example will take a file of one JSON document per line, with items:
  - base_path
  - slug
  - col_containing_html

It will emit a CSV file without headers, but columns for:
  - base_path
  - slug
  - line
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--input_col",
        type=str,
        required=True,
        help="The name of the field of HTML to extract lines of text from",
    )

    parser.add_argument(
        "--id_cols",
        type=str,
        required=False,
        help="Names of columns to be preserved in the output, separated by commas, e.g. --id_cols=url slug",
    )

    args = parser.parse_args()

    input_col = args.input_col
    id_cols = [] if args.id_cols is None else args.id_cols.split(",")

    fieldnames = [*id_cols, "line"]

    # Allow the largest field size possible.
    # https://stackoverflow.com/a/15063941
    maxInt = sys.maxsize
    while True:
        # decrease the maxInt value by factor 10
        # as long as the OverflowError occurs.
        try:
            csv.field_size_limit(maxInt)
            break
        except OverflowError:
            maxInt = int(maxInt / 10)
    csv.field_size_limit(maxInt)

    writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)

    for line in sys.stdin:
        row = json.loads(line.rstrip('\n'))
        row_dict = {col_name: row[col_name] for col_name in id_cols}
        soup = BeautifulSoup(row[input_col], "lxml")
        # Replace breaks with newlines
        for br in soup("br"):
            br.replace_with("\n")
        lines = [l.strip() for l in soup.get_text().splitlines() if l.split()]
        for line in lines:
            row_dict["line"] = line
            writer.writerow(row_dict)
