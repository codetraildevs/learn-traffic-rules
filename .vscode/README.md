# Branch-specific workspace settings

These settings hide the other project in Explorer and Problems when you work on one part of the repo.

- **On `main`:** `settings.json` hides `frontend` (Explorer + Problems + Dart analysis). Use when working on backend only.
- **On `feature/multi-language-support`:** `settings.json` hides `backend` (Explorer + Problems + Dart analysis). Use when working on frontend only.

**To keep the right view when you switch branches:** commit `settings.json` on each branch with the correct content.

- On **main**: ensure `settings.json` matches `settings-main.example.json`, then commit.
- On **feature/multi-language-support**: copy `settings-frontend.example.json` into `settings.json`, then commit.

After switching branch, **reload the window** (Ctrl+Shift+P → "Developer: Reload Window") so the Dart analyzer picks up the new exclusions and the Problems panel updates.
