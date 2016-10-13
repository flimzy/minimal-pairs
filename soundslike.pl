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
use Unicode::GCString;
use List::Util qw( max );
use List::MoreUtils qw( any );

my $ignore = "-ːˈ ˌ";

my %chars;
my %ipa;
while (my $line = <>) {
    $line =~ m#^\s*(.*?)\s:\s(.*)$# or die "Unable to read input: $line\n";
    my ( $ipa, $words ) = ($1,$2);
    $ipa =~ s/[$ignore]//g;
    my $gc = Unicode::GCString->new($ipa);
    $ipa{$ipa} = [ $gc, [split /, /,$words] ];
    $chars{ "$_" }++ for $gc->as_array;
}

my $longest_word = max ( map { $_->[0]->columns } values %ipa );

my %pairs;

for my $word (keys %ipa) {
    # print "$word";
    my @matches = find_matches($word);
    # printf "  (%i)\n", scalar @matches;
    next if ! @matches;
    $pairs{$word} ||= [];
    push @{$pairs{$word}}, @matches;
    # last if scalar keys %pairs > 100;
}

sub find_matches {
    my ( $word ) = @_;
    my $len = $ipa{$word}[0]->columns;
    my @candidates =
        grep { $ipa{$_}[0]->columns eq $len } keys %ipa;
    # printf("Found %i candiates\n", scalar @candidates);
    # Eliminate words with more than one difference
    # for (my $i=0; $i < $len-1; $i++) {
    #
    # }
    my @final;
    for my $c ( @candidates ) {
        my @diff = array_diff($ipa{$word}->[0], $ipa{$c}->[0]);
        # printf("Candidate: %s (%i difference)\n", $c, scalar @diff);
        if (scalar @diff == 1) {
            push @final, $c;
        }
    }
    return @final;
    for my $c ( @final ) {
        printf("Final candidate: %s\n", $c);
    }
}

sub array_diff {
    my ( $a, $b ) = @_;
    my @diffidx;
    for (my $i=0; $i< scalar @$a; $i++) {
        if ( $a->[$i] ne $b->[$i] ) {
            return if @diffidx == 1; # Early exit
            push @diffidx, $i;
        }
    }
    return @diffidx;
}

# for (my $i=0; $i < $longest_word; $i++) {
#     for my $word (keys %ipa) {
#         next if length($word) <= $i;
#         my @word = $ipa{$word}[0]->as_array;
#         delete $word[$i];
#         my $key = join('', grep { defined } @word);
#         $pairs{$key} ||= [];
#         push @{$pairs{$key}}, $word;
#     }
# }

sub heading {
print<<EOF;
<tr>
    <th>Main Pronunciation</th>
    <th>Main Word(s)</th>
    <th>Pronunciation</th>
    <th>Sounds like</th>
</tr>
EOF
}

my $count;
for (keys %pairs) {
    next if scalar @{$pairs{$_}}==1;
    $count++;
}

print<<EOF;
<html>
<head>
<meta charset="UTF-8">
</head>
<style>
table {
  border: 1px solid black;
  text-align: left;
}
td {
    border: 1px solid black;
}
.ipa {
    font-family: 'Charis SIL', 'DejaVu Sans', 'Segoe UI', 'Lucida Grande', 'Doulos SIL', 'TITUS Cyberbit Basic', Code2000, 'Lucida Sans Unicode', sans-serif
}
</style>
<h1>$count French Minimal Pairs</h1>
<p>This file was generated automatically by a script which is <a href='https://github.com/flimzy/minimal-pairs/'>hosted on GitHub</a>.
<table>
EOF

my $j=0;
heading();
for my $pair ( sort { scalar @{$pairs{$b}} <=> scalar @{$pairs{$a}} || $a cmp $b } keys %pairs ) {
    last if scalar @{$pairs{$pair}} == 1;
    if ( $j >= 30 ) {
        heading();
        $j=0;
    }
    my @matches;
    for my $ipa ( sort @{$pairs{$pair}} ) {
        $j++;
        my $gc = $ipa{$ipa}->[0];
        push @matches, sprintf "<td class='ipa'>/%s/</td><td>%s</td>\n",
            $gc, join(', ',@{$ipa{$ipa}[1]});
    }
    my $matches = scalar(@{ $pairs{$pair} });
    printf "<tr><td rowspan='%i'><span class='ipa'>/%s/</span><br />%i phonetically similar words</td>\n",
        $matches, $pair, $matches;
    printf "<td rowspan='%i'>" . join(', ', @{$ipa{$pair}[1]}) . "</td>\n",
        $matches;
    print join("</tr>\n<tr>",@matches)."</tr>\n";
}
print "</table>\n";

printf "<p>Encountered %i distinct graphemes: %s</p>\n",
    scalar(keys %chars), join(' ', sort keys %chars);
