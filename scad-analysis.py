import math
import regex
import json
import hashlib
from datetime import datetime, timezone
import os
from bisect import bisect_left, bisect_right
from typing import Literal, TypeAlias, TypedDict, TypeGuard, Optional
import typing

# doc - document remark that is associated to the file only.
ItemType: TypeAlias = Literal[
  'comment' , # comment
  'use'     , # use statement
  'include' , # include statement
  'cmd'     , # top level command to execute
  'doc'     , # doc string
  'function', # function
  'module'  , # module
  'value'   , # value
  'UNKNOWN' , # shouldn't ever see this
]

NONTYPE_SYMBOLS = ("function", "module", "value")

# half-open range
CharSlice: TypeAlias = slice
# closed range
LinePair: TypeAlias = tuple[int, int]

DocItem = \
 tuple[ItemType, CharSlice]
Symbol = \
  tuple[ItemType, CharSlice, CharSlice, CharSlice, list[tuple[str, str]] | None, CharSlice]
SymWithDoc = \
  tuple[ItemType, CharSlice, CharSlice, CharSlice, list[tuple[str, str]] | None, CharSlice, CharSlice]

# ( Type_of_object, entire_obj_slice ) |
# ( Type_of_object, entire_obj_slice, id_slice, sig_slice, param_list, body_slice ) |
# ( Type_of_object, entire_obj_slice, id_slice, sig_slice, param_list, body_slice, sym_doc_slice)
ItemInfo: TypeAlias = DocItem | Symbol | SymWithDoc

DOC_TYPE         = 0
' Type '
DOC_SLC          = 1
' Document slice '
DOC_S_ID_SLC     = 2
' Symbol Id slice '
DOC_S_SIG_SLC    = 3
' Symbol Signature slice '
DOC_S_PARAM_LST  = 4
' Param symbols tuple (param_name, default) '
DOC_S_BODY_SLC   = 5
' Symbol Body slice '
DOC_S_DOC_SLC    = 6
' Symbol doc slice '

def is_doc(item: ItemInfo) -> TypeGuard[DocItem]:
  return item[DOC_TYPE] == "doc"

def is_symbol(item: ItemInfo) -> TypeGuard[Symbol]:
  return DOC_S_BODY_SLC < len(item) and item[DOC_TYPE] in NONTYPE_SYMBOLS

def is_sym_with_doc(item: ItemInfo) -> TypeGuard[SymWithDoc]:
  return DOC_S_DOC_SLC < len(item) and item[DOC_TYPE] in NONTYPE_SYMBOLS

RES_LIB = r'''
  (?!) (?# This is a list of sub-patterns.  Don't match anything directly here.)
  (?# *_mtws = pattern Matches Trailing WhiteSpace)
  (?# Regex to Parse OpenSCAD)

  (?# Double quoted string literal)
  (?<quote>"(?:[^\\"]++|\\.)*+")

  (?# Characters till unmatched opening or closing of parenthesis, brace or bracket or end of string)
  (?<chars_mtws>(?:[^{}()[\]"]++|\{(?&chars_mtws)\}|\((?&chars_mtws)\)|\[(?&chars_mtws)\]|(?&quote))*+)

  (?# Characters till [;] or unmatched opening or closing of parenthesis, brace or bracket or end of string)
  (?<cmd_chars_mtws>(?:[^;{}()[\]"]++|\{(?&chars_mtws)\}|\((?&chars_mtws)\)|\[(?&chars_mtws)\]|(?&quote))*+)

  (?# Characters till [,] or unmatched opening or closing of parenthesis, brace or bracket or end of string)
  (?<param_chars_mtws>(?:[^,{}()[\]"]++|\{(?&chars_mtws)\}|\((?&chars_mtws)\)|\[(?&chars_mtws)\]|(?&quote))*+)

  (?# Characters till [:,] or unmatched opening or closing of parenthesis, brace or bracket or end of string)
  (?<id_chars_mtws>(?:[^:,{}()[\]"]++|\{(?&chars_mtws)\}|\((?&chars_mtws)\)|\[(?&chars_mtws)\]|(?&quote))*+)

  (?# Characters till [|] or unmatched opening or closing of parenthesis, brace or bracket or end of string)
  (?<type_chars_mtws>(?:[^|{}()[\]"]++|\{(?&chars_mtws)\}|\((?&chars_mtws)\)|\[(?&chars_mtws)\]|(?&quote))*+)

  (?# doc /**...*/)
  (?<doc>           /\* (?! \*/ ) \*             (?: [^*] | \*[^/] )*+ \*/ )
  (?# block comment /*...*/)
  (?<block_comment> /\*       (?: \*/ | (?! \* ) (?: [^*] | \*[^/] )*+ \*/ ))
  (?# one or more line comments //...)
  (?<line_comment> (?:\s*+//.*+\n)++ )
  (?# either block or line comment)
  (?<comment>(?&block_comment)|(?&line_comment))

  (?# using file)
  (?<use>use\s*+<[^>]++>)
  (?# including file)
  (?<include>include\s*+<[^>]++>)

  (?# symbol name)
  (?<symbol>[a-zA-Z_][a-zA-Z_\d]*+)

  (?# command)
  (?<cmd>(?&cmd_chars_mtws);)

  (?<param_mtws>
    (?<p_name>(?&symbol))\s*+
    (?:
      (?# default specified )
      = \s*+
      (?<p_default>  (?&param_chars_mtws)) (?&to_next_param)
    | (?# default not specified )
      (?<p_default>)                       (?&to_next_param)
    )
    \s*+
  )
  (?<to_next_param> , | )

  (?# value definition)
  (?<value>
    (?<sig>(?<id>(?&symbol))) \s*+
    =
    (?<body>
      \s*+
      (?<is_lambda> function \s*+ \( (?&param_mtws)*+ \) )?+
      (?&cmd_chars_mtws)
    );
  )

  (?# function signature)
  (?<function_sig>(?<sig>function \s++ (?<id>(?&symbol)) \s*+ \((?&param_mtws)*+\)))
  (?# function signature and body)
  (?<function>(?&function_sig) \s*+ = (?<body>(?&cmd_chars_mtws));)

  (?# module signature)
  (?<module_sig>(?<sig>module \s++ (?<id>(?&symbol)) \s*+ \((?&param_mtws)*+\)))
  (?# module signature and body)
  (?<module>(?&module_sig) \s*+ \{ (?<body>(?&chars_mtws)) \})
'''

def mtime_to_utc(mtime: float) -> str:
  """
  Converts a modification time to a UTC datetime string.

  Args:
    mtime (float): The modification time as a Unix timestamp.

  Returns:
    str: A string representing the time in UTC (format: 'YYYY-MM-DD HH:MM:SS GMT+0000').
  """
  # Convert the timestamp to a datetime object in UTC
  gmt_datetime = datetime.fromtimestamp(mtime, tz=timezone.utc)
  return gmt_datetime.strftime('%Y-%m-%d %H:%M:%S GMT%z')

def get_line_positions(content: str) -> list[int]:
  '''
  Return a list that gives a character starting position for each line.

  Parameters
  ----------
  content: string
    The string to process.

  Returns
  -------
  list of int
    The list contains the starting character position of each line.
  '''
  assert isinstance(content, str)

  RE_LINE = regex.compile(r'.*+\n?+')

  positions: list[int] = []

  for m in RE_LINE.finditer(content):
    start, end = m.span()

    # Skip the final empty match at end-of-string
    if start == end == len(content):
      break

    positions.append(start)

  return positions

def get_items(content: str) -> list[ItemInfo]:
  '''
  Gets a list of item info found in the content.

  Parameters
  ----------
  content: str
    The content to process.

  Returns
  -------
  list[ItemInfo]
    A list of the item information for all of the items.
  '''
  assert isinstance(content, str)

  RE_ITEM = regex.compile(
    # lib_res + "|"
    r'''
      \G\s*+
      (
          (?<is_comment>  (?&comment))
        | (?<is_use>      (?&use))
        | (?<is_include>  (?&include))
        | (?<is_doc>      (?&doc))
        | (?<is_function> (?&function))
        | (?<is_module>   (?&module))
        | (?<is_value>    (?&value))
        | (?<is_cmd>      (?&cmd))
      ) \s*+
    '''
    '|' + RES_LIB
    , regex.VERBOSE)

  items: list[ItemInfo] = []

  for m in RE_ITEM.finditer(content):
    slc = slice(*m.span(1))

    found = \
     "comment"  if m.group('is_comment')  else \
     "use"      if m.group('is_use')      else \
     "include"  if m.group('is_include')  else \
     "cmd"      if m.group('is_cmd')      else \
     "doc"      if m.group('is_doc')      else \
     "function" if m.group('is_function') else \
     "module"   if m.group('is_module')   else \
     "value"    if m.group('is_value')    else \
     "UNKNOWN"

    result: ItemInfo
    # RE_BREAKDOWN = breakdown_types.get(found)
    if found in NONTYPE_SYMBOLS:
      # m = RE_BREAKDOWN.match(content, slc.start, slc.stop)
      # assert m
      if items and items[-1][DOC_TYPE] == "doc":
        last = items.pop()
        result = (found, slc, slice(*m.spans('id')[0]), slice(*m.spans('sig')[0]), params_as_list(m), slice(*m.spans('body')[0]), last[DOC_SLC])
      else:
        result = (found, slc, slice(*m.spans('id')[0]), slice(*m.spans('sig')[0]), params_as_list(m), slice(*m.spans('body')[0]))
    else:
      result = (found, slc)
    items.append(result)

  return items

