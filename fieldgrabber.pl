#!/usr/bin/env perl -w
######################################################################
#
# fieldgrabber.pl
#
# This script will open an htm* file, and process data
# out of the htm* code, into an output file to later
# be processed into a DB.
#
######################################################################
#
# FLAGS:
#  -d[ir] <directory>     -    specify a directory to run on
# -f[ile] <filename>      -    specify a single file to run on
# -c[all]                 -    specify a run as a "call" page (which
#                               will search for different items and
#                               produce different output)
#
######################################################################

use strict;

use Getopt::Long;

my ($DIR,$FILE,$CALL);
my @htmfiles;

GetOptions("dir=s" => \$DIR, "file=s" => \$FILE, "call" => \$CALL);

####IF NO FLAGS, ASSUME PWD IS DIR####
unless(defined $DIR || defined $FILE){
  $DIR=`pwd`;
  chomp($DIR);
}

####CAN'T DEFINE BOTH DIR AND FILE####
if(defined $DIR && defined $FILE){
  die "Please specify file (-f) or directory (-d), but not both!\n\n";
}

####IF FILE SPECIFIED, IT MUST EXIST####
if(defined $FILE){
  unless(-e $FILE){
    die "File $FILE Does Not Exist!\n\n";
  }
}

my $lsdir;

####GET ALL FILES FOR PROCESSING INTO AN ARRAY####
if(defined $DIR){
  $lsdir=$DIR;
  $lsdir=~s/ /\\ /g;
  @htmfiles=`ls $lsdir/*.htm*`;
} elsif (defined $FILE){
  push(@htmfiles,$FILE);
}

my @dplines;
my $defmatch=0;

####OPEN EACH HTM* FILE ONE AT A TIME, PROCESS FOR DETAILS####
foreach(@htmfiles){
  my $htmfile=$_;
  my $outfile=$htmfile;
  ####OUTFILE IS NAMED THE SAME WITH AN OUT EXTENSION####
  $outfile=~s/html*$/out/;
  ####FILE MUST HAVE READ PERMISSION####
  open(INFILE,"<$htmfile") or die "Cannot open $htmfile for read!\n\n";
  while(<INFILE>){
    unless(defined $CALL){
      ####MATCH LINES, AND STRIP OUT HTML CODE, PUSH INTO ARRAY OF LINES####
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
      ####FOR EACH DEFENDANT, MATCH OFFENSE ONLY ONCE####
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
  }
  close(INFILE);
  ####GENERATE OUTPUT####
  open(OUTFILE,">$outfile") or die "Cannot open $outfile for write!\n\n";
  foreach(@dplines){
    unless(defined $CALL){
      if(m/(DEFENDANT|PLAINTIFF)\s+(Defendant|Plaintiff):\s+([\w\s\,\.]+)\s+represented\s+by\s+([\w\s\(\)\,\.]+)\s+Phone:\s+(\d+)\s+Fax:\s+(\d+)\s+Email:\s+(\S+)/){
	print OUTFILE "$1,$3,$4,$5,$6,$7\n";
      } elsif(m/(DEFENDANT|PLAINTIFF)\s+(Defendant|Plaintiff):\s+([\w\s\,\.]+)\s+represented\s+by\s+([\w\s\(\)\,\.]+)\s+Phone:\s+(\d+)\s+Email:\s+(\S+)/){
	print OUTFILE "$1,$3,$4,$5,N\/A,$6\n";
      } else {
	print OUTFILE "$_\n";
      }
    }
  }
  close(OUTFILE);
}

