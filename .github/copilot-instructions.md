# Copilot instructions

## Project shape

This is a small macOS Perl utility with two commands that pass messages through a filesystem queue and a Swift helper that speaks messages:

- `cli/__init__.pl` is the sender. It joins the command-line arguments into a message, stages a `.msg` file in the data directory, and renames it into the `new` queue.
- `cli/read.pl` is the reader. It moves files from `new` to `speaking`, speaks them in filename order, then removes successful messages.
- `lib/Speaker.swift` uses AVFoundation and selects the highest-quality installed English voice, preferring US English when quality is equal.
- `lib/Folder.pm` centralizes the queue paths under `/tmp/talk` and creates the directories on demand.
- `config/config.json` registers `d2 talk` and `d2 talk.read`; the reader collector is configured to poll every two seconds.

The directory transitions are the queue protocol: keep sender and reader behavior aligned with `Folder`'s paths and preserve the staging/rename handoff when changing message handling. Failed speech leaves the message in `speaking` for a later retry. The Swift helper is macOS-specific and uses the system Swift toolchain; do not add external speech packages without updating `brewfile`.

## Running and checking

Run the scripts directly with the shared module on Perl's include path:

```sh
perl -Ilib cli/__init__.pl "message text"
perl -Ilib cli/read.pl
```

Check syntax for the scripts or shared module with:

```sh
perl -Ilib -c cli/__init__.pl
perl -Ilib -c cli/read.pl
perl -Ilib -c lib/Folder.pm
swiftc -typecheck lib/Speaker.swift
```

There is no checked-in build, lint, or test runner, and no test files are currently present. To exercise the installed D2 flow, run `d2 skill install "$PWD"`, then `d2 talk <message>` and `d2 talk.read`.

## Code conventions and behavior

- Perl files use `strict` and `warnings`; retain both in new or modified Perl code.
- Keep the embedded POD in each Perl script and module aligned with its actual command or API behavior.
- Keep the AVFoundation speaker's voice selection and completion behavior in `lib/Speaker.swift`; the Perl reader invokes that helper and retains messages when speaking fails.
- Keep queue directory behavior in `Folder.pm` rather than duplicating `/tmp/talk` paths in command scripts.
- The sender uses epoch-second filenames with a `.msg` suffix. Account for the fact that messages created within the same second can share a filename.
- The reader only processes regular files and removes them after successful speech; failed messages remain in the speaking queue for retry.

## Commit messages

Use a summary of at most 80 characters, followed by a blank line, a short
description, another blank line, and a `Changes:` section with numbered
`1) ...` entries. Keep punctuation ASCII-only. Do not include co-author trailers
or process/template codenames in commit messages.
