# Copyright (c) 1998 by Jonathan Swartz. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package HTML::Mason::Tools;
require 5.004;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(read_file chop_slash html_escape);

use strict;
use IO::File qw(!/^SEEK/);

#
# Return contents of file.
#
sub read_file
{
    my ($file) = @_;
    die "read_file: '$file' does not exist" if (!-e $file);
    die "read_file: '$file' is a directory" if (-d _);
    my $fh = new IO::File $file;
    die "read_file: could not open file '$file' for reading\n" if !$fh;
    local $/ = undef;
    my $text = <$fh>;
    return $text;
}

#
# Remove final slash from string, if any; return resulting string.
#
sub chop_slash
{
    my ($str) = (@_);
    $str =~ s@/$@@;
    return $str;
}

#
# Escape HTML &, >, <, and " characters. Borrowed from CGI::Base.
# Wanted to use HTML::Entities but it interacts badly with Date::Manip
# and mod_perl (mysterious seg faults).
#
sub html_escape
{
    my ($text) = @_;
    my %html_escape = ('&' => '&amp;', '>'=>'&gt;', '<'=>'&lt;', '"'=>'&quot;');
    my $html_escape = join('', keys %html_escape);
    $text =~ s/([$html_escape])/$html_escape{$1}/mgoe;
    return $text;
}
