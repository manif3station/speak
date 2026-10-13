#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($RealBin);
use Folder;

if (grep { $_ eq '-h' || $_ eq '--help' } @ARGV) {
    print <<'USAGE';
Usage:
  d2 talk.read [OPTIONS]
  perl -Ilib cli/read.pl [OPTIONS]

Read queued messages, speak them using the best-quality available English
macOS voice, and remove them from the queue after processing.

Options:
  -h, --help  Show this help and exit
USAGE
    exit 0;
}
die "talk.read is supported on macOS only\n" if $^O ne 'darwin';

{
    chdir Folder->new_message
      or die "Cannot access the new-message queue: $!";

    opendir( my $dh, '.' )
      or die "Cannot read the new-message queue: $!";

    foreach my $file ( readdir($dh) ) {
        next if !-f $file;
        my ($from, $to) =  map { "$_/$file" } ('.', Folder->speaking);
        rename $from, $to
          or die "Cannot move message '$file' to the speaking queue: $!";
    }

    closedir($dh)
      or die "Cannot close the new-message queue: $!";
}

chdir Folder->speaking
  or die "Cannot access the speaking queue: $!";

opendir( my $dh, '.' )
  or die "Cannot read the speaking queue: $!";

my $failed = 0;
foreach my $file ( sort readdir($dh) ) {
    next if !-f $file;
    open my $fh, '<', $file
      or do {
          warn "Cannot open message '$file': $!\n";
          $failed = 1;
          next;
      };
    local $/;
    my $message = <$fh> // '';
    close $fh
      or do {
          warn "Cannot close message '$file': $!\n";
          $failed = 1;
          next;
      };

    my $status = system 'swift', "$RealBin/../lib/Speaker.swift", $message;
    if ($status != 0) {
        if ($status == -1) {
            warn "Cannot start Swift speech helper: $!\n";
        }
        elsif ($status & 127) {
            warn "Speech helper for '$file' stopped by signal " . ($status & 127) . "\n";
        }
        else {
            warn "Speech helper for '$file' exited with status " . ($status >> 8) . "\n";
        }
        $failed = 1;
        next;
    }

    unlink $file
      or do {
          warn "Cannot remove spoken message '$file': $!\n";
          $failed = 1;
      };
}

closedir($dh)
  or die "Cannot close the speaking queue: $!";
exit 1 if $failed;

__END__

=pod

=head1 NAME

d2 talk.read - speak queued messages

=head1 SYNOPSIS

  perl -Ilib cli/read.pl [-h|--help]
  d2 talk.read [-h|--help]

=head1 DESCRIPTION

Moves regular files from C</tmp/talk/new> into C</tmp/talk/speaking>, then
processes files in filename order. A bundled Swift helper uses Apple's
AVFoundation speech synthesizer and selects the highest-quality available
English voice, preferring US English when quality is equal. Successfully spoken
files are removed. Failed files remain in the speaking queue and are retried
the next time the reader runs.

The Swift helper requires the macOS Swift toolchain. Download an enhanced or
premium English voice in macOS Accessibility settings for more natural speech.

The configured C<d2 talk.read> collector runs this script every two seconds.

=head1 OPTIONS

C<-h> or C<--help> prints usage information and exits.

=cut
