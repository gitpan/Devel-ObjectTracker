#!perl -d:ObjectTracker

#test basic params

sub ok
{
    my ($no, $ok) = @_ ;

    print $ok ? "ok $no\n" : "not ok $no\n";
}

print "1..6\n" ;

# check basic values are initialised
#===========

ok(1, $Devel::ObjectTracker::VERSION > 0);

ok(2, $Devel::ObjectTracker::log_file) ;

ok(3, $Devel::ObjectTracker::details_file) ;

ok(4, ($Devel::ObjectTracker::enable and $Devel::ObjectTracker::print_header));

# check log file exists
ok(5, -f $Devel::ObjectTracker::log_file) ;

my $settings = '
$Devel::ObjectTracker::objects_only = 0;
$Devel::ObjectTracker::log_file     = "test.log";
$Devel::ObjectTracker::details_file = "test_details_<NN>.csv";
$Devel::ObjectTracker::bol      = "";
$Devel::ObjectTracker::delim    = ",";
$Devel::ObjectTracker::eol      = "\n";
$Devel::ObjectTracker::verbose  = 0;
';

# create an .objecttracker file for the next test
ok(6, (open(LOCAL,">.objecttracker") and print (LOCAL $settings) and close(LOCAL)));

#eof
