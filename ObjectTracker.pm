#!perl

# (C) Siemens Business Services 2001-2002

#core DB subs to track the activity

package DB;
sub DB {}

sub sub {

    use vars '$sub';

    local $SIG{__DIE__} = 'IGNORE';
    local $SIG{__WARN__} = 'IGNORE';
    no strict 'refs';
    local $^W = 0; #stop -winge

    my @aArgs=@_;
    my ($bRet,$sRet,@aRet)='';
    my ($mem,$src,$class);

    #get the subname from the global var set by perl
    my $subname = $sub;

    my ($sec,$min,$hour,$mday,$mon,$year) = localtime;
    my $dtime = sprintf('%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d',$year+1900,$mon+1,$mday,$hour,$min,$sec);
    #look for destroy subs
    if ($subname =~ /DESTROY$/) {

	#check if the ObjectTracker UNIVERSAL::DESTROY
	if ($subname eq 'UNIVERSAL::DESTROY' and $Devel::ObjectTracker::hide_ot) {
	    my ($pack,$file,$line,$sub) = caller(0);
	    #print " caller= ".join(' ',($pack,$file,$line,$sub))."\n" if ($Devel::ObjectTracker::verbose > 2);
	    $subname = 'NO_DESTRUCTOR' if ($sub eq '(eval)' or $file =~ /ObjectTracker.pm$/);
	}
	
	my ($oseq,$csrc,$cid,$cref,$cstack,$ex,$osub,$stack,$cdtime,@aCinfo,$pos,$cpos);
	my $val = $aArgs[0];
	my $ref="$val";
	$class=ref $val;
	my $src='DES';
	print "$Devel::ObjectTracker::nSess\t***\t$subname\t$class\t$ref\n" if ($Devel::ObjectTracker::verbose > 2);
	#look for memory ref
	if ($ref =~ /^(?:[A-Za-z0-9:_]+\=)?(?:HASH|ARRAY|GLOB)\((0x[a-f0-9]+)\)/ ) {
	    $mem = $1;
	    
	    if ( $mem and $class and $class !~ /$Devel::ObjectTracker::class_exclude/
		 and $class =~ /$Devel::ObjectTracker::class_match/ ) {
		if (exists $Devel::ObjectTracker::aObjects{$mem} ) {
		    $ex = 'Y';
		    ($oseq,$cid,$csrc,$osub,$class,$cref,$cstack,$cdtime,$cpos) = @{$Devel::ObjectTracker::aObjects{$mem}};
		    #delete from current objects but save in buffer
		    delete $Devel::ObjectTracker::aObjects{$mem};

		    #stick this onto the beginning and remember it
		    splice (@Devel::ObjectTracker::aDestroy_cache,0,0,$mem);
		    $Devel::ObjectTracker::aDestroy_cache{$mem} = $dtime;

		    #trim old stuff out of cache
		    map {delete $Devel::ObjectTracker::aDestroy_cache{$_} } splice (@Devel::ObjectTracker::aDestroy_cache,$Devel::ObjectTracker::nDestroy_save,$Devel::ObjectTracker::nDestroy_save);

		    
		}
		else {
		    $ex = 'N';
		}
		#compute the stack
		my ($stack) = Devel::ObjectTracker::_get_stack();
		
		
		print Devel::ObjectTracker::OTLOG $Devel::ObjectTracker::bol.
		  join($Devel::ObjectTracker::delim,
		       $oseq,$dtime,$Devel::ObjectTracker::nSess,$subname,$src,$pos,$class,$ref,$ex,$cdtime,$cid,$stack,$cstack).
			 $Devel::ObjectTracker::eol; 
		print sprintf($Devel::ObjectTracker::stdout_format,$Devel::ObjectTracker::nSess,$subname,$src,$pos,$ex,$ref) if ($Devel::ObjectTracker::verbose > 1);
		
	    }
	}
	
	#call the sub
	if (wantarray) {
	    @aRet = &$sub;
	} else {
	    $bRet = 1;
	    if (defined wantarray) {
		$sRet = &$sub;
	    } else {
		&$sub; undef $sRet;
	    }
	}
    }
    #else run the sub and look for objects returned or processed
    else {
	#call the sub
	if (wantarray) {
	    @aRet = &$sub;
	} else {
	    $bRet = 1;
	    if (defined wantarray) {
		$sRet = &$sub;
		@aRet = ($sRet);
	    } else {
		&$sub; undef $sRet;
	    }
	}

	#check for pattern match
	if ($Devel::ObjectTracker::enable and $subname =~ /$Devel::ObjectTracker::sub_match/ ) {
	    
	    my $nArgs = @aArgs;
	    my $nRet = @aRet;
	    print "$Devel::ObjectTracker::nSess\t***\t$subname Args=$nArgs Ret=$nRet\n" if ($Devel::ObjectTracker::verbose > 2);
	    my ($ex,$stack,$bDestructor);
	    
	    #first process all the args
	    my $pos=0;
	    foreach my $val (@aArgs) {
		++$pos;
		if (defined $val) {
		    my $ref = "$val";
		    
		    #look for memory ref
		    if ($ref =~ /^(?:[A-Za-z0-9:_]+\=)?(?:HASH|ARRAY|GLOB)\((0x[a-f0-9]+)\)/) {
			$mem = $1;
			$src='Arg';
			$class=ref $val;
			
			#check for valid ememory reference that should be tracked
			if ($mem and $class and $class !~ /$Devel::ObjectTracker::class_exclude/
			    and $class =~ /$Devel::ObjectTracker::class_match/) {

			    #check if this is a new unseen reference
			    if ( not exists $Devel::ObjectTracker::aObjects{$mem} 
				 and not exists $Devel::ObjectTracker::aDestroy_cache{$mem}
			       ) {
				
				#get the stack details
				($stack,$bDestructor) = Devel::ObjectTracker::_get_stack() unless $stack;
				my $oseq;
				#check if destructor
				if ( $bDestructor ) {
				    $ex='de';
				} else {
				    #add the new object to the hash
				    $oseq = ++$Devel::ObjectTracker::oseq;
				    $Devel::ObjectTracker::aObjects{$mem} = [$oseq,$Devel::ObjectTracker::nSess,$src,$subname,$class,$ref,$stack,$dtime,$pos];
				}
				
				print sprintf($Devel::ObjectTracker::stdout_format,$Devel::ObjectTracker::nSess,$subname,$src,$pos,$ex,$ref) if ($Devel::ObjectTracker::verbose > 1);
				print Devel::ObjectTracker::OTLOG $Devel::ObjectTracker::bol.
				  join($Devel::ObjectTracker::delim,
				       $oseq,$dtime,$Devel::ObjectTracker::nSess,$subname,$src,$pos,$class,$ref,$ex,'','',$stack,'').
					 $Devel::ObjectTracker::eol; 
			    }
			}
		    }
		}
	    }
	    
	    #now process all the return values
	    $pos=0;
	    foreach my $val (@aRet) {
		++$pos;
		if (defined $val) {
		    my $ref = "$val";
		    
		    #look for memory ref
		    if ($ref =~ /^(?:[A-Za-z0-9:_]+\=)?(?:HASH|ARRAY|GLOB)\((0x[a-f0-9]+)\)/) {
			$mem = $1;
			$src='Ret';
			$class=ref $val;
			
			#save the details
			if ($mem and $class and $class !~ /$Devel::ObjectTracker::class_exclude/
			    and $class =~ /$Devel::ObjectTracker::class_match/
			    and not exists $Devel::ObjectTracker::aObjects{$mem} ) {
			    #get the stack details
			    ($stack,$bDestructor) = Devel::ObjectTracker::_get_stack() unless $stack;
			    my $oseq;
			    if ( $bDestructor ) {
				$ex='de';
			    } else {
				#add the new object to the hash
				$oseq=++$Devel::ObjectTracker::oseq;
				$Devel::ObjectTracker::aObjects{$mem} = [$oseq,$Devel::ObjectTracker::nSess,$src,$subname,$class,$ref,$stack,$dtime,$pos];
			    }
			    print sprintf($Devel::ObjectTracker::stdout_format,$Devel::ObjectTracker::nSess,$subname,$src,$pos,$ex,$ref) if ($Devel::ObjectTracker::verbose > 1);
			    print Devel::ObjectTracker::OTLOG $Devel::ObjectTracker::bol.
			      join($Devel::ObjectTracker::delim,
				   $oseq,$dtime,$Devel::ObjectTracker::nSess,$subname,$src,$pos,$class,$ref,$ex,'','',$stack,'').
				     $Devel::ObjectTracker::eol; 
			}
		    }
		}
	    }
	}
    }
    
    #return the values
    if ($bRet) {
	return $sRet;
    } else {
	return @aRet;
    }
}

