#!/usr/bin/perl
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# https://github.com/flimzy/minimal-pairs/

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

# Tested with espeak 1.48

my (%words,%ipa);
while (my $line = <>) {
    next if $line !~ m#^<li>#;
    if ( $line =~ m#^<li>\d+. (.*?)</li># ) {
        my ($item) = ($1);
        $item =~ s/<.*?>//g;
        next if $item eq uc($item);
        
        $words{lc $item} = undef;
        next;
    }
    warn "Unrecognized input: $line\n";
}
warn "Calculating pronunciations\n";
my $i=0;
for my $word (keys %words) {
    my $ipa = qx( espeak -q -v fr --ipa=1 "$word" );
    utf8::upgrade($ipa);
    chomp $ipa;
    $ipa =~ s/^\s+//;
    $words{$word} = $ipa;
    $ipa{$ipa} ||= [];
    push @{$ipa{$ipa}},$word;
    if ($i++ % 10 == 0) {
        print STDERR ".";
    }
}
warn "\nDone.\n";
warn sprintf "Found %i words\n", scalar(keys %words);
warn sprintf "Found %i unique pronunciations\n", scalar(keys %ipa);
$i=0;
for my $ipa ( sort { scalar @{$ipa{$b}} <=> scalar @{$ipa{$a}} } keys %ipa ) {
    printf "%20s : %s\n", $ipa, join(', ',@{$ipa{$ipa}});
    last if $i++ == 20;
}

for my $ipa ( sort { scalar @{$ipa{$b}} <=> scalar @{$ipa{$a}} } keys %ipa ) {
    printf "%20s : %s\n", $ipa, join(', ',@{$ipa{$ipa}});
}
