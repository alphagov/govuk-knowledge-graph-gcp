# Extract hyperlinks from an html column of a CSV file.  See the argparse
# description below for more explanation.

import argparse
import sys
import csv
import re

from multiprocessing import Pool, Semaphore, cpu_count
from typing import NamedTuple
from functools import partial
from bs4 import BeautifulSoup


class Hyperlink(NamedTuple):
    """A hyperlink with elements `url` and `text`."""

    href: str
    text: str


def complete_hyperlink(href, from_url):
    """Prepend https://www.gov.uk" to internal links"""

    # Remove newlines from within a URL, such as in the page
    #   https://www.gov.uk/guidance/2016-key-stage-2-assessment-and-reporting-arrangements-ara/section-13-legal-requirements-and-responsibilities
    # Containing al link split over two lines:
    #   https://www.gov.uk/government/publications/teacher-assessment-
    #   moderation-requirements-for-key-stage-2\
    href = href.replace("\r", "").replace("\n", "")

    if href[0] == "/":
        return "https://www.gov.uk" + href

    if href[0] == "#":
        return from_url + href

    return href


def read_rows(semaphore, reader):
    for row in reader:
        # Reduce semaphore by 1 or wait if 0
        semaphore.acquire()
        # Now deliver an item to the caller (pool)
        yield row


def extract_hyperlinks(row, input_col):
    soup = BeautifulSoup(row[input_col], "lxml")
    links = [
        Hyperlink(href=link.get("href"), text=link.get_text())
        for link in soup.findAll("a", href=True)
    ]
    return row, links


def write_hyperlinks(semaphore, writer, row, links, id_cols):
    row_dict = {col_name: row[col_name] for col_name in id_cols}
    for link in links:
        if len(link.href) == 0:
            url = row["url"]
        else:
            url = complete_hyperlink(link.href, row["url"])
        row_dict = {col_name: row[col_name] for col_name in id_cols}
        row_dict["link_url"] = url
        row_dict["link_url_bare"] = url.split("?")[0].split("#")[0]
        row_dict["link_text"] = link.text
        writer.writerow(row_dict)
    semaphore.release()


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="""Extract hyperlinks from an html column of a CSV file, via stdin, to stdout.

Example usage:
    cat myfile.csv | \\
        python src/data/extract_hyperlinks.py \\
            --input_col=col_containing_html \\
            --id_cols=base_path,slug

That example will take a CSV file with headers:
  - base_path
  - slug
  - col_containing_html

It will emit a CSV file with headers:
  - base_path
  - slug
  - link_url
  - link_url_bare
  - link_text

One row will be emitted per URL found.  If no URL is found in an input row, then
no output row will be emitted.

New output columns:
  - link_url: the URL from the href attribute
  - link_url_bare: the URL from the href attribute, stripped of parameters and fragments
  - link_text: the text of the <a> element, visible to the user.
""",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "--input_col",
        type=str,
        required=True,
        help="The name of the column to search for hyperlinks",
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

    fieldnames = [*id_cols, "link_url", "link_url_bare", "link_text"]

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

    for row, hyperlinks in pool.imap_unordered(
        partial(extract_hyperlinks, input_col=input_col),
        read_rows(semaphore_1, reader),
    ):
        write_hyperlinks(semaphore_1, writer, row, hyperlinks, id_cols)