#package distinct subs
package Devel::ObjectTracker;

use strict;

#initialisation
BEGIN {
    $Devel::ObjectTracker::VERSION = '0.4';

    %Devel::ObjectTracker::aObjects=();
    @Devel::ObjectTracker::aDestroy_cache=();
    %Devel::ObjectTracker::aDestroy_cache=();
    $Devel::ObjectTracker::nDestroy_save=200;
    $Devel::ObjectTracker::nSess = 0;
    $Devel::ObjectTracker::oseq = 0;
    $Devel::ObjectTracker::hide_ot = 1;
    $Devel::ObjectTracker::enable = 1;

    $Devel::ObjectTracker::verbose = 1;
    $Devel::ObjectTracker::sub_match = '.';
    $Devel::ObjectTracker::class_exclude = '(HASH|ARRAY|GLOB)';
    $Devel::ObjectTracker::class_match = '.';
    $Devel::ObjectTracker::delim = "\t";
    $Devel::ObjectTracker::bol='';
    $Devel::ObjectTracker::eol = "\n";
    $Devel::ObjectTracker::log_file = 'ObjectTracker.log';
    $Devel::ObjectTracker::details_file = 'ObjectTracker_details_<NN>.txt';
    $Devel::ObjectTracker::stack_format = '<FILE>(<CALLSUB>) l=<LINE>';
    $Devel::ObjectTracker::stack_delim = '; ';
    $Devel::ObjectTracker::print_header = 1;
    $Devel::ObjectTracker::stdout_format = " %-3d %-37s%-3s %-2d%-2s %s\n";

    if (-f '.objecttracker') {
	do '.objecttracker';
    }


}

