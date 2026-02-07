# AI Acknowledgements

I wrote *most* of this library on my own, and all of the ideas to implement the
different pieces are mine. I did the initial coding up to `skin` without any AI
assistance.

*However*, I would have taken a lot longer without the aid of some AI
assistance. Namely:

## ChatGPT 5.1-5.2

Helped with code and document review, ensuring consistency of code and docs up
to the `skin` file.

It also helped *a little* with the doc generator which I initially wrote to keep
GPT on track as it would basically say, "Oooo, is that a butterfly? It
might impact what I'm doing..." and with that, it would timeout and not report
anything.

The original purpose of the doc generator was to generate data suitable for GPT
to find the symbols. I then realized I could make a doc generator out of it,
which I put on hold to make it generate a JSON file of the entire library's
usable symbols and documentation, so that GPT would find the symbol using a
dictionary, speeding symbol search up dramatically and focusing its view.

### Teaching ChatGPT to Stay Focused

Focusing was still a problem and I had to introduce it to how to keep on track
of tasks and how to keep context of what it did so that it could continue at the
next prompt.

**The Task Management Algorithm:**

1. You have a fixed time quota. Get the current time. (Just convincing it that it
   had access to a clock through Python took more than an hour or two. Very
   stubborn.)

2. You have 3 stacks: ToProcess, Processing and Processed.

3. Put all of the tasks that it needed to do into ToProcess.

4. Check time.
   - Are you close to your time quota or nothing in ToProcess or Processing
     stacks? Write what you've completed (Processed stack), what is in progress
     (Processing stack) and what's left to do (ToProcess stack) and stop!

5. Nothing left in Processing?
   - Take item from ToProcess and put into Processing.

6. Take Item in Processing.
   - too big to complete in a "short amount of time"?
     - take it out, break it up into smaller tracks and put back into
       Processing.
     - go to step 6.

7. From the item in Processing, do what you need to do to find the answer.

8. Move item from Processing to Processed.

9. Go to step 4.

I basically told it how to plan as well as not to time out when doing a task.
From there, it kept focus, and *almost* always didn't time out.  Though, I did
have to get it to look at its activity log to review what it did well, and what
could be improved. Then telling it to remember what it just said for future
conversations.

Yeah. This was still a bit of a process, but it was better than before.

## Claude Opus

I needed to direct the `skin` Library using a spline. I had a fairly good idea
what I needed, so I asked GPT. It gave me ideas, but I was getting a little
lost. So I broke down and tried Claude Code. **It was amazing!**

### **The Good**

It had planning skills so I didn't have to teach it. The ramp up to what I got
from GPT felt faster, but that could be that I had a clearer idea what I wanted.

### **The Bad**

It had a token limit which reset every 5 hours, but I was fine with that.

### **The Ugly**

There was a weekly token limit which I wasn't made aware of till I hit it. I
thought it was an accounting error, pushing it to more that 10 hours. After a
while taking with the support AI. I finally figured out what happened, and I
wasn't happy. What I though was a little over 10 hours was actually 10 hours and
a day. I was so pissed.

However, I finally found that I could track my usage by going to the web
interface.  It wasn't easy to find and should be more prominent in the VsCode
UI.  I then allocated how much I should use each day and stuck with that.

But to keep my usage down, I asked GPT questions about Claude Code. That may
have flagged something because the next day I got a message pop up saying
something like, would you like to try Codex?

## Codex

Codex is like Claude Code, it has read/write access to the project files. It is
just like GPT but has no access to the memories that I gave it through the
web, which was annoying. HOWEVER, it appeared that it was a little more generous
with the token limits. That might be just the dealer giving the junkie some free
dope to get me hooked. Still working that out.

But no mistaking it, it's GPT. 5.3 to be exact. Stubborn and obstinate as ever.
Yes. It has planning skills but not on by default, and the number of approvals!
WTF man?

It turns out that many of the approvals were caused by Codex being, let's say...
creative with how it edited files. Instead of using the approved tooling (`rg`
is a read-only tool to read files and `apply_patch` allows writing to files)
which should only ask for permission once per file. Barring a few permission
issues with those tools, Codex would just randomly use handmade PowerShell
scripts that would require me to approve every effing time.  That really pissed
me off... a lot!

It took quite a bit of telling it to remember by storing to the AGENTS.md file
to mostly use the approved tools.  However, the tools are crappy and the
approval detection is still really buggy.

As of right now, even though Claude Code seems to burn more tokens quicker than
Codex, it is a better UX in my opinion.
