# vim: ft=perl
use strict;
use Irssi;
use vars qw($VERSION %IRSSI);

## Settings:
#
# quakenet_account (string) = <servertag>:<username>:<password>
#   List of QuakeNet accounts, in format <servertag>:<username>:<password>
#   Multiple accounts can be separated by spaces.
#
#   <servertag> can be empty to match all connections not already specified.
#   (The script checks for QuakeNet and Q, so this is only useful if you have
#   multiple accounts for some strange reason.)
#
# quakenet_auth_allowed_mechs (string) = any
#   List of allowed mechanisms, separated by spaces.
#   Can be "any" to allow all supported mechanisms.
#
#   Currently supported:
#      HMAC-SHA-256 (Digest::SHA)
#      HMAC-SHA-1   (Digest::SHA1)
#      HMAC-MD5     (Digest::MD5)
#      LEGACY-MD5   (Digest::MD5 without HMAC)
#
#   Note: LEGACY-MD5 is excluded from "any"; if you want to use it, specify
#   it manually.
#
## To trigger the script manually, use:
## /msg Q@cserve.quakenet.org challenge

$VERSION = "1.0";
%IRSSI = (
	authors     => 'Mantas Mikulėnas',
	contact     => 'grawity@gmail.com',
	name        => 'auth_quakenet_challenge.pl',
	description => "Implements QuakeNet's CHALLENGE authentication",
	license     => 'WTFPL v2 <http://sam.zoy.org/wtfpl/>',
	url         => 'http://purl.net/net/grawity/irssi.html',
);

require Digest::HMAC;

my %supported_mechs = ();

eval {
	require Digest::SHA;
	$supported_mechs{"HMAC-SHA-256"} = sub {
		hmac(\&Digest::SHA::sha256_hex, \&Digest::SHA::sha256, @_);
	};
};

eval {
	require Digest::SHA1;
	$supported_mechs{"HMAC-SHA-1"} = sub {
		hmac(\&Digest::SHA1::sha1_hex, \&Digest::SHA1::sha1, @_);
	};
};

eval {
	require Digest::MD5;
	$supported_mechs{"HMAC-MD5"} = sub {
		hmac(\&Digest::MD5::md5_hex, \&Digest::MD5::md5, @_);
	};
	$supported_mechs{"LEGACY-MD5"} = sub {
		Irssi::print("WARNING: LEGACY-MD5 should not be used.");
		my ($challenge, $username, $password) = @_;
		Digest::MD5::md5_hex($password . " " . $challenge);
	}
};

if (scalar keys %supported_mechs == 0) {
	die "No mechanisms available. Please install these Perl modules:\n"
		."  Digest::HMAC\n"
		."  Digest::SHA, Digest::SHA1, Digest::MD5 (at least one)\n";
}

sub hmac {
	my ($fnhex, $fnraw, $challenge, $username, $password) = @_;
	my $key = &$fnhex($username . ":" . &$fnhex($password));
	return Digest::HMAC::hmac_hex($challenge, $key, $fnraw);
}

sub lci { my $t = shift; $t =~ tr/[\\]~/{|}^/; return lc($t); }

my @preferred_mechs = qw(HMAC-SHA-256 HMAC-SHA-1 HMAC-MD5);

Irssi::settings_add_str("misc", "quakenet_auth_allowed_mechs", "any");
Irssi::settings_add_str("misc", "quakenet_account", "");

if (Irssi::settings_get_str("quakenet_account") eq "") {
	Irssi::print("Set your QuakeNet account using /set quakenet_account quakenet:username:password");
}

sub get_account {
	my ($servertag) = @_;
	my $accounts = Irssi::settings_get_str("quakenet_account");
	my ($defuser, $defpass) = (undef, undef);
	foreach my $acct (split / +/, $accounts) {
		my ($tag, $user, $pass) = split /:/, $acct, 3;
		if (lc $tag eq lc $servertag) {
			return ($user, $pass);
		}
		elsif ($tag eq "*" or $tag eq "") {
			($defuser, $defpass) = ($user, $pass);
		}
	}
	return ($defuser, $defpass);
}

Irssi::signal_add_last "event 001" => sub {
	my ($server, $evargs, $srcnick, $srcaddr) = @_;
	return unless $srcnick =~ /\.quakenet\.org$/;

	my ($u, $p) = get_account($server->{tag});
	return if (!defined $p) or ($p eq "");

	$server->print("", "Authenticating to Q");
	$server->send_message('Q@cserve.quakenet.org', "CHALLENGE", 1);
};

Irssi::signal_add_first "message irc notice" => sub {
	my ($server, $msg, $nick, $address, $target) = @_;
	return unless $server->mask_match_address('Q!*@cserve.quakenet.org', $nick, $address);

	if ($msg =~ /^CHALLENGE ([0-9a-f]+) (.+)$/) {
		my $challenge = $1;
		my @server_mechs = split " ", $2;
		Irssi::signal_stop();

		my ($user, $password) = get_account($server->{tag});
		return unless (defined $password) and ($password ne "");
		$user = lci $user;
		$password = substr $password, 0, 10;

		my $mech;
		my @allowed_mechs = ();
		my $allowed_mechs = uc Irssi::settings_get_str("quakenet_auth_allowed_mechs");
		if ($allowed_mechs eq "ANY") {
			# @preferred_mechs is sorted by strength
			@allowed_mechs = @preferred_mechs;
		}
		else {
			@allowed_mechs = split / +/, $allowed_mechs;
		}

		# choose first mech supported by both sides
		foreach my $m (@allowed_mechs) {
			if (grep { $_ eq $m } @server_mechs
				&& grep { $_ eq $m } (keys %supported_mechs))
				{ $mech = $m; last; }
		}

		if (!defined $mech) {
			$server->print("", "Authentication failed: no mechanisms available");
			$server->print("", "Server offers: ".join(", ", @server_mechs));
			$server->print("", "Client supports: ".join(", ", keys %supported_mechs));
			$server->print("", "Restricted to: ".join(", ", @allowed_mechs));
			return;
		}

		my $authfn = $supported_mechs{$mech};

		my $response = &$authfn($challenge, $user, $password);
		$server->send_message('Q@cserve.quakenet.org', "CHALLENGEAUTH $user $response $mech", 1);
	}
	
	elsif ($msg =~ /^You are now logged in as (.+?)\.$/) {
		$server->print("", "Authentication successful, logged in as $1");
		Irssi::signal_stop();
	}

	elsif ($msg =~ /^Username or password incorrect\.$/) {
		$server->print("", "Authentication failed.");
		Irssi::signal_stop();
	}
};
