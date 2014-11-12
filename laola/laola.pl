#
# $Id: laola.pl,v 0.5.1.5 1997/07/01 00:06:42 schwartz Rel $
#
# laola.pl, LAOLA filesystem. 
#
# This perl 4 library gives raw access to "Ole/Com" documents. These are 
# documents like created by Microsoft Word 6.0+ or newer Star Divisions 
# Word by using so called "Structured Storage" technology. Write access 
# still is nearly not supported, but will be done one day. This library 
# is part of LAOLA, a distribution this file should have come along with. 
# It can be found at:
#
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/index.html
# or
#    http://www.cs.tu-berlin.de/~schwartz/pmh/index.html
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
# Diese Veröffentlichung erfolgt ohne Berücksichtigung eines eventuellen
# Patentschutzes. Warennamen werden ohne Gewährleistung einer freien 
# Verwendung benutzt. ;-)
#
# Contact: schwartz@cs.tu-berlin.de
#

#
# Really important topics still MISSING until now:
#
#   - human rights and civil rights where _you_live_
#   - Reformfraktion president for Technische Universität Berlin 
#
#   - creating documents 
#   - sensible error handling...
#   - many property set things: 
#     *  documentation of variable types
#     *  code page support
#   - opening multiple documents at a time 
#   - consistant name giving, checked against MS'
#
# Please refer to the Quick Reference at Laolas home page for further 
# explanations.
#

#
# Abbreviations
# 
#    bbd    Big Block Depot
#    pps    Property Storage
#    ppset  Property Set
#    ppss   Property Set Storage
#    sb     Start Block
#    sbd    Small Block Depot
#    tss    Time Stamp Seconds
#    tsd    Time Stamp Days
# 

##
## "public" 
##

