---
name: ears-spec
description: Companion to cc-sdd for EARS requirements. Use when writing, reviewing or fixing docs/specs/<feature>/requirements.md, when the harness lint-ears hook reports a malformed acceptance criterion, or when turning acceptance criteria into tests (requirement ID to test mapping).
when_to_use: '"write requirements", "EARS", "acceptance criteria", "lint-ears failed", "which tests cover this requirement", before writing the first failing test of a feature.'
---

# EARS requirements (cc-sdd companion)

cc-sdd owns the authoring of specs (`/kiro-spec-init`, `/kiro-spec-requirements`,
`/kiro-validate-*`). This skill does **not** replace it. It adds three rules the
harness enforces so that every requirement is mechanically checkable and
transposable into tests.

Specs live in `docs/specs/<feature>/requirements.md` (cc-sdd installed with
`npx cc-sdd@latest --claude-skills --kiro-dir docs`).

## Rule 1: every acceptance criterion is a valid EARS sentence

Each numbered item under a `#### Acceptance Criteria` heading must match one of
the five EARS patterns. Keywords stay in English, case does not matter.

| Pattern | Template |
|---|---|
| Ubiquitous | `The <system> shall <response>` |
| Event-driven | `When <trigger>, the <system> shall <response>` |
| State-driven | `While <state>, the <system> shall <response>` |
| Unwanted behaviour | `If <condition>, then the <system> shall <response>` |
| Optional feature | `Where <feature is included>, the <system> shall <response>` |

Combinations are allowed (`While <state>, when <trigger>, the <system> shall …`).
One criterion = one observable behaviour. Avoid vague words (fast, user-friendly,
appropriate, etc.); give a measurable threshold instead.

The `lint-ears` hook rejects any criterion that does not start with
`When|While|If|Where|The` and contain `shall`. Fix the sentence; do not
silence the lint by moving the text out of the Acceptance Criteria list.

## Rule 2: every criterion has a stable ID

IDs are derived from cc-sdd's numbering, so nothing extra has to be written in
the spec:

```
REQ-<feature>-<requirement number>.<criterion number>
```

`docs/specs/login/requirements.md`, `### Requirement 2`, criterion `3.` gives
`REQ-login-2.3`. This is the same `N.M` notation cc-sdd uses in `tasks.md`
(`_Requirements: 2.3_`).

Never renumber existing requirements or criteria once tests reference them:
append new ones at the end and mark removed ones `~~struck through~~ (removed)`.

If a spec line must carry an explicit ID (spec written outside cc-sdd), use
`- [REQ-<feature>-<n>.<m>] <EARS sentence>`; the lint checks those lines too.

## Rule 3: every ID is covered by at least one test

Before implementation (superpowers `test-driven-development`), write at least
one failing test per criterion, carrying the ID in its name or annotation:

- Swift Testing: `@Test("REQ-login-2.3 locks account after 5 failed attempts")`
- XCTest: `func test_REQ_login_2_3_locksAccountAfterFiveFailures()`
- JUnit/Kotlin: `@DisplayName("REQ-login-2.3 …")` or `` fun `REQ-login-2_3 locks account`() ``
- Jest/Vitest: `it("REQ-login-2.3 locks account after 5 failed attempts", …)`

Translate the EARS structure directly into Given/When/Then:

| EARS part | Test part |
|---|---|
| `While <state>` / `Where <feature>` | Given (arrange) |
| `When <trigger>` / `If <condition>` | When (act) |
| `the <system> shall <response>` | Then (assert) |

Unwanted-behaviour (`If`) criteria always need a negative-path test.

## Coverage check

To list criteria without a test, compute the IDs from the spec and grep the test
sources:

```bash
f=login; awk -v f="$f" '/^### Requirement [0-9]+/{match($0,/[0-9]+/);r=substr($0,RSTART,RLENGTH)} /^#### Acceptance Criteria/{a=1;next} /^#/{a=0} a&&/^[0-9]+\./{split($0,p,".");print "REQ-" f "-" r "." p[1]}' docs/specs/$f/requirements.md \
  | while read id; do grep -rqF -e "$id" -e "${id//[.-]/_}" Tests tests src 2>/dev/null || echo "uncovered: $id"; done
```

Report uncovered IDs during superpowers `verification-before-completion`.
