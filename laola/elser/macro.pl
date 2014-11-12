#
# $Id: macro.pl,v 0.1.1.5 1997/07/01 00:06:45 schwartz Rel $
#
# Outsourced macro code for program Elser. 
# (This is the only way outsourcing doesn't destroy jobs, isn't it?)
# It is part of Elser, a program to handle word 6 documents. Elser can 
# be found at:
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

sub get_macro_code {
   local(%name)=&macro_get_names();
   return &msg1("no macros") if !(keys %name);

   local(@list)=&get_macro_indices($opt_M);
   return &msg2("macro number missing!") if !@list;
   &msgnl();

   for (@list) {
      &print_macro_code($_);
   }
}

sub yank_macro_code {
   local(%name)=&macro_get_names();
   return &msg1("no macros") if !(keys %name);

   local(@list)=&get_macro_indices($opt_Y);
   return &msg2("macro number missing!") if !@list;

   if ($word_crypted) {
      return &msg2("Cannot yank macros, because the document is crypted!");
   }

   local($yank_message)="Macros removed with Elser $REV";
   local($text)="yanking macro"; $text .= "s" if $#list>0;
   $text ="yanking all macros" if $opt_Y eq "#+";
   &msg1("$text");
   for (@list) {
      &msg2 (&macro_delete($wh, $_));
   }
   &macro_delete_index($wh, $yank_message) if $opt_Y eq "#+";
   1;
}

sub get_macro_indices {
   local($par)=shift;
   local(@list)=();
   if ($par =~ /^#/) {
      local($tmp) = $par =~ /^#(.+)$/; 
      local(@tmp) = split(/[, ]/, $tmp);
      if ($par =~ /^#\+$/) {
         for (sort {$name{$a} cmp $name{$b}} keys %name) {
            push(@list, $_);
         }
      } else {
         for (@tmp) {
            if ($name{$_-1}) {
               push(@list, $_-1);
            } else {
               &msg2("Macro \"#$_\" doesn't exist!");
            }
         }
      }
   } else {
      for (keys %name) { 
         if ($name{$_} =~ /$par/i) {
            push(@list, $_); last;
         }
      }
      if (!@list) {
         &msg2("Macro \"$par\" doesn't exist!");
      }
   }
   @list;
}

sub print_macro_code {
   local($i)=shift;
   local($desc, $key) = (&macro_get_info($i))[0,2];
   print "\nREM ". ("*" x 74) . "\n";
   print "REM Macro \"$infile:$name{$i}\"";
   print " (ExecuteOnly, Key=$key)" if $key;
   print "\n";
   print "REM Description: \"$desc\"\n" if $desc;
   print "REM ". ("-" x 74) . "\n";
   print &macro_get_code($i, $opt_P);
   print "\n\n";
}

sub list_macros_and_menus {
   &list_macro_names;
   &list_menu_names;
}

sub list_menu_names {
   local(%name)=&menu_get_names();
   @keys = keys %name;
   local($int, $menu, $pos, $context);
   local($out);
   if (@keys) {
      printf("\nDocument \"$infile\" adds %d menus:\n", $#keys+1);
      foreach $i (sort {$name{$a} cmp $name{$b}} keys %name) {
         ($int, $menu, $pos, $context) = &menu_get_info($i);
         $out = sprintf("Menu %2d (%02d %02d.%02d): \"%s\"", 
            $i+1, $context, $menu, $pos, $name{$i}||$int
         );
         print "$out\n";
      }
      &msgnl();
   } 
   1;
}

sub list_macro_names {
   local(%name)=&macro_get_names();
   @keys = keys %name;
   local($desc, $int, $key, $v, $stat);
   local($out);
   if (@keys) {
      printf("\nDocument \"$infile\" contains %d macros:\n", $#keys+1);
      foreach $i (sort {$name{$a} cmp $name{$b}} keys %name) {
         ($desc, $int, $key, $v, $stat) = &macro_get_info($i);
         $out = sprintf("Macro %2d: \"%s\"", $i+1, $name{$i}||$int);
         $out .= " (\"$desc\")" if $desc;
         print "$out\n";
      }
      &msgnl();
   } else {
      &msg1("no macros");
   }
   1;
}

sub disable_automacros {
   local(%name)=&macro_get_names();
   local($name, $intname);
   local($result);
   local(@auto) = (
      "AutoClose", "AutoExec", "AutoExit", "AutoNew", "AutoOpen"
   );
   local(@bike) = (
      "BikeClose", "BikeExec", "BikeExit", "BikeNew", "BikeOpen"
   );
   local(%work) = ();
   foreach $mach (keys %name) {
      $name=$name{$mach};
      $intname=(&macro_get_info($mach))[1];
      for (0 .. $#auto) {
         if ($auto[$_]=~/^($name|$intname)$/i) {
            $work{$mach}=$bike[$_];
            last;
         }
      }
   }
   if (!%work) {
      &msg1("no automacros"); 
      return "ok";
   } else {
      &msg1("disabling automacros");
      foreach $mach (keys %work) {
         $result = &macro_rename($wh, $mach, $work{$mach});
         return $result if $result ne "ok";
      }
   }
   "ok";
}

sub unstealth_macros {
   local($result)="";
   local(@list)=();
   local($k)="";
   local(%name)=&macro_get_names();
   &msg1("no macros") && return "ok" if !%name;
   if ($word_crypted) {
      return &msg2("Cannot unstealth macros, because the document is crypted!");
   }
   for (keys %name) {
      $k = (&macro_get_info($_))[2];
      push(@list, $_) if $k;
   }
   &msg1("all macros editable") && return "ok" if !@list;
   &msg1("unstealthing macros");
   for (@list) {
      $result = &macro_unstealth($wh, $_);
      last if $result ne "ok";
   }
   $result;
}

"Atomkraft? Nein, danke!"

