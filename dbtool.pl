#!/usr/bin/perl
use strict;
use warnings;

sub readDbFile($);
sub convertSongToInsert($);
sub convertInsertToSong($);

sub main(@){
  my $klompDb = readDbFile "klomp-db";
  for my $key(sort keys %$klompDb){
    print convertSongToInsert $$klompDb{$key};
  }
}

sub readDbFile($){
  my $file = shift;
  my $songs = {};
  for my $line(`cat $file`){
    $line =~ s/[\r\n]*$/\n/;
    if($line =~ /^INSERT/){
      my $song = convertInsertToSong $line;
      my $key = $$song{library} . "/" . $$song{relpath};
      die "DUPLICATE SONG: $line" if defined $$songs{$key};
      $$songs{$key} = $song;
    }elsif($line !~ /^(PRAGMA|BEGIN|CREATE TABLE|COMMIT)/){
      die "unknown db line: $line";
    }
  }
  return $songs;
}

sub convertSongToInsert($){
  my $song = shift;
  return "INSERT INTO \"Songs\" VALUES"
    . "(" . "'$$song{library}'"
    . "," . "'$$song{relpath}'"
    . "," . "'$$song{filesize}'"
    . "," . "'$$song{modified}'"
    . "," . "'$$song{md5sum}'"
    . "," . "'$$song{acoustid}'"
    . "," . "'$$song{duration}'"
    . "," . "'$$song{title}'"
    . "," . "'$$song{artist}'"
    . "," . "'$$song{albumartist}'"
    . "," . "'$$song{album}'"
    . "," . "'$$song{number}'"
    . "," . "'$$song{date}'"
    . "," . "'$$song{genre}'"
    . "," . "'$$song{title_guess}'"
    . "," . "'$$song{artist_guess}'"
    . "," . "'$$song{albumartist_guess}'"
    . "," . "'$$song{album_guess}'"
    . "," . "'$$song{number_guess}'"
    . "," . "'$$song{date_guess}'"
    . "," . "'$$song{genre_guess}'"
    . ")" . ";\n"
    ;
}

sub convertInsertToSong($){
  my $insert = shift;
  my $quoteVal = "(?:[^']|'')*";
  die "malformed insert line: $insert" if $insert !~ /^
      INSERT \s+ INTO \s+ "Songs" \s+ VALUES \s* \( \s*
        '(?<library>           \w+           )',
        '(?<relpath>           $quoteVal     )',
        '(?<filesize>          \d+           )',
        '(?<modified>          \d+           )',
        '(?<md5sum>            [0-9a-f]{32}  )',
        '(?<acoustid>          $quoteVal     )',
        '(?<duration>          $quoteVal     )',
        '(?<title>             $quoteVal     )',
        '(?<artist>            $quoteVal     )',
        '(?<albumartist>       $quoteVal     )',
        '(?<album>             $quoteVal     )',
        '(?<number>            $quoteVal     )',
        '(?<date>              $quoteVal     )',
        '(?<genre>             $quoteVal     )',
        '(?<title_guess>       $quoteVal     )',
        '(?<artist_guess>      $quoteVal     )',
        '(?<albumartist_guess> $quoteVal     )',
        '(?<album_guess>       $quoteVal     )',
        '(?<number_guess>      $quoteVal     )',
        '(?<date_guess>        $quoteVal     )',
        '(?<genre_guess>       $quoteVal     )'
        \s* \) \s* ; $
  /x;
  my $copyOfMatch = { %+ };
  return $copyOfMatch;
}

&main(@ARGV);