#start the session
Devel::ObjectTracker::increment_session();
print "ObjectTracker creating log file:$Devel::ObjectTracker::log_file sub_match=/$Devel::ObjectTracker::sub_match/ class_exclude=/$Devel::ObjectTracker::class_exclude/ class_match=/$Devel::ObjectTracker::class_match/ verbose=$Devel::ObjectTracker::verbose\n" if $Devel::ObjectTracker::verbose;

open(Devel::ObjectTracker::OTLOG,"> $Devel::ObjectTracker::log_file") or die "Cannot create $Devel::ObjectTracker::log_file Err=$!\n";
print Devel::ObjectTracker::OTLOG $Devel::ObjectTracker::bol.
  join($Devel::ObjectTracker::delim, qw(ObjectNo DateTime Session Sub Source Position Class Ref Exists CrDateTime CrSession Stack CrStack)).$Devel::ObjectTracker::eol if $Devel::ObjectTracker::print_header; 

sub increment_session {
    ++$Devel::ObjectTracker::nSess;
    print "ObjectTracker Session ID for future objects=$Devel::ObjectTracker::nSess\n" if $Devel::ObjectTracker::verbose;
};

sub output_details {
    use strict;
    my $msg = shift;

    my $file=$Devel::ObjectTracker::details_file;
    $file =~ s/<[N]+>/$Devel::ObjectTracker::nSess/g;

    print "ObjectTracker outputting details to:$file... " if $Devel::ObjectTracker::verbose;
    my $nObjects;
    if (open(OBRES,">$file")) {
	print OBRES $Devel::ObjectTracker::bol.
	  join($Devel::ObjectTracker::delim, qw(CrObjectNo CrDateTime CrSession CrSub CrSource CrPosition CrClass CrRef CrStack)).
	    $Devel::ObjectTracker::eol if $Devel::ObjectTracker::print_header; 

	#sort by creation order
	my @aCurrent = sort {@{$Devel::ObjectTracker::aObjects{$a}}[0] <=> @{$Devel::ObjectTracker::aObjects{$b}}[0] } keys %Devel::ObjectTracker::aObjects;
	foreach my $mem (@aCurrent) {
	    $nObjects++;
	    my ($oseq,$cid,$src,$sub,$class,$ref,$cstack,$cdtime,$pos) = @{$Devel::ObjectTracker::aObjects{$mem}};
	    print OBRES $Devel::ObjectTracker::bol.
	      join($Devel::ObjectTracker::delim,
		   $oseq,$cdtime,$cid,$sub,$src,$pos,$class,$ref,$cstack).
		     $Devel::ObjectTracker::eol; 
	}
	close (OBRES);
	print "found $nObjects objects in existence\n" if $Devel::ObjectTracker::verbose;
    }
    else {
	print STDERR "Cannot create details file:$file Err=$!\n";
    }
    log_checkpoint($msg) if $msg;

    #increment session for next time
    increment_session();
}