def params_as_list(m: regex.Match[str]) -> list[tuple[str, str]] | None:
  """ Convert parameters matched in regex to list of names with defaults

  Parameters
  ----------
  m : regex.Match[str]
      matches generated

  Returns
  -------
  list[tuple[str, str]] | None
      A list of (name, default) tuples or None if not declared a callable at top
      level.
  """
  if not (m.spans('is_function') or m.spans('is_module') or m.spans('is_lambda')):
    # not a function, module or top level lambda
    return None
  if not m.spans('p_name'):
    assert not m.spans('p_default'), "regex error"
    return []
  assert len(m.spans('p_name')) == len(m.spans('p_default')), "regex error"
  result = [ (param, default) for param, default in zip(*m.captures('p_name', 'p_default')) ]
  assert len(m.spans('p_name')) == len(result)
  return result

def get_lines(charRange: CharSlice, lines: list[int]) -> LinePair:
  '''
  Converts a character slice (half-open range) to a line pair (closed range).

  Parameters
  ----------
  charRange: CharSlice
    A slice with start and stop character positions.
  lines: list[int]
    Line start indices (from get_line_positions).

  Returns
  -------
  LinePair
    Closed line range pair (1-indexed).
  '''
  start = charRange.start
  stop  = charRange.stop
  return (
    bisect_left(lines, start)+1, bisect_right(lines, stop-1)
  )

# Start of program

import argparse
import sys

# Force utf-8 stdin/stdout
sys.stdout.reconfigure(encoding="utf-8", errors="strict") # pyright: ignore[reportAttributeAccessIssue]
sys.stderr.reconfigure(encoding="utf-8", errors="strict") # pyright: ignore[reportAttributeAccessIssue]

Showing: TypeAlias = Literal[
  "id"              , # Show only the ids
  "sig"             , # Show only the signatures
  "sig-doc"         , # Shows the docs and sigs
  "body"            , # Show only the body (no leading = or { and no trailing ; or })
  "code"            , # Show only the code (signature and body, including the ending ; or })
  "md"              , # Show as a md file, excluding private values and functions.
  "md-with-private" , # Show as a md file, including private values and functions.
  "all"             , # Show all symbol info
  "summary"         , # Show symbol sigs with the line or lines that it encompasses.
  "json"            , # Show symbol info in json format.
]

class OptionDict(TypedDict):
  showLineNums: bool
  show         : Showing
  id           : str | None

options: OptionDict = {
  "showLineNums": False,
  "show"        : "sig-doc",
  "id"          : None,
}

# ---- command-line parsing ----

parser = argparse.ArgumentParser(
  description="Show OpenSCAD symbols and docs from one or more source files.",
  formatter_class=argparse.RawTextHelpFormatter,
  epilog=(
    'Values for --show:\n'
    '  id              Show only the ids\n'
    '  sig             Show only the signatures\n'
    '  sig-doc         Show signature on line before associated doc.\n'
    '  body            Show only the body (no leading = or { or no trailing ; or })\n'
    '  code            Show signature and body, includes trailing ; or }\n'
    '  md              Show as markdown, excluding private symbols\n'
    '  md-with-private Show as markdown, including private symbols\n'
    '  all             Show all symbol info\n'
    '  summary         Show symbol sigs with the line or lines that it encompasses.\n'
    '  json            Show symbol info in json format.\n'
    '\n'
    'The json struct when using --show json:\n'
    '    {\n'
    '      "ids": {\n'
    '        "<id>": {\n'
    '          "filename"  : "<filename>",\n'
    '          "order"     : <found-order-in-file>,\n'
    '          "name"      : "<id>",\n'
    '          "type"      : ("function" | "module" | "value"),\n'
    '          "line_start": <start-line>,\n'
    '          "line_end"  : <end-line>,\n'
    '          "signature" : "<sig>",\n'
    '          "body"      : "<body>",\n'
    '          "doc"       : "<symbol-doc>",\n'
    '        },\n'
    '        ...\n'
    '      }\n'
    '      "filenames": {\n'
    '        "<filename>" : {\n'
    '          "order"  : <processed-order>,\n'
    '          "docs"   : [ [ <found-order-in-file>, "<file-doc>" ], ... ],\n'
    '          "symbols": [ "<symbol-id>", ... ],\n'
    '          "hash"   : "<file-sha256-hash>\n'
    '          "mtime"  : "<gmt-time-stamp-for-file>'
    '        ...\n'
    '      },\n'
    '      "hash_algo"    : "<hash-algorithm-used-in-struct>",\n'
    '      "combined_hash": "<combined-file-sha256-hash>"\n'
    '      "mtime"        : "<time-stamp-for-youngest-file>"\n'
    '    }\n'
  ),
)

parser.add_argument(
  "filenames",
  nargs="*",
  help="Files to analyse. If omitted, read from stdin.",
)

parser.add_argument(
  "--show",
  choices=[
    "id",
    "sig",
    "sig-doc",
    "body",
    "code",
    "md",
    "md-with-private",
    "all",
    "summary",
    "json",
  ],
  default=options["show"],
  help="What to show (default: %(default)s).",
)

parser.add_argument(
  "--id",
  dest="id",
  default=options["id"],
  help="Filter by symbol name (id).",
)

# line-number flags
parser.add_argument(
  "--line-nums",
  dest="showLineNums",
  action="store_true",
  help="Show line numbers.",
)

parser.set_defaults(showLineNums=options["showLineNums"])

# write-to-files
parser.add_argument(
  "--write-to-files",
  metavar="EXT",
  dest="write_ext",
  help="Write each file's output to <filename>.EXT instead of stdout.",
)

# write-to-file
parser.add_argument(
  "--write-to-file",
  metavar="OUTFILE",
  dest="out_file",
  help="Write each file's output to OUTFILE instead of stdout.",
)

args = parser.parse_args()

if args.write_ext is not None and args.out_file is not None:
  parser.error("Cannot use --write-to-files and --write-to-file at the same time")

# ---- validation of write_ext and stdin mode ----

# Reject empty extension - dangerous on Windows (".ext" => may hit original file).
if args.write_ext is not None and args.write_ext.strip() == "":
  parser.error("--write-to-files EXT requires a non-empty EXT")

# Disallow --write-to-files when reading from stdin
if not args.filenames and args.write_ext is not None:
  parser.error("--write-to-files is invalid when reading from stdin")

# Copy to options
options["show"]         = args.show          # type: ignore[assignment]
options["id"]           = args.id
options["showLineNums"] = args.showLineNums

# ---- regexes for .md conversion ----
RE_J_DOC_BOX = regex.compile(
  r'''
  (?:
    ^(?:/\*\*\ *+\r?+\n?+|\ \*(?:\ *+$|\ )) (?# Line leading "/** ", "/**\n" or " * ")
    | \ ++\*/\r?+\n?+                       (?# Trailing " */\n")
  )
  ''', regex.VERBOSE | regex.MULTILINE
)
"Used with .sub('') to remove the doc comment block around the doc"
RE_DOC = regex.compile(
  r"""
    ^(?:
        (?<callback>@)callback[\t ]++(?<id>(?&symbol))
      | (?<typedef> @)typedef[\t ]++
        \{
        (?<aliased> (?&chars_mtws))
        \}
        [\t ]++(?<id>(?&symbol))
    )
    (?:\ *+\n)*+
    (?<body>(?:.++|\n++)*+)
  |""" + RES_LIB, regex.VERBOSE
)

RE_TYPE = regex.compile(
  r"""
    ^(?<type>    @)type\    \{(?<value_type>(?&chars_mtws))\}
    (?:\ *+\n)*+
    (?<body>(?:.++|\n++)*+)
  |""" + RES_LIB, regex.VERBOSE
)


# ---- per-file processing ----
class TrackIds(TypedDict):
  filename   : str
  order      : int
  name       : str
  type       : str
  line_start : int
  line_end   : int
  signature  : str
  body       : str
  doc        : str

class TrackFileDoc(TypedDict):
  order   : int
  docs    : list[tuple[int, str]] # list of (order, doc_str)
  symbols : list[str]
  hash    : str
  mtime   : str

