# ImageSense v 0.1
# Author: Laye
# Date: Feb.6th, 2006

use strict;
use warnings;

use LWP::UserAgent;
use URI::URL;
use URI;

# always flush the STDOUT immediately:
$| = 1;

# pattern of any property
my $r_any = qr/\w+(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^>\s]*))?/;
# pattern of "src" property
my $r_src = qr/src\s*=\s*("[^"]*"|'[^']*'|[^>\s]*)/;
# pattern of image file extension
my $r_imgfe = qr/\.(?:jpg|gif|bmp|png)/;
# pattern of "href" property that point to image
my $r_href2img = qr/href\s*=\s*("[^"]*$r_imgfe"|'[^']*$r_imgfe'|[^>\s]*$r_imgfe)/;
# pattern of "background" property
my $r_background = qr/background\s*=\s*("[^"]*"|'[^']*'|[^>\s]*)/;
# pattern of "background" style
my $r_stylebg = qr/(background\s*:\s*(?:\S+\s*)*url\(([^\)]*)\)(?:\s*\S+)*)/;
# pattern of "background-image" style
my $r_stylebgimg = qr/(background-image\s*:\s*url\(([^\)]*)\))/;

# pattern of "img" tag with a "src" property
my $r_img = qr/<\s*img\s*(?:$r_any\s*)*($r_src)\s*(?:$r_any\s*)*\s*\/?\s*>/;
# pattern of "a" tag whose "href" point to image
my $r_a2img = qr/<\s*a\s*(?:$r_any\s*)*($r_href2img)\s*(?:$r_any\s*)*\s*\/?\s*>/;
# pattern of any tag that contains "background" property
my $r_tagwithbg = qr/<\s*\w+\s*(?:$r_any\s*)*($r_background)\s*(?:$r_any\s*)*\s*\/?\s*>/;

# list of all patterns to scan
my %pats = (
    '<IMG> Tags' => \$r_img, 'hyper links' => \$r_a2img,
    'tags with background' => \$r_tagwithbg,
    'style sheets with background' => \$r_stylebg,
    'style sheets with background-image' => \$r_stylebgimg
    
);

my $ua = LWP::UserAgent->new;

# scan for images
my %imgs;
foreach my $url (@ARGV)
{    
    print ">>> Connecting to $url ...";
    my $r = $ua->get($url);
    if ($r->is_success)
    {   
        print ' '.length($r->content)." byte(s)\n";
        $_ = $r->content;        
        foreach my $scan (keys %pats)
        {
            print "Scanning for images in $scan ";
            my $n = 0;    
            while (m/(${$pats{$scan}})/ig)
            {
                print '.';
                my $img = $3;        
                $img = $1 if ($img =~ m/"([^"]*)"/ || $img =~ m/'([^']*)'/);
                my $img_url = URI::URL->new($img, $r->base);
                my $save_name = $img_url->abs;
                $save_name =~ s{[/\\:\*\?"<>\|]}{\.}g;
                unless (exists $imgs{$img_url->abs})
                {
                    $imgs{$img_url->abs} = $save_name;
                    $n++;
                }  
            }
            print " $n new image(s) found\n";
        }
    }
    else { print "\nERROR: ".$r->status_line }
}

# create directory for downloading images
my $dir;
if (scalar keys %imgs != 0)
{
    my @t = localtime;
    my $mydate = sprintf("%02d%02d%02d", $t[5] % 100, $t[4] + 1, $t[3]);
    my $mytime = sprintf("%02d%02d%02d", $t[2], $t[1], $t[0]);    
    mkdir ($dir = "$mydate-$mytime");
}

# store images
foreach (sort keys %imgs)
{   
    print ">>> Downloading $_ ...";
    my $r = $ua->get($_);
    if ($r->is_success)
    {        
        open DOWN_FILE, "> $dir/$imgs{$_}";
        binmode DOWN_FILE;
        print DOWN_FILE $r->content;
        close DOWN_FILE;        
        print " ".length($r->content)." byte(s)\n";
        print "Stored as: $dir/$imgs{$_}\n";
    }
    else { print "\nError: ".$r->status_line."\n"; }
}