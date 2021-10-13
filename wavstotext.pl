#!/usr/bin/perl

opendir(DIR,".") or die "Can't open current dir for reading";

while(readdir(DIR))
{
    next if (!/-mono.wav$/);
    push @files,$_;
}
closedir DIR;

foreach $in (sort @files)
{
    print "Processing $in...";
    $text = `/Users/hillman/src/perl/spike/wavtotext.py $in 2>/dev/null`;
    if ($?)
    {
	print "  Error - not text?\n";
	sleep 5;
        next;
    }
    else
    {
        chomp($text);
	$text =~ s/ /-/g;
	$text =~ s/'//g;
	$i = "";
	while ( -e "say-$text$i.wav")
	{
	    if ($i == "") { $i=1; } else {$i++;}
	}
	system "cp $in say-$text$i.wav";
	print "  copied to say-$text$i.wav\n";
	sleep 5;
    }
}
