import regex

header = "README-header.md"
with open(header, "r", encoding="utf-8") as in_f:
  contents = in_f.read()

re_file_section = regex.compile(
  r'''
  ^\#\#\#\ Files\r?+\n
  (?:(?!\s*+\d++\.\s).*+(?:\n|$))*+
  ((?:(?!\#).*+(?:\n|$))*+)
  ''', regex.MULTILINE | regex.VERBOSE
)
matched = re_file_section.search(contents)
assert matched
file_section = matched[1]

re_file_items = regex.compile(
  r'''
  \s*+\d++\.\s++(\[.*\])
  (?:(?!\s*+\d++\.\s).*+(?:\n|$))*+
  ''', regex.VERBOSE
)
file_items = re_file_items.sub(r"\1 ", file_section)

re_files = regex.compile(
  r'''
  (?:.|\n)*?\[([a-zA-Z_][a-zA-Z0-9_]*?)\]
  ''', regex.VERBOSE
)
files = re_files.sub(r"\1 ", file_items)
files_list = files.rstrip().split(" ")

import subprocess
import sys

args = [
  sys.executable,
  "-Xfrozen_modules=off",
  "scad-analysis.py",
  "--show", "md",
  # "--write-to-file", "README.md",
  *files_list
]

print("Executing: " + " ".join(args))
result = subprocess.run(args, check=False, capture_output=True, text=True,
                         encoding="utf-8",
                         errors="strict"  # or "replace" if you want it to never crash
)
if result.stderr:
  print(f"STDERR:\n" + result.stderr)
else:
  with open("README.md", "w", encoding="utf-8") as f_out:
    f_out.write(contents)
    f_out.write(result.stdout)
