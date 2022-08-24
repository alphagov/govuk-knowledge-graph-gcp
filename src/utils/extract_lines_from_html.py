# Extract lines of plain text from an html column of a CSV file.  See the
# argparse description below for more explanation.

import argparse
import sys
import csv
import re

from multiprocessing import Pool, Semaphore, cpu_count
from functools import partial
from bs4 import BeautifulSoup


def read_rows(semaphore, reader):
    for row in reader:
        # Reduce semaphore by 1 or wait if 0
        semaphore.acquire()
        # Now deliver an item to the caller (pool)
        yield row


def extract_lines(row, input_col):
    soup = BeautifulSoup(row[input_col], "lxml")

    # Replace breaks with newlines
    for br in soup("br"):
        br.replace_with("\n")

    return (row, [s.strip() for s in soup.get_text().splitlines() if s.split()])


def write_lines(semaphore, writer, row, lines, id_cols):
    row_dict = {col_name: row[col_name] for col_name in id_cols}
    for line in lines:
        row_dict["line"] = line
        writer.writerow(row_dict)
    semaphore.release()


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="""Extract lines of text from an html column of a CSV file, via stdin, to stdout.

Example usage:
    cat myfile.csv | \\
        python src/data/extract_lines.py \\
            --input_col=col_containing_html \\
            --id_cols=base_path,slug

That example will take a CSV file with headers:
  - base_path
  - slug
  - col_containing_html

It will emit a CSV file with headers:
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
        help="The name of the column of HTML to extract lines of text from",
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

    reader = csv.DictReader(sys.stdin)

    writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
    writer.writeheader()

    # Don't bother setting chunksize.  Previously, we have set it to
    # n_rows/n_processes, but we don't know n_rows before parsing the CSV file
    # (can't cheaply count newlines because the body text includes them).  Also,
    # chunksizes larger than 1 aren't necessarily faster, can be slower, and
    # there's no good heuristic to choose one, so it would be trial and error --
    # not worth it in this case.  See:
    # https://stackoverflow.com/questions/53751050
    # https://stackoverflow.com/questions/53306927
    pool = Pool(processes=cpu_count())

    # Allow a buffer of 1024 rows to build up as they are processed, written and
    # discarded. See: https://stackoverflow.com/a/47058399
    semaphore_1 = Semaphore(1024)

    for row, lines in pool.imap_unordered(
        partial(extract_lines, input_col=input_col),
        read_rows(semaphore_1, reader),
    ):
        write_lines(semaphore_1, writer, row, lines, id_cols)
