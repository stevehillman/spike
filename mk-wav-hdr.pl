#!/usr/bin/perl
#
# Test script to create a WAV file header. Run this script, then, to make any file into a playable WAV file, do
# "cat 44kwavhead yourfile > yourfile.wav"

# 44.1Khz stereo
$data = "52494646FFFFFF7F57415645666D7420100000000100020044AC000010B10200040010006461746100FFFF7F";
# 44.1Khz mono
# $data = "52494646FFFFFF7F57415645666D7420100000000100010044AC000010B10200040010006461746100FFFF7F";

$buf = pack('H*',$data);
open OUT,">:raw","44kwavhead";
print OUT $buf;
close OUT;