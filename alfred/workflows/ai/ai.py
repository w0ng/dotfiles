"""Ask Claude and ChatGPT the same thing at once.

Two keywords. `nai` starts a new chat in each app, and `ai` puts the text into
the chat each app already has open. Both then press Escape, clear the composer,
type the text and press Return.

Typing is the only mechanism either app accepts. Neither submits text handed to
it on a URL, and no parameter changes that: Claude reads only q, prompt, surface
and source, and Codex only q, prompt, mode, fallback, target and
automationSource, and none of them send. claude.ai on the web refuses on
purpose, answering a URL-supplied prompt with an injection warning instead of an
answer. Posting a key event straight to each process with CGEventPostToPid was
tried and both apps ignore it. So a keystroke it is, and a keystroke goes to
whatever is frontmost, which is why sending costs a focus change.

`nai` opens its new chat through `claude://claude.ai/new` and
`codex://threads/new?mode=chat` rather than Cmd-N, because `mode=chat` puts
Codex in a chat thread rather than a Work thread whatever tab it was last left
on. It passes no text on the URL. Prefilling by URL and then pressing Return
came first and was abandoned: Claude failed to send at 0.3s and again at 0.5s,
and each failure left the question in the composer for the next run to type
onto, so two questions went as one message.

Escape comes first because activating an app restores whatever it had focused,
which is not always the composer. With Claude's find-in-page open, the text went
into the search box, and in ChatGPT the same keystrokes reached no field at all
and opened a feedback dialog. Escape closes that transient UI and hands focus
back to the composer. Cmd-A and delete then replace a draft rather than typing
onto it, which is what stops two questions becoming one message. It also
discards a half-written draft, which is the lesser harm of the two.

Typing costs about 0.4ms a character, and unlike a paste it leaves the clipboard
alone. Pasting came first and was worse: putting the clipboard back races the
paste, because osascript returns once it has posted a keystroke rather than once
the app has read it, and ChatGPT pasted the restored value instead of the
question.

MAX_BYTES is set by typing time rather than by any limit the apps impose. At
0.4ms a character this is under a second an app, and it bounds the run well
inside OSASCRIPT_TIMEOUT.

`prompt_text` collapses every run of whitespace, because a literal newline
survives into the AppleScript string and `keystroke` presses Return in the
middle of the question, submitting half of it. Alfred passes a single line
today, so this enforces in code what the input happens to guarantee.

SEND_SETTLE is the beat between the last character and Return. The composers
update asynchronously, and without it Return arrives while the box still reads
as empty and submits nothing. 0.05s failed, and 0.1s passed three times on its
own but then failed immediately after `nai`, with both apps still busy drawing a
new chat. 0.2s passed three of those back to back pairs.

NEW_CHAT_WAIT is how long `nai` gives the new chat to appear before typing into
it. 0.45s passed three times and 0.5s passed three more, so it sits just above a
measured floor. Too short a wait types into the chat that was already open and
sends it there, which is the worst failure available here, so this one errs
long.

An app that is not running is skipped and named in a notification, rather than
silently dropped: `nai` still opens its empty new chat, but a cold app can be
showing an update prompt, a sign-in form or an onboarding pane, and neither the
text nor the Return should land there.

One osascript drives both apps, with each app's block wrapped in `try`. A single
invocation without that would stop at the first error, a missing app or refused
automation consent, and never reach the second app. Each block waits for its app
to become frontmost rather than trusting `activate`, which returns before the
app is front.
"""

import subprocess
import sys
import time

MAX_BYTES = 2000

NEW_CHAT_WAIT = 0.5
FOCUS_SETTLE = 0.1
SEND_SETTLE = 0.2

# Bounded, so a stuck app cannot leave an Alfred action running forever.
OSASCRIPT_TIMEOUT = 20
OPEN_TIMEOUT = 15

