#
# $Id: install.pl,v 0.5.1.5 1997/07/01 00:06:42 schwartz Rel $
#
# install.pl, helps installing
#
# For a description please refer to INSTALL.TXT
#
# See also usage() of this file. General information at:
#    http://wwwwbs.cs.tu-berlin.de/~schwartz/pmh/laola.html
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

sub install {
   require "getopts.pl";
   &Getopts('cghlt');
   undef $/;

   $REV = ('$Revision: 0.5.1.5 $' =~ /: ([^ ]*)/) && $1;
   $|=1; $[=0; $error="";
   exit &usage if $opt_h;
   exit &cleanup() if $opt_c;

   &msg("Starting installation of Laola and Elser. (-h for help)\n");
   &fail() if !&msg2 (&check_complete);
   &fail() if !&msg2 (&get_os);
   &get_defaults;
   &fail() if !&msg2 (&get_PerlExePath);
   &fail() if !&msg2 (&is_everything_ok);
   &fail() if !&msg2 (&get_PerlLibPath);
   &fail() if !&msg2 (&do_install);
   &msg("\nEverything went fine! $usage is installed now.\n\n"); exit;
}

sub fail {
   &msg("Installation NOT successful!\n\n");
   exit;
}

sub usage {
   print "\n";
   print "usage: perl install [-c|-g|-h|-l|-t]\n";
   print "Installs $usage. Revision $REV\n";
   print "-c  clean. Removes distribution files from current directory.\n";
   print "-g  global. For Unix. Installs library in /usr/lib/perl.\n";
   print "-h  help. Shows this help.\n";
   print "-l  link. For Unix. Makes symbolic links instead of shell files.\n";
   print "-t  test. Show, what install would do.\n";
   print "\n";
}

sub get_os {
   local($ostype)="";
   if ($sys_os eq "vms") {
       $ostype="VMS";
   }
   if (!$sys_os) {
      $sys_os = "dos"; $ostype="DOS";
      if((-e '/etc/group')||(-e '/etc/hosts.equiv')||(-e '/etc/passwd')) {
         $sys_os = "unix"; $ostype="Unix";
      }
   }
   $sys_os =~ tr/[A-Z]/[a-z]/;

   if (!&permit("\nDo you run a kind of $ostype operating system?")) {
      return 
         "Confusion about your operating system. Please change settings\n"
         ."       in this install program manually!"
      ;
   }
      
   if ($sys_os eq "dos") {
      $HomePath = "C:/" if !$HomePath;
   } elsif ($sys_os eq "unix") {
      $HomePath = $ENV{'HOME'}||$ENV{'LOGDIR'}||(getpwuid($<))[7];
   } elsif ($sys_os eq "vms") {
           $HomePath = "SYS$LOGIN:" if !$HomePath;
   }

   return "Cannot find home directory!" if !$HomePath;

   if ($sys_os eq "dos") {
      &msg("Converting distribution files to DOS text format...");
      return $error if !&unix2dos(@dist_files);
      &msg(" Done.\n\n");
   }

   return "ok";
}

sub get_defaults {
   if (($sys_os eq "unix") && $opt_g) {
      $LibraryPath = "/usr/lib/laola" if !$LibraryPath;
      $ExecutePath = "/usr/bin"       if !$ExecutePath;
      $dir_permit=0755                if !$dir_permit;
      $lib_permit=0644                if !$lib_permit;
      $exe_permit=0755                if !$exe_permit;
   } elsif ($sys_os eq "unix") {
      $LibraryPath = "~/lib/laola"    if !$LibraryPath;
      $ExecutePath = "~/bin"          if !$ExecutePath;
      $dir_permit=0700                if !$dir_permit;
      $lib_permit=0600                if !$lib_permit;
      $exe_permit=0700                if !$exe_permit;
   } elsif ($sys_os eq "dos") {
      $LibraryPath  ="C:/TOOLS/LAOLA" if !$LibraryPath;
      $ExecutePath = &guess_batpath  if !$ExecutePath;
      $dir_permit=0777                if !$dir_permit;
      $lib_permit=0666                if !$lib_permit;
      $exe_permit=0777                if !$exe_permit;
   } elsif ($sys_os eq "vms") {
      $LibraryPath = "PERL_ROOT:[LAOLA]"    if !$LibraryPath;
      $ExecutePath = "PERL_ROOT:[LAOLA]"    if !$ExecutePath;
      $dir_permit=0700                if !$dir_permit;
      $lib_permit=0600                if !$lib_permit;
      $exe_permit=0700                if !$exe_permit;
   }
   $LibraryPath =~ s/\/$//g;
   $ExecutePath =~ s/\/$//g;
}

sub guess_batpath {
   local($guess)=""; local($dosguess)="";
   for (split(/;/, $ENV{PATH})) {
      $dosguess = $_ if (/dos/i) && !$dosguess;
      last if (/bat/i) && ($guess=$_);
   }
   $guess || $dosguess || "C:/DOS";
}

sub is_everything_ok {
   local($msg)="";
   $LibraryPath =~ s/^~\//$HomePath\//;
   $ExecutePath =~ s/^~\//$HomePath\//;
   if (($sys_os eq "unix") && $opt_g) {
      &msg("Installation will be done for whole Unix system (global).\n"
         ."If you have more than one perl version running, you might like\n"
         ."to start install with each of them.\n"
      );
   }
   &msg("\nThe source code and information files will be stored in directory:"
        ."\nLibraryPath = \"$LibraryPath\". "
   );
   return if !&msg2 (&ok("Is this ok?"));

   if ($sys_os eq "unix") {
      if (!$opt_l) {
         $msg = "Shell scripts to call the executable perl programs";
      } else {
         $msg = "Soft links to the executable perl programs";
      }
   } elsif ($sys_os eq "dos") {
      $msg="The .BAT files to call the perl programs";
   } elsif ($sys_os eq "vms") {
      $msg="The .COM files to call the perl programs";
   }

   &msg("$msg will be placed to directory:\n"
      ."ExecutePath = \"$ExecutePath\". "
   );
   return if !&msg2 (&ok("Correct?"));

   "ok";
}

sub ok {
   local($question)=shift;
   if (!&permit($question)) {
      return "Bad settings. Please change system settings manually in\n".
         "this install program." 
      ;
   }
   print "\n"; 
   return "ok";
}

sub get_PerlExePath {
   return "ok" if $PerlExePath;
   $PerlExePath = &which($^X);
   return "Cannot find perl executable!" if !$PerlExePath;
   return "Where is perl executable?" if !&permit(
      "Perl executable is \"$PerlExePath\". Right?"
   );
   "ok";
}

sub get_PerlLibPath {
   local($lib)=""; 
   if ( ($sys_os eq "dos") || $opt_g ) {
      for (@INC) { last if (!/\./) && ($lib=$_) }
      return "Cannot find perl's library directory!" if !$lib;
   } elsif ( $sys_os eq "unix" ) {
      if (!-d "$HomePath/lib/perl") {
         return "Don't know, where to install Laola." if !&permit(
            "Install is going to create the directory \"lib/perl\" in your\n"
            ."home directory. The include files necessary to run Laola "
            ."programs\n"
            ."will be placed there. Is this ok?"
         );
         return $error if !&my_mkdir("$HomePath/lib/perl");
      }
      $lib="$HomePath/lib/perl";
   }

   $lib =~ s/\/$//g;
   $PerlLibPath=$lib;
   "ok";
}

sub check_complete {
   local($status);
   for (@dist_files) {
      next if -e $_;
      return "Your distribution is not complete!\nFile \"$_\" is missing!";
   }
   "ok";
}


sub do_install {
   # If not started from right directory, copy all files of the 
   # distribution to the proper source directory.
   if ($LibraryPath ne $ENV{$PWD}) {
      foreach $dir (@dist_dirs) { 
         return $error if !&my_mkdir($LibraryPath."/".$dir);
      }
      foreach $file (@dist_files) { 
         return $error if !&my_cp($file, $LibraryPath."/".$file);
      }
   }
   
   # Copy / link perl library files from distributionpath to library path
   foreach $dir (@lib_dirs) {
      return $error if !&my_mkdir($PerlLibPath."/".$dir);
   }
   if ($sys_os eq "unix") {
      &msg("Creating symbolic links to library files.\n");
   } else {
      &msg("Copying library files.\n");
   }
   foreach $file (keys %lib_files) {
      return $error if ! &do_library($file);
   }

   local($warn)=
      "This file has been generated automatically by Laola's install $REV."
   ;

   # Create shell files / links to executable programs
   if ($sys_os eq "unix") {
      if ($opt_l) {
         &msg("Creating symbolic links to call executables.\n");
      } else {
         &msg("Creating shell scripts to call executables.\n");
      }
   } else {
      &msg("Creating command files.\n");
   }
   foreach $file (keys %executables) {
      return $error if !&do_executables(
         $LibraryPath."/".$file, $ExecutePath."/".$executables{$file}
      );
   }

   if ($LibraryPath ne $ENV{$PWD}) {
      # Delete temporary files.
      &cleanup();
   } else {
      "ok";
   }
}

sub do_library {
   local($file)=shift;
   if ($sys_os eq "unix") {
      &my_slink("$LibraryPath/$file", $PerlLibPath."/".$lib_files{$file});
   } else {
      &my_cp($file, $PerlLibPath."/".$lib_files{$file})
         && &my_rm("$LibraryPath/$file")
      ;
   }
}

sub do_executables {
   local($source, $dest)=@_;
   if ($sys_os eq "unix") {
      if (!$opt_l) {
         &makeshell ($source, $dest);
       } else {
         &my_chmod ($exe_permit, $source) 
            && &my_slink($source, $dest)
         ;
       }
   } elsif ($sys_os eq "vms") {
        &makedcl ($source, $dest);
   } else {
      &makebatch($source, $dest);
   }
}

sub basename {
   (substr($_[0], rindex($_[0],'/')+1) =~ /(^[^.]*)/) && $1;
}

sub which {
   local($path)=shift;
   local($found)="";
   return "" if !$path;
   if ($path =~ s/^\.\//$ENV{PWD}\//) {
      return $path;
   } elsif ($path =~ s/^\.\.\//$ENV{PWD}\/..\//) {
      return $path;
   } elsif ( ($path=~/[a-z]:/i) && ($sys_os eq "dos")) {
      return $path;
   } elsif ($path =~ /^\//) {
      return $path;
   } else {
      for (split(/:/, $ENV{PATH})) { 
         last if (-f "$_/$path") && ($found="$_/$path")
      }
      return $found;
   }
}

sub permit {
#
# 1||0 = permit($question)
#
   local($question)=shift;
   local($key)="";

   print "$question (y/n) ";
   while (1) {
      last if ($key=getc) =~ /[yn]/;
      print "(y/n) " if $key eq "\n";
   }
   getc; # get \n from userEss input
   $key =~ /y/;
}

sub msg  { @_ && print (shift) || 1 }
sub msg1 { &msg( " ".(shift)."," ) }
sub msg2 {
   local($status) = shift;
   if ($status eq "ok") {
      return &msg(shift);
   } else {
      print "\nERROR: $status\n\n" if $status;
      return 0;
   }
}

##
## IO 
##

sub my_cp {
   local($infile, $outfile)=@_;
   if ($opt_t) {
      print "Copying $infile to $outfile\n"; 
      return "ok";
   }
   local($buf)="";
   if (!open(OUT, ">$outfile")) {
      $error="Cannot write to \"$outfile\"."; return 0;
   }
   if (!open(IN, $infile)) {
      close(OUT); 
      $error="Cannot read \"$infile\"."; return 0;
   }
   binmode(OUT); binmode(IN);
   return "Cannot write to \"$outfile\"." if !(print OUT <IN>);
   close (OUT); close(IN);
   &my_chmod ($lib_permit, $outfile);
}

sub my_chmod {
   local($permit, $path) = @_;
   if ($opt_t) {
      printf "chmod %03o $path\n"; return 1;
   }
   chmod ($permit, $path);
}

sub my_slink {
   local($oldfile, $newfile)=@_;
   if ($opt_t) {
      print "Creating soft link $newfile\n";
      return "ok";
   }
   unlink($newfile);
   if (!symlink ($oldfile, $newfile)) {
      $error="Cannot (symbolically) link:\n"
         ."    \"$newfile\" to \"$oldfile\"."
      ; 
      return 0;
   }
   1;
}

sub my_mkdir {
   local($path)=shift;
   $path .= "/" if ! ($path=~/\/$/);
   local($pos)=0;
   while( ($pos=index($path, "/", $pos+1)) >= 0) {
      return 0 if !&make_one_dir(substr($path, 0, $pos));
   }
   1;
}

sub my_rm {
   local($file)=shift;
   if ($opt_t) {
      print "Removing file $file\n"; 
      return 1;
   } else {
      if (unlink("$file")) {
         return 1;
      } else {
         $error = "Cannot remove \"$file\""; 
         return 0;
      }
   }
}

sub my_rmdir {
   local($dir)=shift;
   if ($opt_t) {
      print "Removing directory $dir\n"; 
      return 1;
   } else {
      if (rmdir("$dir")) {
         return 1;
      } else {
         $error = "Cannot remove \"$dir\""; 
         return 0;
      }
   }
}

sub make_one_dir {
   local($dir)=shift;
   return 1 if -d $dir;
   if ($opt_t) {
      print "Creating directory $dir\n"; 
      return "ok";
   } else {
      return 1 if mkdir($dir, $dir_permit);
      $error="problems with directory \"$dir/\"!";
      return 0;
   }
}

sub makebatch {
   if ($opt_t) {
      print "Creating Batch file $newfile.bat\n"; 
      return "ok";
   }
   local($oldfile, $newfile)=@_;
   if (!open(OUT, ">$newfile.bat")) {
      $error="Cannot create \"$newfile.bat\"!"; return 0;
   }
   print OUT "\@echo off\n"
      ."rem\n"
      ."rem $warn\n"
      ."rem\n"
      ."$PerlExePath $oldfile %1 %2 %3 %4 %5 %6 %7 %8 %9"
   ;
   close(OUT);
}

sub makeshell {
   local($oldfile, $newfile)=@_;
   if ($opt_t) {
      print "Creating shell file $newfile\n";
      return "ok";
   }
   if (-f $newfile || -l $newfile) {
      unlink($newfile);
   }
   if (!open(OUT, ">$newfile")) {
      $error="Cannot create \"$newfile\"!"; return 0;
   }
   print OUT "#!/bin/sh\n"
      ."#\n"
      ."# $warn\n"
      ."#\n"
      ."$PerlExePath $oldfile \$\@"
   ;
   close(OUT);
   &my_chmod ($exe_permit, $newfile) && "ok";
}

sub makedcl {
   local($oldfile, $newfile)=@_;
   if ($opt_t) {
      print "Creating shell file $newfile.com\n";
      return "ok";
   }
   if (-f $newfile || -l $newfile) {
      unlink($newfile);
   }
   if (!open(OUT, ">$newfile")) {
      $error="Cannot create \"$newfile\"!"; return 0;
   }
   print OUT "\$! VMS command procedure\n"
      ."\$!\n"
      ."\$! $warn\n"
      ."\$!]\n"
      ."\$ \$$PerlExePath $oldfile \$\@"
   ;
   close(OUT);
   &my_chmod ($exe_permit, $newfile) && "ok";
}

sub cleanup {
   &msg("Cleaning up.\n");
   foreach $file (@dist_files) { 
      return 0 if !&my_rm($file);
   }
   foreach $dir (@dist_dirs) { 
      return 0 if !&my_rmdir($dir);
   }
   foreach $file (@remove) {
      return 0 if !&my_rm($LibraryPath."/".$file);
   }
   "ok";
}

sub unix2dos {
   local($state, $buf);
   foreach $file (@_) {
      $state=0;
      if ($dist_binary{$file}) {
         $state=1; next;
      }
      if ($opt_t) {
         print "Adding linefeeds to file $file\n";
         $state=1; next;
      }
      if (open(FILE, $file) && ($buf=<FILE>) && close(FILE)) {
         if ($buf =~ s/\x0a/\n/g) {
            $state = open(FILE, ">$file") && (print FILE $buf) && close(FILE);
         }
      }
      $error = "Cannot convert file \"$file\"!" if !$state;
      last if !$state;
   }
   $state;
}

"Atomkraft? Nein, danke!"

