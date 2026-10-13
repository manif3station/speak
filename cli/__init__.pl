#!/usr/bin/env perl

use strict;
use warnings;
use Folder;

my @message = @ARGV;

if (grep { $_ eq '-h' || $_ eq '--help' } @message) {
    print <<'USAGE';
Usage:
  d2 talk [OPTIONS] [MESSAGE ...]
  perl -Ilib cli/__init__.pl [OPTIONS] [MESSAGE ...]

Queue a message to be spoken by d2 talk.read. Message arguments are joined
with spaces.

Options:
  -h, --help  Show this help and exit

Examples:
  d2 talk Hello there
  perl -Ilib cli/__init__.pl "Hello there"
USAGE
    exit 0;
}
die "talk is supported on macOS only\n" if $^O ne 'darwin';

my $file = sprintf '%s.msg', time;
my $from = sprintf '%s/%s', Folder->data, $file;
my $to   = sprintf '%s/%s', Folder->new_message, $file;
$| = 1;
open my $fh, '>>', $from;
print $fh join ' ', @message;
close $fh;
rename $from, $to;

__END__

=pod

=head1 NAME

d2 talk - queue a message to be spoken

=head1 SYNOPSIS

  perl -Ilib cli/__init__.pl [-h|--help] [message ...]
  d2 talk [-h|--help] [message ...]

=head1 DESCRIPTION

Joins the command-line arguments with spaces, stages the message under
C</tmp/talk>, and renames it into the C<new> message queue. The configured
C<d2 talk> command invokes this script. The command is supported on macOS.

=head1 OPTIONS

C<-h> or C<--help> prints usage information and exits.

=cut
