#!perl -w
use strict;
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath 'selector_to_xpath';
use LWP::Simple qw(get);
use Getopt::Long;
use Pod::Usage;
use Data::Dumper;

GetOptions(
    'uri' => \my $make_uri,
) or pod2usage(2);

# Now determine where we get the HTML to scrape from:
my ($url,$selector,$nodepart) = @ARGV;
if ($selector !~ m!^/!) {
    $selector = selector_to_xpath( $selector );
};

my $html;
if ($url eq '-') {
    # read from STDIN
    local $/;
    $html = <>;
} else {
    $html = get $url;
};

# Now munge the XPath expression to select only the nodes we really want
$nodepart ||= 'text';
if ($nodepart =~ /^\@/) {
    $selector = "$selector/$nodepart";
};

my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse($html);
$tree->eof;

my @nodes;
if ($nodepart eq 'text') {
    @nodes = map { join " ", @{ $_->{_content} } } $tree->findnodes($selector);
} else {
    @nodes = $tree->findvalues($selector);
};

for (@nodes) {
    if ($make_uri) {
        $_ = URI->new_abs( $_, $url )->as_string;
    };
    print $_;
    print "\n";
};
$tree->delete;