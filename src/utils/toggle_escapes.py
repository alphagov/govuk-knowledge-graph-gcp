import argparse
import sys
import csv

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="""(Un)escape special characters of columns of a CSV file, via stdin, to stdout.

Example usage:
    cat myfile.csv | \\
        python src/data/toggle_escapes.py \\
            --escape_cols=text_col,other_text_col


    cat myfile.csv | \\
        python src/data/toggle_escapes.py \\
            --unescape_cols=text_col,other_text_col
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--escape_cols",
        type=str,
        required=False,
        help="Names of columns of text to escape, separated by commas, e.g. --escape_cols=text_col,other_text_col",
    )

    parser.add_argument(
        "--unescape_cols",
        type=str,
        required=False,
        help="Names of columns of text to unescape, separated by commas, e.g. --unescape_cols=text_col,other_text_col",
    )

    args = parser.parse_args()
    escape_cols = [] if args.escape_cols is None else args.escape_cols.split(",")
    unescape_cols = [] if args.unescape_cols is None else args.unescape_cols.split(",")

    reader = csv.DictReader(sys.stdin)

    writer = csv.DictWriter(sys.stdout, fieldnames=reader.fieldnames)

    writer.writeheader()

    for row in reader:
        for col in escape_cols:
            row[col] = row[col].encode('unicode-escape').decode('UTF-8')
        for col in unescape_cols:
            row[col] = row[col].encode('UTF-8').decode('unicode-escape')
        writer.writerow(row)

# s = r"""Ernő\nbar
# baz"""
# s
# print(s)
# s.encode('unicode-escape').decode('UTF-8')
# print(s.encode('unicode-escape').decode('UTF-8'))
# s.encode('unicode-escape').decode('UTF-8').encode('UTF-8').decode('unicode-escape')
# print(s.encode('unicode-escape').decode('UTF-8').encode('UTF-8').decode('unicode-escape'))
