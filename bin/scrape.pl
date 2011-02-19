#!perl -w
use strict;
use HTML::TreeBuilder::XPath;
use HTML::Selector::XPath 'selector_to_xpath';
use LWP::Simple qw(get);
use Getopt::Long;
use Pod::Usage;
use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

scrape.pl - simple HTML scraping from the command line

=head1 ABSTRACT

This is a simple program to extract data from HTML by
specifying CSS3 or XPath selectors.

=head1 SYNOPSIS

    scrape.pl URL selector selector ...

    # Print page title
    scrape.pl http://perl.org title
    # The Perl Programming Language - www.perl.org

    # Print links with titles, make links absolute
    scrape.pl http://perl.org a //a/@href --uri=2
    
    # Print all links to JPG images, make links absolute
    scrape.pl http://perl.org a[@href=$"jpg"] --uri=1

=head1 DESCRIPTION

This program fetches an HTML page and extracts nodes
matched by XPath or CSS selectors from it.

If URL is C<->, input will be read from STDIN.

=head1 OPTIONS

=over 4

=item B<--sep>

Separator character to use for columns. Default is tab.

=item B<--uri> COLUMNS

Numbers of columns to convert into absolute URIs

=back

=cut

GetOptions(
    'help|h' => \my $help,
    'uri:s' => \my @make_uri,
    'sep:s' => \my $sep,
) or pod2usage(2);
pod2usage(1) if $help;

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

my $tree = HTML::TreeBuilder::XPath->new;
$tree->parse($html);
$tree->eof;

# now fetch all "rows" from the page. We do this once to avoid
# fetching a page multiple times
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

=head1 REPOSITORY

The public repository of this module is 
L<http://github.com/Corion/App-scrape>.

=head1 SUPPORT

The public support forum of this program is
L<http://perlmonks.org/>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2011-2011 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