sub log_checkpoint {
    my $msg = shift;

    #compute the stack
    my ($stack) = Devel::ObjectTracker::_get_stack();
    
    my ($sec,$min,$hour,$mday,$mon,$year) = localtime;
    my $dtime = sprintf('%4.4d-%2.2d-%2.2d %2.2d:%2.2d:%2.2d',$year+1900,$mon+1,$mday,$hour,$min,$sec);

    print "ObjectTracker checkpoint msg=$msg\n" if $Devel::ObjectTracker::verbose;
    print Devel::ObjectTracker::OTLOG $Devel::ObjectTracker::bol.
      join($Devel::ObjectTracker::delim,
	   '*checkpoint*',$dtime,$Devel::ObjectTracker::nSess,$msg,'','','','','','','',$stack,'').
	     $Devel::ObjectTracker::eol; 
    return 1;
}

sub _get_stack {
    my (@main_stack,@stack,$bDestructor);

    #get the stack
    my $i=0;
    while (my @cinfo = caller($i++)) {
	push @main_stack,[@cinfo];
    }
   my $level;
  STACK:
    for ($level = 0; $level <= $#main_stack; $level++) {
	my ($pack,$file,$line,$sub,$hasargs,$wantarray) = @{$main_stack[$level]};

	$bDestructor = 1 if ($sub =~ /DESTROY$/);

	my $callsub= $level < $#main_stack ? (@{$main_stack[$level+1]})[3] : 'main';
	#print " caller=$level ".join(' ',($pack,$file,$line,$callsub,$sub,$hasargs,$wantarray))."\n" if ($Devel::ObjectTracker::verbose > 2);
	unless ($Devel::ObjectTracker::hide_ot and $file =~ /ObjectTracker.pm$/) {
	    #format the stack line
	    my $stack_line=$Devel::ObjectTracker::stack_format;
	    $stack_line =~ s/<LEVEL>/$level/gme;
	    $stack_line =~ s/<PACK>/$pack/gme;
	    $stack_line =~ s/<FILE>/$file/gme;
	    $stack_line =~ s/<LINE>/$line/gme;
	    $stack_line =~ s/<CALLSUB>/$callsub/gme;
	    $stack_line =~ s/<SUBNAME>/$sub/gme;
	    $stack_line =~ s/<HASARGS>/$hasargs/gme;
	    $stack_line =~ s/<WANTARRAY>/$wantarray/gme;
	    push @stack,$stack_line;
	}
    }
    my $stack = join($Devel::ObjectTracker::stack_delim,@stack);
    #print "stack=$stack\n" if ($Devel::ObjectTracker::verbose > 2);
    return ($stack,$bDestructor);
}

