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

=attr start_date

This is the DateTime of the beginning of the first period.  All events
passed to C<find_chains> must be greater than or equal to this value.
(required)

=cut

has start_date => (
  is       => 'ro',
  isa      => 'DateTime',
  coerce   => 1,
  required => 1,
);

=attr increment

This is the DateTime::Duration giving the length of each period.  You
may also pass a hashref acceptable to the DateTime::Duration
constructor.  (required)

=cut

has increment => (
  is       => 'ro',
  isa      => 'DateTime::Duration',
  coerce   => 1,
  required => 1,
);

=attr skip

This is a CodeRef that allows you to skip specified periods.  It is
called with one argument, the DateTime at which the period begins.  If
the CodeRef returns true, any events taking place during this period
are instead considered to take place in the next period.  (The CodeRef
must not change the DateTime object it was given.)  (optional)

For example, to skip Sundays:

  skip => sub { shift->day_of_week == 7 }

=cut

has skip => (
  is       => 'ro',
  isa      => CodeRef,
);

#=====================================================================

=method find_chains

  $info = $seinfeld->find_chains( \@events );

This calculates the Seinfeld chain from the events in C<@events>
(which must be sorted in ascending order).  Note that you must pass an
array reference, not a list.

On return, C<$info> will contain a hashref with two keys: C<last> (the
last chain of events found) and C<longest> (the longest chain found).
These may be the same chain.  The value of each key is a hashref
describing that chain with the following keys:

=over

=item C<start_period>

The DateTime of the start of the period containg the first event of the chain.

=item C<end_period>

The DateTime of the start of the period where the chain broke
(i.e. the first period that didn't contain an event).

=item C<start_event>

The DateTime of the first event of the chain (this is the same object
that appeared in C<@events>, not a copy).

=item C<end_period>

The DateTime of the last event in the chain (this is the same object
that appeared in C<@events>, not a copy).

=item C<length>

The number of periods in the chain.

=item C<num_events>

The number of events in the chain.  This can never be less than
C<length>, but it can be more (if multiple events occurred in one period).

=back

Note:  If C<@events> is empty, then the return value will be an empty hashref.

=cut

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

=head1 DESCRIPTION

DateTimeX::Seinfeld calculates the maximum Seinfeld chain length from
a sorted list of L<DateTime> objects.

The term "Seinfeld chain" comes from advice attributed to comedian
Jerry Seinfeld.  He got a large year-on-one-page calendar and marked a
big red X on every day he wrote something.  The chain of continuous
X's gave him a sense of accomplishment.
(Source: L<http://lifehacker.com/281626/jerry-seinfelds-productivity-secret>)

This module calculates the length of the longest such chain of
consecutive days.  However, it generalizes the concept; instead of
having to do something every day, you can make it every week, or every
month, or any other period that can be defined by a
L<DateTime::Duration>.

Some definitions: B<period> is the time period during which some B<event>
must occur.

=cut
