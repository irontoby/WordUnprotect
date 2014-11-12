#
# $Id: macrolib.pl,v 0.1.1.8 1997/07/01 00:09:10 schwartz Rel schwartz $
#
# Macro for Word 6
#
# This library handles word 6 macros. It is part of Elser, a program to 
# handle word 6 documents. Elser can be found at:
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

sub macro_open         { &macro'macro_open }
sub macro_bufopen      { &macro'macro_bufopen }
sub macro_close        { &macro'macro_close }

sub macro_get_names    { &macro'macro_get_names }
sub macro_get_info     { &macro'macro_get_info }
sub macro_get_code     { &macro'macro_get_code }
sub macro_unstealth    { &macro'macro_unstealth }
sub macro_delete       { &macro'macro_delete }
sub macro_delete_index { &macro'macro_delete_index }
sub macro_rename       { &macro'macro_rename }

sub menu_get_names     { &macro'menu_get_names }
sub menu_get_info      { &macro'menu_get_info }

sub macro_guess_virus  { &macro'macro_guess_virus; }

package macro;

$uncool_debug = 0;

init: {
   %mac_token=();
   %mac_token67=();
   %mac_token73=();
}

sub init_vars {
   #
   # macro info (118)
   #
   $mac_defbase = undef;
   @mac_defo01  = (); # macro definition01 entry offsets
   @mac_defo10  = (); # macro definition10 entry offsets
   %mac_defo11  = (); # macro definition11 entry offsets
   @mac_codebuf = (); #
   @mac_ver     = (); #
   @mac_key     = ();
   @mac_inti    = ();
   @mac_exti    = ();
   @mac_desci   = ();
   @mac_uk      = ();
   @mac_codel   = ();
   @mac_state   = ();
   @mac_codeo   = ();
   @men_context = (); #
   @men_menu    = (); 
   @men_inti    = (); 
   @men_uk      = (); 
   @men_exti    = (); 
   @men_pos     = (); 
   @mac_ext     = (); #
   @mac_extuk   = ();
   %mac_int     = (); #
   %mac_intuk   = ();
   %idx         = (); # index on exti and desci index

   $macro_trouble=0; #
   $virus_alert=0; #
}

sub macro_open { #
#
# "ok"|$error = macro_open($document_buf)
#
   local($h)=shift;
   local($buf, $status);
   $status = &main'laola_get_file($h, $buf);
   return $status if $status ne "ok";
   &open_main($buf);
}

sub macro_bufopen { #
#
# "ok"|$error = macro_open($document_buf)
#
   &open_main;
}

sub open_main {
#
# "ok"||$error = open_main($buf);
#
   &init_vars();
   $mac_defbase = &get_long(0x118, $_[0]);
   local($buf) = &get_chunk(0x118, $_[0]);
   local($buflen) = length($buf);
   return "ok" if !$buflen;

   local($i);
   local($c);
   local($o, $l);
   local($result);
   $o=0;
   if (&get_byte($o++, $buf) != 0xff) {
      return "Cannot understand macro entry.";
   }
   while ($o<$buflen) {
      $c=&get_byte($o++, $buf);
      if ($c == 1) {
         &get_macrodefs_01();
      } elsif ($c == 0x05) {
         &get_macrodefs_05();
      } elsif ($c == 0x10) {
         &get_macrodefs_10();
      } elsif ($c == 0x11) {
         &get_macrodefs_11();
      } elsif ($c == 0x12) {  # really not certain!
         $macro_trouble=1;
         return &error() if !&get_macrodefs_12();
      } elsif ($c == 0x40) {
         last;
      } else {
         $macro_trouble=1;    # big mess!
         printf ("\nOoops? c=%02x o=%0x\n", $c, $o) if $uncool_debug;
         return "I do not understand this macro chunk!";
      }
   }
   $n=0;
   for (sort {$a <=> $b} (@mac_exti, @mac_desci, @men_exti)) {
      next if $_ == 0xffff;
      next if defined $idx{$_};
      $idx{$_}=$n++;
   }
   &get_code($_[0]);
   "ok";
}

sub error {
   if ($uncool_debug) {
      printf("\nError at: o=%x\n", $o);
   }
   return "I don't understand this macro chunk!";
}

sub get_code { 
   local($buf, $i, $l, $key);
   for ($i=0; $i<=$#mac_ver; $i++) {
      $l=$mac_codel[$i];
      $buf=substr($_[0], $mac_codeo[$i], $l);
      &main'mark($mac_codeo[$i], $l, 
         "macro", 
          $mac_ext[$idx{$mac_exti[$i]}] || $mac_int{$mac_inti[$i]}, 
          1
      ) if $main'mapmem;

      $key=$mac_key[$i];
      if ($key) {
         # "decrypt" macro
         while(--$l>=0) {
            substr($buf, $l, 1) = pack("C", &get_byte($l, $buf) ^ $key);
            &main'msg(".") if (!($l%0x1000) && $l);
         }
      } 
      study($buf);
      silly_virus_check: {
         # .GlobalDotAbfrage = 0
         $virus_alert+=02 if $buf =~ /\x73\xac\x03\x0c\x6c\x00\x00/;
         # .MakroKopieren
         $virus_alert+=04 if $buf =~ /\x67\xc2\x80/;
         # Format C:
         $virus_alert+=10 if $buf =~ /format [c-z]:/i;
      }
      push(@mac_codebuf, $buf);
   }
}

sub get_macrodefs_01 {
#
# macro_open->get_macrodefs_01  (macro header)
#
   local($n)=&get_word($o, $buf); $o+=2;
   while($n-->0) {
      push (@mac_defo01, $o);
      push (@mac_ver,    &get_byte($o+0, $buf));
      push (@mac_key,    &get_byte($o+1, $buf));
      push (@mac_inti,   &get_word($o+2, $buf));
      push (@mac_exti,   &get_word($o+4, $buf));
      push (@mac_desci,  &get_word($o+6, $buf));
      push (@mac_uk,     &get_long($o+8, $buf));
      push (@mac_codel,  &get_long($o+0x0c, $buf));
      push (@mac_state,  &get_long($o+0x10, $buf));
      push (@mac_codeo,  &get_long($o+0x14, $buf));
      $o+=0x18;
   }
}

sub get_macrodefs_05 {
#
# macro_open->get_macrodefs_05
#
# Menüeinträge
#
   local($n)=&get_word($o, $buf); $o+=2;
   while ($n-->0) {
      push(@men_context, &get_word($o+0x00, $buf));
      push(@men_menu,    &get_word($o+0x02, $buf));
      push(@men_exti,    &get_word($o+0x04, $buf));
      push(@men_uk,      &get_word($o+0x06, $buf));
      push(@men_inti,    &get_word($o+0x08, $buf));
      push(@men_pos,     &get_word($o+0x0a, $buf));
      $o+=0xc;
   }
}

sub get_macrodefs_10 {
#
# macro_open->get_macrodefs_10  (userEss strings / external names)
#
   local($max) = $o+&get_word($o, $buf); $o+=2;
   local($l);
   while ($o<$max) {
      push(@mac_defo10, $o);
      if ($l=&get_byte($o++, $buf)) {
         push (@mac_ext, substr($buf, $o, $l)); $o+=$l;
         push (@mac_extuk, &get_word($o, $buf)); $o+=2;
      }
   }
}

sub get_macrodefs_11 {
#
# macro_open->get_macrodefs_11  (system strings / internal names)
#
   local($n)=&get_word($o, $buf); $o+=2;
   local($l, $m);
   while ($n-->0) {
      $m = &get_word($o, $buf); $o+=2;
      $mac_defo11{$m} = $o;
      $l = &get_byte($o, $buf); $o+=1;
      $mac_int{$m} = substr($buf, $o, $l); $o+=$l;
      $mac_intuk{$m} = &get_byte($o, $buf); $o+=1;
   }
}

sub get_macrodefs_12 {
# 
# macro_open->get_macrodefs_12  (very speculative!!)
#
   local($l) = length($buf);
   local($num_of_tables);
   local($type, $num_of_records, $recordlen);
   local($strange_string_num, $strl, $str);

   if ($uncool_debug) {
      printf ("\nAddress 12 begin header (c=%02x o=%0x): ", $c, $o);
      printf ("%04x %02x %04x %04x %04x %04x\n",
         &get_word($o+0x00, $buf),
         &get_byte($o+0x02, $buf),
         &get_word($o+0x03, $buf),
         &get_word($o+0x05, $buf),
         &get_word($o+0x07, $buf),
         &get_word($o+0x09, $buf)
      );
   }
   return 1 if !($num_of_tables = &get_word($o+0x09, $buf));
   $o+=0x0b;

   for (1..$num_of_tables) {
      $strange_string_num=0;

      if ($uncool_debug) {
         printf ("Header of chunk #$_ (o=%03x): ", $o);
         for (0..10-1) {
            printf ("%04x ", &get_word($o+2*$_, $buf));
         }
         print "\n";
      }
      $type = &get_word($o+0x04, $buf);
      $num_of_records = &get_word($o+0x12, $buf);
      $o+=0x14;

      if (!$type) {
         $recordlen = 20;
      } else {
         $recordlen = 14;
         # valid for: $type e (2, 3) ?
      }
      for (1 .. $num_of_records) {
         if ($uncool_debug) {
            printf("  %02x: ", $_);
            for (0 .. $recordlen-1) {
               printf ("%02x ", &get_byte($o+$_, $buf));
            }
            print "\n";
         }
         if (&get_byte($o+$recordlen-7, $buf)) {
            $strange_string_num++;
         }
         $o += $recordlen;
      }
      if ($uncool_debug && $strange_string_num) {
         print "Found $strange_string_num strange strings:\n";
      }
      while($strange_string_num-- >0) {
         $strl = &get_byte($o, $buf); 
         $str  = substr($buf, $o+1, $strl);
         $o+=($strl+1);
         if ($uncool_debug) {
            print "Strange string: \"$str\"\n";
         }
      }
   }
   1;
}

sub macro_close { #
   &init_vars();
   "ok";
}

sub macro_get_names { #
# 
# %name = macro_get_names();  (key=macrohandle, value=macroname)
#
   local(%name)=();
   for (0..$#mac_ver) {
      $name{$_} = $mac_ext[$idx{$mac_exti[$_]}];
   }
   %name;
}

sub menu_get_names { #
   local(%name)=();
   for (0..$#men_context) {
      $name{$_} = $mac_ext[$idx{$men_exti[$_]}];
   }
   %name;
}

sub menu_get_info { #
#
# (intname, menu, position, context) = menu_get_info(menuhandle)
#
   local($i)=shift;
   local($id) = $men_inti[$i];
   local($int) = ""; $int=$mac_int{$id} if $id != 0xffff;
   ($int,
    $men_menu[$i],
    $men_pos[$i],
    $men_context[$i]
   );
}

sub macro_get_info { #
#
# (desc, intname, key, BasicVersion?, status?) = macro_get_info(macrohandle)
#
   local($i)=shift;
   local($id);
   local($desc)=""; 
   local($int)="";
   $id = $mac_desci[$i]; $desc=$mac_ext[$idx{$id}] if $id != 0xffff;
   $id = $mac_inti[$i]; $int=$mac_int{$id} if $id != 0xffff;
   ($desc,
    $int,
    $mac_key[$i],
    $mac_ver[$i],
    $mac_state[$i]
   );
}

sub macro_unstealth { #
#
# "ok"||$error = macro_unstealth(dochandle, macrohandle)
#
   local($i)=$_[1];
   local($result);
   return "Macro does not exist." if $i>$#mac_ver;

   # Mark the macro as readable.
   $result = &main'laola_modify_file(
      $_[0], "\0", $mac_defbase+$mac_defo01[$i]+1,1
   );
   return $result if $result ne "ok";

   # store the decoded data into document
   &main'laola_modify_file(
      $_[0], $mac_codebuf[$i], $mac_codeo[$i], length($mac_codebuf[$i])
   );
}

sub macro_delete { #
#
# "ok"||$error = macro_delete(dochandle, macrohandle)
#
   local($i)=$_[1];
   local($result);
   return "Macro does not exist." if $i>$#mac_ver;

   # Mark the macro as readable.
   $result = &main'laola_modify_file(
      $_[0], "\0", $mac_defbase+$mac_defo01[$i]+1, 1
   );
   return $result if $result ne "ok";

   # Mark the macro as deleted. "Clean" does it this way...
   $result = &main'laola_modify_file(
      $_[0], "\0\0\0\0", $mac_defbase+$mac_defo01[$i]+0x10, 1
   );
   return $result if $result ne "ok";

   # Leaving the macro length entry unchanged. Is this ok? ...

   # Zero the macro buf.
   &main'laola_modify_file(
      $_[0], "\0" x length($mac_codebuf[$i]), 
      $mac_codeo[$i], length($mac_codebuf[$i])
   );
}

sub macro_delete_index { #
#
# "ok"||$error = macro_delete_index(dochandle, macrohandle)
#
   local($h, $msg)=@_;
   local($result);
   local($buf);
   &main'laola_get_file($h, $buf, 0x118, 8);
   local($o, $l)=unpack("V2", $buf);
   $buf = "\xff\x40$msg";
   $buf .= "\0" x ($l-length($buf));
   substr($buf, $l)="";
   $result = &main'laola_modify_file($h, $buf, $o, $l);
   return $result if $result ne "ok";
   &main'laola_modify_file(
      $h, pack("V", 2), 0x11c, 2
   );
}

sub macro_rename {
#
# "ok"||$error = macro_rename(dochandle, macrohandle, $name)
#
# Very alpha... Renames only, if names size stays constant.
#
   local($doch, $mach, $name) = @_;
   local($i, $l);
   local($result)="ok";
   if (($i=$mac_exti[$mach]) != 0xffff) {
      $result = &change_bstr($doch, $mac_defo10[$idx{$i}], $name);
      return $result if $result ne "ok";
   }
   if (($i=$mac_inti[$mach]) != 0xffff) {
      $name = &main'upstr($name);
      $result = &change_bstr($doch, $mac_defo11{$i}, $name);
   }
   $result;
}

sub change_bstr {
   local($doch, $o, $name)=@_;
   local($buf)="";
   local($result);
   $result = &main'laola_get_file($doch, $buf, $mac_defbase+$o, 1);
   return $result if $result ne "ok";
   $l = &get_byte(0, $buf);
   if ($l!=length($name)) {
&main'laola_modify_file($doch, $buf, $mac_defbase+$o+1, $l); #qqqq
print "\nname=$name  basename=$buf\n";
      return "Size of new name does not match to size of old name...";
   }
   &main'laola_modify_file($doch, $name, $mac_defbase+$o+1, $l);
}

sub macro_guess_virus { #
#
# -1||0||1||$n = macro_guess_virus()
#
# This is a very silly try to figure out viri. Value is initialized 
# at macro_open. Return values mean:
#
#    -1: no macros -> no virus
#     0: macros, but probably no virus
#     1: macros, possibly a virus
#    $n: macros, most probably a virus!
#
   if (!@mac_ver && !$macro_trouble) {
      return -1;
   } elsif ($virus_alert==0) {
      return 0;
   } elsif ($virus_alert<10) {
      return 1;
   } else {
      return $virus_alert;
   }
}

sub macro_get_code { #
#
# code_text = macro_get_code( macrohandle, $private );
#
   return "Macro is ExecuteOnly." if ($mac_key[$_[0]] && $_[1]);
   &get_macro_definitions();

   local($buf) = $mac_codebuf[shift];
   local($i, $l);
   local($out)="";
   local($cmd, $n, $p1, $p2, $str);
   local(%parfix)=(
      0x67, 2, 
      0x68, 8,  # double, intel format
      0x6c, 2,  # integer
      0x6e, 1,  # n spaces?
      0x6f, 1,  # n tabs
      0x73, 2,
   );
   local(%parvar)=(
      0x65, 1, # \nstring [following ':']
      0x69, 1, # string
      0x6a, 1, # "string"
      0x6b, 1, # 'string
      0x6d, 1, # char
      0x70, 1, # REMstring
      0x76, 1  # .string
   );
   local($cmd)=0; local($eat)=1; local($col)=0;
   $i=2; $l=length($buf);
   while($i<$l) {
      $cmd=&get_byte($i, $buf);
      if ($parvar{$cmd}) {
         $p1=&get_byte($i+1, $buf);
         $str=substr($buf, $i+2, $p1);
         if       ($cmd == 0x65) { $out.=&macro_out("\n$str"); $eat=1; }
            elsif ($cmd == 0x69) { $out.=&macro_out(" $str");     }
            elsif ($cmd == 0x6a) { $out.=&macro_out(" \"$str\""); }
            elsif ($cmd == 0x6b) { $out.=&macro_out(" \'$str");   }
            elsif ($cmd == 0x6d) { $out.=&macro_out(" $str");     }
            elsif ($cmd == 0x70) { $out.=&macro_out("REM$str");  }
            elsif ($cmd == 0x76) { $out.=&macro_out(" \.$str");
         }
         $i+=1+1+$p1;
      } elsif ($n=$parfix{$cmd}) {
         if ($cmd == 0x67) {
            $p1=&get_word($i+1, $buf);
            if ($mac_token67{$p1}) {
               $out.=&macro_out("$mac_token67{$p1}");
            } else {
               $out.=&macro_out( sprintf("%02x %02x %02x ", 
                  unpack("C3", substr($buf, $i, 3))
               ));
               $uk_mac_token67{$p1}=1;
            }
         } elsif ($cmd == 0x68) {
            $p1=unpack("d", substr($buf, $i+1, 8));
            $out.=&macro_out( sprintf (" %.1f", $p1) );
         } elsif ($cmd == 0x6c) {
            $p1=&get_word($i+1, $buf);
            $out.=&macro_out( sprintf(" %d", $p1) );
         } elsif ($cmd == 0x6e) {
            $p1=&get_byte($i+1, $buf);
            $out.=&macro_out (" " x $p1 ); 
         } elsif ($cmd == 0x6f) {
            $p1=&get_byte($i+1, $buf);
            $out.=&macro_out ("\t" x $p1);
         } elsif ($cmd == 0x73) {
            $p1=&get_word($i+1, $buf);
            if ($mac_token73{$p1}) {
               $out.=&macro_out( "$mac_token73{$p1}" );
            } else {
               $out.=&macro_out( sprintf ("%02x %02x %02x ", 
                  unpack("C3", substr($buf, $i, 3))
               ));
               $uk_token73{$p1}=1;
            }
         }
         $i+=1+$n;
      } else {
         if ($mac_token{$cmd}) {
            $out.=&macro_out("$mac_token{$cmd}");
         } elsif ($cmd == 0x52) {
            $out.=&macro_out("\t");
         } elsif ($cmd == 0x64) {
            $out.=&macro_out("\n"); $eat=1; $col=0;
         } else {
            $out.=&macro_out( sprintf("%02x ", $cmd) );
         }

         if ( ($cmd==0x05) || # "("
              ($cmd==0x71)    # "#"
         ) {
            $eat=1;
         } 

         $i+=1;
      }
   }
   $out;
}

sub macro_out {
   local($out) = shift;
   if ($eat) {
      $out =~ s/^ //;
      $eat=0;
   }
   $col+=length($out);
   $out;
}

sub get_macro_definitions {
#
# init->get_macro_definitions()
#
# Reads the macro definitions from file "word6/macro.txt".
#
   return if %mac_token;
   local($path)=undef;
   local($mode)=0;
   local($key, $val);
   for (@INC) {
      $_ .= "/" if ! /\/$/;
      $path = $_ if -f $_."elser/word6/macro.txt";
      last if $path;
   }
   return if !$path;
   return if !open (DEFMAC, $path."elser/word6/macro.txt");
   is_open: {
      while (<DEFMAC>) {
         next if /^Sub/i;
         next if /^REM/i;
         next if /, ""/;
         next if /, "##"/;
         next if /, "####"/;
         if (/^' %([^=]+)/) {
            $mode=1 if $1 eq mac_token;
            $mode=2 if $1 eq mac_token67;
            $mode=3 if $1 eq mac_token73;
            next;
         }
         next if !/,/;
         ($key, $val) = /^ *"([^"]*)",(.[^ \x0a\x0d]*)/;
         $key = &hex($key);
         if ($mode==1) {
            $mac_token{$key}=$val;
         } elsif ($mode==2) {
            $mac_token67{$key}=$val;
         } elsif ($mode==3) {
            $mac_token73{$key}=$val;
         }
      }
   }
   close(DEFMAC);
}

#
# ------------------------------ Debug -------------------------------------
#

sub debug_macro_info {
   return &main'msg1("no macros") if 
      ! (@mac_ver || %mac_int || @mac_ext)
   ;

   &main'msgnl();
   print "\nDebug Macro Info:\n";
   local($i, $out);
   mac_info: {
      print "Macro info:\n";
      last if !@mac_ver;
      local($l) = $#mac_ver;
      print "  i: v  k   ii ei xi    uk   codel stat codeo  ".
            "intern        extern\n";
      for ($i=0; $i<=$l; $i++) {
         $out = sprintf(" %02x: %2x %02x  %02x %02x %04x  %04x %04x  %04x %04x".
            "   \"%s\"",
            $i, $mac_ver[$i], $mac_key[$i], 
            $mac_inti[$i], $mac_exti[$i], $mac_desci[$i],
            $mac_uk[$i], $mac_codel[$i], 
            $mac_state[$i], $mac_codeo[$i],
            $mac_int{$mac_inti[$i]}
         );
         $out .= " " x (60 - length($out));
         #$out .= sprintf(" \"%s\"", $mac_ext[$idx{$mac_exti[$i]}]); # qqqq
         $out .= sprintf(" \"%s\"", $mac_ext[$idx{$mac_exti[$i]}]);
         print "$out\n";
         if ($mac_desci[$i] != 0xffff) {
            printf("     Desc: \"%s\"\n", $mac_ext[$idx{$mac_desci[$i]}]);
         }
      }
   }
   men_info: {
      print "Menu info:\n";
      last if !@men_context;
      local($l) = $#men_context;
      print "  i: cont menu  ei  4     ii  pos    intern                  extern\n";
      for ($i=0; $i<=$l; $i++) {
         $out = sprintf(" %02x: %04x %04x  %02x  %04x  %02x  %04x   \"%s\"",
            $i, $men_context[$i], $men_menu[$i], 
            $men_inti[$i], $men_uk[$i], $men_exti[$i],
            $men_pos[$i], $mac_int{$men_inti[$i]}
         );
         $out .= " " x (60 - length($out));
         $out .= sprintf(" \"%s\"", $mac_ext[$idx{$men_exti[$i]}]);
         print "$out\n";
      }
   }
   mac_int: {
      last if !%mac_int;
      print "Intern:\n";
      foreach $i (sort {$a <=> $b} keys %mac_int) {
         printf (" %02x: %02x \"%s\"\n", $i, $mac_intuk{$i}, $mac_int{$i});
      }
   }
   mac_ext: {
      last if !@mac_ext;
      print "Extern:\n";
      $l=$#mac_ext;
      for ($i=0; $i<=$l; $i++) {
         printf (" %02x: %02x \"%s\"\n", $i, $mac_extuk[$i], $mac_ext[$i]);
      }
   }
   print "\n";
}

#
# ------------------------------ System -------------------------------------
#

sub hex {
   local($key)=shift;
   local($val)=0;
   local($hex)=0;
   local($l) = length($key);
   local($i);
   for ($i=0; $i<$l; $i++) {
      $hex*=0x10;
      $val = index("0123456789abcdef", substr($key, $i, 1));
      $val = index("0123456789ABCDEF", substr($key, $i, 1)) if $val<0;
      $hex+=$val;
   }
   $hex;
}

# thing = get_thing(offset, extern buf)
sub get_byte { unpack("C", substr($_[1], $_[0], 1)); }
sub get_word { unpack("v", substr($_[1], $_[0], 2)); }
sub get_long { unpack("V", substr($_[1], $_[0], 4)); }

sub get_pair { 
#
# @pair||() = get_pair($offset, $buf);
#
   local(@pair) = unpack("V2", substr($_[1], $_[0], 8)); 
   local(@empty) = (0, 0);
   return @empty if !($pair[0] && $pair[1]);
   @pair;
}

sub get_chunk {
#
# "ok"||$error = get_chunk($pair_offset, $header_buf)
#
   local($o, $l) = &get_pair($_[0], $_[1]);
   substr($_[1], $o, $l);
}

"Atomkraft? Nein, danke!"

