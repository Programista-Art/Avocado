
                            Free Pascal Compiler

                               Version 3.2.2

****************************************************************************
* Introduction
****************************************************************************

Please also read the platform specific README file, if it exists.

This package contains an advanced freeware 32-bit/64-bit/16-bit pascal
compiler for several platforms. The language and the runtime library are
almost compatible with Turbo Pascal 7.0 and recent Delphi releases. There is
also partial support for the Macintosh pascal dialect.

News and changes related to this release are described in whatsnew.txt.

Free Pascal 3.2.2 is currently available for the following platforms:
- Linux-i386
- Linux-x86_64 (amd64)
- Linux-powerpc
- Linux-sparc
- Linux-ARM
- Win32-i386 (2000/XP, WinNT or later)
- Win64-x86_64 (XP or later)
- Wince-ARM (cross compiled from win32-i386)
- FreeBSD-i386
- FreeBSD-x86_64
- Mac OS X/Darwin for PowerPC (32 and 64 bit)
- Mac OS X/Darwin for Intel (32 and 64 bit)
- Mac OS X/Darwin for AArch64/ARM64
- iOS (ARM and AArch64/ARM64) and iPhoneSimulator (32 and 64 bit)
- OS/2-i386 (OS/2 Warp v3.0, 4.0, WarpServer for e-Business and eComStation)
- Haiku-i386
- GO32v2-i386
- Nintendo Gameboy Advance-ARM (cross compile from win32-i386)
- Nintendo DS-ARM (cross compile from win32-i386)
- Nintendo Wii-powerpc (cross compile from win32-i386)
- AIX 5.3 and later for PowerPC (32 and 64 bit)
- Java JVM (1.5 and later) and Android Dalvik (Android 4.0 and later)
- Android (AArch64, x86_64, ARM, i386, MIPS) via cross-compiling.
- MSDos-i8086 (cross compiled from win32-i386 or Linux) 
- Amiga, MorphOS and AROS

There are other platforms (like other BSD variants) which are more or less
working, but there is currently no maintainer for them and thus we cannot
provide adequate support. If you want to change this and create and
maintain versions for other platforms and targets, feel free to contact us,
e-mail addresses are listed below.


****************************************************************************
* Features
****************************************************************************

- high speed compiler
- fully 16, 32 or 64-bit code
  - 32 bit compiler can be used on x86_64 Linux distributions to compile
    32 bit applications
- language features:
  - almost fully compatible with Borland Pascal and Borland Delphi
  - ansi strings
  - wide strings
  - exception support
  - RTTI support
  - procedure overloading
  - generics
  - operator overloading
  - COM, CORBA and raw interfaces support
  - dynamic array support
  - variant support
  - inlining
- code optimizer:
  - peephole optimizer (80x86 only)
  - jump optimizer
  - loading of variables into registers
  - assembler level dataflow analyzer (80x86 only)
  - stack frame eliminations
  - sophisticated register allocator
- integrated BASM (built-in assembler) parser
  - supports ATT syntax used by GNU C
  - supports Intel syntax used by Turbo Pascal (x86-only)
- can compile code into assembler source code for these assemblers:
  - GNU Assembler (GAS)
  - Netwide assembler (Nasm)
  - Microsoft Assembler/Turbo Assembler (Masm/Tasm)
  - Watcom assembler (wasm)
- internal assembler for ultra fast object file generation
- can call external C code
  - h2pas utility to convert .h files to Pascal units
- smart linking (also known as dead code stripping)
- support for the GNU debugger
- integrated development environment (disabled by default on Mac OS X)
  - powerful user friendly Wordstar compatible multi file editor
  - context sensitive help supports help files in HTML, Windows HLP and
    Borland TPH format.
  - debugger on most platforms
- can create binaries running natively under both DOS and OS/2 (EMX version)
- no need for Linux distribution specific binaries, programs you write run
  on all distributions
- high quality documentation


****************************************************************************
* Minimum requirements
****************************************************************************

Processor:
  i386, x86_64, PowerPC, ARM, MIPS, i8086, Motorola 68k, Sparc or JVM 
  runtime
Win32:
 - MS Windows NT/2000/XP or later (Win95, 98 and ME are not supported
   in FPC officially any longer).
 - 16 MB RAM
OS/2:
 - OS/2 Warp v3.0 with one of late fixpaks - FP 35 should be fine,
   OS/2 Warp v4.0 with FP 5 and above, WSeB, MCP or any eComStation version
   (OS/2 2.0/2.1 currently not supported, not even for compiled programs).
 - ArcaOS should be OK too, but it hasn't been tested.
 - Certain features (e.g. Unicode support in the RTL) require proper support
   only available in later OS/2 versions (at least OS/2 Warp 4.0 FP14),
   otherwise the functionality may be limited (but the binaries still work
   even on the older versions, albeit with some limitations).
