#!perl -d:ObjectTracker

#test object life

use Benchmark;

sub ok
{
    my ($no, $ok) = @_ ;

    print $ok ? "ok $no\n" : "not ok $no\n";
}

print "1..5\n" ;



#create 2 objects in session 1
my $t1=new Benchmark;
my $t2=create_object();

#$Devel::ObjectTracker::verbose  = 3;

#increment session independantly and check it is now 2
Devel::ObjectTracker::increment_session();
ok(1,$Devel::ObjectTracker::nSess == 2);

#drop 1st object and create 3rd object in session 2
undef $t1;
my $t3=new Benchmark;

#output the details, check the file has been created and check session is now 3
Devel::ObjectTracker::output_details();
ok(2,-f "test_details_2.csv");
ok(3,$Devel::ObjectTracker::nSess == 3);

undef $t2;

#create 4th object in session 3
my $t4=new Benchmark;

#output the details, check the file has been created and check session is now 4
Devel::ObjectTracker::output_details();
ok(4,-f "test_details_3.csv");
ok(5,$Devel::ObjectTracker::nSess == 4);

sub create_object {
    my $t=new Benchmark;
    return $t;
}

#eof
