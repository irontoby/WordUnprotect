#
# $Id: struct.pl,v 0.1.1.5 1997/07/01 00:06:48 schwartz Rel $
#
# Structs of Word 6
#
# Outsourced code handling Word 6 structure data for program Elser. 
# (This is the only way outsourcing doesn't destroy jobs, isn't it?)
# It is part of Elser, a program to handle word 6 documents. Elser can 
# be found at:
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

sub structure_init {
   #
   # general header data, &get_general_data
   #
   $text_begin = 0;
   $text_end = 0;
   $file_len = 0;
   $text_len = 0;
   $foot_len = 0;
   $dest_len = 0;

   #
   # char formats, &get_char_format_pages o &get_char_formats
   #
   @charf_page = ();
   $charf_first_page = 0;
   $charf_page_num = 0;
   @charf_page_last_o = ();
   @char_o = ();
   @cfi = ();

   #
   # par formats, &get_par_format_pages o &get_par_formats
   #
   $parf_first_page = 0;
   $parf_page_num = 0;
   @parf_page_last_o = ();
   @parf_page = ();
   @parf_info = ();
   @par_o = ();
   @pfi = ();

   #
   # section_info (88), &get_section_info
   #
   @sect_to = ();
   @sect_uk1 = ();
   @sect_fo = ();
   @sect_uk2 = ();
   @sect_uk3 = ();
   @sfi = ();

   # derived: %fs formatstring
   %fs  = (0, ""); # format string hash
   %fsi = ("", 0); # format string index hash
   $fsi = 1;       # current index (internal)
   %fst = (0, ""); # type (internal, optional?)

   # converted: %tfs translated formatstring
   %tfs = (0, "");

   #
   # fastsave parf information (98), &get_fastsave_parf
   #
   @fpar_to = ();
   @fpar_o = (); # to be generated
   @fparf_info = ();
   @fpfi = ();

   #
   # fastsave charf information (160), &get_fastsave_charf
   #
   @fchar_to = ();
   @fast_uk = ();
   @fchar_o = ();
   @fast_ci = ();
   @fcfi = ();

   #
   # style sheets (0x58, 0x60), &get_style_sheet
   #
   @style_name = (); # style name
   @style_n = ();    # style number (-1 if not known)
   @style_id1 = ();
   @style_id2 = (); 
   @style_prev_state = ();
   @style_prev = ();
   @style_prev_gender = ();
   @style_next_state = ();
   @style_next = ();
   @style_next_gender = ();
   @style_pfi = ();
   @style_cfi = ();
   @style_debug = ();

   #
   # footnotes (68), &get_foot_info
   #
   @foot_o = ();
   @foot_num = ();
   @foot_fo = ();

   #
   # paragraphs (90), &get_paragraphs
   #
   @par_texto = ();
   @par_uk1 = ();
   @par_style = ();

   #
   # destination offsets (b0), &get_dest_info
   #
   @dest_do = ();

   #
   # font info (d0), &get_font_info
   #
   @font_n = ();    # name
   @font_ns = ();   # substitute font name?
   @font_pitch = (); 
   @font_family = (); 
   @font_uk0 = ();  # unknown 
   @font_uk1 = ();  # unknown 
   @font_uk2 = ();  # unknown 
   @font_charset = ();
   @font_n2o = (); 

   #
   # field info (d8), &get_field_info
   #
   @field_o = ();  # field texto
   @field_t = ();  # field type
   @field_v = ();  # field value

   #
   # dfield info (e0), &get_dfield_info
   #
   @dfield_o = ();  # field texto
   @dfield_t = ();  # field type
   @dfield_v = ();  # field value

   # 
   # anchor info (100, 108, 110), &get_anchor_info
   #
   @anchor_name = (); 
   @anchor_texto_b = ();
   @anchor_texto_e = ();
   @anchor_num = ();

   #
   # convert this to a common format list, &get_format_list
   #
   @format_to=();
   @format_o=();
   @format_i=();
   @format_ri=();
   @format_t=();
}

