# Copyright (c) 1998 by Jonathan Swartz. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package HTML::Mason::Utils;
require 5.004;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(access_data_cache);

use strict;
use IO::File qw(!/^SEEK/);
use POSIX;
use Fcntl;
use File::lockf;
use HTML::Mason::Config;
use Date::Manip;

sub access_data_cache
{
    my (%options) = @_;

    #
    # Defaults
    #
    my $cacheFile = $options{cache_file} || die "cache: must specify cache file";
    my $physFile = $cacheFile . $HTML::Mason::DBM_FILE_EXT;
    my $action = $options{action} || 'retrieve';
    my $key = $options{key} || 'main';
    my $memCache = $options{memory_cache};
    my $time = time();
    my $path = $cacheFile;

    #
    # Store / expire
    #
    if ($action eq 'store' || $action eq 'expire') {
	my ($expireTime,%out);
	die "no store value provided" if ($action eq 'store' && !exists($options{value}));

	#
	# Validate parameters
	#
	if (my @invalids = grep(!/^(expire_(at|next|in)|action|key|value|memory_cache|cache_file)$/,keys(%options))) {
	    die "cache: invalid parameter '$invalids[0]' for action '$action'\n";
	}
	
	#
	# Determine expiration time if expire flag given
	#
	if (exists($options{expire_at})) {
	    $expireTime = ParseDate($options{expire_at});
	    die "cache: invalid expire_at value '$options{expire_at}' - must be a valid date\n" if !$expireTime;
	} elsif (exists($options{expire_next})) {
	    my $term = $options{expire_next};
	    if ($term eq 'hour') {
		my $hour = UnixDate('now','%H');
		my $nextHour = ($hour+1)%24;
		$expireTime = Date_GetNext('now',undef,1,"$nextHour:00:01");
	    } elsif ($term eq 'day') {
		$expireTime = Date_GetNext('now',undef,1,'00:00:01');
	    } else {
		die "cache: invalid expire_next value '$term' - must be 'hour' or 'day'\n";
	    }
	} elsif (exists($options{expire_in})) {
	    my $delta = $options{expire_in};
	    $delta = "+".$delta if substr($delta,0,1) ne '+';
	    $delta = ParseDateDelta($delta);
	    die "cache: invalid expire_in value '$options{expire_in}' - must be a valid date delta\n" if !$delta;
	    $expireTime = ParseDate(scalar(DateCalc('now',$delta)));
	}
	$expireTime = UnixDate($expireTime,'%s');

	#
	# Create dump version of store value
	# MS 7/16/98: No longer needed under MLDBM
	#
	#	my $d = new Data::Dumper ([$options{value}]);
	#	$d->Indent(0);
	#	$d->Purity(1);
	#	my $dump = $d->Dumpxs();
	#	$dump =~ s/\$VAR1\s*=\s*/return /;

	#
	# Create DB file if necessary
	# MS 7/16/98: Shouldn't need the following if we trap tie later
	#
	#if (!-e $physFile) {
	#    my %new;
	#    tie (%new, 'MLDBM', $cacheFile, O_RDWR|O_CREAT, 0664);
	#    untie(%new);
	#}
	#die "cache: cannot create cache file '$cacheFile'\n"
	#	if (!-f $physFile);

	tie (%out, 'MLDBM', $cacheFile, O_RDWR|O_CREAT, 0664)
		or die "cache: cannot create/open cache file '$cacheFile'\n";

	#
	# Try to get lock on DB file. If not possible, return.
	#
	my $outfh = new IO::File "<$physFile" or die "cache: cannot open cache file '$physFile' for locking\n";
	return if (File::lockf::tlock($outfh) == EAGAIN);

	if ($action eq 'store') {
	    $out{"$key.contents"} = $options{value};
	    $out{"$key.expires"} = $expireTime;
	    $out{"$key.lastmod"} = $time;
	    if (defined($memCache)) {
		$memCache->{$path}->{$key} = {expires=>$expireTime,lastModified=>$time,lastUpdated=>$time,contents=>$options{value}};
	    }
	} elsif ($action eq 'expire') {
	    delete($out{"$key.contents"});
	    delete($out{"$key.expires"});
	    delete($out{"$key.lastmod"});
	    if (defined($memCache)) {
		delete($memCache->{$path}->{$key});
	    }
	}
	# this line causes a bizarre untie/eval bug
	untie(%out);
	$outfh->close();

    #
    # Retrieve
    #
    } elsif ($action eq 'retrieve') {
	return undef if (!(-e $physFile));
	my $fileLastModified = [stat($physFile)]->[9];
	my $mem;

	#
	# Validate parameters
	#
	if (my @invalids = grep(!/^(expire_(if|if_older_than)|action|key|memory_cache|cache_file)$/,keys(%options))) {
	    die "cache: invalid parameter '$invalids[0]' for action '$action'\n";
	}
	
	if (defined($memCache)) {
	    if (!exists($memCache->{$path}->{$key})) {
		$memCache->{$path}->{$key} = {lastUpdated=>0};
	    }
	    $mem = $memCache->{$path}->{$key};
	} else {
	    $mem = {lastUpdated=>0};
	}

	#
	# If file has been modified since we last updated, then
	# our entry may be modified - check it.
	#
	if ($fileLastModified > $mem->{lastUpdated}) {
	    my %in;
	    tie (%in, 'MLDBM', $cacheFile, O_RDONLY, 0);

	    #
	    # If entry has been modified since we last updated, read
	    # it into memory.
	    #
	    my $entryLastModified = $in{"$key.lastmod"};
	    if (defined($entryLastModified) and
			$entryLastModified > $mem->{lastUpdated}) {
		$mem->{contents} = $in{"$key.contents"};
		$mem->{expires} = $in{"$key.expires"};
		$mem->{lastModified} = $in{"$key.lastmod"};
		$mem->{lastUpdated} = $time;
	    }
	    untie(%in);
	}

	#
	# If cache entry has expired, return undef. Otherwise return contents.
	#
	return undef if ($mem->{expires} && $time >= $mem->{expires});
	if (exists($options{expire_if})) {
	    my $sub = $options{expire_if};
	    return undef if (&$sub(key=>$key,lastModified=>$mem->{lastModified}));
	}
	if (exists($options{expire_if_older_than})) {
	    my $compareTime = $options{expire_if_older_than};
	    return undef if ParseDate(scalar(localtime($mem->{lastModified}))) le $compareTime;
	}
	return $mem->{contents};
    } else {
	die "cache: bad action '$options{action}': must be one of 'store', 'retrieve', or 'expire'\n";
    }
}