Linux:
 - system running a 2.4.x kernel
FreeBSD:
- There are separate releases for FreeBSD 7.x system or 8.x system. The code
    works on 6.x too. Older versions might need specific adaptations.
Mac OS X:
 - Mac OS X 10.4 and higher


****************************************************************************
* Quick start - Win32
****************************************************************************

Download the distribution package (fpc-3.2.2.i386-win32.exe) and run it
- it is a self-extracting installer, so just follow the instructions
to install it. The installer should set the PATH environment variable as
appropriate.

To test the compiler, change to the demo\texts directory of the FPC tree
and type on the command line:
        fpc hello
        hello


****************************************************************************
* Quick start - DOS
****************************************************************************

Download distribution archive (dos322.zip for GO32v2) and unzip it into
a temporary directory.

Start the install program INSTALL.EXE and follow the instructions.

Don't forget to set PATH as mentioned by the install program. If running
under plain DOS, this can be done by opening file named AUTOEXEC.BAT located
in the root directory of your boot drive (usually C:\) with a plain text
editor (like EDIT.COM), extending the line starting with "set PATH=" (case
insensitive) with path to newly installed binaries (installation root as
selected in the installation program appended with "\BIN\GO32v2") and save
it.

To test the compiler, change to the demo\texts directory of the FPC tree
and type
        fpc hello
        hello


****************************************************************************
* Quick start - OS/2 / eComStation / ArcaOS
****************************************************************************

Download distribution archive (os2322full.zip or os2322.zip for OS/2,
eComStation or ArcaOS) and unzip it into a temporary directory.

Start the install program INSTALL.EXE and follow the instructions.

Don't forget to set PATH and LIBPATH as mentioned by the install program.
This can be done by opening file named CONFIG.SYS located in the root
directory of your boot drive (e.g. C:\) with a plain text editor (e.g.
E.EXE), extending the lines starting with "set PATH=" and "LIBPATH=" (both
are case insensitive) with path to newly installed binaries (installation
root as selected in the installation program appended with "\BIN\OS2" for
PATH and "\DLL" for LIBPATH) and save it again as a plain text file.
Note that changes to LIBPATH require restart of your machine in order to come
into effect.

To test the compiler, change to the demo\texts directory of the FPC tree
and type
        fpc hello
        hello


****************************************************************************
* Quick start - Linux/FreeBSD
****************************************************************************

Download fpc-3.2.2.<cpu>-<os>.tar and untar into a temporary directory.

Start the install script with ./install.sh and follow the instructions.

To test the compiler, change to the demo/texts directory of the FPC tree
and type
        fpc hello
        hello


****************************************************************************
* Quick start - Mac OS X/Darwin
****************************************************************************

The Xcode command line tools must be installed before FPC is installed. See
the download page for more information (the method changes with almost every
new Xcode and/or Mac OS X release, so the information in this readme is
usually out of date).

There are two methods to install Free Pascal for Mac OS X.

1) Download and install the Mac OS X installer package

2) Install fpc using fink

This second method additionally includes a text mode IDE, which partly works
using XQuartz xterm.


After installing the package, you can write your source code in your favorite
editor (including Project Builder and XCode). To compile something, go to the
directory containing your source files in Terminal and type:

        fpc name_of_your_source_file

The compiler only accepts one file name as argument, but will automatically
search for and compile any units used by the specified source file. Run
"fpc" without any arguments to get an overview of the possible command line
options.


****************************************************************************
* Documentation
****************************************************************************

The documentation is available as HTML pages, PDF, PS, and text although the
recommended format is pdf. The latest PDF version is available on
ftp://ftp.freepascal.org/fpc/dist/docs-pdf/, other formats are available
for download in the directory of the respective distributed release.

NB that there is at present no FPC specific documentation for the platform
specific API (like Win32 system functions, etc.). There is a note in the ftp
/doc explaining where MS help file documenting Win32 API can be obtained,
other platforms (especially Unix-based ones) often come with this
documentation included in system installation.


****************************************************************************
* Suggestions, Help, Bug reporting, snapshots,  ...
****************************************************************************

Suggestions, Help ...
---------------------
e-mail: fpc-devel@lists.freepascal.org (bugs, developer related questions)
e-mail: fpc-pascal@lists.freepascal.org (general pascal related questions)

