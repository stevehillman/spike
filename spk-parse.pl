#!/usr/bin/perl

# Stern SPIKE file parser

$file = $ARGV[0];

die "$file doesn't seem to exist\n" if (! -e $file);

open(IN,"<:raw",$file) or die "Can't open $file for reading in byte mode\n";

# Read the first 12 byte header of the file.

read(IN,my $hdr,12);
die "Doesn't look like a SPK file\n" if ($hdr !~ /^SPKS/);

my $junk;
my $bytes=0;

# SPKS files consist of 1 or more SPK0 blocks, each of which contains
# a directory header, a file info block, and then all of the raw data
while (read(IN,$junk,52))
{
    if ($junk !~ /^SPK0/)
    {
        print "Doesn't look like a SPK0 block\n"; 
        next;
    }
    read(IN,my $dirhdr,20);
    my ($numfiles,$length) = unpack 'x4 L x8 S', $dirhdr;
    print "Total files: $numfiles. Dir length: $length\n";

    read(IN,my $dir, $length);

    my @files = split(/\0/,$dir);
    print "Files:\n";
    foreach (@files)
    {
        print "$_\n";
    }

    my @filedata;
    for (my $i; $i<$numfiles;$i++)
    {
        read(IN,$filedata[$i],68);
        die "Something went wrong" if ($filedata[$i] !~ /^FINF/);
    }

    $i=0;
    foreach (@filedata)
    {
        my ($l1,$l2,$l3) = unpack 'x12 L L L';
        print "File: ",$files[$i], "\n  l1: $l1; l2: $l2; l3: $l3\n";
        $flen[$i] = $l1;
        $i++;
    }

    read(IN,my $junk,16);

    $i=0;
    foreach $f (@files)
    {
        my $buffer;
        $basedir = $f;
        $basedir =~ s/\/[^\/]+$//;
        system "mkdir -p $basedir" if ( ! -d $basedir);
        open(OUT,">:raw",$f) or die "Can't open $f for writing\n";
        my $b = read(IN,$buffer,$flen[$i]);
        print OUT $buffer;
        close OUT;
        $i++;
        $bytes += $b;
    }
}

print "Wrote a total of $bytes bytes\n";
close IN;
exit;