#universal::DESTROY to catch objects without destructors
package UNIVERSAL;
sub DESTROY {
}


__END__

=head1 NAME

Devel::ObjectTracker - Track object life to detect memory leaks

=head1 SYNOPSIS

  perl5 -d:ObjectTracker test.pl

=head1 DESCRIPTION

Debug module to find where perl objects (or arrays, hashes and globs) are created 
by checking for objects passed to and/or returned from subs, 
and monitoring when they are destroyed via destructor subs. 
This can help detect memory leaks caused by objects being left behind in your programs when they shouldn't be.

The main output is stored in a file which logs the first time a memory reference is seen with datetime, current session number (starts at 1),
object type, call stack etc., and whether the object was first seen returned from a sub or passed as an argument.
Details are also logged whenever an object is destroyed. This includes the datetime, session and call stack when the object was created.

The subroutine B<Devel::ObjectTracker::output_details> outputs details on the currently existing objects on demand.
These details contain date/time, session, call stack, etc. when the object was created.

=head1 EXAMPLES

When started ObjectTracker will output all object creation/destruction in the
log file I<ObjectTracker.log> with a session ID of 1.

At a suitable point in your prog the sub B<Devel::ObjectTracker::output_details> should be called
which will output a list of all current objects to a file I<ObjectTracker_details_1.txt> and then 
it will increment the session ID to 2.

You should then carry out the operations being studied. All object creation/destruction will now be recorded
in the log file with session ID of 2.

After the operation you should call B<Devel::ObjectTracker::output_details> again.
This will output a list of all current objects to a file I<ObjectTracker_details_2.txt> and then 
it will increment the session ID to 3.

A look at the details file I<ObjectTracker_details_2.txt> will show any objects that were created during sessions 1 and 2.
From the date/time, session and call stack you can see when and where they were created.
This can highlight objects which are still in existence and shouldn't be.

Multiple sessions can be used to good effect in complex programs either with output each time as above or
separately incremented using the sub B<Devel::ObjectTracker::increment_session>

=head1 OPTIONS

ObjectTracker has some variables which can be used during your script to affect what
gets tracked.

=over 4

=item *

By default it will look for new objects in all subs.
C<$Devel::ObjectTracker::sub_match> can be used to defined a subroutine name pattern within which
to look for new objects. Note it will always check for destructors (=~ /DESTROY$/).

=item *

By default it will look for objects of all classes.
C<$Devel::ObjectTracker::class_match> can be used to defined a class name pattern.

=item *

C<$Devel::ObjectTracker::class_exclude> is used to refine the class selection.
By default this is set to I<(HASH|ARRAY|GLOB)> to exclude hashes, arrays and globs.
If set to '' (blank) hashes, arrays and globs will be included.

Note this takes precedence over the matching.

=item *

The output to STDOUT can be adjusted by changing C<$Devel::ObjectTracker::verbose> as follows:

 0 = print nothing
 1 = print file creation, session ID etc.   (default)
 2 = print summary details upon object creation/destruction 
 3 = print subroutine calls as well as object details 

=item *

The log file name can be changed by setting C<$Devel::ObjectTracker::log_file>.
The default is I<ObjectTracker.log> in the current directory.

=item *

The details file name can be changed by setting C<$Devel::ObjectTracker::details_file>.
The token <NN> will be replaced by the current session number (before it is incremented).
The default is I<ObjectTracker_details_E<lt>NNE<gt>.txt> in the current directory.

=item *

Object monitoring can be switched on and off in your programs by C<$Devel::ObjectTracker::enable>.
The default is 1 (on).

=item *

The whether a file header is printed is controlled by C<$Devel::ObjectTracker::print_header>.
The default is 1 (yes).

=item *

The output file beginning of line is set by C<$Devel::ObjectTracker::bol>.
The default is nothing. Set to "\"" for csv format.

=item *

The output file value seperator is set by C<$Devel::ObjectTracker::delim>.
The default is tab (\t). Set to "\",\"" for csv format.

