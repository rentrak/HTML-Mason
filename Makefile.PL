use ExtUtils::MakeMaker;
require 5.004;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'HTML::Mason',
    'VERSION_FROM' => 'lib/HTML/Mason.pm', # finds $VERSION
    'PREREQ_PM' => { Apache::Constants => 1.08, Date::Manip => 5.31,
                    MLDBM => 2.0, CGI::Base => 2.76, Data::Dumper => 2.081,
                    File::Recurse => 2.0, File::lockf => 0.15,
                    HTML::Entities => 1.11 }
);
