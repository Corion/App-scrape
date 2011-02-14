#!perl -w
use strict;
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath 'selector_to_xpath';
use LWP::Simple qw(get);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

GetOptions(
    'uri:s' => \my @make_uri,
    'sep:s' => \my $sep,
) or pod2usage(2);

# make_uri can be a comma-separated list of columns to map
# The index starts at one
my %make_uri = map{ $_-1 => 1 } map{ split /,/ } @make_uri;
$sep ||= "\t";

# Now determine where we get the HTML to scrape from:
my $url = shift @ARGV;

my $html;
if ($url eq '-') {
    # read from STDIN
    local $/;
    $html = <>;
} else {
    $html = get $url;
};

# Now munge the XPath expression to select only the nodes we really want
#$nodepart ||= 'text';
#if ($nodepart =~ /^\@/) {
#    $selector = "$selector/$nodepart";
#};

my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse($html);
$tree->eof;

# now fetch all "rows"

my @rows;

my $rowidx=0;
for my $selector (@ARGV) {
    if ($selector !~ m!^/!) {
        $selector = selector_to_xpath( $selector );
    };
    my @nodes;
    if ($selector !~ m!/\@\w+$!) {
        @nodes = map { $_->as_trimmed_text } $tree->findnodes($selector);
    } else {
        @nodes = $tree->findvalues($selector);
    };
    
    if ($make_uri{ $rowidx }) {
        @nodes = map { URI->new_abs( $_, $url )->as_string } @nodes;
    };
    
    $rows[ $rowidx++ ] = \@nodes;
};

for my $idx (0.. $#{ $rows[0] }) {
    print join $sep, map { 
            $rows[$_]->[$idx]
        } 0..$#rows;
    
    print "\n";
};

$tree->delete;