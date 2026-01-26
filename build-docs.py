import regex

def generate_toc(markdown_text: str) -> str:
  """
  Generate a Table of Contents from the markdown output.

  Parses H2 (file), H3 (chapter), and H4 (item) headings and builds
  a hierarchical structure with collapsible file and chapter sections.
  Uses blockquotes for indentation to ensure proper nesting.
  """
  lines = markdown_text.split('\n')
  toc_output: list[str] = []
  current_items: list[str] = []
  in_file = False
  in_chapter = False

  def make_link(text: str, anchor: str) -> str:
    """Create an HTML link."""
    return f'<a href="#{anchor}">{text}</a>'

  def heading_to_anchor(heading: str) -> str:
    """Convert a markdown heading to a GitHub-style anchor."""
    # Remove markdown formatting
    anchor = regex.sub(r"\*\*(.+?)\*\*", r"\1", heading)  # bold
    anchor = regex.sub(r"\*(.+?)\*", r"\1", anchor)  # italic
    anchor = regex.sub(r"`(.+?)`", r"\1", anchor)  # code
    # Convert to lowercase
    anchor = anchor.lower()
    # Replace " : " with "--" (GitHub convention for colon with spaces)
    anchor = anchor.replace(" : ", "--")
    # Remove special chars except spaces and hyphens
    anchor = regex.sub(r"[^\w\s-]", "", anchor)
    # Replace spaces with hyphens
    anchor = regex.sub(r"\s+", "-", anchor.strip())
    return anchor

  def flush_items():
    """Flush accumulated items with bullet characters."""
    nonlocal current_items
    if current_items:
      toc_output.append("<blockquote>")
      for item in current_items:
        toc_output.append(f"• {item}<br>")
      toc_output.append("</blockquote>")
      current_items = []

  def close_chapter():
    """Close the current chapter's details section."""
    nonlocal in_chapter
    if in_chapter:
      flush_items()
      toc_output.append("</details>")
      in_chapter = False

  def close_file():
    """Close the current file's details section."""
    nonlocal in_file
    if in_file:
      close_chapter()
      toc_output.append("</blockquote>")
      toc_output.append("</details>")
      toc_output.append("")
      in_file = False

  # First pass: collect chapters and their items to know which have children
  chapter_has_items: dict[str, bool] = {}
  current_chapter_anchor = None
  for line in lines:
    if line.startswith("### "):
      anchor_match = regex.search(r"<a id='([^']+)'></a>", line)
      if anchor_match:
        current_chapter_anchor = anchor_match.group(1)
        chapter_has_items[current_chapter_anchor] = False
    elif line.startswith("#### ") and current_chapter_anchor:
      # Count all H4 headings as items (with or without anchors)
      chapter_has_items[current_chapter_anchor] = True
    elif line.startswith("## "):
      current_chapter_anchor = None

  # Second pass: generate the TOC
  for line in lines:
    # H2: File heading (## <span...>📘filename</span><a id='file-filename'></a>)
    if line.startswith("## "):
      close_file()
      # Extract filename from the anchor
      anchor_match = regex.search(r"<a id='file-([^']+)'></a>", line)
      if anchor_match:
        current_file = anchor_match.group(1)
        anchor = f"file-{current_file}"
        link = make_link(f"📘 <b>{current_file}</b>", anchor)
        toc_output.append(f"<details><summary>{link}</summary>")
        toc_output.append("<blockquote>")
        in_file = True

    # H3: Chapter heading (### <i>📑chapter</i><a id='file-ch-chapter'></a>)
    elif line.startswith("### "):
      close_chapter()
      # Extract chapter from the anchor
      anchor_match = regex.search(r"<a id='([^']+)'></a>", line)
      if anchor_match:
        anchor = anchor_match.group(1)
        # Extract chapter text from <i>📑chapter</i>
        text_match = regex.search(r"📑([^<]+)</i>", line)
        if text_match:
          chapter_text = text_match.group(1)
          link = make_link(f"📑 <i>{chapter_text}</i>", anchor)
          if chapter_has_items.get(anchor, False):
            toc_output.append(f"<details><summary>{link}</summary>")
            in_chapter = True
          else:
            toc_output.append(f"• {link}<br>")

    # H4: Item heading (#### emoji_text<a id='prefix-id'></a>) or plain H4
    elif line.startswith("#### "):
      # Extract anchor if present
      anchor_match = regex.search(r"<a id='([^']+)'></a>", line)
      if anchor_match:
        anchor = anchor_match.group(1)
        # Extract display text (emoji + name) - between "#### " and "<a"
        text_match = regex.search(r"^#### (.+?)<a id=", line)
        if text_match:
          display_text = text_match.group(1).strip()
          # Unescape underscores for display
          display_text = display_text.replace("\\_", "_")
          current_items.append(make_link(display_text, anchor))
      else:
        # H4 without anchor - generate GitHub-style anchor from heading text
        text_match = regex.search(r"^#### (.+)$", line)
        if text_match:
          raw_text = text_match.group(1).strip()
          # Generate anchor from heading text
          anchor = heading_to_anchor(raw_text)
          # Clean up display text (remove markdown bold markers)
          display_text = regex.sub(r"\*\*(.+?)\*\*", r"\1", raw_text)
          current_items.append(make_link(display_text, anchor))

  # Close last file section
  close_file()

  return "\n".join(toc_output) + "\n" if toc_output else ""

with open("README.md", "r", encoding="utf-8") as in_f:
  readme_contents = in_f.read()

with open("API-header.md", "r", encoding="utf-8") as in_f:
  api_contents = in_f.read()

re_file_section = regex.compile(
  r'''
  ^\#\#\#\#\ Synopses\ of\ Files\r?+\n
  (?:(?!\s*+\d++\.\s).*+(?:\n|$))*+
  ((?:(?!\#).*+(?:\n|$))*+)
  ''', regex.MULTILINE | regex.VERBOSE
)
matched = re_file_section.search(readme_contents)
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

if result.returncode != 0:
  print(f"ERROR: scad-analysis.py exited with code {result.returncode}")
else:
  # Generate TOC from the scad-analysis.py output
  toc = generate_toc(result.stdout)

  # Write API.md (full API reference)
  with open("API.md", "w", encoding="utf-8") as f_out:
    f_out.write(api_contents)
    if toc:
      f_out.write("\n## Table of Contents\n\n")
      f_out.write("*If viewing on GitHub, you can also use the"
                  " outline button (☰) near the top right of the page"
                  " to navigate by heading.*\n\n")
      f_out.write(toc)
      f_out.write("\n")
    f_out.write(result.stdout)
