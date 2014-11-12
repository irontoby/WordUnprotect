#
# $Id: mapmem.pl,v 0.1.1.5 1997/07/01 00:06:45 schwartz Rel $
#
# Experimentary package to map some structure. Very beginning...
# It is part of Elser, a program to handle word 6 documents. Elser
# can be found at:
#
#     http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/elser/index.html
# or
#     http://user.cs.tu-berlin.de/~schwartz/pmh/elser/index.html
#
# Copyright (C) 1997 Martin Schwartz 
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

sub mark_setsize       { &mapmem'mark_setsize }
sub mark_newlist       { &mapmem'init }
sub mark               { &mapmem'mark }
sub debug_memory_usage { &mapmem'debug_memory_usage }

package mapmem;

sub init { #
   &mark_setsize(undef);
   @mem_o=();
   @mem_l=();
   @mem_class=();
   @mem_info=();
   @mem_level=();
}

sub mark_setsize { #
   $buflen=shift;
}

sub mark { #
   local($offset, $len, $class, $info, $level) = @_;
   return if $len<0;
   push (@mem_o, $offset);
   push (@mem_l, $len);
   push (@mem_class, $class);
   push (@mem_info, $info);
   push (@mem_level, $level);
}

sub debug_memory_usage { #
   &main'msgnl();
   local($out, $lasto);
   print "\nDebug Documents Storage Use:\n";
   $last=0;
   print "  offset len      class     info\n";
   foreach $i (sort {$mem_o[$a] <=> $mem_o[$b]} (0..$#mem_o)) {
      next if !$mem_l[$i];
      next if $mem_level[$i]>1;
      &debug_memory_usage_diff($mem_o[$i], $last);
      $out = sprintf("  %06x (%x): ", $mem_o[$i], $mem_l[$i]);
      $out .= " " x (18 - length($out));
      $out .= "[".$mem_class[$i]."] ";
      $out .= " " x (28 - length($out));
      $out .= "$mem_info[$i]";
      print "$out\n";
      $last=$mem_o[$i]+$mem_l[$i];
   }
   &debug_memory_usage_diff($buflen, $last);
   printf ("  %06x: eof\n", $buflen);
}

sub debug_memory_usage_diff {
   local($new, $old) = @_;
   local($out);
   if ($new != $old) {
      $out = sprintf(". %06x (%x): ", $old, $new-$old);
      $out .= " " x (18 - length($out));
      $out .= "[ ??? ]";
      print "$out\n";
   } 
}

"Atomkraft? Nein, danke!";