=item *

The output file end of line  is set by C<$Devel::ObjectTracker::eol>.
The default is a single newline (\n).  Set to "\"\n" for csv format.

=item *

The stack format line is set by C<$Devel::ObjectTracker::stack_format>.
This can contain tokens of I<E<lt>LEVELE<gt>>, I<E<lt>PACKE<gt>>, I<E<lt>FILEE<gt>>, I<E<lt>LINEE<gt>>, I<E<lt>CALLSUBE<gt>>, I<E<lt>SUBNAMEE<gt>>, I<E<lt>HASARGSE<gt>>, I<E<lt>WANTARRAYE<gt>> which
are replaced as follows:

   LEVEL     = the call level (starts at 0)
   PACK      = package
   FILE      = file name
   LINE      = line number
   CALLSUB   = the calling sub
   SUBNAME   = the called sub
   HASARGS   = as for caller()
   WANTARRAY = as for caller()
 
The default is "<FILE>(<SUBNAME>) l=<LINE>".

=item *

The stack seperator is set by C<$Devel::ObjectTracker::stack_delim>.
The default is "; ".

=back

These variables can be put in a file called F<.objecttracker> in the current 
directory as in the following example:

    $Devel::ObjectTracker::class_exclude = '';
    $Devel::ObjectTracker::class_match   = '.';
    $Devel::ObjectTracker::sub_match     = '^(Mysubs|OtherSubs)::';
    $Devel::ObjectTracker::log_file      = 'mylogfile';
    $Devel::ObjectTracker::details_file  = 'mydetails_<NN>.txt';

will set ObjectTracker to track hashes, arrays and globs as well as objects but
only in subroutines that match pattern I<^(Mysubs|OtherSubs)::>.
The log output will be in I<mylogfile> 
and details will be output to I<mydetails_1.txt>, I<mydetails_2.txt>, etc. 

=head1 NOTES

=over 4

=item * 

Memory references/Objects are often seen first in unexpected places.
For example as hash arguments to subs which are called within the constructor 
or after unpacking by Storable::thaw etc.

See also B<Exists> as similarly objects are often seen seemingly for the first time
when called below destructors.

=item * 

A sub UNIVERSAL::DESTROY is defined to catch destroys of objects which do not have destructors defined themselves.
If the program defines this sub itself then this should get overridden however this could produce confusing results.

=item * 

It uses the debug hook DB::sub to look for memory references returned from subroutine calls, passed as arguments and
checks for destructors.

=item * 

Enabling/disabling monitoring and using subroutine patterns only affects checking for new objects.
Destruction is always monitored.

=item * 

As every subroutine call is being intercepted and the arguments and return values being analysed it 
obviously adds a performance overhead.
Furthermore it is using considerable amounts of memory keeping
track of the object memory details.
Expect performance to be at least 3 times as slow depending on your platform and size of program.

Note also that the output files can be huge.

=item * 

Tied hashes produce confusing results.

=item * 

ObjectTracker has been tested on perl 5.6.1 and 5.5005 on SGI Irix and Win32 (using SiePerl)

=back

See also B<BUGS> below

=head1 FUNCTIONS

=head2 output_details()

This subroutine outputs details on the currently existing objects.
It creates files in the current directory named (by default) I<ObjectTracker_details_1.txt>, I<ObjectTracker_details_2.txt>, etc.
according to the current session number.
This function increments the session number after each call (via B<increment_session>)

This should be called at suitable points in your program and the resultant files
can be checked to see if there are any objects which shouldn't still be in existence.
It will show the date/time, session ID and the call stack when the object was created.

=head2 log_checkpoint()

This subroutine should be called at suitable points in your program to record a checkpoint in the log file.

=head2 increment_session()

This can be used to independently increment the session ID which is used to record details in the main log file and name the output_details files.

=head1 FILE FORMATS

The output file formats are designed to be used in a spreadsheet.
By default they have a single header line followed by data with values are separated by tab (\t) with a single newline (\n) at the end of each line.

=head2 ObjectTracker.log

