#
# $Id: textutil.pl,v 0.1.1.7 1997/07/01 00:06:46 schwartz Rel $
#
# *Experimentary* package, handles text format documents.
# It is part of Elser, a program to handle word 6 documents. Elser 
# can be found at:
#
#     http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/elser/index.html
# or
#     http://user.cs.tu-berlin.de/~schwartz/pmh/elser/index.html
#
# Copyright (C) 1996, 1997 Martin Schwartz 
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, you should find it at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/COPYING
#
# You can contact me via schwartz@cs.tu-berlin.de
#

sub set_maxcolumn      { &textutil'set_maxcolumn }
sub set_hypen_char     { &textutil'set_hyphen_char }
sub set_line_delimitra { &textutil'set_line_delimitra }
sub set_tab_delimitra  { &textutil'set_tab_delimitra }
sub set_breaking_mode  { &textutil'set_breaking_mode }
sub set_whitespace     { &textutil'set_whitespace }

sub format_lines       { &textutil'format_lines }

#sub format_tabulators  { &textutil'format_tabulators }

package textutil;

init_var: {
   &set_maxcolumn      (0xffffffff);
   &set_hyphen_char    ("-");
   &set_line_delimitra ("\x0d");
   &set_tab_delimitra  ("\x09");
   &set_breaking_mode  (0);
   &set_whitespace     (" ");
}

##
## We maintain the package global variables...
##

sub set_maxcolumn      { $maxcolumn = shift }
sub set_hyphen_char    { $hyphen = shift }
sub set_line_delimitra { $ndel = shift }
sub set_tab_delimitra  { $tdel = shift }
sub set_breaking_mode  { $mode = shift }
sub set_whitespace     { $whitespace = shift }


##
## ... and we are gently.
##

sub format_lines {
#
# (modified buf) 
# void = format_lines(extern buf [,$mode] )
#
# mode: &1 == break long lines with a $hyphen
#

   if ($maxcolumn==1) {
      $_[0] = join($ndel, split(//, $_[0]));
      return "ok";
   } elsif ($maxcolumn<0) {
      return "Number of column is negative. Cannot handle this.";
   }

   local($len)=length($_[0]);
   local($pos)=0; local($n);
   while ($pos<$len) {
      $n=index($_[0], $ndel, $pos);
      last if $n<0;
      if (($n-$pos)<$maxcolumn) {
         $pos=$n+1;
      } else {
         &splitline;
      }
   }

   "ok";
}

sub splitline {
#
# needs: $_[0] == text,  
#        $pos   = current position (standing on a \n)
#
   local($m, $m1);
   local($maxc)=$maxcolumn;
   $m=0;
   for (split(//, $whitespace)) {
      $m1 = rindex($_[0], $_, $pos+$maxc-1);
      $m = $m1 if $m1>$m;
   }
   $m-=$pos;

   if ($m > 0) {
      # Line is teared at a whitespace.
      substr($_[0], $pos+$m, 1) = $ndel;
      $pos+=($m+1);
   } else {
      if ($mode==0) {
         # Line cannot be broken.
         $pos++;
      } elsif ($mode==1) {
         # Break a line and insert a $hyphen.
         $maxc=$len-$pos if ($len-$pos)<$maxc;
         if (substr($_[0],$pos+$maxc-2, 1) =~ /[a-zA-ZÄÖÜäöüß]/) {
            substr($_[0], $pos+$maxc-1, 0) = "-$ndel";
            $len+=2; $pos+=2;
         } else {
            substr($_[0], $pos+$maxc-1, 0) = $ndel;
            $len++; $pos+=1;
         }
         $pos += ($maxc-1);
      }
   }
}

##
## Tabulators
##

sub make_statistic {
   local($l) = length($_[0]);
   local($line)=1;
   local($pos)=0;
   local($tpos)=0;
   local($npos1)=0;
   local($npos2)=0;
   %linetabs=();
   %linelen=();
   while ($npos1 < $l) {
      $npos2 = index($_[0], $ndel, $npos1+1);
      $npos2 = $l if $npos2<0;
      $tpos = $npos1;
      while( ($tpos=index($_[0], $tdel, $tpos+1))>0 ) {
         last if ($tpos > $npos2);
         $linetabs{$line} .= ($tpos-$npos1) . " ";
      }
      $linelen{$line++} = $npos2-$npos1-1;
      $npos1 = $npos2;
   }
}

sub print_statistic {
   print "\nTabulator statistic:\n";
   foreach $line (sort {$a <=> $b} keys %linelen) {
      if (defined $linetabs{$line}) {
         printf(" %03d (%03d): %s\n", $line, $linelen{$line}, $linetabs{$line});
      } else {
         printf(" %03d (%03d)\n", $line, $linelen{$line});
      }
   }
   print "\n";
}

"Atomkraft? Nein, danke!";

