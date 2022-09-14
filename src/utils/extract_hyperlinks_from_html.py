# Extract hyperlinks from an html column of a CSV file.  See the argparse
# description below for more explanation.

import argparse
import sys
import csv
import json
import re

from typing import NamedTuple
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


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="""Extract hyperlinks from an html field of single-line JSON documents, via stdin, to stdout.

Example usage:
    cat myfile.json | \\
      parallel \
        --pipe \
        --round-robin \
        --line-buffer \
        python src/data/extract_hyperlinks.py \\
            --input_col=col_containing_html \\
            --id_cols=base_path,slug

That example will take a file of one JSON document per line, with items:
  - base_path
  - slug
  - col_containing_html

It will emit a CSV file without headers, but columns for:
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
        help="The name of the field to search for hyperlinks",
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
        links = [
            Hyperlink(href=link.get("href"), text=link.get_text())
            for link in soup.findAll("a", href=True)
        ]
        for link in links:
            if len(link.href) == 0:
                url = row["url"]
            else:
                url = complete_hyperlink(link.href, row["url"])
            row_dict["link_url"] = url
            row_dict["link_url_bare"] = url.split("?")[0].split("#")[0]
            row_dict["link_text"] = link.text
            writer.writerow(row_dict)
