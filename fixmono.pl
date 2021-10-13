#!/usr/bin/perl

$file = $ARGV[0];

die "$file doesn't seem to exist\n" if (! -e $file);

open(IN,"<:raw",$file) or die "Can't open $file for reading in byte mode\n";

# Read the first 12 byte header of the file.

read(IN,my $buf,9999999);

@data = split(//,$buf);
$data[28] = pack('C',136);
$data[29] = pack('C',88);
$data[30] = pack('C',1);
$data[31] = pack('C',0);
$data[32] = pack('C',2);

$buf = join('',@data);
open(OUT,">:raw","$file");
print OUT $buf;
close OUT;