class Track(TypedDict):
  filenames: dict[str, TrackFileDoc]
  ids      : dict[str, TrackIds]

class TrackFull(Track):
  combined_hash: str
  hash_algo    : str
  mtime        : str

from abc import ABC, abstractmethod

def make_anchor(prefix: str, id: str):
  return f"<a id='{prefix}-{id}'></a>"

# `any` isn't builtin, but it's not to be linked to
# `...` is just a placeholder
BUILTIN_TYPES: set[str] = set(["number", "string", "list", "undef", "function", "bool", "any", "..."])

class Doc:
  """
  This parses any document or nontype symbol without document so that it can
  generate a markdown compatible output.

  Typedefed types will override the documentation of the aliased type unless
  the typedefed documentation contains a @aliaseddoc tag which will be replaced
  with the aliased documentation (relates to main and returned doc only).
  """

  RE_FN_DOC = regex.compile(
    r'''
    \A
      (?:(?<HEADER_MATCHED>(?&HEADER)))?+(?# 0..1 header, must be at char 0 if present )
      (?:(?<CC_MATCHED>
        (?(HEADER_MATCHED)(?&empty_line))
        (?&CALLCHAIN)))*+                (?# 0..N callchains, must be contiguous )
      (?(CC_MATCHED)(?&empty_line))      (?# consume blank lines after callchains if present )
      (?:(?&DOC_DESC))?+                 (?# 0..1 doc-level description block )
      (?:
          (?(CC_MATCHED)(?!))            (?# if has callchain, then can't be slotted object )
          (?:(?&SLOT))++                 (?# slots path )
        |
          (?:(?&PARAM))*+                (?# params path )
          (?:(?&RETURNS))?+              (?# optional returns )
      )

    | (?!)

    (?<at_bol>(?<=\n|^))
    (?<eol>(?:\r?+\n|\Z))
    (?<line_tail_mtws>[^\r\n]*+)

    (?<ws>[\t ]++)
    (?<empty_line>(?:\r?+\n))
    
    (?# recognised tag sentinel used to stop description blocks )
    (?<is_recognised_tag>@(?:type|callback|typedef|callchain|slot|param|returns)[\t ])
    (?<is_rec_tag_bol>(?&at_bol)(?&is_recognised_tag))

    (?# consume lines until the next recognised tag at BOL )
    (?<to_rec_tag0> (?: (?!(?&is_rec_tag_bol)) .*+ (?&eol))*+ )   (?# 0+ lines )
    (?<to_rec_tag1> (?: (?!(?&is_rec_tag_bol)) .*+ (?&eol))++ )   (?# 1+ lines )

    (?# {type} capture must always capture something )
    (?<type_req>                    \{ (?<type>(?&chars_mtws)) \} )
    (?<type_opt>        (?&type_req) | (?<type>) )
    (?<type_none> (?!\{)               (?<type>) )

    (?# header: @type requires {type}.  @callback forbids {type}. )
    (?<HEADER>
      @
      (?:
         (?# Type id for a @type comes from the symbol being documented )
                  (?<tag>type)      (?&ws) (?&type_req)           (?<id>)           (?&eol)
        |         (?<tag>typedef)   (?&ws) (?&type_opt)  (?&ws)?+ (?<id>(?&symbol)) (?&eol)
        |         (?<tag>callback)  (?&ws) (?&type_none)          (?<id>(?&symbol)) (?&eol)
      )
      (?<desc>)
    )

    (?<CALLCHAIN>
      (?&at_bol) @(?<tag>callchain) (?&ws) (?&type_none)          (?<id>)
      (?<desc>(?&line_tail_mtws))                                                   (?&eol)
    )

    (?# doc-level description "item": empty tag/type/id, desc is the block.
        Not using type_none as it is possible [though unlikely] that description
        could start with `{`
    )
    (?<DOC_DESC>  (?<tag>)                  (?<type>)             (?<id>)
      (?&empty_line)?+
      (?<desc>(?&to_rec_tag0))
    )

    (?<SLOT>
      (?&at_bol) @(?<tag>slot)      (?&ws) (?&type_opt) (?&ws)?+
      (?:
          \[ (?<id>(?&symbol)|\d++) \s*+ (?: = \s*+ (?&id_chars_mtws))?+ \s*+ \] (?# optional slot )
           | (?<id>(?&symbol)|\d++)                                              (?# required slot )
      ) (?&eol)
      (?&empty_line)?+(?<desc>(?&to_rec_tag0))
    )

    (?<PARAM>
      (?&at_bol) @(?<tag>param)     (?&ws) (?&type_opt) (?&ws)?+
      (?:
        \[ \s*+ (?<id>(?&symbol)) \s*+ (?: = \s*+ (?&id_chars_mtws))?+ \s*+ \] (?# optional param with or without default)
      | (?<id>(?&symbol))                                                      (?# required param)
      )
      (?&eol)
      (?&empty_line)?+(?<desc>(?&to_rec_tag0))
    )

    (?<RETURNS>
      (?&at_bol) @(?<tag>returns)   (?&ws) (?&type_opt) (?&ws)?+  (?<id>)           (?&eol)
      (?&empty_line)?+(?<desc>(?&to_rec_tag0))
    )
    ''' + RES_LIB, regex.VERBOSE
  )
  """
  This regex will generate parallel arrays in the match named tag/type/id/desc.
  Reading off the parallel array, the tags will appear in the following order.
  Row/columns with:
    - `R` means that the column for that tag is required.
    - `O` means that the column for that tag is optional.
    - `O*` means optional with caveat.  See Assertions for more details.
    - `` means that the column should be empty.
  Tag <empty> is the symbol's description.
  A type that wasn't specified should read as "???" in output, meaning unknown.

  tag         | type | id | desc | Assertions
  ------------|------|----|------|-----------------
  "callchain" |      |    |   O  | Must start at index 0.
  "type"      |   R  |    |   O  | Must start at index 0 or follow callchains.
  "typedef"   |   O  |  R |   O  | Must start at index 0 or follow callchains.
  "callback"  |      |  R |   O  | Must start at index 0 or follow callchains.
  <empty>     |      |    |   O  | Must start at index 0 or follow an item above.
  "slot"      |   O  |  R |   O  | Must follow itself or an item above.
  "param"     |   O  |  R |   O  | Must follow itself or an item above, except
              |      |    |      | for slot.
  "returns"   |  *O  |    |   O  | Must follow an item above, except for slot.
              |      |    |      | *If callchain defined, then this is required.

  Example of my JSDoc variant:

  /**
   * ### filename
   *
   * #### Purpose
   *
   * This is an example of a test doc of `filename`.
   *
   * #### Does foo
   */

  /**
   * Function doc.  Module docs will have the same format except there wouldn't
   * ever be any returns tag.
   *
   * @param {number} p1
   *   Param 1 is required
   * @param {UserType} [p2=xyz]
   *   Param 2 is optional with default
   * @param {number} [p3]
   *   Param 3 is optional (default is `undef`)
   *
   * @returns {list}
   *   Returns a list for some reason.  This returns tag can be omitted for
   *   functions that just do checks.
   */
   function fn1(p1, p2, p3) = ...;
  
  /**
   * @callback Cb1
   *
   * @param {number} [p3]
   *   Param 3 is optional (default is `undef`).  Since the function doesn't
   *   actually take a p3 parameter, this should cause an assertion to be
   *   reported to the user.
   *
   * @returns {list}
   *   Returns a list for some reason.
   */
   
  /** @typedef {list} UserType
   *
   *  Some user type
   *
   *  @slot {number} VAL1
   *    This is value 1.
   *  @slot {list} LST1
   *    This is list 1.
   */

  /**
   * @callback Cb2
   *
   * @param {UserType} [p2=xyz]
   *   Param 2 is optional with default
   *
   * @returns {Cb1}
   *   Returns lambda that is described by callback definitions.  If just one
   *   of the return types return a callback, will autogenerate the callchains
   *   for *all* return types.
   */
   
  /**
   * @callchain fn2(p1, p2) (p3) : (number|undef)
   * @callchain fn2(p1) (p2) (p3) : (number|undef)
   *
   * This shows optional callchains.  If the function returns lambdas, and
   * doesn't specify callchains, then would autogenerate them in the doc.
   *
   * @param {number} p1
   *   Param 1 is required
   * @param {UserType} [p2=xyz]
   *   Param 2 is optional with default
   * @param {number} [p3]
   *   Param 3 is optional (default is `undef`).  Since the function doesn't
   *   actually take a p3 parameter, this should cause an assertion to be
   *   reported to the user.
   *
   * @returns {(Cb1|Cb2)}
   *   Returns lambdas that are described by callback definitions.  If just one
   *   of the return types return a callback, will autogenerate the callchains
   *   for *all* return types.
   */
   function fn2(p1, p2) = ...;
  
  /** #### Does bar */

  /**
   * @type {number}
   *
   * This describes a type for a value.
   */
   value1 = ...;
  
  /**
   * @type {function}
   *
   * This describes a value being assigned a lambda.
   *
   * @param {number} p1
   *
   * @returns {number}
   */
   lambda1 = ...;

  /**
   * @type {function}
   *
   * This describes a value being assigned a lambda that starts with `function`.
   * Parameter names will be checked against the function parameters.
   *
   * @param {number} p1
   *   This should raise an assertion since the name doesn't correspond.
   *
   * @returns {number}
   */
   lambda2 = function(p2) ...;

  /**
   * @typedef {Cb1} Cb3
   *
   * This is an alias of Cb1.  This doc will supersede any doc in Cb1.  If a
   *
   * @aliaseddoc
   *
   * tag appears, then the aliased description documentation will replace that
   * tag.  If no function description is specified, will assume that aliaseddoc
   * tag was stated.
   *
   * @returns {list}
   *   This is the new returned type.  Would be nice if this caused an error if
   *   this type wasn't the same or narrower than the actual aliased return
   *   type.
   *
   *   Like the function description, will also accept the aliaseddoc tag which
   *   would be replaced by the aliased returns tag description.
   */
  
  Here is some example output, which is incomplete based on my original output
  from Outputable commented out hierarchy.

  ### filename
  
  #### Purpose
  
  This is an example of a test doc of `filename`.
  
  #### Does foo

  #####  <a id="#f-fn1">**fn1**</a>

  *function* fn1(p1, p2, p3)

  Function doc.  Module docs will have the same format except there wouldn't
  ever be any returns tag.
  
  <details><summary>parameters</summary>
  
  ##### `p1`: <code>number</code>
  Param 1 is required

  ##### `p2`: <code><a href="#t-UserType">UserType</a></code> **Default: `xyz`**
  Param 2 is optional with default

  ##### `p3`: <code>number</code> **Optional**
  Param 3 is optional (default is `undef`)
  </details>
  
  <details><summary>return info</summary>
  ##### **Returns**: <code>list</code>
  Returns a list for some reason.  This returns tag can be omitted for
  functions that just do checks.
  </details>
  
  ...
  """

  id: Optional[str]
  "symbol or type id or None if file doc"
  doc_item: ItemInfo
  "Related document item"
  content: str
  "File content"

  DocHeader: TypeAlias = Literal[ "type", "typedef", "callback", "nontype", "file", "none" ]
  doc_type: "Doc.DocHeader"
  "Indicates what kind of document this is"

  Tag: TypeAlias = Literal[ "header", "callchain", "desc", "slot", "param", "returns" ]
  items : dict["Doc.Tag", list[tuple[str,str,str]]]
  "A dictionary that describes the doc"
    
  TYPE = 0
  ID   = 1
  DESC = 2
  ATTR = ("type", "id", "desc")

  @staticmethod
  def is_tag(tag: str) -> TypeGuard["Doc.Tag"]:
    return tag in typing.get_args(Doc.Tag)
  
  @staticmethod
  def is_doc_type(doc_type: str) -> TypeGuard["Doc.DocHeader"]:
    return doc_type in typing.get_args(Doc.DocHeader)
  
  def e(self, msg: str):
    return f"{self.filename}{f':{self.id}' if self.id else ''}{get_lines(self.doc_item[DOC_SLC], line_char_index)}: {msg}"

  ICONS = {
    "> WARNING:": "> ⚠️ WARNING:",
    "> NOTE:":    "> ℹ️ NOTE:",
    "> TTA:":     "> 🤔 TO THINK ABOUT:",
    "> TODO:":    "> 📌 TO DO:"
  }

  def __init__(self, filename: str, content: str, doc_item: ItemInfo) -> None:
    self.filename = filename
    self.content  = content
    self.doc_item = doc_item

    # There are three things that this could be.
    # 1. A file doc (has no id)
    # 2. A nontype symbol without doc
    # 3. A document of a nontype or type symbol

    self.id = None
    sym_and_doc = is_sym_with_doc(doc_item)
    if is_symbol(doc_item):
      self.id = content[doc_item[DOC_S_ID_SLC]]
      if not sym_and_doc:
        self.doc_type = "none"
        return
        
    doc: str = content[doc_item[DOC_S_DOC_SLC]] if sym_and_doc else content[doc_item[DOC_SLC]]
    # remove line leading "/**", " * ", " */"
    doc = RE_J_DOC_BOX.sub("", doc)

    for find, replace in Doc.ICONS.items():
      doc = doc.replace(find, replace)

    m = self.RE_FN_DOC.match(doc, partial=True)

    assert m, self.e(f"Failed to parse any of:\n`{doc}`.")
    assert not m.partial, self.e(f"Expected more text at end of doc:\n`{doc}`.")
    assert m.end() == len(doc), self.e(f"JSDoc parse failed:\n`{doc[0:m.end()]}`\n"
      f"**FAILED HERE**\n`{doc[m.end():]}`.")

    tags = m.captures("tag")
    assert sym_and_doc or len(tags), self.e("Why bother have a symbol doc with no info in it?")
    assert all(len(tags) == len(m.captures(col)) for col in self.ATTR), \
      self.e("Regex is not creating same length parallel arrays.")

    self.items = {
      "header":    [], # Only one header: type, typedef, callback, nontype
                       #   type populates:      TYPE, ID, *DESC
                       #   typedef populates:  *TYPE, ID, *DESC
                       #   callback populates:        ID, *DESC
                       #   nontype populates:         ID, *DESC
      "callchain": [], # Can be used with headers: type, typedef, callback, nontype
                       #   Populates:                      DESC
      "desc":      [], # Can be used with headers: type, typedef, callback, nontype, file
                       #   Populates:                      DESC
      "slot":      [], # Can be used with headers: type, typedef
                       #   Populates:          *TYPE, ID, *DESC
      "param":     [], # Can be used with headers: type, typedef, callback, nontype
                       #   Populates:          *TYPE, ID, *DESC
      "returns":   []  # Can be used with headers: type, typedef, callback, nontype
                       #   Populates:          *TYPE,     *DESC
    }
    self.doc_type = "nontype"
    for i in range(len(tags)):
      if tags[i] in typing.get_args(Doc.DocHeader):
        assert self.doc_type == "nontype", self.e("Should only ever get a DocHeader item once.")
        header_tag = tags[i]
        assert Doc.is_doc_type(header_tag)
        self.doc_type = header_tag
        tag = "header"
        if not self.id:
          self.id = m.captures("id")[i]
      else:
        tag = tags[i] if tags[i] else "desc"

      assert Doc.is_tag(tag)
      self.items[tag].append(
        (m.captures("type")[i], m.captures("id")[i], m.captures("desc")[i])
      )

    assert not self.items["callchain"] or self.items["returns"] and self.items["returns"][0][self.TYPE], \
      self.e("If any @callchain tags are defined, then a @returns tag and its type must also be defined.")
    
    if sym_and_doc:
      self.verify_sig_with_doc(doc_item)
      
      if self.doc_type == "nontype":
        sym_id = content[doc_item[DOC_S_ID_SLC]]
        sig = content[doc_item[DOC_S_SIG_SLC]]
        if sig.startswith("function "):
          symbols.function_dict[sym_id] = self
        elif sig.startswith("module "):
          symbols.module_dict[sym_id] = self
        else:
          symbols.value_dict[sym_id] = self

    elif self.items["header"]:
        sym_id = self.items["header"][0][Doc.ID]
        symbols.type_dict[sym_id] = self
        symbols.type_list.append(self)

    else:
      for tag, info in self.items.items():
        assert tag == "desc" or len(info) == 0, self.e(
          f"Logic error. Tag {tag} found where it shouldn't exist.")
      self.doc_type = "file"

  def verify_sig_with_doc(self, doc_item: SymWithDoc):
    declared_params = doc_item[DOC_S_PARAM_LST]
    if declared_params is None:
      return
    
    documented_params = self.items["param"]
    if len(documented_params) > len(declared_params):
      # There are more parameter documented then were found declared.
      # Possible legit reasons:
      # - Function not specified at top level
      assert len(declared_params) == 0, \
         self.e(f"ERROR: Symbol {self.content[doc_item[DOC_S_ID_SLC]]}"
           " is documenting more callable parameters than are available.")

    for i, ((_, doc_param, _), (declared_param, _)) in enumerate(zip(documented_params, declared_params)):
      assert declared_param == doc_param, \
        f"ERROR: Symbol '{self.filename}::{self.content[doc_item[DOC_S_ID_SLC]]}' named declared param '{declared_param}' at pos {i}, doesn't match documented param '{doc_param}'."

    if len(documented_params) < len(declared_params):
      # Not all parameters are documented.  Possible legit reasons:
      # - Lazy or don't want to document
      print(f"WARNING: Symbol {self.filename}::{self.content[doc_item[DOC_S_ID_SLC]]} isn't documenting all callable parameters.",
            file=sys.stderr)

  RE_FUNC = regex.compile(
    r"""
    function\((?<params>(?&chars_mtws))\)\s*+
    (?: : \s*+(?<rets>.*+))?+
    |""" + RES_LIB, regex.VERBOSE
  )
  """ split up function types """
  RE_PARAMS = regex.compile(
    r"""
    \s*+
    (?:
      (?<id>  (?&symbol))
      : \s*+
    )?+
      (?<type>.(?&param_chars_mtws))
    (?:,|$)
    |""" + RES_LIB, regex.VERBOSE
  )
  """ split up parameter types """

  def _link_type(self, type_name: str, use_full_fn_type: bool) -> str:
    type_name = type_name.strip()

    if type_name.startswith("function"):
      matched = Doc.RE_FUNC.match(type_name)
      if not matched:
        return type_name

      s = "function"
      if use_full_fn_type:
        s += "("
        for i, p_matched in enumerate(Doc.RE_PARAMS.finditer(matched["params"])):
          if i:
            s += ", "
          if p_matched["id"]:
            s += p_matched["id"].rstrip() + ": "
          s += self.link_types(p_matched["type"].rstrip(), use_full_fn_type)
        s += ")"

        if matched["rets"]:
          s += ": "
          rets = matched["rets"]
          if rets.startswith("("):
            rets = rets.rstrip()[1:-1]
          else:
            rets = rets.rstrip()
          rets = "(" + rets + ")"
          s += self.link_types(rets, use_full_fn_type)

      return s

    if type_name not in BUILTIN_TYPES:
      assert type_name in symbols.type_dict, (
        f"ERROR: Symbol '{self.filename}::{self.id}' uses type '{type_name}' "
        "which has not been defined yet."
      )
      symbols.type_refed.add(type_name)
      return f'<a href="#t-{type_name}">{type_name}</a>'

    return type_name

  RE_SEP_TYPES = regex.compile(
    r"""
    \G(?<type>(?&type_chars_mtws))[|)]
    |""" + RES_LIB, regex.VERBOSE
  )
  """ split up union types """
  RE_SEP_LIST_TYPES = regex.compile(
    r"""
    \G(?<type>(?&param_chars_mtws))[,\]]
    |""" + RES_LIB, regex.VERBOSE
  )
  """ split up list types """

  def link_types(self, type_group: str, use_full_fn_type: bool = True) -> str:
    type_group = type_group.rstrip()

    if type_group.startswith("list["):
      ids: list[str] = []
      for id_matched in Doc.RE_SEP_LIST_TYPES.finditer(type_group, 5):
        ids.append(self.link_types(id_matched["type"], use_full_fn_type))
      # Prevent markdown linter from complaining about no link definition found
      return "list\\[" + ",".join(ids) + "]"

    if type_group.startswith("("):
      ids: list[str] = []
      for id_matched in Doc.RE_SEP_TYPES.finditer(type_group, 1):
        ids.append(self.link_types(id_matched["type"].strip(), use_full_fn_type))

      from itertools import groupby
      return "|".join(str(k) for k, _ in groupby(ids))

    return self._link_type(type_group, use_full_fn_type)

  def output_sig(self, output_lines: list[str], id_override: Optional[str]):
    """
    Outputs the signature.
    
    Examples:
    
      If a doc:
        If a callback:
          * @callback <id>
          * @param {t0} p0
          * ...
          * @param {tN} pN
          *
          * @returns {ret_type}

          `*callback* <id>(<p0>: <t0>, ..., <pN>: <tN>) : <ret_type>`

        else if not aliasing a single callback:
          * @typedef {<type>} <id>

          `*type* <id> = <type>`
        else:
          * @typedef {<type>} <id>

          `*callback* <id>(<p0>: <t0>, ..., <pN>: <tN>) : <ret_type>`

      else if a value with a doc:
        * @type {<type>}
        <id> = ...;

        `*value* <id>:<type>`
      else if a value without a doc:
        `*value* <id>:???`
      else if a function with doc and <ret_type> defined:
        * @param {t0} p0
        * ...
        * @param {tN} pN
        * 
        * @returns {ret_type}
        function <id>(<p0>, ..., <pN>) = ...;

        `*function* <id>(<p0>: <t0>, ..., <pN>: <tN>) : <ret_type>`
      else if a function with doc and <ret_type> is not defined:
        * @param {t0} p0
        * ...
        * @param {tN} pN
        function <id>(<p0>, ..., <pN>) = ...;

        `*function* <id>(<p0>: <t0>, ..., <pN>: <tN>)`
      else if a module with doc:
        @param {t0} p0
        ...
        @param {tN} pN

        `*module* <id>(<p0>: <t0>, ..., <pN>: <tN>)`
        module <id>(<p0>, ..., <pN>) = ...;
      else if a function without doc:
        function <id>(<p0>, ..., <pN>) = ...;

        `*function* <id>(<p0>, ..., <pN>)`
      else if a module without doc:
        module <id>(<p0>, ..., <pN>) = ...;

        `*module* <id>(<p0>, ..., <pN>)`


    Parameters
    ----------
    output_lines : list[str]
        Where the documentation is appended to.
    id_override : Optional[str]
        Used with typedef to override the id for a callback.
    """
    id = id_override if id_override else self.id

    if self.doc_type == "callback":
      # callback signature from params and returns
      sig = f"*callback* {id}("
      params = []
      for (ptype, pid, _) in self.items["param"]:
        param_str = f"{pid.replace("_", "\\_")}"
        if ptype:
          param_str += f": {self.link_types(ptype, False)}"
        params.append(param_str)
      sig += ", ".join(params) + ")"

      if self.items["returns"] and self.items["returns"][0][Doc.TYPE]:
        ret_type = self.items["returns"][0][Doc.TYPE]
        sig += f" : {self.link_types(ret_type)}"

      output_lines.append(f"<code>{sig}</code>")

    elif self.doc_type == "typedef":
      # check if aliasing a single callback
      type_name = self.items["header"][0][Doc.TYPE] if self.items["header"] else ""
      if type_name and type_name in symbols.type_dict:
        aliased = symbols.type_dict[type_name]
        if aliased.doc_type == "callback":
          # output as callback with id_override
          aliased.output_sig(output_lines, id)
          return

      # regular typedef
      sig = f"*type* {id}"
      if type_name:
        sig += f" = {self.link_types(type_name)}"
      output_lines.append(f"<code>{sig}</code>")

    elif self.doc_type == "type":
      # @type for a value
      sig = f"*value* {id}"
      if self.items["header"] and self.items["header"][0][Doc.TYPE]:
        type_name = self.items["header"][0][Doc.TYPE]
        sig += f" : {self.link_types(type_name)}"
      else:
        sig += " : ???"
      output_lines.append(f"<code>{sig}</code>")

    elif is_sym_with_doc(self.doc_item):
      # function/module/value with doc
      sig_text = self.content[self.doc_item[DOC_S_SIG_SLC]]

      if sig_text.startswith("function "):
        sig = f"*function* {id}("
      elif sig_text.startswith("module "):
        sig = f"*module* {id}("
      else:
        # value
        sig = f"*value* {id}"
        if self.items["header"] and self.items["header"][0][Doc.TYPE]:
          type_name = self.items["header"][0][Doc.TYPE]
          sig += f" : {self.link_types(type_name)}"
        else:
          sig += " : ???"
        output_lines.append(f"<code>{sig}</code>")
        return

      # build params for function/module
      params = []
      doc_params = self.items["param"]
      for (ptype, pid, _) in doc_params:
        param_str = f"{pid.replace("_", "\\_")}"
        if ptype:
          param_str += f": {self.link_types(ptype, False)}"
        params.append(param_str)

      sig += ", ".join(params) + ")"

      # add return type for functions
      if sig_text.startswith("function ") and self.items["returns"] and self.items["returns"][0][Doc.TYPE]:
        ret_type = self.items["returns"][0][Doc.TYPE]
        sig += f" : {self.link_types(ret_type)}"

      output_lines.append(f"<code>{sig}</code>")

    elif is_symbol(self.doc_item):
      # symbol without doc
      sig_text = self.content[self.doc_item[DOC_S_SIG_SLC]]
      assert id

      if sig_text.startswith("function "):
        sig = f"*function* {id.replace("_", "\\_")}("
      elif sig_text.startswith("module "):
        sig = f"*module* {id.replace("_", "\\_")}("
      else:
        # value without doc
        sig = f"*value* {id.replace("_", "\\_")} : ???"
        output_lines.append(f"<code>{sig}</code>")
        return

      # Extract param names from the parsed param list
      params = []
      if self.doc_item[DOC_S_PARAM_LST] is not None:
        for (param_name, _) in self.doc_item[DOC_S_PARAM_LST]:
          params.append(param_name.replace("_", "\\_"))

      sig += ", ".join(params) + ")"
      output_lines.append(f"<code>{sig}</code>")
  
  def output_callchains(self, output_lines: list[str], id_override: Optional[str]):
    """
    Outputs callchains if specified or if a function callback or typedef to
    callback any of which returns one or more callbacks, generates the
    callchains.

    Example:

    * @callchain <fn>(a, b, c) (...) : <ret_type>
    * @callchain <fn>(a) (b, c) (...) : <ret_type>

    4 space indent to make as code block:
        <fn>(a, b, c) (...) : <ret_type>
        <fn>(a) (b, c) (...) : <ret_type>

    Parameters
    ----------
    output_lines : list[str]
        Where the documentation is appended to.
    id_override : Optional[str]
        Used with typedef to override the id for a callback.
    """
    if self.items["callchain"]:
      for (_, _, callchain) in self.items["callchain"]:
        if id_override and is_sym_with_doc(self.doc_item):
          output_lines.append(f"    {callchain}".replace(self.content[self.doc_item[DOC_S_ID_SLC]], id_override, 1))
        else:
          output_lines.append(f"    {callchain}")
    elif self.doc_type == "typedef":
      type_name = self.items["header"][0][Doc.TYPE] if self.items["header"] else ""
      if type_name:
        type = symbols.type_dict.get(type_name)
        if type:
          type.output_callchains(output_lines, id_override)
    else:
      # Auto-generate callchains for functions that return callbacks
      id = id_override if id_override else self.id
      if id and self.items["returns"]:
        ret_type = self.items["returns"][0][Doc.TYPE]
        if ret_type:
          # Build function signature prefix
          params = ", ".join(name for _, name, _ in self.items["param"])
          func_prefix = f"{id}({params}) "

          # Parse return types using RE_SEP_TYPES for unions
          ret_type = ret_type.strip()
          if ret_type.startswith("("):
            ret_types = [m["type"].strip() for m in Doc.RE_SEP_TYPES.finditer(ret_type, 1)]
          else:
            ret_types = [ret_type]

          # Generate callchain for each return type that is a callback
          generated_count = 0
          for rtype in ret_types:
            cc = symbols.get_callchains(rtype)
            if cc:
              # cc is like "    TypeName(params) ..." - replace type name with function prefix
              cc_stripped = cc.strip()
              if cc_stripped.startswith(rtype):
                cc_rest = cc_stripped[len(rtype):]
                output_lines.append(f"    {func_prefix}{cc_rest}")
                generated_count += 1

          # Warn if auto-generated callchains for multiple return types
          if generated_count > 1:
            print(f"WARNING: '{self.filename}::{id}' has auto-generated callchains. "
                  "Cannot determine which parameter subsets map to which return types. "
                  "All parameters shown for each return type. "
                  "Use @callchain tags for accurate curried function documentation.",
                  file=sys.stderr)
  
  def output_slots(self, output_lines: list[str]):
    """
    Outputs slot documentation for typedef types.
    Slots are displayed as formatted text (not headings) within a details block.
    """
    if not self.items["slot"]:
      return

    # output_lines.append("")
    output_lines.append("<details><summary>slots</summary>")
    # output_lines.append("")

    for (slot_type, slot_id, slot_desc) in self.items["slot"]:
      line = f"<code><b>{slot_id}</b></code>"
      if slot_type:
        line += f": <code>{self.link_types(slot_type)}</code>\n"
      output_lines.append(line)

      if slot_desc:
        # Remove leading indentation from description
        desc_lines = Doc.RE_INDENT.sub("", slot_desc)
        desc_lines = Doc.RE_TRAILING_EMPTY_LINES.sub("", desc_lines)
        output_lines.append(desc_lines+"\n")
      else:
        # No description?  See if the type has one and use it.
        type = symbols.type_dict.get(slot_type)
        if type:
          type.output_desc(output_lines)

    # output_lines.append("")
    output_lines.append("</details>")
    output_lines.append("")
  
  def output_params(self, output_lines: list[str]):
    """
    Outputs parameter documentation for functions/modules/callbacks.
    Parameters are displayed as formatted text (not headings) within a details block.
    """
    if not self.items["param"]:
      return

    # output_lines.append("")
    output_lines.append("<details><summary>parameters</summary>")
    output_lines.append("")

    # Get actual parameter defaults from the signature if available
    param_defaults = {}
    if is_sym_with_doc(self.doc_item):
      param_list = self.doc_item[DOC_S_PARAM_LST]
      if param_list is not None:
        for (param_name, param_default) in param_list:
          if param_default:
            param_defaults[param_name] = param_default

    for (param_type, param_id, param_desc) in self.items["param"]:
      line = f"**<code>{param_id}</code>**"
      if param_type:
        line += f": <code>{self.link_types(param_type, False)}</code>\n"

      # TODO: Missing Optional

      # Check if param has a default value
      if param_id in param_defaults:
        line += f" *(Default: `{param_defaults[param_id]}`)*\n"

      output_lines.append(line)

      if param_desc:
        # Remove leading indentation from description
        desc_lines = Doc.RE_INDENT.sub("", param_desc)
        desc_lines = Doc.RE_TRAILING_EMPTY_LINES.sub("", desc_lines)
        output_lines.append(desc_lines+"\n")
      else:
        # No description?  See if the type has one and use it.
        type = symbols.type_dict.get(param_type)
        if type:
          type.output_desc(output_lines)

    # output_lines.append("")
    output_lines.append("</details>")
    output_lines.append("")
    
  RE_INDENT = regex.compile("^  ", regex.MULTILINE)
  RE_TRAILING_EMPTY_LINES = regex.compile(
    r"(?:\r?+\n)++$"
  )
  def output_rets(self, output_lines: list[str]):
    """
    Outputs return type documentation for functions/callbacks.
    Returns info is displayed as formatted text (not a heading) within a details block.
    """
    if not self.items["returns"]:
      return

    (ret_type, _, ret_desc) = self.items["returns"][0]

    # output_lines.append("")
    output_lines.append("<details><summary>returns</summary>")
    output_lines.append("")

    if ret_type:
      output_lines.append(f"**Returns**: <code>{self.link_types(ret_type)}</code>\n")
    else:
      output_lines.append("**Returns**\n")

    if ret_desc:
      # Remove leading indentation from description
      desc_lines = Doc.RE_INDENT.sub("", ret_desc)
      desc_lines = Doc.RE_TRAILING_EMPTY_LINES.sub("", desc_lines)
      output_lines.append(desc_lines+"\n")

    # Show callchains for return types that are callbacks
    if ret_type:
      callchain_lines: list[str] = []
      # Parse union types - handle both "(A|B)" and "A|B" formats
      type_str = ret_type.strip()
      if type_str.startswith("(") and type_str.endswith(")"):
        # Use RE_SEP_TYPES for parenthesized unions
        for id_matched in Doc.RE_SEP_TYPES.finditer(type_str, 1):
          type_name = id_matched["type"].strip()
          cc = symbols.get_callchains(type_name)
          if cc:
            callchain_lines.append(cc)
      elif "|" in type_str:
        # Simple pipe-separated union
        for type_name in type_str.split("|"):
          type_name = type_name.strip()
          cc = symbols.get_callchains(type_name)
          if cc:
            callchain_lines.append(cc)
      else:
        # Single type
        cc = symbols.get_callchains(type_str)
        if cc:
          callchain_lines.append(cc)

      if callchain_lines:
        output_lines.append("Possible callchains:\n")
        for cc in callchain_lines:
          output_lines.append(cc)
        output_lines.append("")

    # output_lines.append("")
    output_lines.append("</details>")
    output_lines.append("")
  
  SymbolType : TypeAlias = Literal["function", "module-test", "module-build", "value", "type", "callback"]
  SYMBOL_RENDERING_INFO : dict[SymbolType, tuple[str, str]] = {
    "function":     ("⚙️",   "f"),
    "module-test":  ("🧪",   "m"),
    "module-build": ("🧊",   "m"),
    "value":        ("💠",   "v"),
    "type":         ("🧩",   "t"),
    "callback":     ("🧩⚙️", "t"), # callbacks are still types
  }

  def output_desc(self, output_lines: list[str]):
    if self.items["desc"]:
      for (_, _, desc) in self.items["desc"]:
        if desc:
          output_lines.append(Doc.RE_TRAILING_EMPTY_LINES.sub("", desc))
          output_lines.append("")

  def output_doc(self, output_lines: list[str]):
    """
    Outputs the complete documentation for this item.

    Structure:
      #### symbol id (with anchor)
      `sig`

          callchains (if any)

      description

      slots (for typedef) OR params + returns (for functions/modules/callbacks)
    """
    # File-level documentation (no symbol)
    if self.doc_type == "file":
      if self.items["desc"]:
        for (_, _, desc) in self.items["desc"]:
          if desc:
            output_lines.append(desc.strip() + "\n")
      return

    # Type definitions (typedef, callback, type)
    if self.doc_type in ("typedef", "callback", "type"):
      assert self.id is not None, "Type definitions must have an id"
      link_prefix = "t"  # types

      text_prefix = Doc.SYMBOL_RENDERING_INFO[
        "value" if self.doc_type == "type" else "type"][0]
      # output_lines.append("")
      output_lines.append(f"#### {text_prefix}{self.id.replace("_", "\\_")}{make_anchor(link_prefix, self.id)}")
      output_lines.append("")

      # Signature
      self.output_sig(output_lines, None)
      output_lines.append("")

      # Callchains (for callbacks and typedefs to callbacks)
      if self.items["callchain"] or (self.doc_type == "typedef" and self.items["header"]):
        callchain_lines = []
        self.output_callchains(callchain_lines, None)
        if callchain_lines:
          callchain_lines.append("")
          output_lines.append("Possible callchains:\n")
          output_lines += callchain_lines

      # Description
      self.output_desc(output_lines)

      # Slots for typedefs
      if self.doc_type == "typedef":
        self.output_slots(output_lines)

      # Params and returns for callbacks
      if self.doc_type == "callback":
        self.output_params(output_lines)
        self.output_rets(output_lines)

      return

    # Symbol with or without doc (function/module/value)
    if is_sym_with_doc(self.doc_item) or is_symbol(self.doc_item):
      assert self.id is not None, "Symbols must have an id"
      sig_text = self.content[self.doc_item[DOC_S_SIG_SLC]]

      # Determine prefix for anchor based on symbol type
      if sig_text.startswith("function "):
        text_prefix, link_prefix = Doc.SYMBOL_RENDERING_INFO["function"]
      elif sig_text.startswith("module test_"):
        text_prefix, link_prefix = Doc.SYMBOL_RENDERING_INFO["module-test"]
      elif sig_text.startswith("module "):
        text_prefix, link_prefix = Doc.SYMBOL_RENDERING_INFO["module-build"]
      else:
        text_prefix, link_prefix = Doc.SYMBOL_RENDERING_INFO["value"]

      # output_lines.append("")
      output_lines.append(f"#### {text_prefix}{self.id.replace("_", "\\_")}{make_anchor(link_prefix, self.id)}")
      output_lines.append("")

      # Signature
      self.output_sig(output_lines, None)
      output_lines.append("")

      # Only output description and details if doc exists
      if is_sym_with_doc(self.doc_item):
        # Callchains (explicit or auto-generated for functions that return callbacks)
        callchain_lines: list[str] = []
        self.output_callchains(callchain_lines, None)
        if callchain_lines:
          callchain_lines.append("")
          output_lines.append("Possible callchains:\n")
          output_lines += callchain_lines

        # Description
        if self.items["desc"]:
          for (_, _, desc) in self.items["desc"]:
            if desc:
              output_lines.append(desc.strip())
              output_lines.append("")

        # Params and returns
        self.output_params(output_lines)
        self.output_rets(output_lines)

