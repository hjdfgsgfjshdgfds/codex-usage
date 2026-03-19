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

## Run locally

```bash
swift run
```

If you launch from Xcode, set the same environment variables in the Run scheme.

## Notes

- The app recursively searches returned JSON for common key names (`used_messages`, `remaining_messages`, `max_messages`, etc.).
- If your payload shape differs, run once with `CHATGPT_DEBUG_DUMP=1` and update key mappings in `Sources/CodexUsageService.swift`.
