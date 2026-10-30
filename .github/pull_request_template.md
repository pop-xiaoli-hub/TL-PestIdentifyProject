## Summary

- What problem does this PR solve?
- What is the minimal scope of changes?

## Changes

- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Docs
- [ ] Chore

Key changes:

1. 
2. 
3. 

## Verification

- [ ] Local build passes (`xcodebuild ... build`)
- [ ] Main user path tested
- [ ] No obvious regression found

Test details:

1. 
2. 
3. 

- Evidence scope: build / isolated component / local real SSE / physical device / production
- Environment, date, command and observed output:
- Backend contract status: client implemented locally / shared backend implemented / shared backend exercised / not deployed / not applicable (report separately):
- Stop, stale generation/ticket, unknown POST outcome, seq/cursor checkpoint transaction, snapshot replacement and account isolation checked where affected:

## Risk & Rollback

- Risk level: Low / Medium / High
- Possible impact:
- Rollback plan:

## Screenshots (if UI changed)

- Before:
- After:

## Checklist

- [ ] Branch is up to date with latest `main`
- [ ] No debug logs / temporary code left
- [ ] Naming and file structure follow project conventions
- [ ] Public README and affected workflows updated; local review notes and handoff materials are not required for this PR
- [ ] No automatic replay of the legacy POST; restarted unknown job creation is lookup-only, and explicit job selection is not described as production recovery
- [ ] Build, fixture, isolated tests and device/production evidence distinguished

