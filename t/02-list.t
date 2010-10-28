#!perl -T

use Test::More tests => 1;
use Drupal::Credentials;

my $credentials=Drupal::Credentials->new('t/sites');

ok(my @list=$credentials->list);

diag( "@list" );
