package Folder;

use strict;
use warnings;

sub _dir {
    my ($dir, $mode) = @_;
    mkdir $dir if !-d $dir;
    chmod $mode, $dir if $mode && $mode =~/^\d+$/;
    return $dir;
}

sub data { _dir '/tmp/talk' }

sub new_message { _dir data . '/new' }

sub speaking { _dir data . '/speaking' }

1;

__END__

=pod

=head1 NAME

Folder - create and return talk message queue directories

=head1 SYNOPSIS

  use Folder;

  my $data_dir = Folder->data;
  my $new_dir = Folder->new_message;
  my $speaking_dir = Folder->speaking;

=head1 DESCRIPTION

Provides the shared paths used by the sender and reader. Each method creates
its directory if needed, then returns the directory path.

=head1 METHODS

=over 4

=item data

Returns the data directory, C</tmp/talk>.

=item new_message

Returns the incoming message directory, C</tmp/talk/new>.

=item speaking

Returns the directory for messages currently being processed,
C</tmp/talk/speaking>.

=back

=cut
