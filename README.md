Crack passwords on Word for Windows 2.0, 6.0 documents
======================================================

I had a decades-old Word for Windows 2.0 ("winword2") file that was password-protected
and I couldn't remember the password. I remembered that these old versions of Word had
passwords that were trivially easy to crack, but for the life of me I couldn't find an
actual program to crack them; everything was Word 97 or later.

Finally my Google-fu was strong enough to find the names of the DOS executables, and
from there I was able to find the tools themselves. I was able to run both of these
under DOSBox on Linux.

Word Unprotect
--------------

WU, or "Word Unprotect" works on Word 2.0 files to extract the encryption key which is
pretty much in plain sight. (The encryption key is some type of hash of the actual
password; it doesn't reveal your password, but decrypts the file). It was written by
Marc Thibault of Oxford Mills, Ontario on 26 January 1993, and released to the public
domain, including the C++ source.

Word for Windows Password Cracker
---------------------------------

WFWCD, or "Word for Windows Password Cracker", works on Word 2.0 and Word 6.0 files
to extract the actual password. It was written by Fauzan Mirza in 1995 and released as
freeware but without source code.

And yes, the password to that decades-old Word document was indeed `password`. You're
welcome.
