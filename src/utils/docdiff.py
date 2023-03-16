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
import sys
import ast


def ensure_newline(s):
    if s[-1] != "\n":
        return s + "\n"
    return s


def prepare_line(s):
    return ensure_newline(parse_line(s)).splitlines(keepends=True)


def parse_line(s):
    ast.literal_eval(s[2:-1])


path = "@"
deletion = "-"
addition = "+"
quote = '"'
symbols = {path: 4, deletion: 2, addition: 1}
lines = {path: "", deletion: "", addition: ""}
out = {}


if __name__ == "__main__":
    state = 0
    for line in sys.stdin:
        sys.stdout.writelines("\n**\n" + line + "**\n")
        symbol = line[0]
        lines[symbol] = line
        state = state ^ symbols[symbol]
        match state:
            case 4:  # @: new record
                out['path'] = parse_line(lines[path])
                sys.stdout.writelines(lines[path][2:-1])
            case 6:  # @-: wait for next symbol
                pass
            case 5:  # @+: addition, then wait for new record
                out['addition'] = parse_line(lines[addition])
                sys.stdout.writelines(lines[addition])
                state = 0
            case 7:  # @-+: update, then await new record
                # If deletion and addition are both strings, then diff
                if lines[deletion][2] == quote and lines[addition][2] == quote:
                    text1 = prepare_line(lines[deletion])
                    text2 = prepare_line(lines[addition])
                    diff_generator = difflib.unified_diff(text1, text2)
                    diff = list(diff_generator)
                    out['diff'] = diff
                    sys.stdout.writelines(diff)
                # Otherwise output the original deletion and deletion
                else:
                    out['deletion'] = parse_line(lines[deletion])
                    out['addition'] = parse_line(lines[addition])
                    sys.stdout.writelines(lines[deletion])
                    sys.stdout.writelines(lines[addition])
                state = 0
                pass
            case 2:  # @-@: delete and new record
                # Write current record
                out['deletion'] = parse_line(lines[deletion])
                sys.stdout.writelines(lines[deletion])
                json.dump(out, sys.stdout, ensure_ascii=False, indent=4)
                # Begin new record
                out = {}
                out['path'] = parse_line(lines[path])
                sys.stdout.writelines(lines[path])
                state = symbols[path]
            case _:
                raise ValueError
    # Write final record
    json.dump(out, sys.stdout, ensure_ascii=False, indent=4)
