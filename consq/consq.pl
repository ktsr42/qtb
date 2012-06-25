#!/usr/bin/perl

use strict;
use warnings;

# Note: We consciously do not track loaded scripts to avoid loading them twice.
# This will reflect Q's behaviour.  If somebody writes a program that relies on
# the effect of initializing some variables (functions) twice, we should thereby
# retain that behaviour - even if the responsible programmer is probably a
# nutcase...

sub consolidateQ
{
  $#_ + 1 >= 2 or die "Missing argument(s)";
  my $context=$_[0];
  my $filename=$_[1];
  my $script;
  my $line;
  my $blockComment = 0;

  open( $script, $filename ) or die "$filename: $!";
  foreach $line (<$script>)
  {
    chomp $line;

    # Block comment end
    if( $line =~ /^\\\s*$/ )
    {
      if( $blockComment ) { $blockComment = 0; next; }  # Drop out of the block comment mode
      else                { last; }
      # The else branch implements the behaviour of q on a \-line without a preceeding / line,
      # it marks the end of the code in the file.  Everything else after it is ignored.
    }

    # Do not write block comments from the input script to the consolidated file.
    if( $blockComment ) { next; }

    # check if this line loads another script
    if( $line =~ /^ *\\l (.+)$/ )
    {
      # Expand the secondary script, but do not output the \l line
      consolidateQ( $context, $1 );
      # Get q to restore the original context after parsing up to here
      print "\\d $context\n";
    }
    elsif( $line =~ /^\/\s*$/ )
    {
      # Ignore this line and everything after it until we see a \-line
      $blockComment = 1;
    }
    else
    {
      # if this is the selection of a context, store the new context name (path)
      if( $line =~ /^ *\\d (.+)$/ ) { $context = $1; }

      # output the line (including the selection of a new context)
      print $line,"\n";
    }
  }
  close $script;
}

# Invocation: consq.pl source.q [target.q]
# Write to stdout if target.q has not been specified

$#ARGV + 1 > 0 or die "Missing source argument";
-r $ARGV[0]    or die "$ARGV[0] cannot be read";

if( defined $ARGV[1] )
{
  my $output;
  open( $output, ">$ARGV[1]" ) or die $!;
  select( $output );  
}

consolidateQ( ".", $ARGV[0] );

