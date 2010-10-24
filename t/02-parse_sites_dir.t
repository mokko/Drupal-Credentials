#!perl -T

use Test::More tests => 1;
use Drupal::Credentials;

my $credentials=Drupal::Credentials->new('t/sites');

ok($credentials->parse_sites_dir);

#my $credentials = Drupal::Credentials->new($site_dir);




#diag( "Testing Drupal::Credentials $Drupal::Credentials::VERSION, Perl $], $^X" );
