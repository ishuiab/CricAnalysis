#!/usr/bin/perl -w
use strict;
use DBI;
use Data::Dumper;
use File::Slurp qw(read_file write_file);

#Variables
my @files = ();
my %v_ids = ();
my $DP    = "C:\\Users\\ssadiq\\Documents\\IPL\\data\\";
$| = 1;
my $db = "ipl";

&init();

sub execSQL{
    my $query   = $_[0];
    my $connect = get_con();
    my $sth = $connect->prepare($query) or die "Cannot prepare: " . $connect->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    $sth->finish();
}
sub get_con{
	my $database = "ipl";
	my $host     = "localhost";
	my $user     = "root";
	my $pw       = "";
	my $dsn      = "dbi:mysql:$database:$host:3306";
	my $connect  = DBI->connect($dsn, $user, $pw);
	unless($connect){
		print "-E- Fail to connect to server\n";
		exit 1;
	}

	return $connect;
}

#lets start the game
sub init(){
    &load_data();
    &load();
    &parse();
}
#Load all the files
sub load(){
    opendir my $dir, "C:\\Users\\ssadiq\\Documents\\IPL\\data" or die "Cannot open directory: $!";
        @files = readdir $dir;
    closedir $dir;
}


#Parse the loaded CSV Files
sub parse(){
    foreach my $f(@files){
        if ($f =~ /.csv/) {
            my @lines = split("\n",read_file($DP.$f));
            my %meta  = (
                                'D'  => '',
                                'C'  => '',
                                'TW' => '',
                                'MOM'=> '',
                                'TD' => '',
                                'WB' => '',
                                'W'  => '',
                                'V'  => '',
                                'L'  => '',
                                'WV' => ''        
                        );
            my $bctr  = 1;
            foreach my $l(@lines){
                #META DATA Part
                if ($l =~ /team/) {
                    my $team = (split(",",$l))[2];
                    if (! defined $meta{'T'}) {
                        $meta{'T'}{1} = $team;
                    }else{
                        $meta{'T'}{2} = $team;
                    }
                }elsif($l =~ /venue/){
                    my $venue = (split(",",$l))[2];
                    if ($venue =~ /^\"/) {
                        $venue = substr($venue,1);
                    }
                    
                    $meta{'V'} = $venue;
                }elsif($l =~ /toss_winner/){
                    my $toss = (split(",",$l))[2];
                    $meta{'TW'} = $toss;
                }elsif($l =~ /toss_decision/){
                    my $toss = (split(",",$l))[2];
                    $meta{'TD'} = $toss;
                }elsif($l =~ /player_of_match/){
                    my $mom = (split(",",$l))[2];
                    $meta{'MOM'} = $mom;
                }elsif($l =~ /winner/){
                    if ($l =~ /winner_runs/) {
                        $meta{'WB'} = "Runs";
                        my $w = (split(",",$l))[2];
                        $meta{'WV'} = $w;
                    }elsif ($l =~ /winner_wickets/) {
                        $meta{'WB'} = "Wickets";
                        my $w = (split(",",$l))[2];
                        $meta{'WV'} = $w;
                    }else{
                        my $w = (split(",",$l))[2];
                        $meta{'W'} = $w;
                    }   
                }elsif($l =~ /competition/){
                        my $c = (split(",",$l))[2];
                        $meta{'C'} = $c;
                }elsif($l =~ /date/){
                        my $d = (split(",",$l))[2];
                        $meta{'D'} = $d;
                }elsif($l =~ /city/){
                        my $lc = (split(",",$l))[2];
                        $meta{'L'} = $lc;
                }
               #------------------------------------------------------
               else{
                    if (($l !~ /^info/) && ($l !~ /^version/) && (($l =~ /^ball/))) {
                        
                        my @det = split(",",$l);
                        #print "$l \n";
                        
                        my $runs = $det[7]+$det[8];
                        my $action = "";
                        if ($det[7] ne "0") {
                            if (($det[7] eq "4") || ($det[7] eq "6")) {
                                $action = "B";
                            }elsif($det[8] ne "0"){
                                $action = "+E";
                            }
                            else{
                                $action = "R";
                            }
                        }else{
                            if ($det[8] ne "0") {
                                $action = "E";
                            }else{
                                $action = "N";
                            }
                        }
                        my $wicket = "N";
                        my $w_how  = "N";
                        if ($det[9] ne "\"\"") {
                            $wicket = "Y";
                            $w_how  = $det[9];
                        }
                        $bctr++;
                    }
               }
            }
            
        #-------------------------------------------------------------------------------------------------
            
            #print Dumper \%meta;
            my $id      = gen_id();
             my $status = "Complete";
                if ($meta{'W'} eq "") {
                    $status = "Abandoned";
                }
            my $sel_qry = "SELECT * FROM $db.matches WHERE competition = '$meta{C}' AND city = '$meta{L}' AND date = '$meta{D}' AND team_1 = '$meta{T}{1}' AND team_2 = '$meta{T}{2}' AND toss_winner = '$meta{TW}' AND toss_decision = '$meta{TD}' AND winner = '$meta{W}' AND win_by = '$meta{WB}' AND win_value = '$meta{WV}' AND venue = '$meta{V}' AND mom = '$meta{MOM}'";
            if (!nr($sel_qry)) {
                my $ins_query = "INSERT INTO $db.matches VALUES ('$id','$meta{C}','$meta{L}','','$meta{D}','$meta{T}{1}','$meta{T}{2}','$meta{TW}','$meta{TD}','$meta{W}','$meta{WB}','$meta{WV}','$meta{V}','$meta{MOM}','$status')";
                execSQL($ins_query);
            }else{
                my $upd_query = "UPDATE $db.matches SET id='$id',status='$status' WHERE competition = '$meta{C}' AND city = '$meta{L}' AND date = '$meta{D}' AND team_1 = '$meta{T}{1}' AND team_2 = '$meta{T}{2}' AND toss_winner = '$meta{TW}' AND toss_decision = '$meta{TD}' AND winner = '$meta{W}' AND win_by = '$meta{WB}' AND win_value = '$meta{WV}' AND venue = '$meta{V}' AND mom = '$meta{MOM}'";
                execSQL($upd_query);
            }
            
            #-------------------------------------------------------------------------------------------------
            #sleep(1);
           
        }
    }
}
#Load the data required
sub load_data(){
    my $query   = "SELECT * FROM $db.matches";
    my $connect = get_con();
    my $sth = $connect->prepare($query) or die "Cannot prepare: " . $connect->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    while(my @row = $sth->fetchrow_array()){
		$v_ids{$row[0]} = 1;
	}
	$sth->finish();
    
}
#Function to generate 8 Digit Unique ID
sub gen_id(){
   
    my @set = ('0' ..'9', 'A' .. 'F');
    my $id = join '' => map $set[rand @set], 1 .. 8;
    while (defined($v_ids{$id})) {
        $id = join '' => map $set[rand @set], 1 .. 8;
    }
    return $id;
}
#Function for SQL num rows
sub nr{
    my $query   = $_[0];
    my $connect = get_con();
    my $ctr     = 0;
    my $sth = $connect->prepare($query) or die "Cannot prepare: " . $connect->errstr();
    $sth->execute() or die "Cannot execute: " . $sth->errstr();
    while(my @row = $sth->fetchrow_array()){
		$ctr++;
	}
	$sth->finish();
    return $ctr;
}