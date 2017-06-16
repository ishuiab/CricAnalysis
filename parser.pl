#!/usr/bin/perl -w
use strict;
use DBI;
use Data::Dumper;
use File::Slurp qw(read_file write_file);

#Variables
my @files = ();
my $DP    = "C:\\Users\\ssadiq\\Documents\\IPL\\data\\";
$| = 1;
&init();


sub init(){
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
            print "$f \n";
            my @lines = split("\n",read_file($DP.$f));
            my %meta  = ();
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
                        my $w = (split(",",$l))[2];
                        $meta{'WR'} = $w;
                    }elsif ($l =~ /winner_wickets/) {
                        my $w = (split(",",$l))[2];
                        $meta{'WW'} = $w;
                    }else{
                        my $w = (split(",",$l))[2];
                        $meta{'W'} = $w;
                    }   
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
                        
                        #print "[Ball -> $bctr] [Over -> $det[2]] [On Strike -> $det[4]] [Bowler -> $det[6]] [Non Striker -> $det[5]] [Run's -> $runs] [Action -> $action]\n";
                        #print "[Ball -> $bctr] [Over -> $det[2]] [Run's -> $runs] [Action -> $action] [Wicket -> $wicket] [Wicket How -> $w_how]\n";
                        
                        $bctr++;
                        #print "\n";
                        #sleep(1);
                    }
                    
               }
            }
            #print Dumper \%meta;
            sleep(1);
            #exit();
        }
    }
}