Both these adresses are for mailing lists. If you're not subscribed,
be sure to mention this fact when sending questions to these lists,
so that people sending answers know about it and send you a copy.
Information about available lists and subscription can be found
on http://lists.freepascal.org/mailman/listinfo

Combined with Lazarus, an IDE for the Free Pascal Compiler:
Web forum: http://forum.lazarus.freepascal.org (all questions)
Wiki: http://wiki.freepascal.org

WWW: http://www.freepascal.org
FTP: ftp://ftp.freepascal.org/fpc
(several mirrors exist, see website for links)

Additional information about mailing lists, news, future plans etc.
can be found on the web site.

SNAPSHOTS & SOURCES
-------------------
One of the features of FPC is the snapshots. These are made daily or weekly
from the developers' latest versions of the source. Snapshots are available
for GO32v2, Win32 and Linux versions. The latest snapshots are in:
ftp://ftp.freepascal.org/fpc/snapshot/ in appropriately named .zip/tar
files.

You will also normally find in the snapshot archive file a readme, with
a note about the latest included changes. It is quite common, though it
doesn't always happen, that when a bug is reported it is fixed and a fixed
version can be obtained the NEXT day in the appropriate snapshot.... yes
really!

Also on the ftp site you'll find a /dist directory, with the latest
distributed releases, a /docs directory, and a /snapshot/<version>/source
directory, in which every night at about 0100 GMT the latest source
generated by the developers during the day & evening before is exported
from SVN into ZIP file fpc.zip.


Making your own snapshots
-------------------------
By downloading the /source files (makefiles are included) it is possible to
make your own version of the fpc compiler/rtl and to modify it. You are of
course free to do this so as long as you observe the licence conditions. In
order to make the compiler/rtl & IDE in a resonable time (eg <30 minutes)
you'll need at least 32 MB of physical memory (64 MB is better), at least
a 200 MHz processor and at least 100 MB of free disk space. You'll also
need some knowledge of makefiles & programming... it is not difficult but
it isn't easy either!

REPORTING BUGS
----------------
If you find a bug in the released version, you may want to try a snapshot
(see SNAPSHOTS above) to see if it has been fixed before reporting it to
the fpc-devel mailing list.

If you find a fault or 'feature' in a release, please report it either
using the bug reporting interface at http://bugs.freepascal.org, or to
the fpc-devel mailing list. PLEASE ALWAYS INCLUDE A COMPILABLE CODE
FRAGMENT that can be used to reproduce the problem (or a link to larger
archive if it cannot be reproduced with small example). Also state the
FPC version, target platform (Win32, Linux, ...), operating system
version (XP, Ubuntu 12.04, ...), the used compiler options and any other
useful info so the developers can reproduce the problem. Otherwise they
may not be able to fix it.


****************************************************************************
* License
****************************************************************************

The compiler and most utilities and executables distributed in this package
fall under the GPL, for more information read the file COPYING.v2.

Some specific utilities and programs come under the license described in
COPYING.v3, COPYING.DJ, COPYING.EMX, COPYING.RSX and licensez.ip.

FPC for JVM comes with some third party tools which are convered by
the following licenses:
  - jasmin.jar comes under the license described in jasminli.txt
  - bcel-6.0-SNAPSHOT.jar comes under the Apache 2.0 license, described by
    apache2.txt

Portions of FPC are based on libffi. See libffi.txt for the license of that
code.

Some of the licenses of the third party tools require to make the source
available. If you cannot find the sources or information where to find
them for a certain tool under such a license included into the FPC
distribution, please contact us through the contact details given
at http://www.freepascal.org/moreinfo.var and we will provide you
the sources or information where to find them.

The documentation, unless otherwise noted, is distributed as free
text, and is distributed under the GNU Library General Public
License as found in file COPYING.

The runtime library, package libraries, free component library, and
other libraries which are used to create executables by the compiler
come under a modified GNU Library General Public license. Additional
information about the library license is found in COPYING.FPC.

License conditions for DPMI provider for GO32v2 version (CWSDPMI.EXE)
can be found in cwsdpmi.txt, sources and/or binary updates may be
downloaded from http://clio.rice.edu/cwsdpmi/.

The DOS version (go32v2) contains some binaries of DJGPP. You can obtain
the full DJGPP package at: http://www.delorie.com/djgpp/

NOTE: OS/2 version of the installer uses the library UNZIP32.DLL from
      Info-ZIP. Info-ZIP's software (Zip, UnZip and related utilities)
      is free and can be obtained as source code or executables from
      Internet/WWW sites, including http://www.info-zip.org.
