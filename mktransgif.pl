#!/usr/bin/perl
#
# Make the white colour transparent on a GIF
#
# To make use of this script:
#  - use 'convert' to convert the bmp images to gif images
#  - use this script to add transparency to the gif
#  - use 'convert' to convert the gif to either a png or animated gif

$fname = $ARGV[0];

die "No such file: $fname\n" if (! -e $fname);

open(IN,"<:raw",$fname);
read(IN,$buf,999999);
@newbuf = unpack("C*",$buf);

# Check to make sure it's a GIF89A and not already transparent
if ($buf !~ /^GIF89a/ || $newbuf[10] != 243)
{
    print STDERR "not a 16 color GIF89A file\n";
    exit 1;
}
if ($newbuf[11] == 15)
{
    print STDERR "background colour already 0x0F. Skipping\n";
    exit 1;
}

$newbuf[11] = 15;
$newbuf[64] = 1;
$newbuf[67] = 15;

foreach $i (0..scalar(@newbuf)-1)
{
    $newbuf[$i] = pack('C',$newbuf[$i]);
}
$outbuf = join('',@newbuf);
open(OUT,">:raw",$fname);
print OUT $outbuf;
close OUT;
exit 0;