# Ordered, so focus ends on the second one. "name" is both the AppleScript
# application name and the executable `pgrep -x` matches.
APPS = (
    {"name": "Claude", "new_chat": "claude://claude.ai/new"},
    {"name": "ChatGPT", "new_chat": "codex://threads/new?mode=chat"},
)


def prompt_text(raw):
    # `errors="ignore"` rather than "replace", because argv arrives with
    # undecodable bytes as lone surrogates, and replacing them puts literal ?
    # characters into the question instead of removing them.
    collapsed = " ".join(raw.split())
    encoded = collapsed.encode("utf-8", "ignore")[:MAX_BYTES]
    # A cut inside a multi-byte character leaves a partial sequence behind.
    return encoded.decode("utf-8", "ignore")


def applescript_string(text):
    """Quote text as an AppleScript literal, where only \\ and " are special."""
    escaped = text.replace("\\", "\\\\").replace('"', '\\"')
    return f'"{escaped}"'


def osascript(body):
    try:
        # Leave stderr alone, so a refused automation prompt reaches Alfred's
        # workflow log instead of vanishing.
        subprocess.run(
            ["/usr/bin/osascript", "-e", body],
            stdout=subprocess.DEVNULL,
            check=False,
            timeout=OSASCRIPT_TIMEOUT,
        )
    except (OSError, subprocess.TimeoutExpired):
        pass


def running(app):
    # `pgrep -x` on the executable, never `-f`. The -f flag matches the whole
    # command line, so a question mentioning the app's path would match this
    # very script and report a cold app as warm.
    try:
        return (
            subprocess.run(
                ["/usr/bin/pgrep", "-x", app["name"]],
                stdout=subprocess.DEVNULL,
                check=False,
            ).returncode
            == 0
        )
    except OSError:
        return False


def send(apps, query):
    statements = [
        "key code 53",
        f"delay {FOCUS_SETTLE}",
        'keystroke "a" using command down',
        "key code 51",
        f"keystroke {applescript_string(query)}",
        f"delay {SEND_SETTLE}",
        "keystroke return",
    ]
    action = "\n".join(f"      {line}" for line in statements)
    blocks = []
    for app in apps:
        name = app["name"]
        blocks.append(f"""
try
  tell application "{name}" to activate
  tell application "System Events"
    set waited to 0
    repeat until (frontmost of process "{name}") or waited > 100
      delay 0.02
      set waited to waited + 1
    end repeat
    if frontmost of process "{name}" then
{action}
    end if
  end tell
end try""")
    osascript("\n".join(blocks))


def open_new_chats(apps, warm):
    """Report which of the warm apps opened a new chat."""
    started = []
    for app in apps:
        try:
            started.append((app, subprocess.Popen(["/usr/bin/open", app["new_chat"]])))
        except OSError:
            continue

    opened = []
    for app, proc in started:
        # A cold app is never typed into, so waiting on its launch would only
        # delay the app that is.
        if app not in warm:
            continue
        try:
            if proc.wait(timeout=OPEN_TIMEOUT) == 0:
                opened.append(app)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()
    return opened


def notify(text):
    osascript(f'display notification {applescript_string(text)} with title "Ask AI"')


def main(argv):
    new_chat = (argv[1] if len(argv) > 1 else "new") != "existing"
    query = prompt_text(argv[2]) if len(argv) > 2 else ""
    if not query:
        if new_chat:
            open_new_chats(APPS, ())
        return

    # Probed before anything opens, because opening a chat launches the app and
    # every later check would then report it warm.
    warm = [app for app in APPS if running(app)]
    cold = [app["name"] for app in APPS if app not in warm]
    if cold:
        notify("Not running: " + ", ".join(cold))

    sendable = warm
    if new_chat:
        sendable = open_new_chats(APPS, warm)
        if sendable:
            time.sleep(NEW_CHAT_WAIT)
    if sendable:
        send(sendable, query)


if __name__ == "__main__":
    main(sys.argv)
