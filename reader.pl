#!/usr/bin/env perl
 
 
#References
#http://search.cpan.org/~kellan/XML-RSS-1.05/lib/RSS.pm 
#http://www.perlmonks.org/?node_id=99254
#http://lwp.interglacial.com/ch07_05.htm
 
# Bypass bluetongue.cs proxy 
$ENV{"http_proxy"} = ""; 

use strict;
use warnings;
use open qw{:std :utf8};

use LWP::Simple;
use XML::RSS;
use HTML::TokeParser;
use DateTime::Format::HTTP;

use Data::Dump qw(dump); #used for debugging

use Text::Wrap;
$Text::Wrap::columns = 80;

use Encode;

#use HTML::TreeBuilder;
#creates a new rss object with the reference rssRef
my $rssRef = new XML::RSS (version => '2.0');

#checks cmd line argument counts and make sure only 1 argument is entered
 if ($#ARGV < 0 || $#ARGV > 0) #@# returns size of cmd arguements -1 = 0, 0= 1arg
{
	print("One argument is required.\n");
	die "Usage: $0 rss_url\n"
}
#print ("printing argv" . scalar( @ARGV ));

my $url = $ARGV[0]; #enable at a later date
#fetch all data from the argument url
my $content = get($url) or die 'Unable to retrieve page with CPAN Module LWP::Simple';

#handles the wide character issue
$content = decode "utf8", $content;

eval
{
	#call internal method(parse) from rssref ref
	#parse a string to the rss object
	$rssRef->parse($content);
}; die "\nERROR! - Unable to parse contents\n - Is the URL a rss file?\n" if $@;

 foreach my $eachItem (@{$rssRef->{'items'}}) 
 {	 
	#fetch the data from the appropiate tags
	my $realAuthor; 
	my $title = wrap('', '',$eachItem->{'title'});
	my $creator = $eachItem->{'dc'}->{'creator'};
	my $author = $eachItem->{'author'};
	my $pubDate = $eachItem->{'pubDate'};
	my $description = wrap('', '', $eachItem->{'description'});
	my $link = $eachItem->{'link'};
	 
	
		#checks if the author field && creator have any data in the rss for the item
		#if 1 of the fields have author info, then that will be the author
		#<author> will always have precedence over dc:creator
		if(!defined($author) && !defined($creator))
		{
			$realAuthor = 'Not Given';
		}
		elsif(defined($author))
		{
			$realAuthor = $author;
		}
		else
		{
			$realAuthor = $creator;
		}
		
		
		#checks if the published date exists in the rss for the item
		#if no published date, generate current date as stamp
		if(!defined($pubDate))
		{
			#when passing no arguments, it will generate current time in GMT
			my $pubDate = DateTime::Format::HTTP->format_datetime();
		}
		
	
	 
	 #my $parser = HTML::TokeParser->new(\$description);
	 #$description = $parser->get_trimmed_text("description");
	$description = cleanHtml("description", $description);
	$description = wrap('', '',$description);
	 print "-------------------------------------------------------------------------------\n";
	 print "                                   NEWS ARTICLE \n";
	 print "-------------------------------------------------------------------------------\n";
	 print "Title:\n";
	 print "$title\n\n";
	 print "Author: $realAuthor\n";
	 print "Published Date: $pubDate \n\n";
	 print "Description:\n";
	 print "$description\n";
	 print  "-------------------------------------------------------------------------------\n";
	 print  "                                  END ARTICLE \n";
	 print  "-------------------------------------------------------------------------------\n\n";
	 
 }

#pass tag name & string data 
#subroutine strips out html elements from each rss item being parsed
sub cleanHtml
 {
	my $tag = "$_[0]";
	my $rawHtml = "$_[1]";
 
	#creates parser object	 
	my $parser = HTML::TokeParser->new(\$rawHtml);
	$parser->{'textify'} = {}; #annomous hash turns off special tags;
	#return $parser->get_trimmed_text("$tag");
	return $parser->get_trimmed_text('');
 }

exit 0;
	
	
	
	
	
=pod

=head1 NAME

Reader RSS_URL

=head1 DESCRIPTION

This script will accept 1 RSS url as the first argument. 
The script will determine whether the URL is a valid web location and check if the url is rss parsable, 
An error be presented if the url is not valid or rss compatible

The script will filter through an rss file specified in the first argument and output the rss news items 
to standard output(terminal) in the following format
Title:

Author:

Published Date:

Description:


=head1 ASSUMPTIONS

=item * Users will enter a valid rss url as an argument
=item * Users will be using a UTF-8 enabled terminal (no funky characters)

=head1 AUTHOR

Joshua Yu s323 5184
COSC1093 - Scripting Language Programming Sem 1 2013

=cut

__END__