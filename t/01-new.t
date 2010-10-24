#!perl -T

use Test::More tests => 1;
use Drupal::Credentials;

#my $site

my $credentials=Drupal::Credentials->new('t/sites');

ok(my $obj=Drupal::Credentials->new('t/sites') );

#my $credentials = Drupal::Credentials->new($site_dir);




#diag( "Testing Drupal::Credentials $Drupal::Credentials::VERSION, Perl $], $^X" );
