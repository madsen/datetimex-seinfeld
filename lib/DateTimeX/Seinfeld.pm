#---------------------------------------------------------------------
package DateTimeX::Seinfeld;
#
# Copyright 2012 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 10 Mar 2012
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Calculate Seinfeld chain length
#---------------------------------------------------------------------

use 5.010;
use Moose;
use namespace::autoclean;

use MooseX::Types::Moose qw(CodeRef);
use MooseX::Types::DateTime (); # Just load coercions

our $VERSION = '0.01';
# This file is part of {{$dist}} {{$dist_version}} ({{$date}})

#=====================================================================

has start_date => (
  is       => 'ro',
  isa      => 'DateTime',
  coerce   => 1,
  required => 1,
);

has increment => (
  is       => 'ro',
  isa      => 'DateTime::Duration',
  coerce   => 1,
  required => 1,
);

has skip => (
  is       => 'ro',
  isa      => CodeRef,
);

#=====================================================================

sub find_chains
{
  my ($self, $dates) = @_;

  my %info;

  my $end = $self->start_date->clone;
  my $inc = $self->increment;
  my $skip = $self->skip;

  if (@$dates and $dates->[0] < $end) {
    confess "start_date ($end) must be before first date ($dates->[0])";
  }

  for my $d (@$dates) {
    my $count = 0;
    my $skip_this;
    while ($d >= $end) {
      $skip_this = $skip && $skip->($end);
      $end->add_duration($inc);
      redo if $skip_this;
      ++$count;
    }

    undef $info{last} if $count > 1; # the chain broke

    $info{last} ||= {
      start_event  => $d,
      start_period => $end->clone->subtract_duration( $inc ),
    };

    ++$info{last}{num_events};
    ++$info{last}{length} if $count; # first event in period
    $info{last}{end_event}  = $d;
    $info{last}{end_period} = $end->clone;

    if (not $info{longest} or $info{longest}{length} < $info{last}{length}) {
      $info{longest} = $info{last};
    }
  } # end for each $d in @$dates

  return \%info;
} # end find_chains

#=====================================================================
# Package Return Value:

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 SYNOPSIS

  use DateTimeX::Seinfeld;

  my $seinfeld = DateTimeX::Seinfeld->new(
    start_date => $starting_datetime,
    increment  => { weeks => 1 },
  );

  my $chains = $seinfeld->find_chains( \@list_of_datetimes );

  say "Longest chain: $chains->{longest}{length}";
  say "First event in longest chain: $chains->{longest}{start_event}";

=cut