This file logs the details of object creation and destruction. The fields are as follows: 

=over 4

=item ObjectNo

The sequence number of the object (starts at 1).
Only set for new objects where Source ne B<DES>.

=item DateTime

The local date/time the object is first seen or destroyed.

=item Session

current session number (starts at 1)

=item Sub

The subroutine called.

Will be set to B<NO_DESTRUCTOR> if the test program has no destructor for the object concerned.

=item Source

Where the object is seen as follows:

  Ret = first seen returned from a sub.
  Arg = first seen as an arg.
  DES = the sub is a destructor.

See also B<Exists> as objects can sometimes be seen when called from within destructors

=item Position

The argument or return value position (1=first)

=item Class

Object Class or B<HASH>, B<ARRAY> or B<GLOB>

=item Ref

The memory address of the object.

=item Exists

Object existance info as follows:

=over

=item Y

the object/ref has been seen before. Only applies to Source=DES

=item N

the object/ref has not been seen before. Only applies to Source=DES

=item de

the call stack contains a destructor subroutine (sub =~  /DESTROY$/)

=back

=item Stack

The current call stack.
See B<OPTIONS> for content.

=item CrDateTime

The local date/time the object was first seen. Only output where Source=DES.

=item CrDateTime

The datetime when object first seen. Only output where Source=DES.

=item CrSession

The session when object first seen. Only output where Source=DES.

=item CrStack\n

The call stack when object first seen. Only output where Source=DES.

=back

=head2 ObjectTracker_details_<NN>.txt

This file is produced on demand by the subroutine C<Devel::ObjectTracker::output_details>. 
In the file name <NN> is replaced by the current session number which starts at 1. 

The fields are as follows, see desciptions under I<ObjectTracker.log> for full details:

=over 4

=item CrObjectNo

The creation number of the object.

=item CrDateTime

The local date/time the object was first seen.

=item CrSession

Session number when object first seen.

=item CrSub

Subroutine name called when object first seen.

=item CrSource

The source when object first seen. 

=item Position

The argument or return value position when object first seen.

=item CrClass

Object Class when object first seen.

=item CrRef

The memory address of the object when first seen.

=item CrStack

Call stack when object first seen.

=back

=head1 INSTALLATION

The usual:

      perl Makefile.PL
      make
      make test
      make install

Should install fine via the CPAN module.

=head1 BUGS

See also B<NOTES> above

Probably many. Certainly early versions purported to show objects in existence when they did'nt (and vice-versa) although
I think it is more accurate now. You need to validate the results yourself to be sure.

If the sub matches /DESTROY$/ it assumes the first argument is the object being destroyed.

There is a limited cache kept of deleted objects. It is possible that refs/objects are seen again
in subroutines called from within a destructor. To help overcome this the field B<Exists> contains B<de> if a destructor
is seen in the call stack.

Occasionally it produces 'Attempt to free unreferenced scalar' messages but these seem benign.

=head1 COPYRIGHT

Copyright (c) 2001-2002 Siemens Business Services.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

Because this module is distributed free of charge, there is no warranty
for this module to the extent permitted by the applicable law.
This module is provided "as is" without warranty of any kind, either
expressed or implied, including but not limited to the implied
warranties of merchantability and fitness for a particular purpose.
The entire risk as to the quality and performance of this module rests
with you.  Should this module prove defective, you assume the cost
of all necessary servicing, repair or correction. In no event unless
required by the applicable law will the copyright holder, or any
other party who may modify and/or redistribute the program or this
module be liable to you for damages, including any general, special,
incidental or consequential damages arising out of the use or inability
to use this module (including but not limited to loss of data or data
being rendered inaccurate or losses sustained by you or third parties)
or a failure of this module to operate with any other program even
if such holder or other party has been advised of the possibility
of such damages

Siemens Business Services

=head1 AUTHOR

John Clutterbuck, john.clutterbuck@sbs.siemens.co.uk

=head1 SEE ALSO

perl(1).

perldoc perldebug.

=cut

1;
#eof