class Symbols:
  """
  Stores the Symbol info collected from the files.
  """
  def __init__(self) -> None:
    self.type_dict: dict[str, Doc] = {}
    "type symbol -> doc"
    self.type_list: list[Doc] = []
    "type symbol docs in order that they appear in source."
    self.type_refed: set[str] = set()
    """If type symbol set here, then it's been referenced in the documentation
    somewhere, excludes typedefs."""
    self.function_dict:   dict[str, Doc] = {}
    "function symbol -> doc"
    self.module_dict:     dict[str, Doc] = {}
    "module symbol -> doc"
    self.value_dict:      dict[str, Doc] = {}
    "value symbol -> doc"
    
  def get_callchains(self, symbol_name: str, require_curry: bool = False) -> str:
    symbol_name = symbol_name.rstrip()
    if not symbol_name or symbol_name.startswith("(") or symbol_name.startswith("list["):
      return ""
    if symbol_name in BUILTIN_TYPES:
      return ""
    if symbol_name not in self.type_dict and symbol_name not in self.function_dict:
      return ""

    obj = self.type_dict.get(symbol_name) or self.function_dict.get(symbol_name)
    if obj and obj.items["callchain"]:
      return "\n".join(
        "    " + cc_desc for _, _, cc_desc in obj.items["callchain"] if cc_desc
      )

    def resolve_to_callback(type_name: str):
      seen: set[str] = set()
      while True:
        if not type_name or type_name.startswith("(") or \
            type_name.startswith("list["):
          return None
        if type_name in BUILTIN_TYPES:
          return None
        if type_name in seen:
          return None
        seen.add(type_name)

        if type_name not in self.type_dict:
          return None
        o = self.type_dict[type_name]
        if o.doc_type == "callback":
          return o
        if o.doc_type == "typedef":
          type_name = o.items["header"][0][Doc.TYPE]
          continue
        return None

    def get_ret_type(type_name: str, cb: Doc) -> str:
      o = self.type_dict[type_name]
      rets = o.items["returns"]
      if rets:
        return rets[0][Doc.TYPE]
      rets = cb.items["returns"]
      if rets:
        return rets[0][Doc.TYPE]
      return ""

    cb = resolve_to_callback(symbol_name)
    if not cb:
      return ""

    segs: list[str] = []
    segs.append(
      f"{symbol_name}({', '.join(name for _, name, _ in cb.items['param'])})"
    )
    ret_type = get_ret_type(symbol_name, cb)

    seen: set[str] = set([symbol_name])
    had_curry = False
    while True:
      if not ret_type or ret_type in seen:
        break
      next_cb = resolve_to_callback(ret_type)
      if not next_cb:
        break

      had_curry = True
      segs.append(
        f"({', '.join(name for _, name, _ in next_cb.items['param'])})"
      )
      seen.add(ret_type)
      ret_type = get_ret_type(ret_type, next_cb)

    if require_curry and not had_curry:
      return ""
    if not ret_type:
      return ""

    return "    " + " ".join(segs) + f" : {ret_type}"

