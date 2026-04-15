---
name: lowy
description: Evaluate architecture and module boundaries for volatility-based decomposition using Juval Lowy's framework (from "Righting Software", building on Parnas 1972). Use when reviewing module splits, service boundaries, new abstractions, or any decomposition decision. Trigger on phrases like "where should this boundary be", "how to split this", "module boundaries", "encapsulate change", "volatility", or references to Lowy, Parnas, or "Righting Software". Complements /hickey (interleaved concerns) with a different lens (change encapsulation).
context: fork
agent: Explore
---

# Lowy: Volatility-Based Decomposition Review

Evaluate module boundaries and decomposition decisions using Juval Lowy's volatility-based decomposition framework. The core question: **do your boundaries encapsulate axes of change, or do they just group related functionality?**

Source: Juval Lowy, [*Righting Software*](https://rightingsoftware.org/) (2019), building on David Parnas, ["On the Criteria to Be Used in Decomposing Systems into Modules"](https://www.win.tue.nl/~wstomv/edu/2ip30/references/criteria_for_modularization.pdf) (1972). See also: [Volatility-Based Decomposition](https://www.informit.com/articles/article.aspx?p=2995357&seqNum=2) (book excerpt).

## Key Idea

**Functional decomposition** groups code by what it does (UserService, PaymentController, AuthModule). **Volatility-based decomposition** groups code by what is likely to *change* — and encapsulates each axis of change behind a stable interface.

Lowy's electricity analogy: a house's power supply has enormous volatility (AC/DC, 110v/220v, 50/60Hz, solar/grid/generator, wire gauges). All of it is encapsulated behind a receptacle. Without that encapsulation, you'd need an oscilloscope every time you plugged something in. The receptacle is the stable interface; the volatility behind it can change without affecting consumers.

**Functional decomposition maximizes the blast radius of change.** When boundaries track functionality rather than volatility, a single change cuts across multiple modules. Volatility-based decomposition contains the grenade in the vault.

## The Evaluation

For every module boundary, service split, or new abstraction in the code under review:

### 1. Name the Volatility

What is likely to change behind this boundary? Be specific — not "requirements might change" but "the payment provider, the auth protocol, the notification channel." If you can't name concrete axes of change, the boundary may be arbitrary.

**Speculative volatility is not volatility.** A change scenario counts only if it has happened before, is on a roadmap, or is a near-certain consequence of the domain (e.g. "payment providers change" in e-commerce). "What if we swap color spaces" in an app that has never swapped color spaces is speculation, not an axis of change. Lowy's framework is about *observed* or *plausible* volatility — designing for hypothetical change is over-engineering, not encapsulation.

### 2. Functional vs. Volatility Boundary

Does this boundary exist because the code *does something different* (functional), or because what's behind it *changes independently* (volatility)? Functional boundaries look clean on day one but fracture under change. A `UserService` that groups all user operations is functional decomposition — the volatility of auth, profile data, and notification preferences are unrelated axes of change jammed behind one boundary.

### 3. Change Blast Radius

For a plausible change scenario (new provider, new format, new rule), trace how many modules would need to be modified. If the change leaks across boundaries, the decomposition is functional, not volatility-based.

### 4. Interface Stability

Is the interface between modules stable under the changes the module encapsulates? The receptacle doesn't change when you switch from grid to solar. If the interface must change when the encapsulated volatility changes, the abstraction is leaking.

### 5. Reuse Signal

Lowy: volatility-based building blocks are reusable because they encapsulate one axis of change. If a module can only be used in one context, it may be encapsulating functionality rather than volatility.

## Fact-Check Your Own Evaluation

After completing all steps, **invoke `/fact-check` on your own output**. The fact-check catches:

- Findings you talked yourself out of ("However, this is a reasonable grouping..." / "acceptable for now")
- Functional boundaries rationalized as volatility boundaries without naming the concrete axis of change
- "Low blast radius" used as a synonym for "ignore"
- Change scenarios you didn't actually trace through the code

**Flag these phrase shapes** — they mean you stopped one step early:

- _"This boundary groups related functionality but could also be seen as encapsulating volatility"_ — name the volatility or it's functional decomposition. "Could be seen as" is not an axis of change.
- _"The interface would only need minor changes"_ — minor interface changes are still leaking. The receptacle doesn't change at all.
- _"This module is only used in one place, but that's fine for now"_ — single-use is the reuse signal firing. Investigate.
- _"The boundary follows the framework's conventions"_ — framework conventions are functional decomposition by default. Convention is not volatility analysis.
- _"This could theoretically change independently"_ — theoretical independence without a concrete change scenario is wishful thinking.
- _"Out of scope for this PR" / "pre-existing"_ — process judgment, not a volatility judgment. Defer with an issue link or fix it.

If fact-check finds issues, revise before presenting to the user.

## Output Format

1. **Boundaries examined** — List each module boundary or decomposition decision reviewed.
2. **Volatility map** — For each boundary: what volatility it encapsulates (or fails to).
3. **Findings** — Boundaries that track functionality rather than volatility, with blast-radius analysis.
4. **Simplifications** — Concrete restructuring to align boundaries with axes of change.
5. **Fact-check result** — Output of `/fact-check` on this evaluation, including the phrase-shape check.
6. **Actions** — One entry per finding: **Fix in this PR** or **Defer `#<issue>`**. Every finding must appear here — including those labeled "pre-existing" or "orthogonal". A finding that never reaches this section has been dismissed, not deferred.

No findings → "No actions." Findings without actions = incomplete review.

## Relationship to /hickey

This skill and `/hickey` are complementary lenses. Hickey asks "are independent concerns interleaved?" Lowy asks "do boundaries encapsulate axes of change?" Run both on architectural decisions for full coverage.

### When Hickey and Lowy Disagree

The two lenses can produce conflicting recommendations. Lowy may say "merge these — shared volatility is duplicated across both" while Hickey says "keep them separate — a mode flag would complect configuration with implementation." Neither lens is wrong; they're optimizing for different things.

The resolution pattern: **unify the volatile axis without complecting the strategies.** Typically this means a wrapper or shared module that encapsulates the volatile part (satisfying Lowy) while the distinct strategies remain private and uncomplected (satisfying Hickey). If merging for blast-radius reduction requires a mode flag, conditional branching, or type-switching — that's complecting. Find the layer where unification is mechanical (a shared function, a common interface, a single config source) rather than conditional.