sub laola_open_document        { &laola'laola_open_document; }
sub laola_close_document       { &laola'laola_close_document; }

sub laola_pps_get_name         { &laola'laola_pps_get_name; }
sub laola_pps_get_date         { &laola'laola_pps_get_date; }

sub laola_is_directory         { &laola'laola_is_directory; }
sub laola_get_directory        { &laola'laola_get_directory; }
sub laola_get_dirhandles       { &laola'laola_get_dirhandles; }

sub laola_is_file              { &laola'laola_is_file; }
sub laola_get_filesize         { &laola'laola_get_filesize; }
sub laola_get_file             { &laola'laola_get_file; }

sub laola_is_root              { &laola'laola_is_root; }

#
# writing 
#
sub laola_modify_file          { &laola'laola_modify_file; }

#
# property set handling
#
sub laola_is_file_ppset        { &laola'laola_is_file_ppset; }
sub laola_ppset_get_dictionary { &laola'laola_ppset_get_dictionary; }
sub laola_ppset_get_idset      { &laola'laola_ppset_get_idset; }
sub laola_ppset_get_property   { &laola'laola_ppset_get_property; }

#
# trash handling
#
sub laola_get_trashsize        { &laola'laola_get_trashsize; }
sub laola_get_trash            { &laola'laola_get_trash; }
sub laola_modify_trash         { &laola'laola_modify_trash; }


package laola;

$laola_date = "03/25/97";

changable_options: {
   $optional_do_iobuf=0;  # 0: don't cache  1: cache whole compound document 
   $optional_do_debug=0;  # 0: don't debug  1: print some debugging information
}

##
## File and directory handling
##

sub laola_open_document { ##
#
# "ok"||$error = laola_open_document($filename [,$openmode [,$streambuf]]);
#
# openmode bitmask (0 is default):
#
# Bit 0:  0 read only   1 read and write
# Bit 4:  0 file mode   1 buffer mode 
#
   local($status)="";
   open_doc1: {
      &init_vars();
      if ( ($status=&init_io(@_)) ne "ok") {
         last;
      }
      if ( ($status=&init_doc()) ne "ok") {
         &laola_close_document();
         last;
      }
      return "ok";
   }
   $status;
}

sub laola_close_document { ##
#
# "ok" = laola_close_document([streambuf])
#
   if ($openmode & 0x10) {
      if (defined $_[0]) {
         $_[0]=$iobuf;
      }
   } else {
      &flush_cache();
      &clean_file();
   }
   &init_vars();
   return "ok";
}

sub laola_is_directory { ##
#
# 1||0 = laola_is_directory($pps)
#
   local($pps)=shift;
   (!$pps || ($pps_type[$pps] == 1));
}

sub laola_is_file { ##
#
# 1||0 = laola_is_file($pps)
#
   ($pps_type[shift] == 2);
}

sub laola_is_root { ##
#
# 1||0 = laola_is_root($pps)
#
   ($pps_type[shift] == 5);
}

sub laola_get_dirhandles { ##
#
# @pps = laola_get_dirhandles($pps);
#
   local($start)=shift;

   (!$start || &laola_is_directory($start))
      && &get_ppss_chain($pps_dir[$start])
   ;
}

sub laola_get_directory { ##
#
# %pps_names = laola_get_directory($pps);
#
   local(%pps_namehandle)=();
   for (&laola_get_dirhandles) {
      $pps_namehandle{&laola_pps_get_name($_)} = $_;
   }
   %pps_namehandle;
}

sub laola_pps_get_name { ##
#
# $name_of_pps = laola_pps_get_name($pps);
#
   $pps_name[shift];
}

sub laola_pps_get_date { ##
#
# ($day,$month,$year,$hour,$min,$sec)||0 = laola_pps_get_date($pps)
# (1..31, 1..12, 1601..., 0..23, 0..59, 0.x .. 59.x)
#
   local($pps)=shift;
   &laola_is_directory($pps) 
      && &filetime_to_time($pps_ts2s[$pps], $pps_ts2d[$pps]);
}

sub laola_get_filesize { ##
#
# $filesize || 0 = laola_get_filesize($pps);
#
   local($pps)=shift;
   &laola_is_file($pps) && $pps_size[$pps];
}

sub laola_get_file { ##
#
# "ok"||$error = laola_get_file($pps, extern $buf [,$offset, $size]);
#
   &rw_file("r", @_);
}

sub laola_modify_file { ##
#
# "ok"||$error = laola_modify_file($pps,extern $buf, $offset, $size);
# 
   return "Laola: File is write protected!" if !io_writable;
   &rw_file("w", @_);
}


##
## Property set handling
##

sub laola_is_file_ppset { ##
#
# ppset_type || 0 = laola_is_file_ppset($pps)
# ppset_type e {1, 5}
#
   local($pps)=shift;
   (&laola_is_file($pps)) 
   && ( (&laola_pps_get_name($pps) =~ /^\05/) && 5
        || (&laola_pps_get_name($pps) =~ /^\01CompObj$/) && 1
   );
}

sub laola_ppset_get_dictionary { ##
#
# ("ok", %dictionary)||$error = laola_ppset_get_dictionary($pps)
#
   local($pps)=shift;
   local($status) = &load_propertyset($pps);
   if ($status ne "ok") {
      return $status;
   } else {
      return ("ok", %ppset_dictionary);
   }
}

sub laola_ppset_get_idset { ##
#
# ("ok", %ppset_idset) || $error = laola_ppset_get_idset($pps);
#
   local($pps)=shift;
   local($status) = &load_propertyset($pps);
   return $status if $status ne "ok";

   local(%ts)=();
   foreach $key (keys %ppset_fido) {
      $ts{$key} = $ppset_dictionary{$key}; 
   }
   ("ok", %ts);
}

sub laola_ppset_get_property { ##
#
# ($type,@mixed)||("error",$error)=laola_ppset_get_property($pps, $id)
#
   local($pps, $id)=@_;
   local($type, $l, $var, @var);
   local($o, $n);

   local($status)= &load_propertyset($pps);
   return ("error", $status) if $status ne "ok";

   return "" if !defined $ppset_fido{$id}; 
   $n = int($id / 0x1000);
   $o = $ppset_o[$n]+$ppset_fido{$id};

   if ($ppset_type == 5) {
      #return ("error", "Property Identifier is invalid.") if $id < 2;
      ($type, $l, @var) = &ppset_get_property($o);
      return ($type, @var);

   } elsif ($ppset_type == 1) {
      ($l, $var) = &ppset_get_var(0x1e, $o);
      return (0x1e, $var);
   }
}


##
## Trash handling
##

sub laola_get_trashsize { ##
#
# $sizeof_trash_section = laola_get_trashsize($type)
#
   &get_trash_size(@_);
}

sub laola_get_trash { ##
#
# "ok"||$error = laola_get_trash ($type, extern $buf [,$offset,$size]);
#
   &rw_trash("r", @_);
}

sub laola_modify_trash { ##
#
# "ok"||$error = laola_modify_trash ($type, extern $buf [,$offset,$size]);
# 
   return "Laola: File is write protected!" if !io_writable;
   &rw_trash("w", @_);
}


##
## "private" 
##

global_init: {
   &var_init();
   &filetime_init();
   &propertyset_type_init();
   $[=0;
}

#
# laola_open_document ->
#

sub init_vars {
   # laola_open_document->init_vars
   # laola_close_document->init_vars
   internal: {
      $infilename=undef;
      $filesize=undef;
      $openmode=undef;
      $io_writable=undef;

      $curfile=undef;
      @curfile_iolist = ();

      $iobuf=undef;
      @iobuf_modify_a=();
      @iobuf_modify_l=();
   }

   &init_propertyset(); 

   OLEstructure: {
      # unknown header things that matter:
      # ? $version=undef;       # word(1a)
      # ? $revision=undef;      # word(18)
      # ? $bigunknown=undef;    # byte(1e)

      # known header things that matter:
      $num_of_bbd_blocks=undef; # long(2c)
      $root_startblock=undef;   # long(30)
      $sbd_startblock=undef;    # long(3c)

      # property storage things
      @pps_name=();		# 0 .. pps_sizeofname
      #pps_sizeofname=();	# word(40)
      @pps_type=();		# byte(42)
      @pps_uk0=();		# byte(43)
      @pps_prev=();		# long(44)
      @pps_next=();		# long(48)
      @pps_dir=();		# long(4c)
      @pps_ts1s=();		# long(64)
      @pps_ts1d=();		# long(68)
      @pps_ts2s=();		# long(6c)
      @pps_ts2d=();		# long(70)
      @pps_sb=();		# long(74)
      @pps_size=();		# long(78)
   }

   various: {
      $maxblock=undef;
      $maxsmallblock=undef;

      # block depot blocks
      # - these blocks are building the block depots 
      @bbd_list=();
      @sbd_list=();	  

      # block depot tables
      @bbd=();
      @sbd=();

      # contents blocks
      @root_list=();
      @sb_list=();

      blockusage: {
         @bb_usage=();       # big blocks usage  
         @sb_usage=();       # small blocks usage
         $usage_known=undef;
      }

      trash: {
         %trashsize=();
         @trash1_o=(); @trash1_l=();
         @trash2_o=(); @trash2_l=();
         @trash3_o=(); @trash3_l=();
         @trash4_o=(); @trash4_l=();
         $trash_known=undef;
      }
   }
}


sub init_io {
   ($infilename, $openmode) = @_;

   if ($openmode & 0x10) {
      return &init_stream;
   } else {
      return &init_file;
   }
}

sub init_stream {
   return "No stream data available!" if !defined $_[2];
   #$openmode &= 0xfffffffe; # clear writeable flag
   $optional_do_iobuf=1;
   $iobuf = $_[2];
   $filesize = length($iobuf);
   if ( (&read_long(0) != 0xe011cfd0) ||
        (&read_long(4) != 0xe11ab1a1) ) {
      return "\"$infilename\" is no Ole / Compound Document!\n";
   }
   "ok";
}

sub init_file {
   local($status);
   return "\"$infilename\" does not exist!"    if ! -e $infilename;
   return "\"$infilename\" is a directory!"    if -d $infilename;
   return "\"$infilename\" is no proper file!" if ! -f $infilename;
   return "Cannot read \"$infilename\"!"       if ! -r $infilename;
   if ($openmode & 1) {
      return "\"$infilename\" is write protected!" if ! -w $infilename;
      $io_writable = 1;
      $status = open(IO, '+<'.$infilename);
   } else {
      $io_writable = 0;
      $status = open(IO, $infilename);
   }
   return "Cannot open \"$infilename\"!" if !$status;

   binmode(IO); 
   if ($io_writable) {
      select(IO); $|=1; select(STDOUT);
   }

   if ( (&read_long(0) != 0xe011cfd0) ||
        (&read_long(4) != 0xe11ab1a1) ) {
      return "\"$infilename\" is no Ole / Compound Document!\n";
   }

   $filesize = -s $infilename;

   read_iobuf: {
      if ($optional_do_iobuf) {
         if (!&myread(0, $filesize, $iobuf, 0)) {
            undef $iobuf;
         } 
      }
   }

   "ok";
}

sub init_doc {
   # read bbd, 
   # get bbd -> root-chain,  get bbd -> sbd-chain
   local($i, $tmp)=(undef, undef);
   local(@tmp)=undef;

   internal: {
      $maxblock = int ($filesize / 0x200 -2);
      return "Document is corrupt - size is too small." if $maxblock < 1;
      return "Document is corrupt - size mismatch." if $filesize % 0x200;
   }

   header_information: {
      $num_of_bbd_blocks=&read_long(0x2c);
      $root_startblock=&read_long(0x30);
      $sbd_startblock=&read_long(0x3c);
      $maxsmallblock= int ( 
        (&read_long(($root_startblock+1)*0x200+0x78)) / 0x40 -1);
   }

   # read big block depot
   read_bbd: {
      $tmp="";
      for ($i=0; $i<$num_of_bbd_blocks; $i++) {
         push (@bbd_list, &read_long(0x4c+4*$i));
      }
      &rw_iolist("r", $tmp, 
         &get_iolist(3, 0, 0xffffffff, 0, @bbd_list) 
      );
      @bbd = unpack ($vtype{"l"}.($maxblock+1), $tmp);
   }

   # read small block depot
   read_sbd: {
      $tmp="";
      @sbd_list=&get_list_from_depot($sbd_startblock, 1);
      &rw_iolist("r", $tmp, 
         &get_iolist(3, 0, 0xffffffff, 0, @sbd_list) 
      );
      @sbd = unpack ($vtype{"l"}.($maxsmallblock+1), $tmp);
   }

   root_and_sb_chains: {
      @root_list=&get_list_from_depot($root_startblock, 1);
      return "Document is corrupt - no root entry." if !@root_list;
      @sb_list=&get_list_from_depot(
         &read_long(($root_startblock+1)*0x200+0x74), 1
      );
   }

   read_PropertyStorages: {
      &read_ppss(0);

      #
      # If there are many property storages, they will be loaded 
      # dynamically. If there are few (I randomly chosed 50), they
      # all will be read (ditto for debugging).
      #
      last if $#root_list>50 || !$optional_do_debug;

      local($buf)=""; 
      local($i, $nl);
      &rw_iolist("r", $buf, 
         &get_iolist(3, 0, 0xffffffff, 0, @root_list) 
      );
      print "\n\n"
         ."---------------------------------------------\n"
         ."LAOLA INTERNAL start of debugging information\n\n"
         ." n   size    chain     typ name                    date\n"
      ;
      for ($i=0; $i<=($#root_list+1)*4; $i++) {
         &read_ppss_buf($i, $buf);
         &debug_report_pps($i) if $optional_do_debug;
      }
      print "\n"
         ."LAOLA INTERNAL end of debugging information\n"
         ."-------------------------------------------\n\n"
      ;
   }

   &report_blockuse_statistic() if $optional_do_debug;
   "ok";
}

##
## laola_close_document ->
##

sub clean_file {
   close(IO);
}


##
## -------------------------- File IO ------------------------------
## 

sub rw_file {
#
# "ok"||error = rw_file("r"||"w", $pps_handle, extern $buf [,$offset, $size])
#
   local($maxarg)=$#_;
   local($rw, $pps) = @_[0..1];
   return "Laola: pps is no file!" if !&laola_is_file($pps);
   return "Laola: no method \"$rw\"!" if !($rw =~ /^[rw]$/i);

   local($status, $offset, $size) = 
      &get_default_iosize($pps_size[$pps], $rw, @_[2..$maxarg]);
   return $status if $status ne "ok";

   return "Bad document structure!" if ! &get_curfile_iolist($pps);
   return "ok" if &rw_iolist($rw, $_[2], &get_iolist(4, $offset, $size));

   $rw =~ /^r$/i ? "Laola: read error!" : "Laola: write error!";
}

sub get_default_iosize {
#
# ("ok", $offset, $size) || $error =
#    get_default_iosize (defsize, "r"||"w", extern buf, offset, size)
#
   local($maxarg)=$#_;
   local($defsize, $rw) = @_[0..1];
   local($offset, $size) = @_[3..4];

   if (!$size) {
      if ($rw =~ /^r$/i) { 
         if ($maxarg < 4) {
            # read default: read trashsize
            $offset=0; $size=$defsize;
         } else {
            # read zero size: no problem 
            $_[2]="";
         }
      } else {
         if ($maxarg < 4) {
            # write default: not allowed!
            return "Laola: write error! Unknown size.";
         } else {
            # write zero size: no problem
         }
      }
   }
   ("ok", $offset, $size);
}

sub get_curfile_iolist {
#
# 1||0 = get_curfile_iolist($pps)
#
# Gets the iolist for the current file $pps
#
   if ($curfile) {
      return 1 if $curfile==$pps;
   }
   @curfile_iolist = &get_iolist(
      $pps_size[$pps]>=0x1000, 0, $pps_size[$pps], $pps_sb[$pps]
   );
   $curfile = $pps;
   1;
}

sub get_all_filehandles {
#
# &get_all_filehandles(starting directory)
#
# !recursive!
# Recurse over all files and directories, 
# return all file handles as @files.
#
   local($directory_pps)=shift;
   local(@dir)=&laola_get_dirhandles($directory_pps);
   local(@files)=();

   foreach $entry (@dir) {
      if (&laola_is_file($entry)) {
         push (@files, $entry)
      } elsif (&laola_is_directory($entry)) {
         push (@files, &get_all_filehandles($entry));
      }
   } 
   @files;
}

##
## --------------------- Property Set Handling -------------------------
##

sub propertyset_type_init {
   %ppset_vtype = ( 
      0x00, "empty",
      0x01, "null",
      0x02, "i2",
      0x03, "i4",
      0x04, "r4",
      0x05, "r8",
      0x06, "cy",
      0x07, "date",
      0x08, "bstr",
      0x0a, "error",
      0x0b, "bool",
      0x0c, "variant",
      0x11, "ui1",
      0x12, "ui2",
      0x13, "ui4",
      0x14, "i8",
      0x15, "ui8",
      0x1e, "lpstr",
      0x1f, "lpwstr",
      0x40, "filetime",
      0x41, "blob",
      0x42, "stream",
      0x43, "storage",
      0x44, "streamed_object",
      0x45, "stored_object",
      0x46, "blobobject",
      0x48, "clsid",
      0x49, "cf",
      0xfff, "typemask",
   ); 
   local(@type) = keys %ppset_vtype;
   for (@type) {
      $ppset_vtype{$_+0x1000} = $ppset_vtype{$_}.'[]';
   }

   # \05
   %ppset_SummaryInformation = (
     2, "title", 3, "subject", 4, "authress", 5, "keywords", 
     6, "comments", 7, "template", 8, "lastauthress", 
     9, "revnumber", 10, "edittime", 11, "lastprinted", 
    12, "create_dtm_ro", 13, "lastsave_dtm", 14, "pagecount", 
    15, "wordcount", 16, "charcount", 17, "thumbnail", 
    18, "appname", 19, "security"
   );

   %ppset_DocumentSummaryInformation = (
    15, "organization"
   );

   # \01CompObj
   %ppset_CompObj = (
      0, "doc_long", 1, "doc_class", 2, "doc_spec"
   );
}


sub load_dictionary {
#
# "ok"||"done"||0 = load_dictionary($pps)
#
   local($pps)=shift;
   &load_dictionary_defaults($pps);

   local($i, $n, $o, $ps);
   local($did, $dname, $l);

   foreach $id (keys %ppset_fido_dict) {
      next if !$ppset_fido_dict{$id};

      $ps = int($id/0x1000);
      $o = $ppset_o[$ps]+$ppset_fido_dict{$id};
      $n = &get_long($o, $ppset_buf); $o+=4;

      for (; $n; $n--) {
         $did = &get_long($o, $ppset_buf); $o+=4;
         ($l, $dname) = &ppset_get_var(0x1e, $o); $o+=$l;
         $ppset_dictionary{$did+$ps*0x1000} = $dname;
      }
   }
   return "ok";
}

sub load_dictionary_defaults {
   local($name)=&laola_pps_get_name($pps);
   if ($name eq "\05SummaryInformation") {
      %ppset_dictionary = %ppset_SummaryInformation;
      return "ok";
   } elsif ($name eq "\05DocumentSummaryInformation") {
      %ppset_dictionary = %ppset_DocumentSummaryInformation;
      return "ok";
   } elsif ($name eq "\01CompObj") {
      %ppset_dictionary = %ppset_CompObj;
      return "ok";
   }
   return 0;
}

sub load_propertyset {
   local($pps)=shift;
   local($status)="";

   check_current: {
      if ($ppset_current && $pps && ($ppset_current == $pps)) {
         $status="ok"; last;
      }
      if (!&laola_is_file_ppset($pps)) {
         $status="This is not a property set handle."; last;
      }
      &init_propertyset();
      if (!&laola_get_file($pps, $ppset_buf)) {
         $status="Cannot load property set.";
      }
      $ppset_type = &laola_is_file_ppset($pps);
   }
   return $status if $status;

   if ($ppset_type == 5) {
      $status = &load_propertyset_05($pps);
      return $status if $status ne "ok";
   } elsif ($ppset_type == 1) {
      $status = &load_propertyset_01CompObj($pps);
      return $status if $status ne "ok";
   } else {
      return "Unknown property set!";
   }

   $status = &load_dictionary($pps);
   return $status;
}

sub init_propertyset {
   # !global! property set things

   $ppset_current=undef;      # current property storage handle
   $ppset_type=undef;         # \05, \01CompObj
   $ppset_buf=undef;          # buffer for whole property
   %ppset_fido=();            # $ppset_fido{Identifier}=Offset; 
                              #    Format Pairs of $ppset_current
   %ppset_fido_dict=();       # Dictionaries
   %ppset_fido_cp=();         # Code pages

   $ppset_codepage=undef;
   %ppset_dictionary=(); 

   structure_05: { # 05 ppsets
      # Header
      $ppset_byteorder=undef; # word (0)  {0xfffe}
      $ppset_format=undef;    # word (2)  {0}
      $ppset_osver=undef;     # word (4)  {lbyte=version  hbyte=revision}
      $ppset_os=undef;        # word (6)  {0=win16|1=mac|2=win32)
      @ppset_clsid=();        # class identifier (8) {e.g. @0}
      $ppset_reserved=undef;  # long (18) {>=1}
   
      # FormatIDOffset
      @ppset_fmtid=();        # format identifier (1c)
      @ppset_o=();            # ppset_o[0]: long (2c)

      # PropertySectionHeader
      @ppset_size=();         # word ($ppset_o[])
      @ppset_num=();          # long ($ppset_o[]+4)
   }

   #structure_01CompObj: {  
      #$ppset_uk1=undef;       # word (0)  {0x0001}
      #$ppset_byteorder=undef; # word (2)  {0xfffe}
      #$ppset_osver=undef;     # word (4)  {lbyte=version  hbyte=revision}
      #$ppset_os=undef;        # word (6)  {0=win16|1=mac|2=win32)
                               # { ff ff ff ff  00 09 02 00  00 00 00 00 
                               #   c0 00 00 00  00 00 00 46 }
      #@ppset_o=();            # 0x1c
   #}
}

sub load_propertyset_01CompObj {
   local($pps)=shift;
   set_current: {
      $ppset_current = $pps;
      get_structure: {
         $ppset_byteorder = &get_word(0x02, $ppset_buf);
         $ppset_osver =     &get_word(0x04, $ppset_buf);
         $ppset_os =        &get_word(0x06, $ppset_buf);
         @ppset_o =         (0x1c);
      }
      check_structure: {
         if ($ppset_byteorder !=0xfffe) {
            return "Cannot understand property set.";
         } 
      }
   }
   get_offsets: {
      local($i);
      local($offset, $length)=(0, 0);
      for ($i=0; $i<3; $i++) {
         $length = &get_long($ppset_o[0] + $offset, $ppset_buf);
         last if !$length;
         $ppset_fido{$i} = $offset;
         $offset = $offset + 4 + $length;
      }
   }
   "ok";
}

sub load_propertyset_05 {
   local($pps)=shift;
   set_current: {
      $ppset_current = $pps;
      get_structure: {
         ($ppset_byteorder, $ppset_format, $ppset_osver, $ppset_os) =
            &get_nword(4, 0, $ppset_buf)
         ;
         @ppset_clsid =     &get_uuid(0x08, $ppset_buf);
         $ppset_reserved =  &get_long(0x18, $ppset_buf);
         @ppset_fmtid =     &get_uuid(0x1c, $ppset_buf);
         $ppset_o[0] =      &get_word(0x2c, $ppset_buf);
         $ppset_size[0] =   &get_word($ppset_o[0], $ppset_buf);
         $ppset_num[0] =    &get_word($ppset_o[0]+4, $ppset_buf);
      }
      check_structure: {
         $status="Cannot understand property set.";
         last if $ppset_byteorder != 0xfffe;
         last if $ppset_format != 0;
         last if $ppset_reserved < 1;
         last if $ppset_o[0] < 0x30;
         $status="";
      }
   }
   return $status if $status;
 
   get_ids_and_offsets: {
      local($i, $id, $n, $num, $fido);
      local($o)=$ppset_o[0];
      for ($n=0; $n<$ppset_reserved; $n++) {

         # default dictionary and codepage
         $ppset_fido_dict{$n*0x1000+0} = 0;
         $ppset_fido_cp{$n*0x1000+1} = 0x4e4;

         $num=&get_word($o+4, $ppset_buf);
         for ($i=0; $i<$num; $i++) {
            $id = &get_long($o+8+$i*8, $ppset_buf);
            if ($n) {
               $id = $i if $id>1; # ! hacky !
            }
            $fido = &get_long($o+8+$i*8+4, $ppset_buf);
            if ($id>1) {
               $ppset_fido{$n*0x1000+$id} = $fido;
            } elsif ($id==1) {
               $ppset_fido_cp{$n*0x1000+1} = $fido;
            } elsif ($id==0) {
               $ppset_fido_dict{$n*0x1000} = $fido;
            }
         }
         $o+=&get_word($o, $ppset_buf);
         $ppset_o[$n+1]=$o;
      }
   }
   # todo: code page
   "ok";
}

sub ppset_get_property {
#
# ($type, $size, @mixed)||("error", $debuginfo) = ppset_get_property($offset)
#
   local($o_begin)=$_[0];
   local($o)=$o_begin;
   local($type) = &get_long($o, $ppset_buf);

   if (! ($type & 0x1000)) {
      return ($type, &ppset_get_var($type, $o+4));
   } else {
      local(@mixed)=();
      local($n)=&get_long($o+4, $ppset_buf); $o+=8;
      local($t, $l, @var);
      for (; $n; $n--) {
         @var=();
         ($l, @var) = &ppset_get_var($type^0x1000, $o);
         push (@mixed, 1+($#var+1), $type^0x1000, @var);
         $o+=$l; 
      }
      return ($type, $o-$o_begin, @mixed);
   }
}

sub ppset_get_var {
#
# ($size, @var) = &ppset_get_var($type, $offset);
#
   local($type, $o)=@_;
   if (!$type || $type == 0x01) { # empty, null
      return (0, ""); 
   } elsif ($type == 0x02) {  # i2
      local($tmp) = &get_word($o, $ppset_buf);
      $tmp = - (($tmp^0xffff) +1) if ($tmp & 0x8000);
      return (2, $tmp);
   } elsif ($type == 0x03) {  # i4
      local($tmp) = &get_long($o, $ppset_buf);
      $tmp = - (($tmp^0xffffffff) +1) if ($tmp & 0x80000000);
      return (4, $tmp);
   } elsif ($type == 0x04) {  # real
      return (4, unpack("f", substr($ppset_buf, $o, 4)) );
   } elsif ($type == 0x05) {  # double
      return (8, unpack("d", substr($ppset_buf, $o, 8)) );
   } elsif ($type == 0x0a) {  # error
      return (4, &get_word($o, $ppset_buf)); 
   } elsif ($type == 0x0b) {  # bool (0==false, -1==true)
      return (4, &get_long($o, $ppset_buf)); 
   } elsif ($type == 0x0c) {  # variant
      local($t, $l, @var);
      $t = &get_long($o, $ppset_buf);
      ($l, @var) = &ppset_get_var($t, $o+4);
      return (4+$l, $t, @var);
   } elsif ($type == 0x11) {  # ui1
      return (1, &get_byte($o, $ppset_buf));
   } elsif ($type == 0x12) {  # ui2
      return (2, &get_word($o, $ppset_buf));
   } elsif ($type == 0x13) {  # ui4
      return (4, &get_long($o, $ppset_buf));
   } elsif ($type == 0x1e) {  # lpstr
      local($l)=&get_long($o, $ppset_buf);
      if ($l) {
         return (4+$l, substr($ppset_buf, $o+4, $l-1));
      } else {
         return (4, "");
      }
   } elsif ($type==0x40) {    # filetime
      return (8, &filetime_to_time(&get_nlong(2, $o, $ppset_buf)) );
   } else {
      return (
         "error", 
         sprintf("(offset=%x, type=%x, buf[0]=%x)",
            $o, $type, &get_long($o+4, $ppset_buf)
         )
      );
   }
}

##
## Basic laola data types
##

sub var_init {
#
# At this work I still don't trust in signed integers, therefore I 
# prefer the unsigned 0xffffffff to -1 (don't beat me)
#
   $vtype{"c"}="C"; $vsize{"c"}=1;    # unsigned char
   $vtype{"w"}="v"; $vsize{"w"}=2;    # 0xfe21     == 21 fe
   $vtype{"l"}="V"; $vsize{"l"}=4;    # 0xfe21abde == de ab 21 fe
}

sub get_chars { 
#
# get_chars ($offset, $number, extern $sourcebuf);
#
   substr($_[2], $_[0], $_[1]); 
}

sub read_chars { 
#
# read_chars ($offset, $number);
#
   local($tmp)=""; 
   &myread($_[0], $_[1], $tmp) && $tmp; 
}

# get_thing ($offset, extern $buf);
sub get_byte { &get_var("c", @_); }
sub get_word { &get_var("w", @_); }
sub get_long { &get_var("l", @_); }
sub get_var { 
   unpack ($vtype{$_[0]}, substr($_[2], $_[1], $vsize{$_[0]}));
}

# get_nthing ($n, $offset, extern $buf);
sub get_nbyte { &get_nvar("c", @_); }
sub get_nword { &get_nvar("w", @_); }
sub get_nlong { &get_nvar("l", @_); }
sub get_nvar { 
   unpack ($vtype{$_[0]}.$_[1], substr($_[3], $_[2], $vsize{$_[0]}*$_[1]));
}

# read_thing ($offset);
sub read_byte { &read_var("c", @_); }
sub read_word { &read_var("w", @_); }
sub read_long { &read_var("l", @_); }
sub read_var {
   unpack ($vtype{$_[0]}, &read_chars($_[1], $vsize{$_[0]}));
}

# read_nthing ($n, $offset);
sub read_nbyte { &read_nvar("c", @_); }
sub read_nword { &read_nvar("w", @_); }
sub read_nlong { &read_nvar("l", @_); }
sub read_nvar {
   unpack ($vtype{$_[0]}.$_[1], &read_chars($_[2], $vsize{$_[0]}*$_[1]));
}

##
## --------------------------- IO handling ------------------------------
##

sub myio {
#
# 1||0= myio("r"||"w", $file_offset, $num_of_chars, $extern_var [,$var_offset])
#
   $_ = shift;
   /^r$/i ? &myread : /^w$/i ? &mywrite : 0;
}

sub myread {
#
# 1||0 = myread($file_offset, $num_of_chars, $extern_var [,$var_offset])
#
   local($varoffset)= $_[3] || 0;
   if ($optional_do_iobuf && $iobuf) {
      substr($_[2], $varoffset, $_[1])=substr($iobuf, $_[0], $_[1]);
      return 1;
   } else {
      seek(IO, $_[0], 0) && (read(IO,$_[2],$_[1],$varoffset) == $_[1]);
   }
}

sub mywrite {
#
# 1||0 = mywrite($file_offset, $num_of_chars, $extern_var [,$var_offset])
#
   return 0 if !$io_writable;

   local($varoffset)= $_[3] || 0;
   local($tmp) = substr($_[2], $varoffset, $_[1]);
         $tmp .= "\00" x ($_[1]-length($tmp));
   if ($optional_do_iobuf && $iobuf) {
      substr($iobuf, $_[0], $_[1]) = $tmp;
      push(@iobuf_modify_a, $_[0]);
      push(@iobuf_modify_l, $_[1]);
      return 1;
   } else {
      seek(IO, $_[0], 0) && print IO $tmp;
   }
}

sub flush_cache {
#
# void = flush_cache()
#
# flush io cache, if caching is turned on
#
   return if !($optional_do_iobuf && $iobuf);

   &rw_iolist("w", $iobuf, 
      &aggregate_iolist(2, @iobuf_modify_a, @iobuf_modify_l)
   );

   @iobuf_modify_a=(); @iobuf_modify_l=();
}

##
## The "logical" core of laola
##

sub get_ppss_chain {
#
# @blocks = get_ppss_chain($ppss)
#
# !recursive!
#
   local($ppss) = shift;
   local(@chain)=();
   return @chain if $ppss == 0xffffffff;

   &read_ppss($ppss);
   push(@chain, $ppss);

   # insert chain link(s)
   splice(@chain, 0, 0, &get_ppss_chain($pps_prev[$ppss]));

   # append chain link(s)
   splice(@chain, $#chain+1, 0, &get_ppss_chain($pps_next[$ppss]));

   @chain;
}

sub read_ppss_buf {
#
# "ok" = read_ppss_buf ($i, extern $buf)
#
   local($i)=$_[0];
   local($nl);
   return "ok" if $pps_name[$i];
   return if ! ($nl = &get_word($i*0x80+0x40, $_[1]));

   $pps_name[$i] = &pps_name_to_string($i*0x80, $nl, $_[1]);

   ($pps_type[$i], $pps_uk0[$i], 
    $pps_prev[$i], $pps_next[$i], $pps_dir[$i]) =
      unpack($vtype{"c"}."2".$vtype{"l"}."3",
             substr($_[1], $i*0x80+0x42, $vsize{"c"}*2+$vsize{"l"}*3))
   ;

   ($pps_ts1s[$i], $pps_ts1d[$i], $pps_ts2s[$i], $pps_ts2d[$i],
    $pps_sb[$i], $pps_size[$i]) = 
      &get_nlong(6, $i*0x80+0x64, $_[1])
   ;

   "ok";
}

sub read_ppss {
#
# "ok" = read_ppss ($i)
#
   local($i)=shift;
   return "ok" if $pps_name[$i];

   local($buf)="";
   &rw_iolist("r", $buf, &get_iolist(3, $i*0x80, 0x80, 0, @root_list));

   local($nl);
   return if ! ($nl = &get_word(0x40, $buf));
   $pps_name[$i] = &pps_name_to_string(0, $nl, $buf);
   ($pps_type[$i], $pps_uk0[$i], $pps_prev[$i], $pps_next[$i], $pps_dir[$i])=
      unpack($vtype{"c"}."2".$vtype{"l"}."3",
             substr($buf, 0x42, $vsize{"c"}*2+$vsize{"l"}*3)
      )
   ;

   ($pps_ts1s[$i], $pps_ts1d[$i], $pps_ts2s[$i], $pps_ts2d[$i],
    $pps_sb[$i], $pps_size[$i]) = unpack(
      $vtype{"l"}."6", substr($buf, 0x64, $vsize{"l"}*6)
   );

   "ok";
}


sub get_list_from_depot {
#
# @blocks = get_list_from_depot ($start, depottype)
#
# Read a block chain starting with block $start out of a either
# depot @bbd (for $t) or depot @sbd (for !$t).
#
   local($start, $t)=@_;
   local(@chain)=();
   return @chain if $start == 0xfffffffe;

   push (@chain, $start);
   while ( ($start = $t?$bbd[$start]:$sbd[$start]) != 0xfffffffe ) {
      push(@chain, $start);
   }
   @chain;
}

sub get_iolist {
# 
# @iolist = get_iolist ($depottype, $offset, $size, $startblock [,@depot])
#
# This is the main IO logic. Returns the iolist for a data stream according 
# to depot type $t. The stream may start at offset $offset and can have a 
# size $size. If size is bigger than the total size of the stream according 
# to its depot, it will be cut correctly. (So if you want to read until the
# files end without knowing how many bytes that are, take 0xffffffff as size).
#
# depottype $t:
#    0 small block (for @sbd)                    small block depot
#    1 big block   (for @bbd)                    big block depot
#    2 small block (for @_[4..$#])               some small blocks
#    3 big block   (for @_[4..$#])               some big blocks
#    4 variable    (for @curfile_iolist)         iolist of current file
#    5 variable    (for @_[4..$#] == (@o, @l))   some iolist
#
   local($t, $offset, $size, $sb) = (shift||0, shift||0, shift||0, shift||0);
   local($di);
   local($bs, $max);

   local(@empty)=();
   return @empty if !$size;

   local($begin, $done, $len);
   local(@o)=(); local(@l)=();

   $bs = ($t==1 || $t==3) ? 0x200 : 0x40;

   if ($t<2) {
      # To skip these offsets, stream chains would have to be resolved 
      # before. 
   } elsif ($t<4) {
      $max = $#_;
      # Skip whole blocks, when offset given
      $sb += int ($offset / $bs);
      $offset -= int ($offset / $bs) * $bs;
   } elsif ($t==4) {
      $max = ($#curfile_iolist-1)/2;
   } elsif ($t==5) {
      $max = ($#_-1)/2;
   } else {
      return @empty;
   }

   $done = 0;
   for ( $di=$sb; 
         ($t<2) ? ($di!=0xfffffffe): ($di<=$max);
         $di=&next_dl
   ) {
      last if ($done == $size);
      if ($t==4) {
         $bs = $curfile_iolist[$max+1+$di];
      } elsif ($t==5) {
         $bs = $_[$max+1+$di];
      }
      if ($offset) {
         if ($bs <= $offset) {
            $offset -= $bs;
            next;
         } else {
            $begin = &depot_offset + $offset;
            $len   = $bs - $offset;
            $offset = 0;
         }
      } else {
         $begin = &depot_offset;
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
   (@o, @l);
}
sub next_dl { # get_iolist:next_dl
#
# index = depot ($di==index, $t==depothandle)
#
# Returns next chain link of depot @bbd ($t) or @sbd (!$t)
#
   return $sbd[$di] if !$t;
   return $bbd[$di] if $t==1;
   $di+1;
}
sub depot_offset { # get_iolist:depot_offset
#
# offset = depot_offset ($di==index, $t==depottype)
#
   return (($sb_list[$di/8]+1)*8 + ($di%8)) * 0x40 if $t==0;
   return ($di+1) * 0x200 if $t==1;
   return (($sb_list[$_[$di]/8]+1)*8 + ($_[$di]%8)) * 0x40 if $t==2;
   return ($_[$di]+1) * 0x200 if $t==3;
   return ($curfile_iolist[$di]) if $t==4;
   return ($_[$di]) if $t==5;
}


sub aggregate_iolist {
#
# (@offsets, @lengths)||() = aggregate_iolist(method,@offsets,@lengths)
#
# method:  
#    1  @offsets shall be sorted, no overlap allowed
#    2  @offsets shall be sorted, overlap is allowed
#    3  @offsets are sorted, no overlap allowed
#    4  @offsets are sorted, overlap is allowed
#
   local($method)=shift;
   local(@empty)=();
   return @empty if ($method<1)||($method>4); # Don't know method!

   local($max)=int(($#_+1)/2);

   local($i, $j);
   local(@o_in)=(); local(@l_in)=();
   local(%o_in)=();
   local(@o_out)=(); local(@l_out)=();
   local($offset, $len);

   #
   # Sort
   #
   if ( ($method==1) || ($method==2)) {
      # sort offsets
      for ($i=0; $i<$max; $i++) {
         next if !$_[$max+$i];
         if ($o_in{$_[$i]}) {
            return @empty if $method==1; # Data chunks overlap!
            $o_in{$_[$i]}=$i if $_[$max+$i]>$o_in{$_[$i]};
         } else {
            $o_in{$_[$i]}=$i;
         }
      } 
      foreach $key (sort {$a <=> $b} keys %o_in) {
         push(@o_in, $_[$o_in{$key}]);
         push(@l_in, $_[$max + $o_in{$key}]);
      }
   } else {
      @o_in=@_[0..($max-1)];
      @l_in=@_[$max..$#_];
   }

   #
   # Aggregate
   #
   $offset=$o_in[0];
   $len=$l_in[0];

   for ($i=1; $i<=($#o_in+1); $i++) {
      if ( ($i==($#o_in+1)) 
           || ($o_in[$i]<$offset)
           || ($o_in[$i]>($offset+$len)) 
         ) {
         push(@o_out, $offset);
         push(@l_out, $len);
         $offset=$o_in[$i];
         $len=$l_in[$i];
      } elsif ($o_in[$i]<($offset+$len)) {
         return @empty if ($type==1 || $type==3); # Data chunks overlap! 
         if ( ($o_in[$i]+$l_in[$i]) > ($offset+$len) ) {
            $len=$o_in[$i]+$l_in[$i]-$offset;
         }
      } else {
         $len += $l_in[$i];
      }
   }
   (@o_out, @l_out); 
}

sub rw_iolist {
   # 
   # 1||0 = rw_iolist("r"||"w", extern buf, @offsets, @lengths);
   # . read or write global chunklist
   #
   local($done, $i, $l);
   local($max) = int(($#_-2+1)/2);

   $done=0;
   for ($i=0; $i<$max; $i++) {
      next if ! ($l = $_[2+$i+$max]);
      if (&myio($_[0], $_[2+$i], $l, $_[1], $done)) {
         $done += $l;
      } else {
         # io error!
         return 0;
      }
   }
   1;
}

##
## ---------------------- Property Set Handling --------------------------
##

sub pps_name_to_string {
#
# $string = pps_name_to_string($offset, $pps_name_len, extern $buf)
#
   local($l)=$_[1]-2;
   local($i); 
   local($tmp)="";
   for ($i=0; $i<$l; $i+=2) {
      $tmp.=substr($_[2], $_[0]+$i, 1);
   }
   $tmp;
}

sub learn_guids {
    @guids = ("dsi", "si");
    $guid_dsi="\0x5DocumentSummaryInformation";
    @guid_dsi=( 0xd5cdd502, 0x2e9c, 0x101b, 
                "\0x93\0x97\0x08\0x00\0x2b\0x2c\0xf9\0xae" );
    $guid_si="\0x5SummaryInformation";
    @guid_si=( 0xf29f85e0, 0x4ff9, 0x1068, 
                "\0xab\0x91\0x08\0x00\0x2b\0x27\0xb3\0xd9" );
}

sub get_uuid {
   local($o)=$_[0];
   ( &get_long($o, $_[1]), 
     &get_word($o+4, $_[1]), 
     &get_word($o+6, $_[1]), 
     &get_chars($o+8, 8, $_[1])
   );
}

#
# This section refers to pps_ts2 and pps_ts1, the one ore two timestamps 
# used for each "Storage" Property Set. It seems, that the second timestamp 
# gets actualized, when changing the storage. The first stamp is sometimes 
# used, sometimes unused.
#
# The stamp is a 64 bit ulong. It counts every second 10 * 10 ^ 6, 
# starting at 01/01/1601. When the 64 bit int gets evaluated as
# two 32 bit integers, the faster running ("least significant long")
# can hold just 0x100000000 / 10000000.0 (about 429.5) seconds. So the 
# slower running ("most significant long") increments every 429.5 seconds.
#

sub filetime_init {
   @monsum  = ( 0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
                0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335 );
   $a_minute = 60 * 10000000.0 / (0x10000000 * 16);
}

sub is_schaltjahr {
   local($year)=shift;
   !($year%4) && ($year%100 || !($year%400) ) && 1;
}

sub filetime_years_to_days {
   local($year)=shift;
   int($year-1600) * 365 
     + int( ($year-1600) / 4 )
     - int( ($year-1600) / 100 )
     + int( ($year-1600) / 400 )
     ;
}

sub filetime_to_time {
   local($ds, $dd)=@_;
   local($day, $month, $year, $hour, $min, $sec);
   local($i, $m, $d, $dsum, $tmpsec);

   $dsum = $dd + ($ds / (0x10000000 * 16.0));

   $d= int( $dsum/($a_minute*60*24) )+1;
   $m= $dsum - ($d-1)*$a_minute*60*24;

   $year  = int( $d/365.2425 ) + 1601;
   $d -= &filetime_years_to_days($year-1);

   for( $i=11; $i && ($d <= $monsum[$i+&is_schaltjahr($year)*12]); $i--) {}
   $month = $i+1; 
   $day   = $d - $monsum[$i+&is_schaltjahr($year)*12];

   $hour  = int( $m / ($a_minute*60) ); 
   $min   = int( $m/$a_minute - $hour*60 );
   $sec   =    ( ($m/$a_minute - $hour*60 - $min) * 60);

   ($day, $month, $year, $hour, $min, $sec);
}

sub time_to_filetime {
   local($day, $month, $year, $hour, $min, $sec)=@_;
   local($d, $tss, $tsd);

   $d = &filetime_years_to_days($year-1) 
   + $monsum[$month-1 + &is_schaltjahr($year)*12]
   + $day-1; 

   $tsd = (24*60*$d + 60*$hour +$min +$sec/60.0) * $a_minute;

   $tss = ($tsd-int($tsd)) * 0x10000000 * 16;

   ( int($tss), int($tsd) );
}


##
## ------------------------- Trash Handling ------------------------------
##

sub make_blockuse_statistic {
   #
   # block statistic: 
   #    0 == irregular free (block depot entry != -1) (== undef)
   #    1 == regular free (block depot entry == -1)
   #    2 == used for ole system
   #    3 == used for ole application
   #
   return 1 if $usage_known;
   local($i, @list);

   # default: all small and big blocks are undef

   #
   # regular system data 
   #

   # ole system blocks
   for (@bbd_list, @sbd_list, @root_list, @sb_list) { 
      $bb_usage[$_]=2; 
   }

   # free blocks according to block depots
   for (@bbd) { 
      $bb_usage[$_]=1 if $bbd[$_]==0xffffffff; 
   }
   for (@sbd) { 
      $sb_usage[$_]=1 if $sbd[$_]==0xffffffff; 
   }

   #
   # OLE application blocks
   #
   foreach $file (&get_all_filehandles(0)) {
      if ($pps_size[$file]>=0x1000) {
         for (&get_list_from_depot($pps_sb[$file], 1)) { $bb_usage[$_]=3; }
      } else {
         for (&get_list_from_depot($pps_sb[$file], 0)) { $sb_usage[$_]=3; }
      }
   }

   $usage_known=1;
}

sub get_trash_info {
#
# void get_trash_info();
#
# Trash types:
#
#    0 == all
#    1 == unused big blocks
#    2 == unused small blocks 
#    4 == unused file space, according to sizeof pps_size (incl. root_entry)
#    8 == unused system space (header, sb_table, bb_table)
#
   return 1 if $trash_known;
   &make_blockuse_statistic();

   local(@o, @l);
   local(@list);
   local($size, $m);
   local($i);
   local($begin, $len);
 
   unused_big_blocks: {
      $size=0; @list=();
      for ($i=0; $i<=$maxblock; $i++) {
         push(@list, $i) if $bb_usage[$i]<=1;
      }
      @trash1_o = &get_iolist(3, 0, 0xfffffff, 0, @list);
      @trash1_l = splice(@trash1_o, ($#trash1_o+1)/2); 
      $m=$#trash1_o; for ($i=0; $i<=$m; $i++) { $size+=$trash1_l[$i]; }
      $trashsize{1}=$size;
   }

   unused_small_blocks: {
      $size=0; @list=();
      for ($i=0; $i<=$maxsmallblock; $i++) {
         push(@list, $i) if $sb_usage[$i]<=1;
      }
      @trash2_o = &get_iolist(2, 0, 0xfffffff, 0, @list);
      @trash2_l = splice(@trash2_o, ($#trash2_o+1)/2); 
      $m=$#trash2_o; for ($i=0; $i<=$m; $i++) { $size+=$trash2_l[$i]; }
      $trashsize{2}=$size;
   }

   unused_file_space: {
      $size=0;

      # 3.1. normal files
      foreach $file (&get_all_filehandles(0)) {
         @o = &get_iolist(
            $pps_size[$file]>=0x1000 && 1, 
            $pps_size[$file], 0xffffffff, $pps_sb[$file]
         );
         push(@trash3_l, splice(@o, ($#o+1)/2)); 
         push(@trash3_o, @o);
      }
      $m=$#trash3_o; for ($i=0; $i<=$m; $i++) { $size+=$trash3_l[$i]; }

      # 3.2. system file of root_entry (small block file)
      @list = ();
      while (($#list+$#sbd+2) % 8) {
         push(@list, $#list+$#sbd+2);
      }
      @o = &get_iolist(2, 0, 0xfffffff, 0, @list);
      @l = splice(@o, ($#o+1)/2); 
      push(@trash3_o, @o); push(@trash3_l, @l);
      $m=$#o; for ($i=0; $i<=$m; $i++) { $size+=$l[$i]; }

      $trashsize{3}=$size;
   }

   unused_system_space: {
      $size=0;

      # 4.1. header block
      $begin = 0x4c + $num_of_bbd_blocks*4;
      $len = 0x200 - $begin;
      push(@trash4_o, $begin); push(@trash4_l, $len);
      $size+=$len;
   
      # 4.2. big block depot
      @o = &get_iolist(3, ($maxblock+1)*4, 0xffffffff, 0, @bbd_list);
      @l = splice(@o, ($#o+1)/2); 
      push(@trash4_o, @o); push(@trash4_l, @l);
      $m=$#o; for ($i=0; $i<=$m; $i++) { $size+=$l[$i]; }
   
      # 4.3. small block depot
      @o = &get_iolist(3, ($maxsmallblock+1)*4, 0xffffffff, 0, @sbd_list);
      @l = splice(@o, ($#o+1)/2); 
      push(@trash4_o, @o); push(@trash4_l, @l);
      $m=$#o; for ($i=0; $i<=$m; $i++) { $size+=$l[$i]; }

      $trashsize{4}=$size;
   }

   $trash_known=1;
}

sub get_trash_size {
   local($type)=shift;
   $type = (1|2|4|8) if !$type;
   &get_trash_info();

   local($trashsize)=0;
   $trashsize += $trashsize{1} if $type & 1;
   $trashsize += $trashsize{2} if $type & 2;
   $trashsize += $trashsize{3} if $type & 4;
   $trashsize += $trashsize{4} if $type & 8;

   $trashsize;
}

sub rw_trash {
#
# "ok"||error = rw_trash("r"||"w", $type, extern $buf [,$offset,$size])
#
   local($maxarg)=$#_;
   &get_trash_info();

   local($rw, $type) = @_[0..1];
   $type = (1|2|4|8) if !$type;

   local($status, $offset, $size) = 
      &get_default_iosize(&laola_get_trashsize($type), $rw, @_[2..$maxarg]);
   return $status if $status ne "ok";

   local(@o)=(); local(@l)=();
   if ($type & 1) { push (@o, @trash1_o); push (@l, @trash1_l); }
   if ($type & 2) { push (@o, @trash2_o); push (@l, @trash2_l); }
   if ($type & 4) { push (@o, @trash3_o); push (@l, @trash3_l); }
   if ($type & 8) { push (@o, @trash4_o); push (@l, @trash4_l); }

   return "ok" if &rw_iolist(
      $rw, $_[2],
      &get_iolist(5, $offset, $size, 0, &aggregate_iolist(1, @o, @l))
   );

   "Laola: IO Error!";
}


##
## ----------------------------- Debugging -------------------------------
##

#
# Some debug information. Switch it on via $optional_do_debug=1
# Information will be shown directly after opening any document.
# 

sub debug_report_pps {
   local($i)=shift;
   local($out)="";
   local($tmp, $tmp2)="";

   return if !$pps_name[$i];

   $out = sprintf ("%2x", $i); 
   $out .= $pps_uk0[$i]==1 ? ":  " : sprintf ("#%-2x", $pps_uk0[$i]);

   if (&laola_is_directory($i)) {
      $out .= "-->    ";
   } elsif (&laola_is_file($i)) {
      $out .= sprintf ("%-5x  ", 
                       &laola_get_filesize($i));
   } else {
      $out .= "       ";
   }
   
   if ($pps_prev[$i]==0xffffffff) { $out .= "  .";
      } else { $out .= sprintf ("%3x", $pps_prev[$i]); }
   if ($pps_next[$i]==0xffffffff) { $out .= "  .";
      } else { $out .= sprintf ("%3x", $pps_next[$i]); }
   if ($pps_dir[$i]==0xffffffff) { $out .= "  .";
      } else { $out .= sprintf ("%3x", $pps_dir[$i]); }

   if (&laola_is_file_ppset($i)) {
      $out .= "  set";
   } else {
      $out .= "  pp "; 
   }

   ($tmp=$pps_name[$i]) =~ s/[^_a-zA-Z0-9]/ /g;
   $out .= sprintf (" \"%s\"",$tmp); 

   $out .= " " x (50 - length($out));

   if ($pps_ts2d[$i]) {
      $out .= sprintf (" %d.%d.%d %02d.%02d:%02d", 
        &filetime_to_time($pps_ts2s[$i], $pps_ts2d[$i])
      );
   }

   print "$out\n";
}

sub report_blockuse_statistic {
   return 1;
   print "--- LAOLA internal, begin block statistic ---\n\n";
   &make_blockuse_statistic();
   local($i, $j, $m);
   local(@o, @l);
   print "Big blocks:\n";
   for ($i=0; $i<4; $i++) {
      @o=(); @l=();
      $m=$#bb_usage; for ($j=0; $j<=$m; $j++) {
         next if $bb_usage[$j]!=$i;
         push(@o, $j); push(@l, 1);
      }
      &report_blockuse_list($i, &aggregate_iolist(1, @o, @l));
   }
   print "Small blocks:\n";
   for ($i=0; $i<4; $i++) {
      @o=(); @l=();
      $m=$#sb_usage; for ($j=0; $j<=$m; $j++) {
         next if $sb_usage[$j]!=$i;
         push(@o, $j); push(@l, 1); 
      }
      &report_blockuse_list($i, &aggregate_iolist(1, @o, @l));
   }
   print "\n--- LAOLA internal, end block statistic ---\n\n";
}

sub report_blockuse_list {
   local($type)=shift;
   return if !@_;
   local(%info)=(0, "Trash", 1, "Free", 2, "System", 3, "Application");
   local($max)=($#_+1)/2;
   local($i); local($o, $l);
   print "Type $type {$info{$type}} = (";
   for ($i=0; $i<$max; $i++) {
      $o=$_[$i]; $l=$_[$max+$i];
      if ($l==1) {
         printf (" %x ", $o);
      } else {
         printf (" %x-%x ", $o, $o+$l-1);
      }
   }
   print ")\n";
}

sub report_trash_statistic {
   return; 
   &get_trash_info();
   print "Trash statistic.\n";
   print "Free big block chunks: (\n";
   &report_trash_list($trashsize{1}, @trash1_o, @trash1_l);
   print "\nFree small block chunks: (\n";
   &report_trash_list($trashsize{2}, @trash2_o, @trash2_l);
   print "\nUnused file space: (\n";
   &report_trash_list($trashsize{3}, @trash3_o, @trash3_l);
   print "\nUnused system space: (\n";
   &report_trash_list($trashsize{4}, @trash4_o, @trash4_l);

   print "\nSummary: (\n";
   &report_trash_list(
      $trashsize{1}+$trashsize{2}+$trashsize{3}+$trashsize{4}, 
      &aggregate_iolist( 1, 
         @trash1_o, @trash2_o, @trash3_o, @trash4_o,
         @trash1_l, @trash2_l, @trash3_l, @trash4_l
      )
   );
}

sub report_trash_list {
   local($size)=shift;
   local(@o)=@_;
   local(@l)=splice(@o, ($#o+1)/2);
   local($i, $m);
   printf ("   %d elements, size=%x\n", $#o+1, $size);
   $m=$#o; for ($i=0; $i<=$m; $i++) {
      printf ("   offset %5x (len %x)\n", $o[$i], $l[$i]);
   }
   print ")\n";
}

sub print_iolist {
   local(@o)=@_;
   local(@l)=splice(@o, ($#o+1)/2); 
   local($i);
   $m=$#o; for ($i=0; $i<=$m; $i++) {
      printf("   o=%6x (%x)\n", $o[$i], $l[$i]);
   }
}

"Atomkraft? Nein, danke!"

