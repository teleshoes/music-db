#!/usr/bin/perl
use strict;
use warnings;

my $usage = "Usage:
  $0 -h|--help
    print this message

  $0 [OPTS]
    query klomp-db for each line in 'cds'
    ensure at least one FLAC file, with an acoustid, is found for each cd

    -look at all lines in './cds'
    -parse each line as one of these formats:
      *<ALBUM>                       (one section)
      *<ARTIST>|<ALBUM>              (two sections, none empty)
      *<ARTIST>|<ALBUM>|<EXTRAS>     (three or more sections, none empty)
      *<ALBUM>||<EXTRAS>             (three or more sections, second is empty)
    -if line does not match one of the above formats, FAIL
    -if line does not start with '*', FAIL
    -split <ARTIST> (if present) into words (\\w+) and prepand '\@a'
    -split <ALBUM> into words (\\w+) and prepend '\@l'
    -run klomp-db -s '<ARTIST_WORDS> <ALBUM_WORDS'
      e.g.: klomp-db -s '\@aEdith \@aPiaf \@lLa \@lVie \@len \@lRose'
    -ignore all non-flac songs returned
    -if no songs returned, FAIL
    -check each song returned for an acoustid
    -if no acoustids returned, FAIL

  OPTS
    -v | --verbose
      print the klomp-db lookup query
";

sub main(@){
  if(@_ == 1 and $_[0] =~ /^(-h|--help)$/){
    print $usage;
    exit 0;
  }

  my $verbose = 0;
  while(@_ > 0 and $_[0] =~ /^-/){
    my $opt = shift;
    if($opt =~ /^(-v|--verbose)$/){
      $verbose = 1;
    }else{
      die "$usage\nunknown opt: $opt\n";
    }
  }

  if(@_ > 0){
    die $usage;
  }

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

      my @cmd = ("klomp-db", "-s", "@queryWords");
      print "@cmd\n" if $verbose;
      open CMD, "-|", @cmd
        or die "could not run @cmd\n";
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
