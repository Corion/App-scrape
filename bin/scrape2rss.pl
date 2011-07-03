#!perl -w
use strict;
use App::scrape 'scrape';
use LWP::Simple qw(get);
use Getopt::Long;
use Pod::Usage;
use XML::Atom::SimpleFeed;
use Time::Piece;
use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

scrape2rss.pl - extract information as RSS (well, Atom) feed

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
    scrape.pl http://perl.org a[@href=$"jpg"]

=head1 DESCRIPTION

This program fetches an HTML page and extracts nodes
matched by XPath or CSS selectors from it.

If URL is C<->, input will be read from STDIN.

=head1 OPTIONS

=over 4

=item B<--sep>

Separator character to use for columns. Default is tab.

=item B<--uri> COLUMNS

Numbers of columns to convert into absolute URIs, if the
known attributes do not everything you want.

=item B<--no-uri>

Switches off the automatic translation to absolute
URIs for known attributes like C<href> and C<src>.

=back

=cut

GetOptions(
    'help|h' => \my $help,
    'feed-url|b:s' => \my $feed_url,
    'feed-title|f:s' => \my $feed_title,
    'title|t:s' => \my $title,
    'summary|s:s' => \my $summary,
    'permalink|l:s' => \my $permalink,
    'date:s' => \my $date,
    'date-fmt:s' => \my $date_fmt,
    'category|c:s' => \my $category,
    'outfile|o:s' => \my $outfile,
    'debug|d' => \my $debug,
) or pod2usage(2);
pod2usage(1) if $help;

$feed_url ||= $outfile || 'feed.atom';
$title ||= 'Atom feed';
$category ||= '';

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

my @fields;

my @rows = scrape($html, {
        summary => $summary,
        permalink => $permalink,
        title => $title,
        date => $date,
        #category => $category,
    }, {
    base => $url,
});

my $updated = Time::Piece->gmtime->strftime('%Y-%m-%dT%H:%M:%SZ');

my $feed = XML::Atom::SimpleFeed->new(
    title   => $title,
    link    => $feed_url,
    link    => { rel => 'self', href => $feed_url, },
    author  => 'scrape2rss',
    id      => $feed_url,
    updated => $updated,
);

for my $item (@rows) {
    my $updated = $item->{date} || $updated;
    
    # Now, extract the information, just in case there is "garbage"
    # around the string
    (my $extr = $date_fmt) =~ s!%\w!\\d+!g;
    $extr = qr/($extr)/;
    
    $updated =~ $extr
        or warn "Is [$updated] a valid date?";
    $updated = $1;
    warn $updated;
    
    my $ts = Time::Piece->strptime( $updated, $date_fmt );
    $updated = $ts->strftime('%Y-%m-%dT%H:%M:%SZ');

    my $enc_url = URI::Escape::uri_escape($item->{permalink});
    
    my %info = (
        title     => $item->{title},
        link      => $enc_url,
        id        => $enc_url,
        summary   => $item->{summary},
        updated   => $updated,
        category  => ($item->{category} || $category),
    );
    
    if ($debug) {
        for (sort keys %info) {
            printf "%10s : %s\n", $_, $info{ $_ };
        };
    };
        
    # beware. XML::Atom::SimpleFeed uses warnings => fatal,
    # so all warnings within it die.
    $feed->add_entry(%info);
};

if ($outfile) {
    open STDOUT, '>', $outfile
        or die "Couldn't create '$outfile': $!";
};
    
print $feed->as_string;

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