symbols = Symbols()
def render_md(filename: str, content: str, output_lines: list[str], items: list[ItemInfo], show_private: bool):
  types_start = len(symbols.type_list)
  type_refed = symbols.type_refed.copy()

  for item in items:
    if is_doc(item):
      doc = Doc(filename, content, item)
      assert doc.doc_type != "nontype", \
        "Nontypes should have occurred in `if is_sym_with_doc(item):` branch"
      if doc.doc_type == "file":
        if doc.id and doc.id.startswith("_") and not show_private:
          continue
        doc.output_doc(output_lines)
      # else:
      # Types are printed at the end
    elif is_sym_with_doc(item):
      doc = Doc(filename, content, item)
      if doc.id and doc.id.startswith("_") and not show_private:
        continue
      doc.output_doc(output_lines)

  # dry run so that types that reference callbacks will allow callbacks to show
  for type in symbols.type_list[types_start : ]:
    type.output_doc([])
  new_refed = symbols.type_refed - type_refed

  # actual output
  temp_output_lines = []
  types_output : set[str] = set()
  for type in symbols.type_list[types_start : ]:
    id = type.id
    assert id
    types_output.add(id)
    type.output_doc(temp_output_lines)

  # in case type that was declared in a previous file which wasn't referenced
  # directly, is.
  temp_pre_output_lines = []
  for type_name in new_refed - types_output:
    symbols.type_dict[type_name].output_doc(temp_pre_output_lines)

  # no file header if no output generated
  if temp_output_lines:
    output_lines.append(f"### {filename} types\n")
    output_lines += temp_output_lines

  # Prepend emojis to header markers.
  RE_H2 = regex.compile(r"^(## )(.*)", regex.MULTILINE)
  RE_H3 = regex.compile(r"^(### )(.*)", regex.MULTILINE)

  def add_h2_emoji_anchor(m):
    return f"{m.group(1)}<span style=\"font-size: 1.1em; color: yellow\">📘{m.group(2)}</span>{make_anchor('file', m.group(2))}"

  def add_h3_emoji_and_anchor(m):
    heading_text = m.group(2)
    assert isinstance(heading_text, str)
    return f"{m.group(1)}<i>📑{heading_text}</i>{make_anchor(f'{filename}-ch', heading_text)}"

  for i in range(len(output_lines)):
    tmp = output_lines[i]
    tmp = RE_H2.sub(add_h2_emoji_anchor, tmp)
    tmp = RE_H3.sub(add_h3_emoji_and_anchor, tmp)
    output_lines[i] = tmp

