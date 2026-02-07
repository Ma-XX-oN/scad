# AI Acknowledgements

- [ChatGPT 5.1-5.2](#chatgpt-51-52)
  - [Teaching ChatGPT to Stay Focused](#teaching-chatgpt-to-stay-focused)
- [Claude Opus 4.5](#claude-opus-45)
  - [The Good](#the-good)
  - [The Bad](#the-bad)
  - [The Ugly](#the-ugly)
- [Codex](#codex)
- [Summary](#summary)

I wrote most of this library myself, and the design ideas for each part are mine.
Initial coding for the library sequence up to and including `skin` was done
without AI assistance.

However, AI support still saved a lot of time.

## ChatGPT 5.1-5.2

ChatGPT helped with code and documentation review, mainly for consistency and
cleanup.

It also helped a bit with a doc-generator workflow I originally built to keep
GPT focused. Without strong constraints, it would basically say, "Ooo, is that a
butterfly? It might impact what I'm doing..." and with that, it would go off and
search and search resulting in a timeout and not report anything.

The original goal of that generator was to produce structured symbol data for
GPT lookup. I later pivoted it into JSON output for the whole library's usable
symbols and docs, so symbol lookup could be dictionary-driven instead of fuzzy
search.

### Teaching ChatGPT to Stay Focused

Focus was still a recurring problem, so I had to suggest a task-management loop.
In short, I suggested it:

1. Track a fixed time quota.
2. Use three stacks: `ToProcess`, `Processing`, `Processed`.
3. Plan work into `ToProcess` first.
4. Periodically check time and produce a stop-report for the next prompt's
   context before timing out.
5. Pull one item into `Processing`, split if too large, execute, then move it
   to `Processed`.
6. Repeat until done or near quota.

GPT actually saw the benefits and took to it quite quickly.  That in turn
improved reliability a lot, but all of this took far too much prompt-level
coaching to get there.  Just convincing it that it had access to a clock through
Python took more than an hour or two.  It was very stubborn.

## Claude Opus 4.5

I needed spline-driven direction for the `skin` library. GPT gave useful ideas,
but the workflow was slow - I had to manually copy-paste outputs, often
discovering errors that required another round trip. I wanted editor integration
to speed up the iteration cycle. I'd tried GitHub Copilot earlier, so I asked
GPT which coding AI followed directions best. It referenced articles showing
Claude was slightly better than GPT on coding benchmarks (around 4%). So I tried
Claude Code. **It was amazing!**

![Coding benchmark comparison](benchmark.webp)
*Source: [Anthropic announces Claude Opus 4.5, the new AI coding frontrunner](https://www.itpro.com/technology/artificial-intelligence/anthropic-announces-claude-opus-4-5-the-new-ai-coding-frontrunner?utm_source=chatgpt.com)*

### The Good

Claude's planning behavior worked out of the box, so I did not need to spend
nearly as much time teaching process.

### The Bad

The 5-hour limit itself was manageable, but I still had to teach it to:

- Stop being "helpful" by writing code when I had only asked a question.
- Read the code and docs before writing tests.
- Adapt to my coding style.

These were all things I had already taught GPT, so having to teach them again
was frustrating.

### The Ugly

The weekly limit wasn't clearly communicated, so I only discovered it after I
hit it.  I initially thought it was an accounting error, lost time trying to
resolve it, then learned about this secondary cap. I was so pissed.

I eventually found usage tracking in the web interface, but it was harder to
find than it should be, and I could not find an equivalent view in the VS Code
UI.

> **Update**:
>
> Initially, Claude Code had no way to check usage limits from the VS Code UI.
> The `/usage` command existed but wasn't functional. It has since been fixed
> and now works properly. For comparison, Codex had working usage tracking from
> the start.

## Codex

Codex is ChatGPT 5.3 which gives GPT-style behavior with direct project file
access, but without the web-memory context I had already built up. That gap was
annoying.

In practice, my biggest pain point was approvals and tool behavior. Too often,
it would choose unnecessary ad-hoc scripting instead of the approved workflow
(`rg` for reads, `apply_patch` for writes), which meant I had to approve every
effing time. That really pissed me off.

Another big issue was line endings. `apply_patch` appeared to behave as if it
were Unix-centric, adding `LF` lines in files that were otherwise `CRLF`.

I'm hedging here because Codex later claimed it hadn't sent `CRLF` even after
specifically telling it to, so this may have been the tool's design limitation,
the model making things up, or both. Either way, it was super frustrating!

I eventually had it verify output and normalize line endings back to the
expected format. That required extra approvals and overhead that shouldn't
have been necessary.

Both of these issues had to be significantly reduced by pushing stricter rules
into `AGENTS.md`, but that itself took effort I should not have had to spend.

## Summary

I liked Claude Code's feel much better out of the box.  It felt more polished to
me than Codex.

Despite the frustrations documented above, once set up properly, both tools
significantly accelerated my development workflow. Ironically, both helped
edit this very document.
