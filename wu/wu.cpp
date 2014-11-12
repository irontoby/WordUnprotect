// wu.cpp        -- Unprotect Microsoft Word/Winword Document


//	Marc Thibault <marc@tanda.isis.org>

// Word protects a document by XOR'ing a 16-byte key repetitively
//	through the document file, starting at byte 40. The header (0x180 bytes)
//	is filthy with zeros including what appears to be over 48 of them at
//	the end of the header. This program hopes that the last 32 are zeros
//	(it checks) and extracts the key from this area. Improvements can be
//	made to this if it ever turns out that these bytes are used for
//	something.

// The encryption key is derived from the user's passphrase by some means
//  I have not attempted to discover. It is unnecessary, since the
//	encryption key can be directly discovered and applied.

// Call:
//			wu infile outfile

// Exit Status:
//	1	too few arguments
//	2	can't open given file for input
//	3	can't open given file for output
//	4	can't find a key (last two rows of header aren't the same)
//	5	too short to be a Word file
//	6	Problem writing to output file


#include <stdio.h>
#include <process.h>
#ifdef __TURBOC__
    #include <iostream.h>
#endif
#ifdef __ZTC__
    #include <stream.h>
#endif

#define Version "1.2"
#define VersionDate "26 January 1993"
#define keyLength 0x10
#define bufferLength 0x180
#define headerLength 0x180


int  findKey(unsigned char buffer[], unsigned char key[]);
void fixHeader(unsigned char buffer[], unsigned char key[]);
void fixBuffer(unsigned char buffer[], unsigned char key[]);

#ifdef debug
void showBuffer(unsigned char buf[]);
#endif

char *copyLeft[] = {"\nMarc Thibault <marc@tanda.isis.org>\n",
                    " Oxford Mills, Ontario \n",
					" This work is released to the public domain. \n",
					" It may be copied and distributed freely \n",
					" with appropriate attribution to the author.\n"};


void main(int argc, char *argv[])
{
	unsigned char buffer[bufferLength];		// data buffer
	unsigned char key[keyLength];			// encryption key
	size_t count, check;
    int i;

	FILE *crypt, *plain;

	// ----------------------

	if( argc < 3)                         	// file names must be present
	{
		cout << "\n Word Unprotect -- Version " << Version;
		cout << "\n   by Marc Thibault, " << VersionDate;
		cout << "\n Syntax: wu infile outfile \n";
		exit (1);
	}

	// Open files

	if( NULL == (crypt = fopen(argv[1], "rb")))
	{
		cout << "\n wu error: can't open the input file\n";
		exit (2);
	}

	if( NULL == (plain = fopen(argv[2], "wb")))
	{
		cout << "\n wu error: can't open the output file\n";
		exit (3);
	}

    // Read header from input file

	count = fread(buffer,1,headerLength,crypt);
	if(count != bufferLength)
	{
		cout << "\n wu error: Input file too short to be a Word File\n";
		exit(5);
	}

    // Extract the encryption key

	if(findKey(buffer,key))
	{
    	cout << "\n wu error: Couldn't find a key \n";
		exit(4);
	}

#ifdef debug
	cout << "\n Key in hexadecimal is";
	for (i=0; i<keyLength; i++) printf(" %02X", key[i]);
	cout << "\n";
#endif

	// Decrypt/fixup the header and
    // write it to the output file

	fixHeader(buffer,key);
    check = fwrite(buffer, 1, headerLength, plain);
	if (check != headerLength)
	{
		cout << "\n wu error: Problem writing to output file";
		exit(6);
	}

	// decrypt the rest of the file

	do
	{
		count = fread(buffer,1,bufferLength,crypt);
		if (count != 0)
		{
			fixBuffer(buffer, key);
			check = fwrite(buffer, 1, count, plain);
			if (check != count)
			{
				cout << "\n wu error: Problem writing to output file";
				exit(6);
			}
        }
    } while (count == bufferLength); 
}

// --------------------------------------------------------------------------
#ifdef debug
void showBuffer(unsigned char buf[])
{
	for( int i=0; i<bufferLength; i += 16)
	{
	printf("\n");
	for(int j=0; j<16; j++) printf (" %2X", buf[i+j]);
	}
	printf("\n");
}
#endif

// --------------------------------------------------------------------------
// findKey -- Find key in protected Word File
// entered with everything initialized, including the initial buffer

int findKey(unsigned char buffer[], unsigned char key[])
{
	int i,check;

	// make sure the header looks ok, with 32 bytes of zeros (two copies
	// of the key) at the end of the header.

    check=0;
	for (i=0; i<keyLength; i++) check |= (buffer[0x160+i]^buffer[0x170+i]); 
	if (check != 0) return(1);

    // If there's ever a problem, this is a place
    // to put a scanner for majority
    // vote on each key byte. The header
    // is so full of zeros, this should work.

    // In the meantime, just move one copy to the key buffer.

	for (i=0; i<keyLength; i++) key[i] = buffer[0x160+i];
	return(0);
}

// --------------------------------------------------------------------------
// fixHeader -- Fix the header block after finding key


void fixHeader(unsigned char buffer[], unsigned char key[])
{
	int i, j;

	// reset the protect flag
	buffer[11] &= 0xfe;

	// reset bytes 14-17 (key hash?)
	for( i=14; i<18; i++) buffer[i] = 0;

	// decrypt partial row at 0x24
	for( i=4; i<16; i++) buffer[0x20+i] ^= key[i];

	// decrypt rest of header
	for( i=0x30; i < headerLength; i += keyLength)
	{
		for( j=0; j < keyLength; j++) buffer[i+j] ^= key[j];
	}
}

// --------------------------------------------------------------------------
// fixBuffer -- Decrypt the buffer contents as a whole


void fixBuffer(unsigned char buffer[], unsigned char key[])
{
	for( int i=0; i < bufferLength; i += keyLength)
	{
		for( int j=0; j < keyLength; j++) buffer[i+j] ^= key[j];
	}
}
