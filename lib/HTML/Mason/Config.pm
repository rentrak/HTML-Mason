# Copyright (c) 1998 by Jonathan Swartz. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# ----------------------------
# DBM file class
# Uncomment one pair of lines below to choose your DBM file type.
# ----------------------------

use MLDBM;                           	# defaults for SDBM/Data::Dumper
$HTML::Mason::DBM_FILE_EXT = '.pag';	# this for file locking

# use MLDBM qw(DB_File Storable);       # this is the fastest, most
# $HTML::Mason::DBM_FILE_EXT = '';		# flexible combination

# use MLDBM qw(DB_File Data::Dumper);	# other combinations ...
# $HTML::Mason::DBM_FILE_EXT = '';      

# use MLDBM qw(GDBM_File FreezeThaw);
# $HTML::Mason::DBM_FILE_EXT = '';
