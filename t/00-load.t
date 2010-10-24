#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Drupal::Credentials' ) || print "Bail out!
";
}

diag( "Testing Drupal::Credentials $Drupal::Credentials::VERSION, Perl $], $^X" );
