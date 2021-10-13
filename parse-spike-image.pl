#!/usr/bin/perl
#
# parse-spike-image.pl
#
# Parse a Stern SPIKE image.bin file and save all audio and image files found

use Getopt::Std;

getopts('si') or die "Usage: parse-spike-image.pl -s -i -f <filename>\n   -s   Create sound files\n   -i   Create image files\n";

$make_sounds = $opt_s;
$make_images = $opt_i;
$file = $ARGV[0];

die "$file doesn't seem to exist\n" if (! -e $file);

mkdir "sounds" if ( ! -d "sounds");
mkdir "images" if ( ! -d "images");

open(IN,"<:raw",$file) or die "Can't open $file for reading in byte mode\n";

read(IN, my $mainheader, 56);

my ($dum1,$imgstart,$image_table_end,$image_table,$wave_table_end,$wave_table) = unpack('QQQQQQ',$mainheader);

print "Seeking to $wave_table\n";
seek(IN,$wave_table,SEEK_SET);
my $pos = $wave_table;
my @wave_addresses,@wave_metadata;
my $total_waves = 0;

# Every wave table entry consists of 5 64-bit pointers. In our case, each of the 5 point to the same
# place. This is likely for future il8n support 
my $buf;
while(read(IN,$buf,40))
{
   #printf("%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X%X\n",split(//,$buf));
   # print $buf,"\n\n";
    # We only care about the first of the 5 pointers
    $wave_addresses[$total_waves] = unpack('L',$buf);
    $pos += 40;
    $total_waves++;
    last if ($pos >= $wave_table_end);
}

print "Read in a total of $total_waves wav files\n";


# The WAV sounds use two levels of indirection. The first table points to (what is most likely) a C structure, and one of the
# values in the C structure points to the actual WAV data. Unfortunately, the location of that second value moves around
# depending on the size of the C structure. So we use different 'unpack' rules depending on the length. The length is
# determined by the diff between the current structure and the next structure in the table

my $i=0;
for (my $i=0;$i < $total_waves;$i++)
{
    seek(IN,$wave_addresses[$i],SEEK_SET);
    if (defined($wave_addresses[$i+1]))
    {
        $readlen = $wave_addresses[$i+1] - $wave_addresses[$i];
    }
    else { $readlen = 32; }
    read(IN,$wave_metadata[$i],$readlen);
}

for (my $i=0;$i < $total_waves;$i++)
{
    if (defined($wave_addresses[$i+1]))
    {
        $readlen = $wave_addresses[$i+1] - $wave_addresses[$i];
    }
    else { $readlen = 32; }

    if ($readlen == 8 || $readlen == 16)
    {
        # Skip these
        $wave_metadata[$i] = 0;
        next;
    }
    if ($readlen == 24 || $readlen == 32)
    {
        ($c[0],$c[1],$c[2],$c[3],$c[4],$c[5],$c[6],$c[7],$i1,$i2,$addr,$l1,$l2) = unpack('CCCCCCCCSSLLL',$wave_metadata[$i]);
        $pfstr = "";
        if ($readlen == 32 && $c[7] == 1)
        {
            # Last few 32-byte blocks at the end have a different format, need to re-unpack
            ($c[0],$c[1],$c[2],$c[3],$c[4],$c[5],$c[6],$c[7],$i1,$l2,$l1,$i2,$addr) = unpack('CCCCCCCCSCLSL',$wave_metadata[$i]);
        }
    }
    elsif ($readlen == 48)
    {
        ($c[0],$c[1],$c[2],$c[3],$c[4],$c[5],$c[6],$c[7],$c[8],$c[9],$c[10],$i1,$i2,$addr,$l1,$l2) = unpack('CCCCCCCCCCCSSLLL',$wave_metadata[$i]);
        $pfstr = "";
    }
    elsif ($readlen == 64)
    {
        ($c[0],$c[1],$c[2],$c[3],$c[4],$c[5],$c[6],$c[7],$i1,$i2,$l1,$l2,$l3,$l4,$addr) =  unpack('CCCCCCCCSSLLLLL',$wave_metadata[$i]);
        $pfstr = " l3=%08X l4=%08X";
        unshift(@c,$l3);
        unshift(@c,$l4);
    }
    elsif ($readlen == 96)
    {
        ($c[0],$c[1],$c[2],$c[3],$c[4],$c[5],$c[6],$c[7],$i1,$i2,$l1,$l2,$l3,$l4,$l5,$l6,$l7,$l8,$addr) =  unpack('CCCCCCCCSSLLLLLLLLL',$wave_metadata[$i]);
        $pfstr = " l3=%08X l4=%08X l5=%08X l6=%08X l7=%08X l8=%08X";
        unshift(@c,$l3);
        unshift(@c,$l4);
        unshift(@c,$l5);
        unshift(@c,$l6);
        unshift(@c,$l7);
        unshift(@c,$l8);
    }
    elsif ($readlen == 112)
    {
        ($c[0],$c[1],$c[2],$c[3],$c[4],$c[5],$c[6],$c[7],$i1,$i2,$l1,$l2,$l3,$l4,$l5,$l6,$l7,$l8,$q1,$q2,$addr) =  unpack('CCCCCCCCSSLLLLLLLLQQL',$wave_metadata[$i]);
        $pfstr = " l3=%08X l4=%08X l5=%08X l6=%08X l7=%08X l8=%08X";
        unshift(@c,$l3);
        unshift(@c,$l4);
        unshift(@c,$l5);
        unshift(@c,$l6);
        unshift(@c,$l7);
        unshift(@c,$l8);
    }
    else
    {
        print "Unsupported length: $readlen\n";
        next;
    }
    print "Length: ",$addr-$oldaddr,"\n\n";
    print "Wave $i:\n  offset: $addr. len: $readlen; ";
    printf ("i1=%04X i2=%04X l1=%08X l2=%08X $pfstr rest=%02X %02X %02X %02X %02X %02X %02X %02X\n",$i1,$i2,$l1,$l2,@c);
    $oldaddr = $addr;
    # The wav header may be either 8 or 10 bytes
    seek(IN,$addr,SEEK_SET);
    read(IN,$wavhdr,8);
    my ($mlen,$channels,$s1) = unpack('LSS',$wavhdr);
    my $musicbuf;

    if ($make_sounds)
    {
        read(IN,$musicbuf,$mlen*2*$channels);

        $wavhdr1 = pack('H*',"52494646FFFFFF7F57415645666D7420100000000100");
        $freq = 44100;
        # $freq = 22050 if ($i2 == 9);
        $wavhdr2 = pack('SLLSH*',$channels,$freq,$freq*$channels*2,$channels*2,"10006461746100FFFF7F");

        $chans = ($channels == 2) ? "" : "-mono";
        $snum = sprintf("%04d",$i);
        open(OUT,">:raw","sounds/sound$snum$chans.wav");
        print OUT $wavhdr1,$wavhdr2,$musicbuf;
        close OUT;
    }

}