sub get_text_data {
   &get_general_data();
   &get_char_format_pages();
   &get_char_formats();
   &get_par_format_pages();
   &get_par_formats();
   &get_fastsave_parf();
   &get_fastsave_charf();
   &get_format_list();
}

#
# --------------  get documents structure data  -------------------
#

sub get_general_data {
   return if $text_begin;
   $text_begin = &get_long(0x18, $header);
   $text_end   = &get_long(0x1c, $header);
   $file_len   = &get_long(0x20, $header);
   $text_len   = &get_long(0x34, $header);
   $foot_len   = &get_long(0x38, $header);
   $dest_len   = &get_long(0x3c, $header);
}

sub get_style_sheet {
   return if @style_name;
   local($buf) = &get_chunk(0x60);
   local($tmp);

   local($len) = length($buf);
   push(@style_debug, substr($buf, 0, 0x10));

   local($o, $l, $fo, $fl); 

   if (&get_word(0, $buf) != 0x0e) {
      return;
   }
   $o=0x10; $l=0; 
   while (1) {
      while ( $o<$len ) {
         last if $l=&get_word($o, $buf);
         $o+=2; 
      }
      last if $o>=$len;

      # word(o+8) always contains a copy of word(o+0). Why?
      last if &get_word($o+8, $buf) != $l; # oops!

      # style ids
      push (@style_id1, &get_byte($o+2, $buf));
      push (@style_id2, &get_byte($o+3, $buf));

      $tmp = &get_word($o+4, $buf);
      push(@style_prev_state, $tmp/0x1000);
      push(@style_prev, ($tmp/0x10)&0xff);
      push(@style_prev_gender, $tmp&0xf);

      $tmp = &get_word($o+6, $buf);
      push(@style_next_state, $tmp/0x1000);
      push(@style_next, ($tmp/0x10)&0xff);
      push(@style_next_gender, $tmp&0xf);

      # style name
      push (@style_name, &get_lbstr($o+10, $buf));

      $fo=10+2+length($style_name[$#style_name]); $fo++ if ($fo&1);

      if ($style_prev_gender[$#style_prev_gender] & 1) {
         # Len of par string. Includes a style number.
         last if ($fl = &get_word($o+$fo, $buf)) < 2;

         # number of style 
         push(@style_n, &get_word($o+$fo+2, $buf) );

         # par style string
         push(@style_pfi, &add_format(substr($buf, $o+$fo+4, $fl-2), "sp"));

         $fo+=$fl+2; $fo++ if ($fo&1);
      } else {
         # Character styles have no paragraph string. Furthermore they
         # have no "next" character format (why?), therefore next format
         # stores the style number.
         push(@style_n, $style_next[$#style_next]);
         push(@style_pfi, 0);
      }

      # char style string
      push(@style_cfi, &add_format(&get_lwstr($o+$fo, $buf), "sc"));
      
      push(@style_debug, substr($buf, $o, $l+2));
      $o+=$l+2;
   }
}

sub get_dest_info {
   return if @dest_do;
   local($buf) = &get_chunk(0xb0);
   local($n) = length($buf) / 4;
   push(@dest_do, &get_nlong($n, 0, $buf));
}

sub get_font_info {
   return if @font_n;
   local($buf) = &get_chunk(0xd0);

   local($buflen) = length($buf);

   local($reclen);
   local($font1, $font2); 
   local($l, $strbuf); 

   local($pos)=2;
   while (1) {
      $reclen = &get_byte($pos, $buf);
      last if ($pos+$reclen) >= $buflen;

      $l = $reclen - 6;
      last if $l < 0;

      $strbuf = substr($buf, $pos+6, $l);
      ($font1, $font2) = ($strbuf =~ /(^[^\00]*)\00{0,1}([^\00]*)/);
      push (@font_n,  $font1);
      push (@font_ns, $font2);
      push (@font_pitch, &get_byte($pos+1, $buf) & 0x03);
      push (@font_uk0, &get_byte($pos+1, $buf) & 0x0c);
      push (@font_family, &get_byte($pos+1, $buf) & 0xf0);
      push (@font_uk1, &get_byte($pos+2, $buf));
      push (@font_uk2, &get_byte($pos+3, $buf));
      push (@font_charset, &get_byte($pos+4, $buf));
      push (@font_n2o, &get_byte($pos+5, $buf));
      $pos += $reclen+1;
   }
}

sub get_char_format_pages {
   return if @charf_page;
   local($buf) = &get_chunk(0xb8);

   @charf_page_last_o = &get_nlong((length($buf)-4)/6 +1, 0, $buf);
   @charf_page = (undef, 
      &get_nword($#charf_page_last_o, ($#charf_page_last_o+1)*4, $buf)
   );
   $charf_page_num = &get_word(0x18e, $header);
   if ($#charf_page < $charf_page_num) {
      $charf_first_page = &get_word(0x18a, $header);
      push(@charf_page,
           ($charf_first_page+1 .. ($charf_first_page+$charf_page_num-1))
      );
   }

   &mark_pagelist("charf page", @charf_page) if $mapmem;
}
   
sub get_char_formats {
   return if @char_o;
   if ($text_begin != $charf_page_last_o[0]) {
      return "Text section doesn't match with char format info!";
   }
   local($i, $j, $idx);

   local($fpage);
   local($o, $lo, $fodo, $l, $buf);
   local($n);

   for ($i=1; $i<=$#charf_page; $i++) {
      $fpage = substr($inbuf, $charf_page[$i]*0x200, 0x200);
      $n = &get_byte(0x1ff, $fpage);
      push(@char_o, unpack(sprintf("V%d",$n), $fpage));
      for ($j=0; $j<$n; $j++) {
         if ($fodo = &get_byte(4+$n*4+$j, $fpage)) {
            push (@cfi, &add_format(&get_lbstr($fodo*2, $fpage), "c"));
         } else {
            push (@cfi, 0);
         }
      }
   }
}

sub add_format {
#
# index = add_format (format_string)
#
   local($s, $t)=@_;
   if (defined $fsi{$s}) {
      return $fsi{$s};
   } else {
      $fs{$fsi}=$s;
      $fsi{$s}=$fsi;
      $fst{$fsi}=$t;
      return $fsi++;
   }
}
sub get_format {
#
# format_string = get_format (index)
#
   $fs{ shift(@_) };
}
sub get_type {
#
# format_string = get_format (index)
#
   $fst{ shift(@_) };
}

sub get_par_format_pages {
   return if @parf_page;
   $buf = &get_chunk(0xc0);

   @parf_page_last_o = &get_nlong((length($buf)-4)/6 +1, 0, $buf);
   @parf_page = (undef, 
      &get_nword($#parf_page_last_o, ($#parf_page_last_o+1)*4, $buf)
   );
   $parf_page_num = &get_word(0x190, $header);
   if ($#parf_page < $parf_page_num) {
      $parf_first_page = &get_word(0x18c, $header);
      push(@parf_page,
           ($parf_first_page+1 .. ($parf_first_page+$parf_page_num-1))
      );
   }
   &mark_pagelist("parf page", @parf_page) if $mapmem;
}

sub get_par_formats {
   return if @par_o;
   if ($text_begin != $parf_page_last_o[0]) {
      return "Text section doesn't match with par format info!";
   }
   local($i, $j);

   local($fpage);
   local($o, $lo, $fodo, $l, $buf);
   local($n);

   for ($i=1; $i<=$#parf_page; $i++) {
      $fpage = substr($inbuf, $parf_page[$i]*0x200, 0x200);
      $n = &get_byte(0x1ff, $fpage);
      push(@par_o, unpack(sprintf("V%d",$n), $fpage));
      for ($j=0; $j<$n; $j++) {
         push(@parf_info, substr($fpage, ($n+1)*4+$j*7+1, 6));
         if ($fodo = &get_byte(($n+1)*4+$j*7+0, $fpage)*2) {
            $l = &get_byte($fodo, $fpage);
            push (@pfi, &add_format(substr($fpage, $fodo+1, 2*$l), "p"));
         } else {
            push (@pfi, 0);
         }
      }
   }
}

sub get_fastsave_parf {
   return if @fpar_to;
   local($buf) = &get_chunk(0x98);
   return if !$buf;
   local($i);
   local($n) = (length($buf)-4)/10;
   @fpar_to = &get_nlong($n+1, 0, $buf);
   for ($i=0; $i<$n; $i++) {
      push(@fparf_info, substr($buf, ($n+1)*4 + $i*6, 6));
   }
}

sub get_fastsave_charf {
   return if @fcfi;
   return if !$word_fast;
   local($buf) = &get_chunk(0x160);
   return if !$buf;

   local($t, $o, $l);
   local($i, $fcfi, $max);
   $o=0; 
   while ($o<=length($buf)) {
      $t=0; $t=&get_byte($o, $buf);
      $l=0; $l=&get_word($o+1, $buf); 
      $o+=3;
      next if !$l;
      if (!$t) {
         $o++; next;
      } elsif ($t==1) {
         push(@fcfi, &add_format(substr($buf, $o, $l), "fc"));
      } elsif ($t==2) {
         $max = ($l-4)/12; $o+=2;
         @fchar_to = &get_nlong($max+1, $o, $buf);
         for ($i=0; $i<$max; $i++) {
            push(@fast_uk, &get_word($o+4+$max*4 + $i*8 + 0, $buf));
            push(@fchar_o, &get_long($o+4+$max*4 + $i*8 + 2, $buf));
            $fcfi =        &get_word($o+4+$max*4 + $i*8 + 6, $buf);
            push(@fast_ci, $fcfi);
            if ($fcfi) {
               push(@fcfi, ($fcfi-1)/2);
            } else {
               push(@fcfi, 0);
            }
         }
      } else {
         return "I don't understand this fastsave format!";
      }
      $o+=$l;
   }
}

sub get_foot_info {
   return if @foot_o;
   local($buf) = &get_chunk(0x68);

   local($n) = (length($buf)-4) / 6;
   local($i);
   for ($i=0; $i<$n; $i++) {
      push (@foot_o, &get_long($i*4, $buf));
      push (@foot_num, &get_word(($n+1)*4+$i*2, $buf));
   }
   push(@foot_o, &get_long($n*4, $buf));

   $buf = &get_chunk(0x70);
   $n = length($buf)/4;
   for ($i=0; $i<$n; $i++) {
      push (@foot_fo, &get_long($i*4, $buf));
   }
}

sub get_section_info {
   return if @sect_to;
   local($buf) = &get_chunk(0x88);

   local($i);
   local($n) = (length($buf)-4)/16;
   @sect_to = &get_nlong($n+1, 0, $buf);
   for ($i=0; $i<$n; $i++) {
      push(@sect_uk1, &get_word(($n+1)*4 + $i*12 + 0, $buf));
      push(@sect_fo,  &get_long(($n+1)*4 + $i*12 + 2, $buf));
      push(@sect_uk2, &get_word(($n+1)*4 + $i*12 + 6, $buf));
      push(@sect_uk3, &get_long(($n+1)*4 + $i*12 + 8, $buf));
      push(@sfi, &add_format(&get_lwstr($sect_fo[$i], $inbuf), "s"));
      &mark_lwstr($sect_fo[$i], "section format #".($i+1), 1) if $mapmem;
   }
}

sub get_paragraphs {
   return if @par_texto;
   local($buf) = &get_chunk(0x90);

   local($i);
   local($n) = (length($buf)-4)/8;
   @par_texto = &get_nlong($n+1, 0, $buf);
   for ($i=0; $i<$n; $i++) {
      push(@par_uk1, &get_word(($n+1)*4 + $i*4, $buf));
      push(@par_style, &get_word(($n+1)*4 + $i*4 +2, $buf));
   }
}

sub get_field_info {
   return if @field_o;
   local($buf) = &get_chunk(0xd8);

   local($buflen) = length($buf);
   local($n) = ($buflen-4) / 6;
   local($i);
   for ($i=0; $i<$n; $i++) {
      push (@field_o, &get_long($i*4, $buf));
      push (@field_t, &get_byte(($n+1)*4 + $i*2, $buf));
      push (@field_v, &get_byte(($n+1)*4 + $i*2 +1, $buf));
   }
   push (@field_o, &get_long($n*4, $buf));
}

sub get_dfield_info {
   return if @dfield_o;
   local($buf) = &get_chunk(0xe0);

   local($buflen) = length($buf);
   local($n) = ($buflen-4) / 6;
   local($i);
   for ($i=0; $i<$n; $i++) {
      push (@dfield_o, &get_long($i*4, $buf));
      push (@dfield_t, &get_byte(($n+1)*4 + $i*2, $buf));
      push (@dfield_v, &get_byte(($n+1)*4 + $i*2 +1, $buf));
   }
   push (@dfield_o, &get_long($n*4, $buf));
}

sub get_anchor_info {
   return if @anchor_name;
   local($buf) = &get_chunk(0x100);
   local($buflen) = length($buf);
   local($o, $l);
   $o=2;
   while ($o<$buflen) {
      $l = &get_byte($o, $buf);
      push(@anchor_name, substr($buf, $o+1, $l));
      $o += $l+1;
   }
   anchor_texto_b: {
      $buf = &get_chunk(0x108);
      local($n) = (length($buf)-4)/8;
      @anchor_texto_b = unpack(sprintf("V%d", $n+1), $buf);
      @anchor_num = unpack( sprintf("V%d", $n), substr($buf, ($n+1)*4) );
   }
   anchor_texto_e: {
      $buf = &get_chunk(0x110);
      local($n) = length($buf)/4;
      @anchor_texto_e = unpack(sprintf("V%d",$n), $buf);
   }
}

#
# -------------------------- Derived -------------------------------
#

sub get_format_list {
   return &get_fastformat_list if $word_fast;

   local($ic)=0; local($ico)=0;
   local($ip)=0; local($ipo)=0;
   foreach $ico (@char_o) {
      while ( ($ip<=$#par_o) && ($ipo=$par_o[$ip])<=$ico ) {
         push(@format_o, $par_o[$ip]);
         push(@format_to, $ipo-$text_begin);
         push(@format_t, 2);
         push(@format_ri, $ip);
         push(@format_i, $pfi[$ip++]);
      }
      push(@format_o, $char_o[$ic]);
      push(@format_to, $ico-$text_begin);
      push(@format_t, 1);
      push(@format_ri, $ic);
      push(@format_i, $cfi[$ic++]);
   }
}

sub get_fastformat_list {
   local($ic)=0; local($ico)=0; 
   local($oic)=0;
   local($ip)=0; local($ipo)=0;
   foreach $ico (@fchar_to) {
      while ( ($ip<=$#fpar_to) && ($ipo=$fpar_to[$ip])<=$ico ) {
         push(@format_to, $ipo);
         push(@format_t, 5);
         push(@fpar_o, $fchar_o[$oic]+$ipo-$fchar_to[$oic]);
         push(@format_o, $fpar_o[$ip]);
         push(@format_ri, $ip);
         push(@format_i, $fpfi[$ip++]);
      }
      push(@format_o, $fchar_o[$ic]);
      push(@format_to, $ico);
      push(@format_t, 4);
      $oic=$ic;
      push(@format_ri, $ic);
      push(@format_i, $fcfi[$ic++]);
   }
}

"Atomkraft? Nein, danke!"