def process_file(filename: str, write_ext: Optional[str], from_stdin: bool = False) -> Optional[Track]:
  item_count = 0

  if from_stdin:
    content = sys.stdin.read()
  else:
    with open(filename, "r", encoding="utf-8") as f:
      try:
        content = f.read()
      except Exception as e:
        raise ExceptionGroup(f"While reading '{filename}'", [e])

  out_text = ""
  track       : Optional[Track]
  output_lines: Optional[list[str]]

  if options["show"] == "json":
    current_hash = hashlib.sha256()
    current_hash.update(content.encode("utf-8"))
    track = {
      "filenames": {
        filename: {
          "order"    : -1,
          "docs"     : [],
          "symbols"  : [],
          "hash"     : current_hash.hexdigest(),
          "mtime"    : mtime_to_utc(os.path.getmtime(filename))
        }
      },
      "ids": {}
    }
    track_ids  = track["ids"]
    track_docs = track["filenames"][filename]["docs"]
    track_symbols = track["filenames"][filename]["symbols"]
    output_lines = None
  else:
    track = None
    track_ids = None
    track_docs = None
    track_symbols = None
    output_lines = []

  if len(content):
    global line_char_index
    line_char_index = get_line_positions(content)
    items = get_items(content)

    if options["show"] == "summary":
      last_line_digit_count = 0
    else:
      last_line_digit_count = math.floor(math.log(len(line_char_index), 10)) + 1

    # Create conditional implementations of disp() to display slices of content
    # with optional line number prefixes or independent strings.
    if options["show"] == "summary" or not options["showLineNums"]:
      def disp(param: slice | str):
        nonlocal output_lines
        assert output_lines is not None
        if isinstance(param, slice):
          output_lines.append(content[param])
        else:
          output_lines.append(param)

    else:
      def disp(param: slice | str):
        nonlocal output_lines
        assert output_lines is not None

        if isinstance(param, slice):
          start_line, _ = get_lines(param, line_char_index)
          ls = content[param].split("\n")

          def append(line_num: int, line: str):
            nonlocal output_lines
            assert output_lines is not None
            output_lines.append(
              f"{line_num:>{last_line_digit_count}}: {line}"
            )

          append(start_line, ls[0])
          for i in range(1, len(ls)):
            line = ls[i]
            line_num = start_line + i
            append(line_num, line)
        else:
          output_lines.append(
            f"{'':>{last_line_digit_count}}  {param}"
          )

    if options["show"] in ("md", "md-with-private"):
      assert output_lines is not None
      render_md(filename, content, output_lines, items, options["show"] == "md-with-private")
    else:

      for item in items:
        if options["id"] and (len(item) == 2 or content[item[DOC_S_ID_SLC]] != options["id"]):
          # This item is not being filtered for
          continue

        if options["show"] == "summary":
          # Generating text with symbol name and the lines it resides on.
          if len(item) > 2: # implies some sort of symbol
            sig_slc = item[DOC_S_SIG_SLC]
            s_line, e_line = get_lines(item[DOC_SLC], line_char_index)
            if s_line == e_line:
              disp(f"{content[sig_slc]} (line {s_line})")
            else:
              disp(f"{content[sig_slc]} (lines {s_line}-{e_line})")
          continue

        elif options["show"] == "json":
          # Generating json representation
          if len(item) > 2:
            # Generating json for symbol
            sig_slc = item[DOC_S_SIG_SLC]
            s_line, e_line = get_lines(item[DOC_SLC], line_char_index)
            result: TrackIds = {
              "filename"  : filename,
              "order"     : item_count,
              "type"      : item[DOC_TYPE],
              "name"      : content[item[DOC_S_ID_SLC]],
              "line_start": s_line,
              "line_end"  : e_line,
              "signature" : content[item[DOC_S_SIG_SLC]],
              "body"      : content[item[DOC_S_BODY_SLC]],
              "doc"       : content[item[DOC_S_DOC_SLC]] if is_sym_with_doc(item) else ""
            }
            # assert track_ids is not None
            assert track_ids is not None
            track_ids[result["name"]] = result
            assert track_symbols is not None
            track_symbols.append(result["name"])
            item_count += 1

          elif item[DOC_TYPE] == "doc":
            # Generating json for doc
            assert track_docs is not None
            track_docs.append( (item_count, content[item[DOC_SLC]]) )
            item_count += 1

          continue

        elif options["show"] == "sig-doc":
          # Generating text for symbol signatures and docs
          if item[DOC_TYPE] == "doc":
            disp(item[DOC_SLC])
          else:
            if is_sym_with_doc(item):
              disp("")
              disp(item[DOC_S_SIG_SLC])
              disp(item[DOC_S_DOC_SLC])
            elif is_symbol(item):
              disp("")
              disp(item[DOC_S_SIG_SLC])
              disp("** NO DOCUMENT FOR SYMBOL **")
          continue

        if len(item) > 2:
          # Generating text for ids, sigs, bodies and code.
          match options["show"]:
            case "id":
              disp(item[DOC_S_ID_SLC])
            case "sig" | "all":
              disp(item[DOC_S_SIG_SLC])
            case "body":
              disp(item[DOC_S_BODY_SLC])
            case "code":
              disp(item[DOC_SLC])

    if output_lines is not None:
      out_text = "\n".join(output_lines)

      # This makes sure that the heading for the next file will be separated by
      # an empty line.  A side effect of this is that the end of the file will
      # contain 2 consecutive blank lines, causing the markdown linter to complain.
      if out_text and not out_text.endswith("\n\n"):
        out_text += "\n"

  assert out_text == "" or out_text.endswith("\n\n")
  # Output phase
  # from_stdin is always combined with write_ext=None (enforced above).
  if write_ext is None:
    if out_text:
      # printing json is done in the caller to merge all json object together.
      if not track:
        if args.out_file:
          with open(args.out_file, "a", encoding="utf-8") as out_f:
            out_f.write(out_text)
        else:
          print(out_text)
  else:
    out_name = f"{filename}.{write_ext}"
    with open(out_name, "w", encoding="utf-8") as out_f:
      if track:
        json.dump(track, out_f, indent=2)
      else:
        out_f.write(out_text)

  return track
