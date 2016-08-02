#!/usr/bin/perl
use strict;
use warnings;

sub readDbFile($);
sub convertSongToInsert($);
sub convertInsertToSong($);
sub analyzeDurations($$);

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

sub analyzeDurations($$){
  my ($old, $new) = @_;
  $old = { (%$old) };
  $new = { (%$new) };

  my @msgAddRemove;
  my @msgDiff;
  for my $key(sort keys %$old){
    if(not defined $$new{$key}){
      push @msgAddRemove, "REMOVED SONG: $key=$$old{$key}{duration}\n";
      delete $$old{$key};
    }
  }
  for my $key(sort keys %$new){
    if(not defined $$old{$key}){
      push @msgAddRemove, "ADDED SONG: $key=$$new{$key}{duration}\n";
      delete $$new{$key};
    }
  }

  my $sameCount = 0;
  for my $key(sort keys %$old){
    my $oldD = $$old{$key}{duration};
    my $newD = $$new{$key}{duration};
    my $oldOk = 0;
    if($oldD =~ /^\d+(\.\d+)?$/){
      $oldOk = 1;
    }
    my $newOk = 0;
    if($newD =~ /^\d+(\.\d+)?$/){
      $newOk = 1;
    }

    if($oldOk and not $newOk){
      push @msgAddRemove, "REMOVED DURATION$key=$oldD\n";
    }elsif(not $oldOk and $newOk){
      push @msgAddRemove, "ADDED DURATION: $key=$newD\n";
    }elsif($oldOk and $newOk and $newD ne $oldD){
      my $diff = $newD-$oldD;
      my $rat = $newD/$oldD;
      push @msgDiff, sprintf "%4d%% %7.2f  %7.2f => %7.2f  %s\n",
        ($rat*100), $diff, $oldD, $newD, $key;
    }else{
      $sameCount++;
    }
  }

  my $msg = '';
  $msg .= join "", @msgDiff;
  $msg .= join "", @msgAddRemove;
  $msg .= "  SAME:       $sameCount\n";
  $msg .= "  ADD/REMOVE: " . (0+@msgAddRemove) . "\n";
  $msg .= "  CHANGE:     " . (0+@msgDiff) . "\n";
  return $msg;
}

&main(@ARGV);
