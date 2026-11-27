# Claudewin11
Environment for windows

## Windows smoke test (GitHub Actions)

GitHub has no Windows emulator, but its `windows-latest` machines are real Windows VMs, so the app is
built and actually run there.

- `scripts/smoke-test.ps1` starts the app and checks that it opens a window, stays running, responds,
  has no crash in the Windows event log, and closes cleanly. It saves a screenshot and a report.
- `.github/workflows/windows-smoke-test.yml` builds a .NET project and runs that test. Pushing here
  tests the sample in `samples/HelloWinForms`. Other repos can reuse it:

```yaml
jobs:
  test:
    uses: drortl/Claudewin11/.github/workflows/windows-smoke-test.yml@main
    with:
      project: src/MyApp/MyApp.csproj
      exe-name: MyApp.exe
```

Run the script on your own PC too: `.\scripts\smoke-test.ps1 -ExePath bin\Release\net8.0-windows\MyApp.exe`
