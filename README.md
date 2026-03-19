# ChatGPT Plus Usage Menubar (macOS)

A tiny SwiftUI menubar app that shows your **ChatGPT Plus** usage in the menu bar, focused on the rolling 5-hour limit window.

## What it displays

- **Used / limit** in the current rolling window (for example `18/40`)
- **Percent used** in the current rolling window
- **Remaining messages** in the current rolling window
- **Total messages** (if returned by the backend payload)
- **Reset timestamp** (if returned by the backend payload)

It polls every 5 minutes and includes a manual **Refresh** button.

## Important caveat

This uses an **unofficial ChatGPT web endpoint** (`/backend-api/usage_limits`) and your browser session token cookie.

- It may break at any time if ChatGPT changes backend payloads or auth flow.
- Keep the session token private.
- This is intended for personal/prototype usage.

## Prerequisites

- macOS 14+
- Xcode 15.4+ (or Swift 5.10 toolchain)
- A `CHATGPT_SESSION_TOKEN` environment variable containing your `__Secure-next-auth.session-token` cookie value

```bash
export CHATGPT_SESSION_TOKEN="<your-session-token>"
```

Optional debug env var to print the raw JSON payload:

```bash
export CHATGPT_DEBUG_DUMP=1
```

## Test it on your local Mac

### 1) Quick API sanity check (Terminal)

Run this first to confirm your token works before opening Xcode:

```bash
curl 'https://chatgpt.com/backend-api/usage_limits' \
  -H "Cookie: __Secure-next-auth.session-token=$CHATGPT_SESSION_TOKEN" \
  -H 'Origin: https://chatgpt.com' \
  -H 'Referer: https://chatgpt.com/' \
  -H 'User-Agent: Mozilla/5.0'
```

If that returns JSON (not an auth error), the app should be able to read usage.

### 2) Run from Terminal

```bash
swift run
```

You should see a new menubar item like `Plus 42%`.

### 3) Run/debug in Xcode (recommended)

1. Open the folder or `Package.swift` in Xcode.
2. Select the `ChatGPTPlusUsageMenubar` run target.
3. Edit Scheme → Run → Arguments → Environment Variables:
   - `CHATGPT_SESSION_TOKEN` = your token
   - (optional) `CHATGPT_DEBUG_DUMP` = `1`
4. Press Run.

### 4) What “working” looks like

- Menubar text changes from `Plus --%` to `Plus <number>%`
- Clicking it shows `5-hour window: used/limit`
- Refresh button updates values

### 5) If it fails

- `401/403`: token expired; grab a fresh session token
- “Could not find usage counters…”: backend JSON shape changed; enable `CHATGPT_DEBUG_DUMP=1` and update keys in `Sources/CodexUsageService.swift`
- No menu item appears: make sure the app is running in macOS (not Linux/CI)

## Notes

- The app recursively searches returned JSON for common key names (`used_messages`, `remaining_messages`, `max_messages`, etc.).
- If your payload shape differs, run once with `CHATGPT_DEBUG_DUMP=1` and update key mappings in `Sources/CodexUsageService.swift`.
