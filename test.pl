#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use Drupal::Credentials;
use Data::Dumper;
$Data::Dumper::Indent = 1;
#$Drupal::Credentials::Symlinks='follow';
my $credentials = Drupal::Credentials->new('t/sites');


print "in test.pl $Drupal::Credentials::Symlinks \n";
foreach ( $credentials->list ) {
	print "TT$_\n";
}

print "d" . Dumper $credentials;
