#!perl

print "1..1\n" ;

#clear out any files that could exist and upset tests
unlink qw(ObjectTracker.log .objecttracker test_details_1.csv test.log test_details_2.csv test_details_3.csv);

print "ok 1\n";

exit 0;

#eof
