#!perl

# (C) Siemens Business Services 2001-2002

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	=> 'Devel::ObjectTracker',
    ABSTRACT    => 'Track object life to aid memory leak detection',
    AUTHOR      => 'John Clutterbuck (john.clutterbuck@sbs.siemens.co.uk)',
    PREREQ_PM   => {
		    'Benchmark'  => 0,    #use for tests
		   },
    VERSION_FROM => 'ObjectTracker.pm', # finds $VERSION
);
