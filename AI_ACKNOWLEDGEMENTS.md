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
GPT focused. Without strong constraints, it would basically say, "Ooo, is that
a butterfly? It might impact what I'm doing..." and with that, it would timeout
and not report anything.

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

![Coding benchmark comparison](data:image/webp;base64,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)
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

Another big issue was line endings. `apply_patch` often behaved as if it were
Unix-centric, adding `LF` lines in files that were otherwise `CRLF`.

I'm hedging here because Codex later claimed it hadn't sent `CRLF`, so this may
have been the tool, the model, or both making things up. Either way, it was
super frustrating!

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
