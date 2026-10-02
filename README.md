# live-share.nvim

Live collaboration between independent Neovim processes, with no plugin dependencies
and no external server executable. Edit together across nodes that share a file over
NFS, or join directly by host, port and token.

The source lives on disk; unsaved edits and peer cursors travel over TCP. Sharing
an NFS path alone does not provide a network connection between the editors.

## Requirements

- Neovim 0.12 or newer on Linux or macOS.
- A reachable TCP port between participants.
- Git is used only to exclude session credentials when advertising inside a Git repository.
  Without safe exclusion, manual sharing still works.

## Local installation

Add the package directory to your `init.lua` before loading plugins:

```lua
vim.opt.runtimepath:prepend("/Users/sunwookh/01_code/live-share.nvim")
require("live-share").setup({
    discovery = true,
    max_peers = 8, -- Includes the owner; 2–64.
})
```

Use the equivalent absolute directory on other machines. There is no dependency on
FLASH, dotfiles, a language server or Treesitter. Commands also register automatically
when installed as a native `pack/*/start` plugin. Transport code stays unloaded until
it is needed; discovery performs one filesystem check per source-file read.

## Usage

On the owner, open a named, editable UTF-8 source file, save it and run:

```vim
:LiveShare
```

This opens a dedicated shared buffer and advertises the session beside the source.
Another participant opening that source in their active editor receives a join prompt.
For files that were already open, use `:LiveShareJoin` without arguments.

Manual joining works without shared storage:

```vim
:LiveShareJoin <owner-host> <port> <token>
```

The owner can find that command in `:messages`. The default bind address is `0.0.0.0`
and the port is selected automatically. For local-only collaboration:

```vim
:LiveShare 0 127.0.0.1
```

| Command / key | Action |
| --- | --- |
| `:LiveShare [port] [bind-address]` | Share the current source; at most one session per Neovim process |
| `:LiveShareJoin [host port token]` | Join the current source's advertised session or an explicit session |
| `:LiveShareStatus` | Show role, revision, pending edits and peer cursor positions |
| `:LiveShareStop` | Disconnect; the owner also stops the server |
| `u` / `Ctrl+r` | Undo / redo your own edits in the shared buffer |
| `:w` | Owner saves synchronized text through the original source buffer |

Edit the shared buffer rather than the original source. Guests cannot save the original
through this plugin. Source-buffer changes or external disk changes prevent the owner
from overwriting them. Disconnecting retains the shared buffer's text.

Public Lua entry points mirror the commands:

```lua
require("live-share").start({ "0", "127.0.0.1" })
require("live-share").join({ "host", "12345", "token" })
require("live-share").status()
require("live-share").stop()
```

## Safety and limits

- The bearer token authorizes access. TCP is not encrypted; use a trusted network or an SSH tunnel.
  Do not publish the token or forward it to people who should not edit the document.
- Sidecars retain the `.<name>.flash-share` filename and protocol used by FLASH's
  live-share branch, so both implementations can discover and join each other.
- Sidecars and their random temporary files are excluded through local Git `info/exclude`.
  Existing advertised sessions prevent a second owner. If safe advertisement fails,
  the manual command remains available.
- Sidecar readers follow source write-permission classes. This is not a general
  access-control system: ACLs and network security must be configured separately.
- Discovery never prompts for a background preview. If the target window or buffer
  changes during connection, the shared buffer remains available through `:buffer`.
- Concurrent UTF-8 edits use byte-based operational transformation. Final newline is
  retained, and documents are limited to 1 MiB. Undo history, queues and lag are bounded.
- Shared `acwrite` buffers have their own in-memory undo. LSP attachment, formatting and
  other editor features are left to the user's configuration; they are not supplied here.
- Sidecars are removed on clean owner exit. Same-host stale sessions are cleaned up;
  stale files from another host may need manual removal.

Peer colors use `LiveSharePeer1` through `LiveSharePeer6`, linked to the active theme's
native diagnostic/Visual groups. No icon font is required.

[한국어 사용 안내](README.ko.md)
