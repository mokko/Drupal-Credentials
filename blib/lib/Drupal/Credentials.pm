package Drupal::Credentials;

use warnings;
use strict;

=head1 NAME

Drupal::Credentials - Access credentials (username, password etc.) from
Drupal's sites directory (settings.php)!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Read $db_uri from Drupal's settings.php make accessing it easy

    use Drupal::Credentials;

    my $credentials = Drupal::Credentials->new($site_dir);
	$credentials->parse_sites_dir

	my @sites=$credentials->get_sites;

	foreach my $site_id ($sites) {
		my $dbstring=$credentials->get_dbstring($site_id);
		my $proto=$credentials->get_protocoll($site_id);
		my $passw=$credentials->get_password($site_id);
		my $db=$credentials->get_database($site_id);
		my $host=$credentials->get_host($site_id);
		my $username=$credentials->get_username($site_id);
	}
	my $sites_dir=$credentials->get_sites_dir;


=head1 METHODS

=head2 my $credentials = Drupal::Credentials->new($site_dir);

$site_dir is the drupal/sites

Returns 1 on success and nothing on failure.

=cut

sub new {

	my $class     = shift;
	my $sites_dir = shift;
	if ( !$sites_dir ) {
		return;

		#	carp "Sites_dir not specified!";
	}
	if ( !-e $sites_dir ) {
		return;

		#carp "Sites_dir does not exist";
	}

	my $self = {};
	$self->{sites_dir} = $sites_dir;

	bless( $self, $class );
	return $self;
}

=head2 $credentials->parse_sites_dir

Reads the directory specified as sites_dir during new, and looks for
subdirectories which a setting.php file in them. Settings.php file
is searched for $db_url from which the credentials are extracted.

=cut

sub parse_sites_dir {
	my $self = shift;

	opendir( my $dh, $self->{sites_dir} ) || die "can't opendir sites dir: $!";
	my @sites = grep { !/^\.|all/ && -d "$self->{sites_dir}/$_" } readdir($dh);
	closedir $dh;

	my @dbstrings;
	foreach my $site_name (@sites) {
		my $path = "$self->{sites_dir}/$site_name";

		#		$self->{sites}{$site_name}='';

		if ( -f "$path/settings.php" ) {
			open( SETTINGS, "<$path/settings.php" );
			while (<SETTINGS>) {
				if ( $_ =~ /^\s*\$db_url\s*=\s*'(\w+:\/\/[^']+)'/ ) {
					$self->{sites}{$site_name}{dbstring} = $1;
					$self->_parse_dbstring($site_name);

				#					($1) ? $href->{function} = $1 : die "no function found\n";
				}
			}
			close SETTINGS;
		}
	}
	return 1;    #indicate success
}

sub _parse_dbstring {
	my $self      = shift;
	my $site_name = shift;

	#PERL REGEX
	#perl \w is the word character (alphanumeric or _) [0-9a-zA-Z_]

	#PROTOCOL
	#mail me if you have a better name for 'protocol'
	#protocol unlikeley to have anything else than \w
	#USERNAME / PASSWORD
	#see e.g. mysql http://dev.mysql.com/doc/refman/5.1/en/user-names.html
	#username should not be longer than 16 characters, but I don't care
	#all ascii characters allowed/recommended, possibly even more
	#Drupal::Credentials should be permissive
	#HOST / DATABASE
	#I guess it is possible to use unicode for host and db, but that would
	#be a little insane. Here I limit it [0-9a-zA-Z_-+&@!]
	#Tell if this is too restrictive!

	$self->{sites}{$site_name}{dbstring} =~
	  /(\w+):\/\/ 			#protocol
	   (\p{IsASCII}+): 		#username
	   (\p{IsASCII}+)@ 		#password
	   ([\w\-\+\!\@\&]+)\/  #host
	   ([\w\-\+\!\@\&]+)	#db
	  /x;

	$self->{sites}{$site_name}{protocol} = $1;
	$self->{sites}{$site_name}{username} = $2;
	$self->{sites}{$site_name}{password} = $3;
	$self->{sites}{$site_name}{host}     = $4;
	$self->{sites}{$site_name}{db}       = $5;

}


=head2 my $host=$credentials->get_host($site_id);

Return host from credentials.

=cut


#ALTERNATIVE WOULD BE TO USE AUTOLOAD. will not be faster, but
#cleaner code

sub get_host {
	my $self      = shift;
	my $site_name = shift;

	#return empty handed when no site specified
	return if ( !$site_name );
	return $self->{sites}{$site_name}{host};
}

=head2 my $pw=$credentials->get_password($site_id);

Return password from credentials for site with $site_id.

=cut


sub get_password {
	my $self      = shift;
	my $site_name = shift;

	return if ( !$site_name );
	return $self->{sites}{$site_name}{password};
}

=head2 my $proto=$credentials->get_protocol($site_id);

Return 'protocol' from credentials for site with $site_id.

=cut


sub get_protocol {
	my $self      = shift;
	my $site_name = shift;

	return if ( !$site_name );
	return $self->{sites}{$site_name}{protocol};
}

=head2 my $un=$credentials->get_username($site_id);

Return username from credentials for site with $site_id.

=cut


sub get_username {
	my $self      = shift;
	my $site_name = shift;

	return if ( !$site_name );
	return $self->{sites}{$site_name}{username};
}

=head2 my $db=$credentials->get_database($site_name);

Return database from credentials for site with $site_id.

=cut

sub get_database {
	my $self      = shift;
	my $site_name = shift;

	#return empty handed when no site specified
	return if ( !$site_name );
	return $self->{sites}{$site_name}{db};
}

=head2 my @sites=$credentials->get_sites;

Return site ids in an array. A site id is the name of the directory in sites
directory, e.g.
	exampledomain.com

(In code site id is sometimes referred to as site name.)

=cut

sub get_sites {
	my $self = shift;
	return keys %{ $self->{sites} };
}

=head2 my $sites_dir=$credentials->get_sites_dir;

Return Drupal's path for site as specified during new.

=cut


sub get_sites_dir {
	my $self = shift;
	return $self->{sites_dir};
}

=head1 AUTHOR

Maurice Mengel, C<< <mauricemengel at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-drupal-credentials at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Drupal-Credentials>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Drupal::Credentials


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Drupal-Credentials>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Drupal-Credentials>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Drupal-Credentials>

=item * Search CPAN

L<http://search.cpan.org/dist/Drupal-Credentials/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Maurice Mengel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Drupal::Credentials