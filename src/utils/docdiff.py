#!python

# /src/utils/docdiff.py

# Parse the output of a json diff, e.g.
# jd -f="jd" json_1.json json_2.json | python docdiff.py
# The output is the same as the input, except when a string value has changed,
# in which case a normal diff is output instead of the json diff.

# Use a bit to represent combinations of symbols, like unix file permissions do
# to represent combinations of permissions.
# https://wiki.python.org/moin/BitwiseOperators

# | symbol| name  | bits | value |
# | ------| ----- | ---- | ----- |
# | @     | path  |  100 |  4    |
# |  -    | minus |  010 |  2    |
# |   +   | plus  |  001 |  1    |

# | state | action | bits | value | operation | next state |
# | ----- | ------ | ---- | ----- | --------- | ---------- |
# | @     | new    |  100 |     4 |         4 | @          |
# | @-    | wait   |  110 |     6 |       4^2 | @-         |
# | @+    | create |  101 |     5 |       4^1 |            |
# | @-+   | update |  111 |     7 |     4^2^1 |            |
# | @-@   | delete |  010 |     2 |     4^2^4 | @          |

import difflib
import json
import ast
import sys


def ensure_newline(s):
    if s[-1] != "\n":
        return s + "\n"
    return s


def prepare_line(s):
    return ensure_newline(parse_line(s)).splitlines(keepends=True)


def parse_line(s):
    return ast.literal_eval(s[2:-1])


path = "@"
deletion = "-"
addition = "+"
patch = "~"
quote = '"'
symbols = {path: 4, deletion: 2, addition: 1}
lines = {path: "", deletion: "", addition: ""}
json_path = ""
out = {}

if __name__ == "__main__":
    state = 0
    for line in sys.stdin:
        # sys.stdout.writelines("\n**\n" + line + "**\n")
        symbol = line[0]

        if symbol not in [path, deletion, addition]:
            sys.stdout.writelines(ensure_newline(line))
            continue

        lines[symbol] = line
        state = state ^ symbols[symbol]
        match state:
            case 4:  # @: new record
                sys.stdout.writelines(ensure_newline(lines[path][2:-1]))
                json_path = "/".join(str(x) for x in ast.literal_eval(lines[path][2:-1]))
                out[json_path] = {}
            case 6:  # @-: wait for next symbol
                pass
            case 5:  # @+: addition, then wait for new record
                sys.stdout.writelines(lines[addition])
                state = 0
                out[json_path][addition] = lines[addition][2:-1]
            case 7:  # @-+: update, then await new record
                # If deletion and addition are both strings, and neither contains a newline, then diff
                if lines[deletion][2] == quote and lines[addition][2] == quote and ("\\n" in lines[deletion][0:-1] or "\\n" in lines[addition][0:-1]):
                        text1 = prepare_line(lines[deletion])
                        text2 = prepare_line(lines[addition])
                        diff_generator = difflib.unified_diff(text1, text2)
                        diff = list(diff_generator)
                        sys.stdout.writelines(diff)
                        out[json_path][patch] = "".join(diff)
                # Otherwise output the original deletion and addition
                else:
                    sys.stdout.writelines(lines[deletion])
                    sys.stdout.writelines(lines[addition])
                    out[json_path][deletion] = lines[deletion][2:-1]
                    out[json_path][addition] = lines[addition][2:-1]
                state = 0
                pass
            case 2:  # @-@: delete and new record
                # Write current record
                sys.stdout.writelines(lines[deletion])
                out[json_path][deletion] = lines[deletion][2:-1]
                # Begin new record
                sys.stdout.writelines(lines[path])
                state = symbols[path]
            case _:
                raise ValueError
    # Write final record
    if state == 6:
        sys.stdout.writelines(lines[symbol])
        out[json_path][deletion] = lines[deletion][2:-1]

    json.dump(out, sys.stdout, ensure_ascii=False, indent=4)
