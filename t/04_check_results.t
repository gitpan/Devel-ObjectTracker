#!perl

#check results

use Benchmark;

my $output;

my $dbg = 0;
open (DBG,">test_dbg") if $dbg;

sub ok
{
    my ($no, $ok) = @_ ;

    #add to the output - print at end
    my $isok = $ok ? "ok $no\n" : "not ok $no\n";
    $output .= $isok;
    print DBG $isok if $dbg;
}

my $nOk;

#process the log file - which should have 9 lines inc header
{
    local $^W = 0;
    ok(++$nOk,open(LOG,"<test.log"));
    my $num;
    while (my $log = <LOG>) {
	++$num;
	print DBG $log if $dbg;
	chomp $log;
	my ($ObjectNo,$DateTime,$Session,$Sub,$Source,$Position,$Class,$Ref,$Exists,$CrDateTime,$CrSession,$Stack,$CrStack) = split(',',$log);
	#line 1 should be a header
	if ($num == 1) {
	    ok(++$nOk,($log eq 'ObjectNo,DateTime,Session,Sub,Source,Position,Class,Ref,Exists,CrDateTime,CrSession,Stack,CrStack'));
	}
	else {
	    
	    print DBG "Check sessions nos\n" if $dbg;
	    
	    #lines 2,3 in Session 1
	    if ($num == 2 or $num == 3 ) {
		ok(++$nOk,($DateTime and $Session == 1));
	    }
	    # 4 & 5 session 2
	    elsif ($num == 4 or $num == 5 ) {
		ok(++$nOk,($DateTime and $Session == 2));
	    }
	    # 6 = session 3
	    elsif ($num == 6 or $num == 7 ) {
		ok(++$nOk,($DateTime and $Session == 3));
	    }
	    #remainder session 4
	    else {
		ok(++$nOk,($DateTime and $Session == 4));
	    }

	    print DBG "Check subs num=$num Sub=$Sub Source=$Source Position=$Position CrSession=$CrSession Ref=$Ref Class=$Class Stack=".($Stack and 1)." CrStack=".($CrStack and 1)."\n" if $dbg;

	    #lines 2,3 should be objects 1 and 2 in Benchmark::new
	    if ($num == 2 or $num == 3) {
		ok(++$nOk,($ObjectNo == $num-1 and $Sub eq 'Benchmark::new' and $Source eq 'Ret' 
			   and $Position == 1 and $Class eq 'Benchmark' and $Ref =~ /^Benchmark=/ and $Stack));
	    }
	    #lines 5 should be objects 3 in Benchmark::new
	    elsif ($num == 5) {
		ok(++$nOk,($ObjectNo == $num-2 and $Sub eq 'Benchmark::new' and $Source eq 'Ret' 
			   and $Position == 1 and $Class eq 'Benchmark' and $Ref =~ /^Benchmark=/ and $Stack));
	    }
	    #lines 7 should be objects 4 in Benchmark::new
	    elsif ($num == 7) {
		ok(++$nOk,($ObjectNo == $num-3 and $Sub eq 'Benchmark::new' and $Source eq 'Ret' 
			   and $Position == 1 and $Class eq 'Benchmark' and $Ref =~ /^Benchmark=/ and $Stack));
	    }
	    # all others should be NO_DESTRUCTOR
	    else {
		ok(++$nOk,($Sub eq 'NO_DESTRUCTOR' and $Source eq 'DES' 
			   and not $Position and $CrDateTime 
			   and $CrSession and $Class eq 'Benchmark' and $Ref =~ /^Benchmark=/ and $Stack and $CrStack));
	    }
	}
    }
    #should be 9 lines
    ok(++$nOk,($num == 9));
}

#there shoudl not be a details 1 file
ok(++$nOk,(not -f "<test_details_1.csv"));

#process the details 2 file - which should have 3 lines inc header
{
    local $^W = 0;
    print DBG "\ntest_details_2.csv\n" if $dbg;

    ok(++$nOk,open(DET2,"<test_details_2.csv"));
    my $num;
    while (my $det2 = <DET2>) {
	++$num;
	print DBG $det2 if $dbg;
	chomp $det2;
	my ($CrObjectNo,$CrDateTime,$CrSession,$CrSub,$CrSource,$CrPosition,$CrClass,$CrRef,$CrStack) = split(',',$det2);
	#line 1 should be a header
	if ($num == 1) {
	    ok(++$nOk,($det2 eq 'CrObjectNo,CrDateTime,CrSession,CrSub,CrSource,CrPosition,CrClass,CrRef,CrStack'));
	}
	#we expect line 2 to have object 2 (1 is already destroyed)
	elsif ($num == 2) {
	    
	    ok(++$nOk,($CrObjectNo == 2 and $CrDateTime and $CrSession == 1 
		       and $CrSub eq 'Benchmark::new' and $CrSource eq 'Ret' 
		       and $CrPosition == 1 and $CrClass eq 'Benchmark' and $CrRef =~ /^Benchmark=/ and $CrStack));
	}
	#we expect line 3 to have object 3
	elsif ($num == 3) {
	    
	    ok(++$nOk,($CrObjectNo == 3 and $CrDateTime and $CrSession == 2 
		       and $CrSub eq 'Benchmark::new' and $CrSource eq 'Ret' 
		       and $CrPosition == 1 and $CrClass eq 'Benchmark' and $CrRef =~ /^Benchmark=/ and $CrStack));
	}
    }
    #should be 3 lines
    ok(++$nOk,($num == 3));
}

#process the details 3 file - which should have 3 lines inc header
{
    local $^W = 0;
    print DBG "\ntest_details_3.csv\n" if $dbg;
    ok(++$nOk,open(DET3,"<test_details_3.csv"));
    my $num;
    while (my $det3 = <DET3>) {
	++$num;
	print DBG $det3 if $dbg;
	chomp $det3;
	my ($CrObjectNo,$CrDateTime,$CrSession,$CrSub,$CrSource,$CrPosition,$CrClass,$CrRef,$CrStack) = split(',',$det3);
	#line 1 should be a header
	if ($num == 1) {
	    ok(++$nOk,($det3 eq 'CrObjectNo,CrDateTime,CrSession,CrSub,CrSource,CrPosition,CrClass,CrRef,CrStack'));
	}
	#we expect line 2 to have object 3
	elsif ($num == 2) {
	    
	    ok(++$nOk,($CrObjectNo == 3 and $CrDateTime and $CrSession == 2 
		       and $CrSub eq 'Benchmark::new' and $CrSource eq 'Ret' 
		       and $CrPosition == 1 and $CrClass eq 'Benchmark' and $CrRef =~ /^Benchmark=/ and $CrStack));
	}
	#we expect line 3 to have object 4
	elsif ($num == 3) {
	    
	    ok(++$nOk,($CrObjectNo == 4 and $CrDateTime and $CrSession == 3
		       and $CrSub eq 'Benchmark::new' and $CrSource eq 'Ret' 
		       and $CrPosition == 1 and $CrClass eq 'Benchmark' and $CrRef =~ /^Benchmark=/ and $CrStack));
	}
     }
    #should be 3 lines
    ok(++$nOk,($num == 3));
}

#print the results
print "1..$nOk\n$output" ;

#clear out any files that could exist
unlink qw(ObjectTracker.log .objecttracker test_details_1.csv test.log test_details_2.csv test_details_3.csv test_dbg) unless $dbg;

#eof