# ---- main loop over all filenames ----

tracking: list[Track] = []
hashes_combined: str = ""

def process_file_helper(fname, i, write_ext, from_stdin=False):
  global hashes_combined
  result = process_file(fname, write_ext, from_stdin)
  if result:
    result["filenames"][fname]["order"] = i
    hashes_combined += fname + result["filenames"][fname]["hash"]
    tracking.append(result)

if not args.filenames:
  # stdin mode: content from stdin, output only to stdout
  process_file_helper("<stdin>", 0, args.write_ext)
else:
  hash = hashlib.sha256()
  if args.out_file:
    with open(args.out_file, "w", encoding="utf-8") as out_f:
      pass
  for i, fname in enumerate(args.filenames):
    process_file_helper(fname, i, args.write_ext)

if len(tracking) and args.write_ext is None:
  # tracked the files in json
  hash = hashlib.sha256()
  hash.update(hashes_combined.encode())
  merged_tracking: TrackFull = {
    "filenames": {},
    "ids": {},
    "hash_algo": "SHA256",
    "combined_hash": hash.hexdigest(),
    "mtime": ""
  }
  # merge tracking together into one.
  for tracked in tracking:
    # merge filenames together
    for filename in tracked["filenames"]:
      assert filename not in merged_tracking["filenames"], \
        f"Filename {filename} cannot be added twice."
      fn_obj = tracked["filenames"][filename]
      merged_tracking["filenames"][filename] = fn_obj
      if merged_tracking["mtime"] < fn_obj["mtime"]:
        merged_tracking["mtime"] = fn_obj["mtime"]

    # merge ids together
    for id in tracked["ids"]:
      assert id not in merged_tracking["ids"], \
        f"id {id} cannot be added twice.  Found in files:\n" \
        f"  {merged_tracking['ids'][id]['filename']}\n" \
        f"  {tracked['ids'][id]['filename']}"
      merged_tracking["ids"][id] = tracked["ids"][id]

  if args.out_file is None:
    # output json to stdout
    print(json.dumps(merged_tracking, indent=2))
  else:
    # output json to a single file
    with open(args.out_file, "w", encoding="utf-8") as f_out:
      json.dump(merged_tracking, f_out, indent=2)

    with open(args.out_file, "rb") as f_in:
      data_bytes = f_in.read()

    with open("track_creation.log", "a", encoding="utf-8") as f_out:
      json.dump(
        {
          "mtime": mtime_to_utc(os.path.getmtime(args.out_file)),
          "len": len(data_bytes),
          "hash": hashlib.sha256(data_bytes).hexdigest()
        }, f_out
      )
      f_out.write("\n")

