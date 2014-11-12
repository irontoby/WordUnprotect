#
# $Id: decrypt.pl,v 0.1.1.6 1997/07/01 00:06:46 schwartz Rel $
#
# Decrypt Word 6
#
# This library handles decryption of password protected Word 6 style
# documents. It is part of Elser, a program to handle word 6 documents. 
# Elser can be found at:
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

sub word_decrypt_document    { &wdecrypt'decrypt_document; }


package wdecrypt;

sub decrypt_document { #
#
# ("ok",$password)|$error = decrypt_document($documentbuf, $docsum_handle);
#
# Package 'main must hold open laola library for the current docsum_handle.
# It also should have the routine msg().
#
   local($inbuf, $suminfoh, $word_version, $word_status) = @_;
   local($uncertain)=0;
   local($solved)=0;
   local($solved_old);
   local(%crypt_info) = ();
   local(%crypt_method) = ();
   local(%key) = ();
   local(%keylevel) = ();
   local(%ambig_key) = ();
   local(%ambig_keylevel) = ();
   local($password)=undef;

   decrypt: {
      while (($solved<16) && ($uncertain<7)) {
         $solved_old = $solved;
         &solve_key($uncertain);
         if ($solved_old == $solved) {
            $uncertain++;
         } else {
            $uncertain=0;
         }
      }
      $password = &get_password();
      &debug_decrypt();
      return "Cannot decrypt \"$infile\"!" if $solved != 16; 
      &do_decrypt($inbuf);
      $_[0]=$inbuf;
   }

   ("ok", $password);
}

sub get_password {
#
# $pw = get_password()
#
# Password is yielded as follows: starting with byte 0 of the key, each
# byte of the (key) is rotated one bit left. Then it is xored with the 
# according byte of the (password key). 0 and even indices belong to 
# pwkey[0], odd indices belong to pwkey[1]. pwkey stands at 0x10 and 0x11 
# of the header. As passwords of course differ in length, end of password 
# has to be found. Therefore a hash for the current pw is computed. Password 
# is found, when this hash is equal to the 16 bit hash standing at 0x0e of
# the header. (So you see, it is actually not very complicated to compute 
# a full password table, as the pwkey is just 16 bit and it's visible for 
# everybody...)
#
   local($hash) = &main'get_word(0x0e, $inbuf);
   local(@pwkey) = &main'get_nbyte(2, 0x10, $inbuf);
   local($b, $i);
   local($pw) = "";

   local($h) = 0xce4b;
   return $pw if $h == $hash;
   for ($i=0; $i<15; $i++) {
      if (defined $key{$i}) {
         $b = &rol($key{$i},1,8) ^ $pwkey[$i&1];
         $h ^= ( &rol($b,$i+1,15) ^ ($i+1) ^ $i);
         $pw .= pack("C", $b);
         last if $h == $hash;
      } else {
         $pw .= '.'; $h=0;
      }
   }
   $pw;
}

sub do_decrypt {
#
# void = do_decrypt($buf)
#
# Decryption is probably not equivalent to Word's, as Word seems to 
# decrypt used data only, leaving trash data unchanged. It is slow, because
# this kind of bit operations of course should be done by a compiled
# program, and because perl 4 obviously cannot xor chars (unlike perl 5).
#
   local($i, $c, $k); 
   local($key)="";
   local($l) = length($_[0]);

   # clear encryption flag
   &main'put_byte(&main'get_byte(0x0b, $_[0])^1, 0x0b, $_[0]);

   # clear checksum and password key
   substr($_[0], 0x0e, 4) = "\0\0\0\0";

   # xor 16 byte key over all document, starting at byte 0x28
   for ($i=0x28; $i<$l; $i++) {
      if ($c = unpack("C", substr($_[0], $i, 1)) ) {
         if ($k = $c ^ $key{$i % 16}) {
            substr($_[0], $i, 1) = pack("C", $k);
         }
      }
      # Tell userEss, that everything runs fine...
      &main'msg(".") if (!($i%0x2000)) && ($l>0x8000);
   }
}

