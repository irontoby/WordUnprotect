#
# $Id: elserdb.pl,v 0.1.1.5 1997/07/01 00:06:45 schwartz Rel $
#
# Outsourced debugging and information code for program Elser. 
# (This is the only way outsourcing doesn't destroy jobs, isn't it?)
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

sub internal_info {
   for (split(//, $opt_z)) {
      &debug_it();
   }
}

sub debug_it {
   if    (/a/) { &debug_anchor() }
   elsif (/c/) { &debug_char_format() }
   elsif (/C/) { &debug_char_format_pages() }
   elsif (/d/) { &debug_dfield_info() }
   elsif (/D/) { &debug_dest_info() }
   elsif (/f/) { &debug_foot_info() }
   elsif (/F/) { &debug_font_info() }
   elsif (/i/) { &debug_field_info() }
   elsif (/k/) { &debug_format_hashlist() }
   elsif (/l/) { &debug_format_list() }
   elsif (/L/) { &debug_format_list_mucho() }
   elsif (/m/) { &macro'debug_macro_info() }
   elsif (/M/) { &debug_memory() }
   elsif (/p/) { &debug_par_format(); &debug_paragraph() }
   elsif (/P/) { &debug_par_format_pages() }
   elsif (/q/) { &debug_fastsave_info() }
   elsif (/s/) { &debug_section_info() }
   elsif (/S/) { &debug_style_sheet() }
   elsif (/T/) { &debug_text() }
   elsif (/Z/) { }
   else { 
      &msg3("Unknown option $_.\n");
   }
}

sub debug_char_format_pages {
   &get_text_data();
   if (!@charf_page) {
      &msg1("no char table"); return;
   }
   &msgnl();
   local($i);
   printf ("\nDebug Char format tables (%s full entries):\n", $#charf_page);
   printf ("   Last Offset %2d: %5x\n", 0, $charf_page_last_o[0]);
   for ($i=1; $i<=$#charf_page; $i++) {
      printf ("   Last Offset %2d: %5x  page %x (page offset %x)\n", 
         $i, $charf_page_last_o[$i], $charf_page[$i], $charf_page[$i]*0x200
      );
   }
}

sub debug_char_format {
   &get_text_data();
   if (!@char_o) {
      &msg1("no character info"); return;
   }
   &msgnl();
   local($i, $s);
   printf ("\nDebug Format Character (%d entries) = \n", $#char_o+1);
   for ($i=0; $i<=$#char_o; $i++) {
      $s = &get_format($cfi[$i]);
      printf ("   %2d: %05x = " . "%02x " x length($s) . "\n",
         $i, $char_o[$i], unpack("C"x length($s), $s)
      );
   }
   printf "\n";
}

sub debug_par_format_pages {
   &get_text_data();
   if (!@parf_page) {
      &msg1("no par table"); return;
   }
   &msgnl();
   local($i);
   print "\nDebug Paragraph format tables ($#parf_page full entries):\n";
   printf ("   Last Offset %2d: %5x\n", 0, $parf_page_last_o[0]);
   for ($i=1; $i<=$#parf_page; $i++) {
      printf ("   Last Offset %2d: %5x  page %x (page offset %x)\n", 
         $i, $parf_page_last_o[$i], $parf_page[$i], $parf_page[$i]*0x200
      );
   }
}

sub debug_par_format {
   &get_text_data();
   if (!@par_o) {
      &msg1("no paragraph info"); return;
   }
   &msgnl();
   local($i, $l, $s);
   printf ("\nDebug Format Paragraph (%d entries) = \n", $#par_o+1);
   for ($i=0; $i<=$#par_o; $i++) {
      $s = &get_format($pfi[$i]);
      printf (" %3x: %05x  (" . "%02x " x 5 . "%02x) = " 
              . "%02x " x length($s) . "\n",
         $i, $par_o[$i],
         &get_nbyte(6, 0, $parf_info[$i]),
         unpack("C"x length($s), $s)
      );
   }
}

sub debug_section_info {
   &get_section_info();
   if (!@sect_to) {
      &msg1("no section info"); return;
   }
   &msgnl();
   local($i);
   printf ("\nDebug Section info:\n");
   for ($i=0; $i<=$#sect_to; $i++) {
      printf("  %3x: %05x  %04x %05x %04x %08x\n",
             $i, $sect_to[$i], $sect_uk1[$i], $sect_fo[$i],
             $sect_uk2[$i], $sect_uk3[$i]
      );
   }
   print "\n";
   local($str);
   for ($i=0; $i<$#sect_to; $i++) {
      $str = &get_format($sfi[$i]);
      printf("Section Format %02x:\n   ", $i);
      printf("%02x " x length($str), &get_nbyte(length($str), 0, $str));
      print "\n\n";
   }
}

sub debug_fastsave_info {
   &get_text_data();
   if (!@fcfi && !@fchar_to) {
      &msg1("no fastsave info"); return;
   }
   &msgnl();
   local($i, $l, $s);
   print "\nDebug Fastsave\n";

   print "Fastsave paragraph info:\n";
   for ($i=0; $i<$#fpar_to; $i++) {
      printf (" %3x: %05x  (" . "%02x " x 5 . "%02x)\n",
         $i, $fpar_to[$i], &get_nbyte(6, 0, $fparf_info[$i])
      );
   }
   printf (" %3x: %05x\n", $#fpar_to, $fpar_to[$#fpar_to]);

   print "Fastsave character formats:\n";
   for ($i=0; $i<=$#fcfi; $i++) {
      printf (" %3x: ", $i);
      $s = &get_format($fcfi[$i]);
      $l = length($s);
      printf ("%02x " x $l, unpack("C$l", $s));
      print "\n";
   }
   print "Fastsave character offsets:\n";
   for ($i=0; $i<=$#fchar_to; $i++) {
      printf (" %3x: to=%05x  uk=%04x  o=%04x  ci=%02x\n",
         $i,
         $fchar_to[$i], $fast_uk[$i], 
         $fchar_o[$i], 
         $fast_ci[$i] 
      );
   }
}

sub debug_memory {
   &mark_setsize(length($inbuf));

   &get_text_data();
   &mark_all_chunks();
   &mark_text();

   &get_style_sheet();
   &get_foot_info();
   &get_paragraphs();
   &get_dest_info();
   &get_font_info();
   &get_field_info();
   &get_dfield_info();
   &get_anchor_info();

   &debug_memory_usage();
}

sub debug_style_sheet {
   &get_style_sheet();
   &msgnl();
   local($l) = $#style_debug;
   local($i);
   print "\nDebug Style sheet:\n";
   print "Header: ";
   printf ("%02x " x 0x10, unpack("C16", $style_debug[0]));
   print "\n";
   print "     0   #   2  3    4       6        8     a\n";
   for ($i=1; $i<=$l; $i++) {
      printf(" %02x (%02x) %02x: %02x %02x   %x %02x %x  %x %02x %x".
             "  (%02x)  \"%s\"\n", 
         $i-1, 
         &get_word(0, $style_debug[$i]), 
         $style_n[$i-1],
         $style_id1[$i-1],
         $style_id2[$i-1],
         $style_prev_state[$i-1],
         $style_prev[$i-1],
         $style_prev_gender[$i-1],
         $style_next_state[$i-1],
         $style_next[$i-1],
         $style_next_gender[$i-1],

         &get_word(8, $style_debug[$i]),
         &get_lbstr(0xa, $style_debug[$i])
      );
   }
}

sub debug_font_info {
   &get_font_info();
   if (!@font_n) {
      &msg1("no fonts"); return;
   }
   &msgnl();
   local($i);
   print "\nDebug Font Info:\n";
   for ($i=0; $i<=$#font_n; $i++) {
      printf ("%2x: [%0x %0x %02x, %02x, %02x, %02x, %02x]  %s", 
              $i, $font_pitch[$i], $font_uk0[$i], $font_family[$i], 
              $font_uk1[$i], $font_uk2[$i], $font_charset[$i], 
              $font_n2o[$i],
              $font_n[$i]);
      printf (" (%s)", $font_ns[$i]) if $font_ns[$i];
      print "\n";
   }
}

sub debug_foot_info {
   &get_text_data();
   &get_foot_info();
   if (!@foot_o) {
      &msg1("no footnotes"); return;
   }
   &msgnl();
   local($buf) = &get_text($text_len, $foot_len);
   print "\nDebug Footnote info:\n";
   local($i, $l);
   for ($i=0; $i<$#foot_o; $i++) {
      $l = $foot_fo[$i+1]-$foot_fo[$i];
      $l = 45 if $l > 45;
      printf ("%2x: %02x %05x %05x == \"%s\"\n",
              $i, $foot_num[$i],
              $foot_o[$i], $foot_fo[$i],
              substr($buf, $foot_fo[$i], $l)
      );
   }
   printf ("%2x:          %05x\n", $i, $foot_fo[$#foot_fo]);
   print "\n";
}

sub debug_paragraph {
   &get_paragraphs();
   return if !@par_texto;
   &msgnl();
   local($i);
   printf ("\nDebug Paragraph info (extra):\n");
   for ($i=0; $i<=$#par_texto; $i++) {
      printf("  %3x: %05x %02x %02x\n",
             $i, $par_texto[$i], $par_uk1[$i], $par_style[$i]
      );
   }
}

sub debug_dest_info {
   &get_text_data();
   &get_dest_info();
   if (!@dest_do) {
      &msg1("no destinations"); return;
   }
   &msgnl();
   local($buf) = &get_text($text_len+$foot_len, $dest_len);
   print "\nDebug Destination info:\n";
   local($i, $l);
   for ($i=0; $i<$#dest_do; $i++) {
      $l = $dest_do[$i+1]-$dest_do[$i];
      printf ("%2x: %05x = \"%s\"\n",
              $i, $dest_do[$i],
              substr($buf, $dest_do[$i], $l)
      );
   }
   printf ("%2x: %05x\n", $i, $dest_do[$#dest_do]);
   print "\n";
}

sub debug_field_info {
   &get_text_data();
   &get_field_info();
   if (!@field_o) {
      &msg1("no field"); return;
   }
   &msgnl();
   print "\nDebug Field info:\n";
   local($buf) = &get_text(0, $text_len);
   local($i, $l, $out);
   for ($i=0; $i<=$#field_o; $i++) {
      $out = sprintf ("%2x: %05x (%2x, %2x) ",
              $i, $field_o[$i], $field_t[$i], $field_v[$i]);
      if ( ($i<$#field_o) && ($field_t[$i]<=$field_t[$i+1])) {
         $l = $field_o[$i+1]-$field_o[$i]-1;
         if ($l) {
            $out .= " " x (20 - length($out));
            $out .=  "== \"".substr($buf, $field_o[$i]+1, $l)."\"";
         }
      }
      print "$out\n";
   }
   print "\n";
}

sub debug_dfield_info {
   &get_text_data();
   &get_dfield_info();
   if (!@dfield_o) {
      &msg1("no dfield"); return;
   }
   &msgnl();
   print "\nDebug Destination Field:\n";
   local($buf) = &get_text($text_len+$foot_len, $dest_len);
   local($i, $l, $out);
   for ($i=0; $i<=$#dfield_o; $i++) {
      $out = sprintf ("%2x: %05x (%2x, %2x) ",
              $i, $dfield_o[$i], $dfield_t[$i], $dfield_v[$i]);
      if ( ($i<$#dfield_o) && ($dfield_t[$i]<=$dfield_t[$i+1])) {
         $l = $dfield_o[$i+1]-$dfield_o[$i]-1;
         $l = 50 if $l > 50;
         if ($l) {
            $out .= " " x (20 - length($out));
            $out .=  " == \"".substr($buf, $dfield_o[$i]+1, $l)."\"";
         }
      }
      print "$out\n";
   }
   print "\n";
}
   
sub debug_anchor {
   &get_text_data();
   &get_anchor_info();
   if (!@anchor_name) {
      &msg1("no anchors"); return;
   }
   &msgnl();
   print "\nDebug Anchors:\n";
   local($i, $l);
   local($out);
   for ($i=0; $i<=$#anchor_name; $i++) {
      $l = $anchor_texto_e[$anchor_num[$i]] - $anchor_texto_b[$i];
      #$l = 30 if $l > 30;
      $out = sprintf(" %3x: %3x (%05x..%05x) %s", 
         $i, $anchor_num[$i], 
         $anchor_texto_b[$i], 
         $anchor_texto_e[$anchor_num[$i]], $anchor_name[$i]
      );
      $out .= " " x (38 - length($out));
      if ( ($anchor_name[$i] =~ /^_Toc/) || 1) {
         $out .=  sprintf(" = \"%s\"", 
            substr($inbuf, $text_begin+$anchor_texto_b[$i], $l)
         );
      }
      print "$out\n";
   }
}

sub debug_format_list {
   &get_text_data();
   if (!@format_to) {
      &msg1("no format list"); return;
   }
   &msgnl();
   print "\nDebug Format List:\n";
   local($i);
   for ($i=0; $i<$#format_to; $i++) {
      printf(" %3x: to=%04x  l=%04x  t=%d  i=%03x  ri=%03x  o=%05x\n",
             $i, $format_to[$i], $format_to[$i+1]-$format_to[$i],  
             $format_t[$i], $format_i[$i], $format_ri[$i], $format_o[$i]
      );
   }
}

sub debug_format_list_mucho {
   &get_text_data();
   if (!@format_to) {
      &msg1("no format list"); return;
   }
   &msgnl();
   local($buf) = &get_text(0, $text_len);
   print "\nDebug Format List (big):\n";
   local($i, $ii, $j, $l, $s);
   for ($i=0; $i<$#format_to; $i++) {
      print "-" x 60 ."\n" unless !$l;
      printf(" %2x: to=%04x  l=%04x  t=%d  i=%03x  ri=%03x\n",
             $i, $format_to[$i], $format_to[$i+1]-$format_to[$i], 
             $format_t[$i], $format_i[$i], $format_ri[$i]
      );
      $ii=$format_i[$i]; next if !$ii;
      if ($format_t[$i]==1) {
         &print_format($ii, "  char");
      } elsif ($format_t[$i]==2) {
         printf ("  parfinfo = (" . "%02x " x 5 . "%02x)\n",
            unpack("C"x 6, $parf_info[$format_ri[$i]])
         );
         &print_format($ii, "  par");
      } elsif ($format_t[$i]==4) {
         &print_format($ii, "  fchar");
      } elsif ($format_t[$i]==5) {
         &print_format($ii, "  fpar");
      }
      print "\n";

      $l=$format_to[$i+1]-$format_to[$i]; #$l=60 if $l>60;
      print substr($buf, $format_to[$i], $l);
      print "\n\n" unless !$l;
   }
}

sub debug_format_hashlist {
   &get_text_data();
   &get_section_info();
   &get_style_sheet();
   &msgnl();
   print "\n";
   foreach $i ( sort {$a <=> $b} keys %fs ) {
      next if !$i;
      printf ("  %02x %2s: ", $i, &get_type($i));
      &print_format($i);
   }
}

sub print_format {
   local($i)=shift;
   return if !$i;
   local($s)=shift; print $s if $s;
   $s=&get_format($i);
   local($l)=length($s);
   local($n) = 20;
   local($r) = $l / $n;
   local($c) = ($l % $n);
   local($out) = sprintf ("f = " 
      . ( "%02x " x $n . "\n             ") x $r
      . ( "%02x " x $c ) . "\n",
      unpack("C"x $l, $s)
   );
   $out =~ s/\n +\n/\n/;
   print "$out";
}

sub debug_text {
   &output_init();
   &msg1("converting to text");
   &get_text_data();
   $outbuf = &get_text(0, $text_len+$foot_len+$dest_len);
   $outbuf =~ s/\x0d/\n/g if ($sys_os eq "unix");
   if ($opt_f || $opt_F) {
      return print $outbuf;
   } else {
      &msg1("saving");
      return &msg2(&save_txt_document($infile))
   }
}

sub report_statistic {
   local($i, @i);
   local($max, $out);
   $max=0;
   for (sort {$a<=>$b} keys %stat_o) {
      $stat_o{$_}=$max++;
   }
   print "\nDebug Header Statistic:\n";
   print "Filename     v status           ";
   for ($i=0; $i<=2; $i++) {
      print " " x 32 if $i==1;
      print " " x 15 . "fedcba9876543210 " if $i==2;
      for (sort {$a<=>$b} keys %stat_o) {
         print substr(sprintf("%03x", $_), $i, 1);
      }
      print "\n";
   }
   foreach $file (sort {$stat_fn{$a} cmp $stat_fn{$b}} keys %stat_fn) {
      printf("%12s %d ", substr($stat_fn{$file}, 0, 12), $stat_v{$file});
      $out = sprintf("%8s", unpack("B*", pack("C", $stat_s{$file} / 256) ));
      $out .= sprintf("%8s ", unpack("B*", pack("C", $stat_s{$file} & 255) ));
      $out =~ s/0/-/g;
      print $out;
      $out = '.' x $max;
      @i = split(/ +/, $stat_i{$file});
      for (@i) {
         substr($out, $stat_o{$_}, 1)="x";
      }
      print $out;
      print "\n";
   }

   print "\nUnknown variables:\n";
   print " "x16 . "0c   12   14   16   24       28       2c       30\n";
   print " "x16 . "40        44        48       4c       50       54\n";
   foreach $file (sort {$stat_fn{$a} cmp $stat_fn{$b}} keys %stat_fn) {
      printf("%12s %d: ", substr($stat_fn{$file}, 0, 12), $stat_v{$file});
      $out = sprintf("%04x %04x %04x %04x %08x %08x %08x %08x\n",
         $stat_w0c{$file}, $stat_w12{$file}, $stat_w14{$file},
         $stat_w16{$file}, $stat_l24{$file}, $stat_l28{$file},
         $stat_l2c{$file}, $stat_l30{$file}
      );
      $out =~ s/0/./g; print $out;
      $out = sprintf(" "x16 . "%08x  %08x  %08x %08x %08x %08x",
         $stat_l40{$file}, $stat_l44{$file}, $stat_l48{$file},
         $stat_l4c{$file}, $stat_l50{$file}, $stat_l54{$file}
      );
      $out =~ s/0/./g; print "$out\n";
   }
   print "\n";
}

sub get_text {
#
# $buf = get_text ($offset, $size)
#
   ($offset, $size) = (shift||0, shift||0);
   return "" if !$size;

   local($i);
   local($bs, $max);
   local($buf)="";

   local($begin, $done, $len);
   local(@o)=(); local(@l)=();

   $max = $#format_to;

   $done = 0;
   for ( $i=0; ($i<=$max) && ($done!=$size); $i++) {
      $bs = $format_to[$i+1]-$format_to[$i];
      last if $bs<0; 
      if ($offset) {
         if ($bs <= $offset) {
            $offset -= $bs;
            next;
         } else {
            $begin = &get_text_offset($i) + $offset;
            $len   = $bs - $offset;
            $offset = 0;
         }
      } else {
         $begin = &get_text_offset($i);
         $len   = $bs;
      }
      if ( ($done+$len) > $size ) {
         $len = $size - $done;
      }
      if ( !@o || ($o[$#o]+$l[$#l])!=$begin ) {
         push(@o, $begin); 
         push(@l, $len);
      } else {
         $l[$#l]+=$len;
      }
      $done += $len;
   }

   $max=$#o;
   for ($i=0; $i<=$max; $i++) {
      $buf .= substr($inbuf, $o[$i], $l[$i]);
   }

   $buf;
}

sub save_chunks {
   &info_init();
   local($buf, $o, $out);
   local($result)="ok"; local(@i);
   return "Invalid parameters." if !($opt_Z =~ /^#/);
   local($tmp) = $opt_Z =~ /^#(.+)$/; 
   &msg1("saving chunks");
   @i = ();
   for (split(/[, ]/, $tmp)) {
      push(@i, &hex2dez($_));
   }
   @i = (0x58, sort {$a <=> $b} keys %chunk_info) if !@i;
   foreach $o (@i) {
      $buf = &get_chunk($o);
      next if !length($buf);
      $out = sprintf("$analyzedir/%s.%03x", ($infile=~/^([^.]*)/), $o);
      $result = &save_buf($out, $buf);
      next if $result eq "ok";
   }
   $result;
}

#
# --------------------------- Storage Use ----------------------------------
#

sub get_statistic {
   &info_init();
   local($o, $l);
   return if !($word_version==6 || $word_version==7);
   $stat_fn{$stat_i}=$infile;
   $stat_v{$stat_i}=$word_version;
   $stat_s{$stat_i}=$word_status;
   $chunk_info{0x58}="";
   for (keys %chunk_info) {
      ($o, $l) = &get_nlong(2, $_, $inbuf);
      next if !($o && $l);
      $stat_i{$stat_i}.="$_ ";
      $stat_o{$_}=1;
   }
   $chunk_info{0x58}=undef;
   unknown: {
      $stat_w0c{$stat_i} = &get_word(0x0c, $inbuf);
      $stat_w12{$stat_i} = &get_word(0x12, $inbuf);
      $stat_w14{$stat_i} = &get_word(0x14, $inbuf);
      $stat_w16{$stat_i} = &get_word(0x16, $inbuf); 
      $stat_l24{$stat_i} = &get_long(0x24, $inbuf);
      $stat_l28{$stat_i} = &get_long(0x28, $inbuf);
      $stat_l2c{$stat_i} = &get_long(0x2c, $inbuf);
      $stat_l30{$stat_i} = &get_long(0x30, $inbuf);
      $stat_l40{$stat_i} = &get_long(0x40, $inbuf);
      $stat_l44{$stat_i} = &get_long(0x44, $inbuf);
      $stat_l48{$stat_i} = &get_long(0x48, $inbuf);
      $stat_l4c{$stat_i} = &get_long(0x4c, $inbuf); 
      $stat_l50{$stat_i} = &get_long(0x50, $inbuf);
      $stat_l54{$stat_i} = &get_long(0x54, $inbuf);
   }
   $stat_i++;
}

sub info_init {
   return if %chunk_info;
   # statistic
   $stat_i=0; %stat_fn=(); %stat_i=(); %stat_v=(); %stat_s=(); %stat_o=();
   %stat_w0c=(); %stat_w12=(); %stat_w14=(); %stat_w16=(); 
   %stat_l24=(); %stat_l28=(); %stat_l2c=(); %stat_l30=();
   %stat_l40=(); %stat_l44=(); %stat_l48=(); %stat_l4c=(); 
   %stat_l50=(); %stat_l54=();
   # chunks
   %chunk_info = (
      0x060, "stylesheet",
      0x068, "footnote info",
      0x070, "footnote offsets",
      0x078, "",
      0x080, "",
      0x088, "section info",
      0x090, "paragraph extra info",
      0x098, "fastsave paragraph format info",
      0x0a0, "",
      0x0a8, "",
      0x0b0, "destination offsets",
      0x0b8, "charf pages",
      0x0c0, "parf pages",
      0x0c8, "",
      0x0d0, "font info",
      0x0d8, "field info",
      0x0e0, "destination field info",
      0x0e8, "",
      0x0f0, "",
      0x0f8, "",
      0x100, "anchor 1 info",
      0x108, "anchor 2 info",
      0x110, "anchor 3 info",
      0x118, "macro definition",
      0x120, "",
      0x128, "",
      0x130, "printer info",
      0x138, "printer 1",
      0x140, "printer 2",
      0x148, "",
      0x150, "summary information",
      0x158, "summary information 2",
      0x160, "fastsave character format info",
      0x168, "",
      0x170, "",
      0x178, "",
      0x192, "",
      0x19a, "",
      0x1a2, "",
      0x1aa, "",
      0x1b2, "",
      0x1ba, "",
      0x1c2, "",
      0x1ca, "",
      0x1d2, "",
      0x1da, "",
      0x1e2, "",
      0x1ea, "",
      0x1f2, "",
      0x1fa, "authress history",
      0x202, "",
      0x20a, "",
      0x212, "",
      0x21a, "",
      0x222, "",
      0x22a, "",
      0x232, "",
      0x23a, "",
      0x242, "document vars",
      0x24a, "",
      0x252, "",
      0x25a, "",
      0x262, "",
      0x26a, "",
      0x272, "",
      0x27a, "",
      0x282, "",
      0x28a, "",
      0x292, "",
      0x29a, "document history"
   );
}

sub mark_lwstr {
   local($o, $info, $level) = @_;
   &mark ($o, &get_word($o, $inbuf)+2, "format", $info, $level);
}

sub mark_pagelist {
   local($info) = shift;
   local($i)=1;
   for (@_) {
      next if !$_;
      &mark_page($_, "$info #".$i++);
   }
}

sub mark_page {
   local($o, $info) = @_;
   &mark ($o*0x200, 0x200, "page", $info, 1);
}


sub mark_text {
   local($i, $o, $l);
   local($oi)=1; 
   local($oo)=$format_o[0];
   local($ol)=0;
   for ($i=0; $i<=$#format_to; $i++) {
      $l = $format_to[$i+1]-$format_to[$i];
      $o = $format_o[$i];
      &mark_text_check;
   }
   &mark_text_chunk;
}

sub mark_text_check {
   return if $l<0;
   if ($o == ($oo+$ol)) {
      $ol+=$l;
   } else {
      &mark_text_chunk;
      $oo=$o; $ol=$l;
   }
}

sub mark_text_chunk {
   &mark($oo, $ol, "text", "text chunk #".$oi++, 1);
}


sub mark_all_chunks {
   &info_init();
   &mark (0, 0x300, "system", "header", 1);
   while (($k,$v) = each %chunk_info) {
      $v=sprintf("- 0x%x -", $k) if !$v;
      &mark_chunk($k, $v);
   }
}

sub mark_chunk {
   local($o, $info) = @_;
   &mark ($o, 8, "pair", $info, 4);
   &mark (&get_long($o, $inbuf), &get_long($o+4, $inbuf), 
      "chunk", $info, 1
   );
}

"Atomkraft? Nein, danke!"

