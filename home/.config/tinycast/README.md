# Tinycast

Installed from `abue-ammar/tinycast` by `packages/bundle`. This is the upstream
self-signed stable release, not an Apple-notarized application; the cask clears
its quarantine flag. On a new Mac, explicitly trust the tap before installation:

```sh
brew trust --tap abue-ammar/tinycast
```

## Configuration

1. Run `dot stow` before opening Tinycast.
2. In Tinycast, enable **Settings → Backup → Settings File**. Choose **Import**
   when it detects the existing file, not Replace.
3. Verify **General → App Launcher** shows Command-Space. Enable Launch at login.
4. Grant Accessibility yourself for clipboard paste, snippets and window actions.

`settings.json` is tracked and carries the launcher, window-management and emoji
shortcuts; the file alone does nothing until Settings File is enabled.
Tinycast keeps UserDefaults as its source of truth and applies this JSON mirror
only after Settings File is enabled. GUI edits rewrite the mirror, and edits to
it apply live. Upstream explicitly preserves symlinks. GUI changes show up as
git diffs: review them for personal paths or prompts before committing.

Tinycast has System/Light/Dark appearance, not our Vicinae Catppuccin theme.
Extensions, AI, snippets and other opt-in capabilities need separate setup.
Do not import credentials or enable third-party code automatically. Current
Raycast imports require a v2 export; the saved Raycast preference plist is not one.

Vicinae configuration backups were deleted. Earlier Raycast data/backups remain.
Avoid assigning Command-Space to multiple launchers or running simultaneous
clipboard/snippet managers.
