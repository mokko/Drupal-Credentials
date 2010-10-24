#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use Drupal::Credentials;
use Data::Dumper;
$Data::Dumper::Indent = 1;
my $credentials = Drupal::Credentials->new('t/sites');

$credentials->parse_sites_dir;

foreach ( $credentials->get_sites ) {
	print "TT$_\n";
}

print "d" . Dumper $credentials;
