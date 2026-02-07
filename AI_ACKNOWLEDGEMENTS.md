# AI Acknowledgements

I wrote most of this library myself, and the design ideas for each part are mine.
Initial coding for the library sequence up to and including `skin` was done
without AI assistance.

However, AI support still saved a lot of time.

## ChatGPT 5.1-5.2

ChatGPT helped with code and documentation review, mainly for consistency and
cleanup.

It also helped a bit with a doc-generator workflow I originally built to keep
GPT focused. Without strong constraints, it was prone to drifting, timing out,
and returning incomplete work.

The original goal of that generator was to produce structured symbol data for
GPT lookup. I later pivoted it into JSON output for the whole library's usable
symbols and docs, so symbol lookup could be dictionary-driven instead of fuzzy
search.

### Teaching ChatGPT to Stay Focused

Focus was still a recurring problem, so I had to force a task-management loop.
In short, I made it:

1. Track a fixed time quota.
2. Use three stacks: `ToProcess`, `Processing`, `Processed`.
3. Plan work into `ToProcess` first.
4. Periodically check time and produce a stop-report before timing out.
5. Pull one item into `Processing`, split if too large, execute, then move it to `Processed`.
6. Repeat until done or near quota.

That process improved reliability a lot, but it took far too much prompt-level
coaching to get there.

## Claude Opus

I needed spline-driven direction for the `skin` library. GPT gave useful ideas,
but I was getting stuck, so I switched to Claude Code.

### The Good

Claude's planning behavior worked out of the box, so I did not need to spend
nearly as much time teaching process.

### The Bad

The 5-hour limit itself was manageable.

### The Ugly

The weekly limit wasn't clearly communicated, so I only discovered it after I
hit it.  I initially thought it was an accounting error, lost time trying to
resolve it, then learned about this secondary cap. That process was intensely
frustrating.

I eventually found usage tracking in the web interface, but it was harder to
find than it should be, and I could not find an equivalent view in the VS Code
UI.

## Codex

Codex gives GPT-style behavior with direct project file access, but without the
web-memory context I had already built up. That gap was annoying.

In practice, my biggest pain point was approvals and tool behavior. Too often,
it would choose unnecessary ad-hoc scripting instead of the approved workflow
(`rg` for reads, `apply_patch` for writes), which translated into repeated
approval friction.

I eventually reduced that by pushing stricter rules into `AGENTS.md`, but that
itself took effort I should not have had to spend.

As of now, even with higher token burn, Claude Code still feels like the better
UX to me.
