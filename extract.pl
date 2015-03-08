#!/usr/bin/perl
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
