#!/usr/bin/env perl -w

use strict;

use Getopt::Long;

my ($DIR,$FILE);
my @htmfiles;

GetOptions("dir=s" => \$DIR, "file=s" => \$FILE);

unless(defined $DIR || defined $FILE){
  $DIR=`pwd`;
  chomp($DIR);
}

if(defined $DIR && defined $FILE){
  die "Please specify file (-f) or directory (-d), but not both!\n\n";
}

if(defined $FILE){
  unless(-e $FILE){
    die "File $FILE Does Not Exist!\n\n";
  }
}

my $lsdir;

if(defined $DIR){
  $lsdir=$DIR;
  $lsdir=~s/ /\\ /g;
  @htmfiles=`ls $lsdir/*.htm`;
} elsif (defined $FILE){
  push(@htmfiles,$FILE);
}

my @dplines;
my $defmatch=0;

foreach(@htmfiles){
  my $htmfile=$_;
  my $outfile=$htmfile;
  $outfile=~s/htm$/out/;
  open(INFILE,"<$htmfile") or die "Cannot open $htmfile for read!\n\n";
  while(<INFILE>){
    if(m/(Defendant:.*)$/){
      my $line=$1;
      $line=~s/\<[\w\s\"\=\/]+\>/ /g;
      $line=~s/\&nbsp\;/ /g;
      $line=~s/\s+/ /g;
      push(@dplines,"DEFENDANT $line");
      $defmatch=1;
    }
    if(m/(Plaintiff:.*)$/){
      my $line=$1;
      $line=~s/\<[\w\s\"\=\/]+\>/ /g;
      $line=~s/\&nbsp\;/ /g;
      $line=~s/\s+/ /g;
      push(@dplines,"PLAINTIFF $line");
    }
    if($defmatch==1){
      if(m/(\<td\s+colspan\=\"6\".*)$/){
	my $offline=$1;
	$offline=~s/\<[\w\s\"\=\/]+\>/ /g;
	$offline=~s/\&nbsp\;/ /g;
	$offline=~s/\s+/ /g;
	push(@dplines,"OFFENSE $offline");
	$defmatch=0;
      }
    }
  }
  close(INFILE);
  open(OUTFILE,">$outfile") or die "Cannot open $outfile for write!\n\n";
  foreach(@dplines){
    if(m/(DEFENDANT|PLAINTIFF)\s+(Defendant|Plaintiff):\s+([\w\s\,\.]+)\s+represented\s+by\s+([\w\s\(\)\,\.]+)\s+Phone:\s+(\d+)\s+Fax:\s+(\d+)\s+Email:\s+(\S+)/){
      print OUTFILE "$1\t\t$3\t\t$4\t\t$5\t\t$6\t\t$7\n";
    } elsif(m/(DEFENDANT|PLAINTIFF)\s+(Defendant|Plaintiff):\s+([\w\s\,\.]+)\s+represented\s+by\s+([\w\s\(\)\,\.]+)\s+Phone:\s+(\d+)\s+Email:\s+(\S+)/){
      print OUTFILE "$1\t\t$3\t\t$4\t\t$5\t\tN\/A\t\t$6\n";
    } else {
      print OUTFILE "$_\n";
    }
  }
  close(OUTFILE);
}

