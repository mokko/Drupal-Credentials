package Drupal::Credentials;

use warnings;
use strict;

#use URI::Escape; or regex?

=head1 NAME

Drupal::Credentials - Access credentials (user, pass etc.) from
Drupal's sites directory (settings.php)

=head1 VERSION

Version 0.02

=cut

our $VERSION  = '0.02';
$Drupal::Credentials::Symlinks ='dontfollow';    # default is dontfollow or set to follow

=head1 SYNOPSIS

Access info from Drupal's $db_uri contained in settings.php

    use Drupal::Credentials;

#new
	Drupal::Credentials::Symlinks='follow';#default is dontfollow

    my $credentials = Drupal::Credentials->new($site_dir);

	foreach my $site_id ($credentials->list) {
		my $dbstring=$credentials->get_dbstring($site_id);
		my $proto=$credentials->get_scheme($site_id);
		my $passw=$credentials->get_pass($site_id);
		my $db=$credentials->get_database($site_id);
		my $host=$credentials->get_host($site_id);
		my $user=$credentials->get_user($site_id);
#new:
		my $dir=$credentials->get_install_dir ($site_id);
	}
	my $sites_dir=$credentials->get_sites_dir;


=head1 METHODS

=head2 my $credentials = Drupal::Credentials->new($site_dir);

$site_dir is the full path to the drupal/sites directory.

Returns the Drupal::Credentials object on success and nothing on failure.

=cut

sub new {

	my $class     = shift;
	my $sites_dir = shift;
	return if ( !$sites_dir );
	return if ( !-e $sites_dir );

	my $self = {};
	$self->{sites_dir} = $sites_dir;

	bless( $self, $class );
	$self->_parse_sites_dir;
	return $self;
}

=head2 $credentials->_parse_sites_dir

Reads the directory specified as sites_dir during new, and looks for
subdirectories which a setting.php file in them. Settings.php file
is searched for $db_url from which the credentials are extracted.

TODO: Currently, always returns 1. Should be able to fail

=cut

sub _parse_sites_dir {
	my $self = shift;

	opendir( my $dh, $self->{sites_dir} ) || die "can't opendir sites dir: $!";

	#ignore the 'all' directory
	my @sites = grep { !/^\.|all/ && -d "$self->{sites_dir}/$_" } readdir($dh);
	closedir $dh;

	#weed out symlinks unless Drupal::Credentials::Symlinks = 'follow'
	if ( $Drupal::Credentials::Symlinks eq 'dontfollow' ) {
		print "GET HERE $Drupal::Credentials::Symlinks\n";
		@sites=grep (! -l "$self->{sites_dir}/$_",@sites);
	}

	my @dbstrings;
	foreach my $site_id (@sites) {
		my $path = "$self->{sites_dir}/$site_id";

		#		$self->{sites}{$site_id}='';

		if ( -f "$path/settings.php" ) {
			open( SETTINGS, "<$path/settings.php" );
			$self->{sites}{$site_id}{install_dir}=$path;
			while (<SETTINGS>) {
				if ( $_ =~ /^\s*\$db_url\s*=\s*'(\w+:\/\/[^']+)'/ ) {
					$self->{sites}{$site_id}{dbstring} = $1;
					$self->_parse_dbstring($site_id);
				}
			}
			close SETTINGS;
		}
	}
	return 1;    #indicate success
}

