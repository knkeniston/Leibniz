#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More tests => 3;

my $fname;
foreach my $maybe_fname ("README", "README.txt", "README.md") {
	if (-f $maybe_fname) {
		$fname = $maybe_fname;
		last;
	}
}

ok(defined $fname, "README found") || die "No README; bailing\n";
# ok(-f $fname, "README found");

# I've decided I hate Perl, so let's just grep
ok(!system("grep -qi \"name:.*[[:alpha:]]\" $fname"), "README contains a name");
ok(!system("grep -qi \"email.*@.*\" $fname"), "README contains an email");

# Do we really want to require a SID in the README?
# These repos are supposed to be private, but the students might screw it up...
# ok($readme =~ qr/^sid:\s+[0-9]+$/mi, "README contains a SID");
