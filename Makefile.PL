use ExtUtils::MakeMaker;
require 5.004;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'HTML::Mason',
    'VERSION_FROM' => 'lib/HTML/Mason.pm', # finds $VERSION
    'PREREQ_PM' => { Apache::Constants => 1.06, Date::Manip => 5.31,
                    MLDBM => 2.0, Data::Dumper => 2.08,
                    File::Recurse => 2.0, HTML::Entities => 1.11 }
);