print "Processing images\n";

# Image extraction is a bit hit-or-miss. There are two 16-bit values in the header of each image that indicate (presumably) its width
# and height (so most images are 128x32 - the size of the standard DMD), but there are a lot of images with the 128x32 that are NOT
# actually that many bytes long (each byte is two pixels, as each pixel can have 16 shades). Since I only really cared about
# the DMD animations, I skip over anything that's not long enough to fill the screen.

seek(IN,$image_table,SEEK_SET);
my @image_addresses;
$pos = $image_table;
my $total_images = 0;

while(read(IN,$buf,8))
{
    $image_addresses[$total_images] = unpack('L',$buf);
    $pos += 8;
    $total_images++;
    last if ($pos >= $image_table_end);
}

print "There are a total of $total_images images\n";

# Standard BMP header for a 128x32 16-grey-scale image
$BMPhdr = "BM" . pack('LLLLLLSSLLLLLLH*',2166,0,118,40,128,32,1,4,0,0,1280,320,16,0,"00000000111111002222220033333300444444005555550066666600777777008888880099999900AAAAAA00BBBBBB00CCCCCC00DDDDDD00EEEEEE00FFFFFF00");

for($i=0;$i < $total_images;$i++)
{
    seek(IN,$image_addresses[$i],SEEK_SET);
    read(IN,$buf,11);
    ($imgnum,$l2,$w,$h,$c1) = unpack('LLSSC',$buf);
    $bytes = $image_addresses[$i+1]-$image_addresses[$i]-11;
    printf ("Num: %05d; Width: %03d; Height: %03d l2: %08X; bytes: %04d\n",$imgnum,$w,$h,$l2,$bytes);

    if ($opt_i)
    {
        if ($w == 128 && $h == 32 && $bytes > 2000)
        {
            my $numfmt = sprintf("%05d",$imgnum);
            open(OUT,">:raw", "images/image$numfmt.bmp");
            print OUT $BMPhdr;
            read(IN,$buf,2048);
            print OUT flipbuf($buf,64,32);
            close OUT;
        }
    }
}


close IN;
exit;

# Stern stores its DMD images Y-inverted - presumably that's how they get clocked into the DMD. Flip them back
# To do that, we have to know the X-Y size of the image in bytes
# We also need to flip the high and low nibble of each byte
sub flipbuf
{
    my ($buf,$x,$y) = @_;
    my @oldbuf = unpack("(a$x)*",$buf);
    my @newbuf;
    foreach $my_y (0..$y-1)
    {
        my @tmpbuf = split(//,$oldbuf[$y-$my_y-1]);
        foreach $my_x (0..$x-1)
        {
            $fl = unpack('C',$tmpbuf[$my_x]);
            $tmpbuf[$my_x] = pack('C',(($fl<<4)&0xf0) | (($fl>>4)&0x0f));
        }
        $newbuf[$my_y] = join('',@tmpbuf);
    }
    return join('',@newbuf);
}
