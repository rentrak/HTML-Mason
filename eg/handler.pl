#!/usr/bin/perl
package HTML::Mason;

#
# Sample Mason handler. At a minimum, set comp_root and data_dir.
#
use HTML::Mason;
use strict;

# List of symbol-importing modules (see Admin manual for details)
#{  package HTML::Mason::Commands;
#   use CGI;
#}

# Create Mason objs and handler within HTML::Mason package
#
my $parser = new HTML::Mason::Parser;
my $interp = new HTML::Mason::Interp (parser=>$parser,
                                      comp_root=>'<component root>',
                                      data_dir=>'<data directory>');
my $ah = new HTML::Mason::ApacheHandler (interp=>$interp);

# Activate the following if running httpd as root (the normal case).
# Resets ownership of all files created by Mason at startup. Change
# these to match your server's 'User' and 'Group'.
#
#chown ( [getpwnam('nobody')]->[2], [getgrnam('nobody')]->[2],
#        $interp->files_written );

sub handler
{
    my ($r) = @_;
    $ah->handle_request($r);
}

1;
