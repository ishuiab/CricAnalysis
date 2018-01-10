#!/usr/bin/perl -w
use strict;
use DBI;
use Data::Dumper;
use File::Slurp qw(read_file write_file);

my $DP    = "C:\\Users\\ssadiq\\Documents\\CricAnalysis\\files\\";
$| = 1;
my $db = "ipl";

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
    #&load_data();
    &load();
    &parse();
}
#Load all the files
sub load(){

    opendir my $dir, "C:\\Users\\ssadiq\\Documents\\CricAnalysis\\files\\" or die "Cannot open directory: $!";
        @files = readdir $dir;
    closedir $dir;
}

sub parse(){
     foreach my $f(@files){
         print "-I- Processing file $f\n";
     }
}
