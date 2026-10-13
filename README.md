# talk

`talk` is a small macOS Perl message queue that speaks queued messages with
Apple's AVFoundation speech synthesizer. The sender writes messages to a shared
directory, and the reader speaks and consumes them.

## Requirements

- Perl
- The macOS Swift toolchain (provided by Xcode or Xcode Command Line Tools)

The reader uses the highest-quality English voice available to a command-line
process, preferring US English when voice quality is equal and Samantha when
quality is tied. macOS may list Siri natural voices that a command-line helper
cannot access; those voices are excluded to avoid playback failures.

## Usage

Send a message:

```sh
perl -Ilib cli/__init__.pl "Hello there"
```

Read queued messages:

```sh
perl -Ilib cli/read.pl
```

For the installed D2 commands, install the skill and send/read a message:

```sh
d2 skill install "$PWD"
d2 talk Hello there
d2 talk.read
```

The sender joins its command-line arguments with spaces. Both scripts accept
`-h` or `--help` to display usage information.

The D2 collector configuration in `config/config.json` registers `d2 talk` as
the sender and `d2 talk.read` as the reader; the reader collector is configured
to run every two seconds.

## Message flow

Messages are staged under `/tmp/talk` and moved into `/tmp/talk/new`. The reader
moves pending files into `/tmp/talk/speaking`, speaks each message in filename
order through `lib/Speaker.swift`, and removes successfully spoken files. If
speech fails, the file remains in the speaking queue for a later retry.
`lib/Folder.pm` owns these directory paths and creates directories as
requested.

The speech helper uses the Swift and AVFoundation frameworks supplied by macOS;
no extra Homebrew packages are required. The lowercase `brewfile` records this
system dependency policy.

## Validation

There is no checked-in test suite, build system, or linter configuration. Check
Perl syntax with:

```sh
perl -Ilib -c cli/__init__.pl
perl -Ilib -c cli/read.pl
perl -Ilib -c lib/Folder.pm
podchecker cli/__init__.pl cli/read.pl lib/Folder.pm
swiftc -typecheck lib/Speaker.swift
```

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
