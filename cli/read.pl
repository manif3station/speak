#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($RealBin);
use Folder;

$| = 1;

if ( grep { $_ eq '-h' || $_ eq '--help' } @ARGV ) {
    print <<'USAGE';
Usage:
  d2 talk.read [OPTIONS]
  perl -Ilib cli/read.pl [OPTIONS]

Read queued messages, speak them using the best-quality English macOS voice
available to a command-line process, and remove them from the queue after
processing.

Options:
  -h, --help  Show this help and exit
USAGE
    exit 0;
}

{
    chdir Folder->new_message
      or die "Cannot access the new-message queue: $!";

    opendir( my $dh, '.' )
      or die "Cannot read the new-message queue: $!";

    foreach my $file ( readdir($dh) ) {
        next if !-f $file;
        my ( $from, $to ) = map { "$_/$file" } ( '.', Folder->speaking );
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

    unlink $file;
    print "> $message\n";
    my $say = $ENV{SAY_BIN} // 'say';
    while (system $say => $message) {
        sleep 1;
        system $say => 'excuse me';
        sleep 1;
    }
}

closedir($dh)
  or die "Cannot close the speaking queue: $!";
exit 1 if $failed;

sub speak {
    my ($text) = @_;

    my $width = 80;

    for my $line ( split /\n/, $text, -1 ) {

        # Preserve blank lines
        if ( $line =~ /^\s*$/ ) {
            print "\n";
            next;
        }

        my @words = split /\s+/, $line;
        my $out   = '';

        for my $word (@words) {
            if ( !$out ) {
                $out = $word;
            }
            elsif ( length($out) + 1 + length($word) <= $width ) {
                $out .= " $word";
            }
            else {
                system say => $out;
                $out = $word;
            }
        }

        system say => $out;
    }
}

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
AVFoundation speech synthesizer and selects the highest-quality English voice
available to a command-line process, preferring the Samantha voice when quality
is equal. Siri natural voices are excluded because their model files are not
accessible to this process on some macOS installations. Successfully spoken
files are removed. Failed files remain in the speaking queue and are retried
the next time the reader runs.

The Swift helper requires the macOS Swift toolchain. Download an enhanced or
premium English voice in macOS Accessibility settings for more natural speech.

The configured C<d2 talk.read> collector runs this script every two seconds.

=head1 OPTIONS

C<-h> or C<--help> prints usage information and exits.

=cut