sub _parse_dbstring {
	my $self    = shift;
	my $site_id = shift;

	#Which characters are allowed for the components? Mysql is pretty
	#permissive. It allows at least ASCII if not unicode characters in
	#some settings and cases, but Drupal parses input from $db_uri thru
	#php's parse_url() function and requires URI hex encodings. Quote
	#from settings.php:
	#   : = %3a   / = %2f   @ = %40
	#   + = %2b   ( = %28   ) = %29
	#   ? = %3f   = = %3d   & = %26"

	#perl \w is the word character (alphanumeric or _) [0-9a-zA-Z_]

	$self->{sites}{$site_id}{dbstring} =~ /
	   ([\w\-\%\#]+):\/\/ 		#scheme
	   ([\w\-\%\#]+): 	#user
	   ([\w\-\%\#]+)@ 	#pass
	   ([\w\-\%\#]+)\/  	#host
	   ([\w\-\%\#]+)		#db
	  /x;

	$self->{sites}{$site_id}{scheme} = $1;
	$self->{sites}{$site_id}{user}   = $2;
	$self->{sites}{$site_id}{pass}   = $3;
	$self->{sites}{$site_id}{host}   = $4;
	$self->{sites}{$site_id}{db}     = $5;

	#unescape if uri encoded
	foreach (qw/scheme user pass host db/) {
		$self->{sites}{$site_id}{$_} =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

		#print "$self->{sites}{$site_id}{$_}\n";
	}

	#TODO
	#DRUPAL's multiple connections currently not supported!
	#" To specify multiple connections to be used in your site (i.e. for
	# complex custom modules) you can also specify an associative array
	# of $db_url variables with the 'default' element used until otherwise
	# requested."

}

=head2 my $host=$credentials->get_host($site_id);

Return host from credentials.

=cut

#ALTERNATIVE WOULD BE TO USE AUTOLOAD. will not be faster, but
#cleaner code

sub get_host {
	my $self    = shift;
	my $site_id = shift;

	#return empty handed when no site specified
	return if ( !$site_id );
	return $self->{sites}{$site_id}{host};
}

=head2 my $pw=$credentials->get_pass($site_id);

Return pass from credentials for site with $site_id.

=cut

sub get_pass {
	my $self    = shift;
	my $site_id = shift;

	return if ( !$site_id );
	return $self->{sites}{$site_id}{pass};
}

=head2 my $proto=$credentials->get_scheme($site_id);

Return scheme from credentials for site with $site_id.

=cut

sub get_scheme {
	my $self    = shift;
	my $site_id = shift;

	return if ( !$site_id );
	return $self->{sites}{$site_id}{scheme};
}

=head2 my $un=$credentials->get_user($site_id);

Return user from credentials for site with $site_id.

=cut

sub get_user {
	my $self    = shift;
	my $site_id = shift;

	return if ( !$site_id );
	return $self->{sites}{$site_id}{user};
}

=head2 my $db=$credentials->get_database($site_id);

Return database from credentials for site with $site_id.

=cut

sub get_database {
	my $self    = shift;
	my $site_id = shift;

	#return empty handed when no site specified
	return if ( !$site_id );
	return $self->{sites}{$site_id}{db};
}

=head2 my $dbstring=$credentials->get_dbstring($site_id);

Return string from settings.php's $db_uri for site with $site_id. This one
will not be unescaped, if it uses hex encoding (e.g. %2a for :). I suspect
that this method is not of real use except for debugging.

=cut

sub get_dbstring {
	my $self    = shift;
	my $site_id = shift;

	#return empty handed when no site specified
	return if ( !$site_id );
	return $self->{sites}{$site_id}{db};
}

=head2 my $credentials->list;
Return site ids in an array. A site id is the name of the directory in sites
directory, e.g.
	exampledomain.com

(In code site id is sometimes referred to as site name.)

=cut

sub list {
	my $self = shift;
	return keys %{ $self->{sites} };

}

=head2 my $sites_dir=$credentials->get_install_dir;

Return path for the installation (in Drupal's site directory). At the moment,
it can be relative or absolute path.

Todo: Do i need an absolute path?

=cut

sub get_install_dir {
	my $self = shift;
	my $site_id = shift;

	#return empty handed when no site specified
	return if ( !$site_id );
	return $self->{sites}{$site_id}{install_dir};
}



=head2 my $sites_dir=$credentials->get_sites_dir;

Return Drupal's path for site as specified during new.

=cut

sub get_sites_dir {
	my $self = shift;
	return $self->{sites_dir};
}

=head1 SEE ALSO

http://php.net/manual/en/function.parse-url.php
Drupal's settings.php

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

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Maurice Mengel.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of Drupal::Credentials
