#!perl -d:ObjectTracker

#test local settings params

sub ok
{
    my ($no, $ok) = @_ ;

    print $ok ? "ok $no\n" : "not ok $no\n";
}

print "1..7\n" ;

# check basic values are initialised
#===========

ok(1, $Devel::ObjectTracker::log_file eq "test.log") ;

ok(2, $Devel::ObjectTracker::details_file eq "test_details_<NN>.csv") ;

ok(3, ($Devel::ObjectTracker::objects_only == 0 and $Devel::ObjectTracker::verbose ==0) );

ok(4, $Devel::ObjectTracker::bol   eq "" );
ok(5, $Devel::ObjectTracker::delim eq ",");
ok(6, $Devel::ObjectTracker::eol   eq "\n");

# check log file exists
ok(7, -f $Devel::ObjectTracker::log_file);

#eof
