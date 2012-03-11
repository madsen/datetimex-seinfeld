#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-chains.t
# Copyright 2012 Christopher J. Madsen
#
# Test calculation of Seinfeld chain length
#---------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

use Test::More 0.88 tests => 3;

use DateTimeX::Seinfeld ();

#---------------------------------------------------------------------
sub dt # Trivial parser to create DateTime objects
{
  my %dt = qw(time_zone UTC);
  @dt{qw( year month day hour minute second )} = split /\D+/, $_[0];
  while (my ($k, $v) = each %dt) { delete $dt{$k} unless defined $v }
  DateTime->new(\%dt);
} # end dt

#---------------------------------------------------------------------
sub test
{
  my ($start, $inc, $dates, $expected) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $seinfeld = DateTimeX::Seinfeld->new( start_date => dt($start),
                                           increment  => $inc );

  $_ = dt($_) for @$dates;
  my $got = $seinfeld->find_chains($dates);

  unless (is_deeply($got, $expected)) {
    diag("Full result:\n");
    for my $type (reverse sort keys %$got) {
      diag(sprintf "   %-7s => {\n", $type);
      my $entry = $got->{$type};

      for my $key (qw(start_period end_period start_event end_event length)) {
        my $value = $entry->{$key};
        if (ref $value) {
          $value = $value->ymd . ' ' . $value->hms;
          $value =~ s/:00$//;
          $value =~ s/ 00:00$//;
          $value = "dt('$value')";
        }
        diag(sprintf "     %-12s => %s,\n", $key, $value);
      } # end for $key
      diag("   },\n");
    } # end for $type
  } # end unless test successful
} # end test

#---------------------------------------------------------------------
sub both
{
  my ($info) = @_;

  return (longest => $info, last => $info);
} # end both

#---------------------------------------------------------------------

test('2012-01-01', { weeks => 1 },
 [qw(
   2012-01-02
   2012-01-10
   2012-01-18
   2012-01-26
   2012-02-03
   2012-02-11
   2012-02-19
   2012-02-27
   2012-03-06
   2012-03-14
   2012-03-22
   2012-03-30
 )],
 {
   longest => {
     start_period => dt('2012-01-01'),
     end_period   => dt('2012-02-12'),
     start_event  => dt('2012-01-02'),
     end_event    => dt('2012-02-11'),
     length       => 6,
   },
   last    => {
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-01'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-03-30'),
     length       => 6,
   }
 }
);

#---------------------------------------------------------------------
test('2012-01-01', { weeks => 1 },
 [qw(
   2012-01-02
   2012-01-10
   2012-01-18
   2012-01-26
   2012-02-03
   2012-02-11
   2012-02-19
   2012-02-27
   2012-03-06
   2012-03-14
   2012-03-22
   2012-03-30
   2012-04-04
 )],
 {
   both ({
     start_period => dt('2012-02-19'),
     end_period   => dt('2012-04-08'),
     start_event  => dt('2012-02-19'),
     end_event    => dt('2012-04-04'),
     length       => 7,
   })
 }
);

#---------------------------------------------------------------------
test('2012-01-01', { days => 1 },
 [qw(
   2012-02-02
   2012-02-03
   2012-02-04
   2012-02-05
   2012-02-06
   2012-02-07
   2012-02-08
   2012-02-09
   2012-02-10
   2012-02-11
   2012-02-12
   2012-02-13
   2012-02-14
   2012-02-15
   2012-02-16
   2012-02-17
   2012-02-18
   2012-02-19
   2012-02-21
   2012-02-22
   2012-02-23
   2012-02-24
   2012-02-25
   2012-02-26
 )],
 {
   longest => {
     start_period => dt('2012-02-02'),
     end_period   => dt('2012-02-20'),
     start_event  => dt('2012-02-02'),
     end_event    => dt('2012-02-19'),
     length       => 18,
   },
   last    => {
     start_period => dt('2012-02-21'),
     end_period   => dt('2012-02-27'),
     start_event  => dt('2012-02-21'),
     end_event    => dt('2012-02-26'),
     length       => 6,
   },
 }
);

#---------------------------------------------------------------------
done_testing;
