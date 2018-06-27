#!/usr/bin/perl
use strict;
use warnings;

sub main(@){
  for my $cd(`cat cds`){
    chomp $cd;
    next if $cd =~ /^\s*$/;

    if($cd =~ /^[^*]/){
      die "cd not marked as raptured: $cd\n";
    }

    if($cd !~ /^\*([^|]+)(?:\|([^|]*))?(?:\|(.*))?$/){
      die "malformed cd: $cd";
    }else{
      my ($part1, $part2, $extras) = ($1, $2, $3);
      my ($album, $artist);
      if(defined $part2 and length $part2 > 0){
        $artist = $part1;
        $album = $part2;
      }else{
        $album = $part1;
        $artist = "";
      }
      my @artistWords = split /\W+/, $artist;
      my @albumWords = split /\W+/, $album;

      my @queryWords;
      @queryWords = (@queryWords, map {"\@a$_"} @artistWords);
      @queryWords = (@queryWords, map {"\@l$_"} @albumWords);

      open CMD, "-|", "klomp-db", "-s", "@queryWords"
        or die "could not run klomp-db\n";
      my @songs = <CMD>;
      close CMD;
      chomp foreach @songs;

      @songs = grep /\.flac$/, @songs;
      if(@songs == 0){
        die "missing CD: $cd\n";
      }
      my $anyAcoustid;
      for my $song(@songs){
        open CMD, "-|", "klomp-db", "-i", $song
          or die "could not run klomp-db\n";
        my $info = join '', <CMD>;
        close CMD;
        my $acoustid = $1 if $info =~ /acoustid=(.*)/;
        if(defined $acoustid and $acoustid =~ /^[0-9a-f\-]+$/){
          $anyAcoustid = $acoustid;
          last;
        }
      }
      if(not defined $anyAcoustid){
        die "no acoustids: $cd\n";
      }

      print "$cd\n";
      print "$_\n" foreach @songs;
      print "\n\n\n";
    }
  }
  print "SUCCESS\n";
}

&main(@ARGV);