sub solve_key {
#
# Find the key. Find keys in the document by trying several methods.
# There are different levels of assumed certainty, where 0 means very
# certain and 5 means very speculative. 6 is special and is used to
# finally decide, if ambigous keys have the value 0 or not.
# 
# Yes, can be improved :*)
#
   local($uncertain) = shift;
   local(%solved);
   local($method);
   local($i);
   local($max)=10;
   &get_crypt_info();
   for ($i=1; $i<=$max; $i++) {
      $method=$uncertain*$max+$i;
      next if $crypt_method{$method};
      %solved=();
      solve: {
         if ($uncertain == 0) {
            &method1  if $i==1;
            &method2  if $i==2;
            &method3  if $i==3;
            &method4  if $i==4;
            &method5  if $i==5;
         } elsif ($uncertain == 1) {
            &method10 if $i==1;
            &method11 if $i==2;
            &method12 if $i==3;
            &method13 if $i==4;
         } elsif ($uncertain == 2) {
            &method41 if $i==1;
            &method42 if $i==2;
            &method43 if $i==3;
            &method44 if $i==4;
            &method45 if $i==5;
         } elsif ($uncertain == 3) {
            &method31 if $i==1;
            &method32 if $i==2;
            &method33 if $i==3;
            &method34 if $i==4;
         } elsif ($uncertain == 4) {
            &method20 if $i==1;
            &method21 if $i==2;
            &method22 if $i==3;
            &method24 if $i==4;
            &method25 if $i==5;
            &method26 if $i==6;
         } elsif ($uncertain == 5) {
            &method50 if $i==1;
            &method51 if $i==2;
            &method52 if $i==3;
            &method53 if $i==4;
         } elsif ($uncertain == 6) {
            &method60 if $i==1;
         }
      }
      next if !%solved; 

      foreach $key (keys %solved) {
         if ( (! defined $key{$key}) || ($uncertain<$keylevel{$key})) {
            $solved++ if !defined $key{$key};
            #printf("%d solved key %x, value %x\n", $method,$key,$solved{$key});
            $key{$key} = $solved{$key};
            $keylevel{$key} = $uncertain;
         }
      }
   }
}

sub get_crypt_info {
   if (!$crypt_info{"fp_page"}) {
      $crypt_info{"fp_page"} = &get_crypt_word(0x18c);
   } 
   if ($crypt_info{"fp_page"}) {
      if (!$crypt_info{"fp_num"}) {
         local($o) = $crypt_info{"fp_page"} * 0x200;
         local($n) = &get_crypt_byte($o+0x1ff);
         if ($n) {
            $crypt_info{"fp_num"} = $n;
         } else {
            local($i);
            for ($i=0; $i<45; $i++) {
               last if &main'get_word($o+$i*4+2, $inbuf);
            }
            $crypt_info{"fp_num"}=$i-1 if ($i);
         }
      }
   }
}

sub method1 {
   local($o) = &main'get_long(0x1c, $inbuf);
   $crypt_method{$method} = 1;
   %solved = &solve_string($o-1, "\x0d");
}

sub method2 {
   local($solve)="";
   if ($word_version==6) {
      $solve = "\x54";
      $solve = "\x98\x01" if ($word_status & 2**9);
   } elsif ($word_version==7) {
      $solve = "\x58";
   }
   $crypt_method{$method} = 1;
   %solved = &solve_string(0x154, $solve);
}

sub method3 {
   # Alas, this is not really secure...
   $crypt_method{$method} = 1;
   %solved = &solve_string(0x14c, "\x1e");
}

sub method4 {
   return if ! defined $key{4};
   local($a);
   $a = &main'get_byte(0x64, $inbuf) ^ $key{4};
   $crypt_method{$method} = 1;
   %solved = &solve_string(0x5c, pack("C", $a));
}

sub method5 {
   local($fp) = $crypt_info{"fp_page"};
   return if !$fp;
   local(%tmp)=();
   local($o) = 0x200*$fp;
   %solved = &solve_string($o, pack("V", &main'get_long(0x18, $inbuf)));
   local($max) = $crypt_info{"fp_num"};
   if ($max) {
      local($a, $i, $j, $k, $v);
      for ($i=0; $i<=($max-4); $i+=4) {
         $a = &main'get_byte($o+$i*4+1, $inbuf);
         if ($a == &main'get_byte($o+($i+4)*4+1, $inbuf)) {
            for ($j=1; $j<4; $j++) {
               %tmp = &solve_string($o+($i+$j)*4+1, pack("C", $a^$solved{1}));
               for (keys %tmp) { $solved{$_}=$tmp{$_}; }
            }
            last;
         }
      }
      $crypt_method{$method} = 1;
   }
}

sub method10 { $crypt_method{$method} = &method_par(0x0) }
sub method11 { $crypt_method{$method} = &method_par(0x4) }
sub method12 { $crypt_method{$method} = &method_par(0x8) }
sub method13 { $crypt_method{$method} = &method_par(0xc) }
sub method_par {
   local($o0)=shift;
   return 0 if !$crypt_info{"fp_page"};
   return 0 if !$crypt_info{"fp_num"};
   return 0 if !defined $key{$o0};
   return 0 if !defined $key{$o0+1};
   local($op) = $crypt_info{"fp_page"}*0x200;
   local($max) = $crypt_info{"fp_num"};
   local($o); local($i);
   local(%tmp)=();
   for ($i=($o0/4); $i<$max; $i+=4) {
      $o = &get_crypt_long($op+$i*4);
      %tmp = &solve_string($o-1, "\x0d");
      for (keys %tmp) { $solved{$_}=$tmp{$_}; }
   }
   1;
}

sub method41 { &try_suminfo(1, 7); $crypt_method{$method}=1;}
sub method42 { &try_suminfo(3, 2); $crypt_method{$method}=1;}
sub method43 { &try_suminfo(7, 4); $crypt_method{$method}=1;}
sub method44 { &try_suminfo(8, 4); $crypt_method{$method}=1;}
sub method45 { &try_suminfo(8, 8); $crypt_method{$method}=1;}
sub try_suminfo {
   local($arraynum, $ppsetnum) = @_;
   local($o, $l)=&get_crypt_pair(0x158);
   local($len); local($str);
   if ($o) {
      $o = &get_crypt_abstr_offset($o+1, $arraynum);
      if ($o) {
         $str = ( &main'laola_ppset_get_property(
            $suminfoh, $ppsetnum)
         ) [1];
         if ($str && &get_crypt_byte($o)) {
            $len=length($str);
            substr($str, 0, 0) = pack("C", $len);
            #printf("\no=%x, anum=%d, pnum=%d, str=\"%s\" solvestr=\"%s\"\n",
               #$o, $arraynum, $ppsetnum, $str, &get_crypt_str($o, $len+1)
            #);
            %solved = &solve_string($o, $str);
         }
      }
   }
}

sub method20 {
   local($o, $l) = &get_crypt_pair(0x118);
   if ($o) {
      $crypt_method{$method} = 1;
      if ($l==2) {
         %solved = &solve_string($o, "\xff\x40");
      } else {
         %solved = &solve_string($o, "\xff");
      }
   }
}

sub method21 {
   local($o, $l) = &get_crypt_pair(0x58);
   if ($o) {
      $crypt_method{$method} = 1;
      %solved = &solve_string($o+4, "\x08\x00\x01\x00\x4b\x00\x0f\x00");
   }
}

sub method22 {
   local($o, $l) = &get_crypt_pair(0xd0);
   local($tmp);
   if ($o) {
      $crypt_method{$method} = 1;
      if ($l) {
         return &solve_string($o, pack("v",$l));
      } else {
         $tmp=&get_crypt_word($o);
         %solved = &solve_string(0xd4, pack("v",$tmp)) if $tmp;
      }
   }
}

sub method24 {
   local($o, $l) = &get_crypt_pair(0xb8);
   if ($o) {
      $crypt_method{$method} = 1;
      %solved = &solve_string($o, pack("V", &main'get_long(0x18, $inbuf)));
   }
}

sub method25 {
   local($o, $l) = &get_crypt_pair(0xc0);
   if ($o) {
      $crypt_method{$method} = 1;
      %solved = &solve_string($o, pack("V", &main'get_long(0x18, $inbuf)));
   }
}

sub method26 {
   local($o, $l) = &get_crypt_pair(0x158);
   if ($o && $l) {
      $crypt_method{$method} = 1;
      %solved = &solve_string($o, pack("v", $l));
   }
}


sub method31 {
   local($o1, $l1) = &get_crypt_pair(0x130);
   local($o2, $l2) = &get_crypt_pair(0x138);

   if ($o1 && $o2 && $l1) {
      %solved = &solve_string($o2, &get_crypt_str($o1, $l1));
   }
}

sub method32 {
   local($o1, $l1) = &get_crypt_pair(0x130);
   local($o2, $l2) = &get_crypt_pair(0x140);

   if ($o1 && $o2 && $l1) {
      %solved = &solve_string($o2, &get_crypt_str($o1, $l1));
   }
}

sub method33 {
   local($o1, $l1) = &get_crypt_pair(0x138);
   local($o2, $l2) = &get_crypt_pair(0x140);

   if ($o1 && $o2 && $l1) {
      %solved = &solve_string($o2, &get_crypt_str($o1, $l1));
   }
}

sub method34 {
   local($o1, $l1) = &get_crypt_pair(0x138);
   local($o2, $l2) = &get_crypt_pair(0x140);

   if ($o1 && $o2 && $l2) {
      %solved = &solve_string($o1, &get_crypt_str($o2, $l2));
   }
}

sub method50 {
   local($o, $l) = &get_crypt_pair(0x88);
   if ($o && $l) {
      $crypt_method{$method} = 1;
      %solved = &solve_string($o+$l-4, "\xff\xff\xff\xff"); # most probably
   }
}

sub method51 {
   local($o) = length($inbuf);
   while (! &main'get_byte($o, $inbuf)) { $o--; }
   while (&main'get_byte($o, $inbuf)) { $o--; }
   $o+=2;
   local($authress) = ( &main'laola_ppset_get_property(
      $suminfoh, 4)
   ) [1];
   $crypt_method{$method}=1;
   %solved = &solve_string($o, $authress);
}

sub method52 {
   local($o) = &main'get_long(0x1c, $inbuf);
   $crypt_method{$method}=1;
   %solved = &solve_string($o+2, "\xa4\0\0\0\xa5");
}

sub method53 {
   local($o) = &main'get_long(0x18, $inbuf);
   local($title) = (&main'laola_ppset_get_property(
      $suminfoh, 2)
   ) [1];
   $crypt_method{$method}=1;
   %solved = &solve_string($o, $title);
}

sub method60 {
   local($chance0, $key);
   foreach $m (keys %ambig_key) {
      ($chance0, $key) = &vote($m);
      $chance0 += &vote_properly($m);
      if ($chance0 >= 100) {
         $solved{$m} = 0;
      } else {
         $solved{$m} = $key;
      }
   }
   %ambig_key=();
   %ambig_keylevel=();
}

sub vote {
   local($m, $surehand)=@_;
   local($l1)=10; local($k1)=0;
   local($l2)=9; local($k2)=0;

   local($k, $i, $l, $n, $len);
   $len = length($ambig_key{$m});
   for ($i=0; $i<$len; $i++) {
      $k = &main'get_byte($i, $ambig_key{$m});
      $l = &main'get_byte($i, $ambig_keylevel{$m});
      if ($l1>$l2) {
         if ($l<$l1) {
            $k1=$k; $l1=$l; $n=0;
         }
      } else {
         if ($l<$l2) {
            $k2=$k; $l2=$l; $n=0;
         } elsif ($l==$l2) {
            $n++;
            $k2=$k if $k != $k1;
         }
      }
   }
   if ($l1<=2 && $l2<=2) {
      if ($k1==$k2) {
         return "" if $surehand;
         return (100-$n/$len*100, $k1);
      } else {
         return (100, $k1);
      }
   } else {
      if ($surehand) {
         return "";
      } else {
         if ($k1==$k2) {
            return (50-$n/$len*50, $k1);
         } else {
            return (100-5*($l1+$l2), $k1);
         }
      }
   }
}

sub vote_properly {
   local($m) = shift;
   local($small)=0; local($other)=0;
   local($text_begin, $text_end) = &main'get_nlong(2, 0x18, $inbuf);
   local($begin) = ($text_begin/16)*16;
   $begin+=16 if ($begin+$m)<$text_begin;
   local($i);
   for ($i=$begin+$m; $i<$text_end; $i+=16) {
      if (substr($inbuf, $i, 1) =~ /[lern was.\x0dt]/) {
         $small++;
      } else {
         $other++;
      }
   }
   100*$small/($small+$other);
}

sub solve_string {
#
# %solved = solve_string ($offset, $compare_string)
# (%solved = (pos, value))
#
   local($l) = length($_[1]);
   local($o) = $_[0];
   local($buf) = substr($inbuf, $o, $l);
   local($i, $a, $b);
   local($m, $n);
   local(%solved)=();
   $n=0; 
   for ($i=0; $i<$l; $i++) {
      next if ! ($a = &main'get_byte($i, $_[1]));
      next if ! ($b = &main'get_byte($i, $buf));

      if (defined $solved{$m = ($o+$i) % 16}) {
         next if $solved{$m} == $a^$b;
         %solved=(); last;
      }
      if (! defined $ambig_key{$m}) {
         if ($a ^ $b) {
            $solved{ $m } = ($a ^ $b);
            last if ++$n==16;
            next;
         }
      }
      $ambig_key{$m} .= pack("C",$a);
      $ambig_keylevel{$m} .= pack("C",$uncertain);
   }
   %solved;
}

#
# -------------------------- Crypt utils ------------------------------
#

sub get_crypt_long { &get_crypt_n(shift, 4); }
sub get_crypt_word { &get_crypt_n(shift, 2); }
sub get_crypt_byte { &get_crypt_n(shift, 1); }
sub get_crypt_n {
#
# value = get_crypt_n( $o, $n_bytes );
#
   local($o, $n) = @_;
   local($b, $i, $m);

   local($oo)=0;
   for ($i=($n-1); $i>=0; $i--) {
      $oo *= 0x100;
      if ($b = &main'get_byte($o+$i, $inbuf)) {
         $m = ($o+$i) % 16;
         return undef if ! defined $key{$m};
         $oo += ($b ^ $key{$m});
      }
   }
   $oo;
}

sub get_crypt_pair {
#
# (o, l) = get_crypt_pair( $o );
#
   local($o)=shift;
   (&get_crypt_long($o), &get_crypt_long($o+4));
}

sub get_crypt_str {
#
# string = get_crypt_str( $o, $l );
#
   local($o, $l) = @_;
   local($i, $buf, $c, $m);
   $buf="";
   for ($i=0; $i<$l; $i++) {
      $m = ($o+$i) % 16;
      $c = &main'get_byte($o+$i, $inbuf);
      last if !$c;
      if (defined $key{$m}) {
         $buf.= pack("C", ($c ^ $key{$m}) || $c);
      } else {
         $buf .= "\x00";
      }
   }
   $buf;
}

sub get_crypt_bstr {
   local($o) = shift;
   if (defined &get_crypt_byte($o)) {
      &get_crypt_str($o+1, &get_crypt_byte($o));
   } 
}

sub get_crypt_abstr_offset {
   local($o, $n) = @_;
   local($i);
   for ($i=0; $i<$n; $i++) {
      if (defined &get_crypt_byte($o)) {
         $o += (&get_crypt_byte($o)+1);
      } else {
         return 0;
      }
   }
   return $o;
}

sub rol {
#
# int = rol(n, numbits, bitlen)
# rotate (bitlen bits sized) (integer n) (numbits bits) left
#
   local($n, $num, $bitlen) = @_;
   return $n if !$num;
   $num %= $bitlen;
   ($n * 2**$num) & (2**$bitlen-1) | ( ($n * 2**($num-$bitlen)) );
}

#
# ------------------------------ Debug -------------------------------------
#

sub debug_decrypt {
   return;
   $out = sprintf("\n%-15s", $main'infile.":");
   local($i);
   for ($i=0; $i<16; $i++) {
      if (defined $key{$i}) {
         $out .= sprintf ("%02x ", $key{$i});
      } else {
         $out .= "-- ";
      }
   }
   $out .= " " x (65 - length($out));
   $out .= sprintf ("%04x %04x", &main'get_nword(2, 0x0e, $inbuf));
   print "$out\n";
}

"Atomkraft? Nein, danke!";

