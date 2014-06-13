#!/usr/bin/env perl

# Bypass bluetongue.cs proxy environmental variable
$ENV{"http_proxy"} = ""; 

use strict;
use warnings;
use open qw{:std :utf8};


use LWP::Simple;
use XML::RSS;
use HTML::TokeParser;
use DateTime::Format::Strptime;
use DateTime::Format::HTTP;

use Data::Dumper;
use Text::Wrap;
$Text::Wrap::columns = 80;

use Encode;
use HTML::Entities;

use HTML::Template;

#References
#http://perl5maven.com/open-and-read-from-files
#http://search.cpan.org/dist/DateTime-Format-Strptime/lib/DateTime/Format/Strptime.pm
#http://datetime.perl.org/wiki/datetime/page/FAQ%3A_Basic_Usage
#http://search.cpan.org/dist/DateTime-Format-HTTP/lib/DateTime/Format/HTTP.pm#parse_datetime(_$str_[,_$zone]_)


#Require 2 cmd arguments .
#1st arg is text file of rss URLS
#2nd arg is for path to the output file
#3rd arg is for the starting date for filter


#checks the argument count that is passed in
if (@ARGV < 2 || @ARGV > 3)
{
	print "\nERROR: Script requires 2 arguments to run and 1 optional\n";
	print"USAGE: $0 URL_FILE.txt {*.txt|*.xml|*.html} [dd/mm/yyyy]\n";
	die("Exiting\n");
}

#reading file

my $fileName = $ARGV[0]; #enable later
my $outputFileName = $ARGV[1]; #enable later



#checks if the first argument has a .txt file extension
if($fileName =~ /^.*\.(txt)$/i )
{
	print "First argument has .txt extension\n"
}
else
{
	die("ARGUMENT MISMATCH - Feeds URL argument only accepts .txt\n");
}

if ($outputFileName =~ /^.*\.(xml|html|txt)$/i)
{
	print "Second argument extension is compatible\n";	
}
else
{
	die("ARGUMENT MISMATCH - .txt | .html | .xml only accepted in second argument\n");
}

my @unsortedStories=(); #stors all the stories in no specified order
my @sortedStories=(); #stores the sorted news article 




open (my $fh,'<',$fileName) or die "Cannot open $fileName for reading\n";

#read each line in the url file
while (my $row = <$fh>)
{
	chomp $row; # rids the new line character per url
	fetchRss("$row");
}
close $fh; #closes file header for url file

	#sort stories in array by date(RSS ID) into a new array
	@sortedStories = sort {$b->{ID} <=> $a-> {ID}} @unsortedStories;
	print "Sorting RSS feed by published date .. Complete\n";
	#print Dumper(@sortedStories);
	
	
	
#if the date argument is entered
if(@ARGV > 2)
{
	my $startDate = $ARGV[2];
	
	eval
	{
		#extract time and date from specified date
		#should return an unified date/time which can be compared with RSS ID's
		$startDate = stripDateTime($startDate);
	}; die "\nERROR! - Date is malformed\n" if $@;
	
	
	my $spliceCounter =0;
	# loop through the sorted array and find the index where start news item is 
	#older than the date specified
	#if the pubdate is < than the unified date
	
	foreach my $item (@sortedStories)
	{
		if ($item->{'ID'} > $startDate)
		{
			$spliceCounter++;
		}
	}
	#print("Splice counter is $spliceCounter\n");
	if($spliceCounter > 0)
	{
		my $arrayEnd =scalar(@sortedStories);
		splice(@sortedStories, "$spliceCounter","$arrayEnd" );
	}
	
	#print Dumper(@sortedStories);
	
} #end IF	
	
	#determines which output file format to do
	if ($outputFileName =~ /^.*\.(txt)$/i)
	{
		writeToText();
	}
	elsif($outputFileName =~ /^.*\.(xml)$/i)
	{
		writeToRSS();
	}
	elsif($outputFileName =~ /^.*\.(html)$/i)
	{
		writeToHTML();
	}

	print "Script Finished\n";


#Fetches the rss feeds and parses it into a hash data structure with tags as the keys
sub fetchRss
{
	my $rssParser = new XML::RSS (version => '2.0');
	my $rssUrl = "$_[0]";
	print "Processing URL: $rssUrl\n";
	my $content = get($rssUrl) or die 'Unable to retrieve page with LWP::Simple';
	
	$content = decode "utf8", $content; #decode will fix the wide character issue
	#try/catch - Tests if the url is able to be parsed by XML::RSS
	eval
	{
		$rssParser->parse($content);	
		
	}; die "\nERROR! - Unable to parse contents\n - Is the URL a rss file?\n" if $@;
	
	foreach my $eachItem (@{$rssParser->{'items'}})
	{
		my $realAuthor; 
		#fetch the data from the appropiate tags
		my $title = $eachItem->{'title'};
		my $creator = $eachItem->{'dc'}->{'creator'};
		my $author = $eachItem->{'author'};
		my $pubDate = $eachItem->{'pubDate'};
		my $description = $eachItem->{'description'};
		my $link = $eachItem->{'link'};
	 
		my $cleanDescription = cleanHtml('description', $description);
	 
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
		#if no published date, generate current date/time as stamp
		if(!defined($pubDate))
		{
			#when passing no arguments, it will generate current time in GMT
			my $pubDate = DateTime::Format::HTTP->format_datetime();
		}
		
		#converts all dates and time to human Readable GMT
		#used when displaying the feed items
		$pubDate = humanReadableTime($pubDate);
		
		#used to unify time and date to be used for chronlogical comparison
		my $uniformedDate = stripDateTime($pubDate);
	
		#adds a news item (story) as a hash to the end of the unsorted array
		push @unsortedStories, { 
		'Title' => "$title",
		'Author' => "$realAuthor",
		'ID' =>"$uniformedDate",
		'Date' => "$pubDate",
		'Description' => "$cleanDescription",
		'Link' => "$link"
		};
	
	} #end foreach
} #end fetchRss subroutine

#writes rss news items to a txt file
sub writeToText
{
my @array = @sortedStories;

print "Writing to Text File $outputFileName\n";
open(my $fh, '>', $outputFileName) or die "Could not open $outputFileName to write to";

	foreach my $item (@array)
	{
	my $title = wrap('', '', $item->{'Title'});
	my $author = $item->{'Author'};
	my $pubDate = $item->{'Date'};
	my $description = wrap('', '',$item->{'Description'});
	my $url = wrap('', '', $item->{'Link'});

	print $fh "-------------------------------------------------------------------------------\n";
	print $fh "                                  NEWS ARTICLE \n";
	print $fh "-------------------------------------------------------------------------------\n";
	print $fh "Title:\n";
	print $fh "$title\n";
	print $fh "Author: $author\n";
	print $fh "Published Date: $pubDate \n\n";
	print $fh "Description:\n"; 
	print $fh "$description\n\n";
	print $fh "URL:\n";
	print $fh "$url\n";
	print $fh "-------------------------------------------------------------------------------\n";
	print $fh "                                  END ARTICLE \n";
	print $fh "-------------------------------------------------------------------------------\n\n";
	} #end foreach
close $fh;
}

#converts the rss time and returns human readable GMT date/time 
sub humanReadableTime
{
	my $RSSDate = "$_[0]";

	#converts majority of time formats to a uniform date format (machine time)
	#http://search.cpan.org/dist/DateTime-Format-HTTP/lib/DateTime/Format/HTTP.pm#parse_datetime(_$str_[,_$zone]_)
	my $uniformMacTime = DateTime::Format::HTTP->parse_datetime($RSSDate);
	
	#converts from machine code to GMT format (date string)
	my $dstring = DateTime::Format::HTTP->format_datetime($uniformMacTime);
	return "$dstring";
} #end humanReadableTime sub


#writes rss news contents to HTML file
sub writeToHTML
{
	my @array = @sortedStories;

	
	print "Writing to HTML file $outputFileName\n";
	open(my $fh, '>', $outputFileName) or die 'Could not open $outputFileName to write to';

	# instantiate the template and substitute the values
	my $template;
	eval
	{
	 $template = HTML::Template->new(filename => 'template.tmpl');
	}; die "ERROR - something wrong with template\n" if $@;
	
	#print Dumper(@array);
	$template->param(ROWS => \@sortedStories);
	
	my $markUp  = $template->output();
	print $fh "$markUp";
	close $fh;
	
} #end writeToHTML
sub writeToRSS
{
	my @array = @sortedStories;
	print "Creating RSS File\n";

	my $rss = new XML::RSS (version => '2.0', encoding=> 'UTF-8');
	$rss->add_module(prefix=>'my', uri=>'http://purl.org/dc/elements/1.1/');

	#creating the start of the RSS channel
	$rss->channel(title          => 'SLP 2013 S1 Latest Feeds',
               link           => 'http://numbat.cs.rmit.edu.au/~s3235184/',
               language       => 'en',
               description    => 'My rss feeds',
               rating         => 'n/a',
               copyright      => 'Copyright 2013, Joshua Yu',
               pubDate        => 'Fri, 19 Apr 2013 00:00:00 GMT',
               lastBuildDate  => 'Fri, 19 Apr 2013 00:00:00 GMT',
               docs           => 'http://numbat.cs.rmit.edu.au/~s3235184/',
               managingEditor => 's3235184@student.rmit.edu.au (Joshua Yu)',
               webMaster      => 's3235184@student.rmit.edu.au (Joshua Yu)'
               );


	#Creates each item for the xml file
	foreach my $item (@array)
	{
	#my $title = wrap('', '', $item->{'Title'});
	#print "$author\n";
	#my $description = wrap('', '',$item->{'Description'});
	#my $url = wrap('', '', $item->{'Link'});


	my $author = $item->{'Author'};
	my $pubDate = $item->{'Date'};
	my $title = $item->{'Title'};
	my $description = $item->{'Description'};

	$description = decode_entities($description);
	my $link = $item->{'Link'};


	#adding each article to the RSS channel
	$rss->add_item(
				title => "$title",
				description => "$description",
				pubDate => "$pubDate",
				link => "$link",
				permaLink => "$link",
				dc => {
						creator => "$author", },
				author => "$author"	
				);			
	} #end foreach
	eval
	{
		$rss->save("$outputFileName");
	}; die "\nERROR! - Unable to save RSS file\n" if $@;

} # end subroutine

#subroutine strips out html elements from each rss item being parsed
sub cleanHtml
{
	my $tag = "$_[0]";
	my $rawHtml = "$_[1]";

	#creates parser object	 
	my $parser = HTML::TokeParser->new(\$rawHtml);
 
	$parser->{'textify'} = {}; #annomous hash turns off special tags;
	#http://www.perlmonks.org/bare/?node_id=507285
	#http://lwp.interglacial.com/ch07_05.htm
	#return $parser->get_trimmed_text("$tag");
	return $parser->get_trimmed_text('');
} #end cleanHtml subroutine
 
 
 
 #This function will convert the different date formats in the rss feeds to a 
 #unified machine code format eg 1994-02-03T14:15:29 (T as separator) then
 #extract and reformat the time/date to form a ID for each news item
 sub stripDateTime
 {
	my $RSSDate = "$_[0]";
 
	#converts majority of time formats to a uniform date format (machine time)
	my $uniformMacTime = DateTime::Format::HTTP->parse_datetime($RSSDate);

	
	#Overall this will allow me to extract the specifc parts of the machine code date string
	#which was converted from Format::HTTP	
	
	#creating object with the following constuctors on what format pattern to expect
	#AKA what is the format will the string that will be passed in
	my $stripObject = DateTime::Format::Strptime->new(
	# pattern   => '%a, %d %b %Y %T', #this pattern to strip GMT format date/time
	pattern   => '%Y-%m-%dT%T', #this pattern used for stripping the data from machine code time
	time_zone => 'Australia/Melbourne',
	on_error  => 'croak',
	);


	my $dateString = $stripObject->parse_datetime($uniformMacTime); #
	return $dateString->strftime('%d%m%Y%H%M%S'); #prints the date in the specific format
} #end stripDateTime subroutine
exit 0;


=pod

=head1 NAME

aggregator URL_FILE output_FILE [dd/mm/yyyy]

=head1 DESCRIPTION


This script will aggregate all rss news items from a txt file containing RSS urls on each line 
and sort them by published date then output  the contents to the following extenstions as 
specified in the second argument.

NOTE: specifying output file name must include the extension.
NOTE: URLS specified in LIST_OF_URLS.txt file must each be on new lines.
NOTE: The default behaviour of the writing output files is to replace NOT append
NOTE: The file containing the url feeds must be .txt
NOTE: Default sorting is from Newest to Oldest
NOTE: DO not remove/modify the template file as that is used to output to html


Supported output file types:
*.txt
*.html
*.xml

Example:
./aggregator LIST_OF_URLS.txt output.txt
./aggregator LIST_OF_URLS.txt output.xml
./aggregator LIST_OF_URLS.txt output.html

Example of format rss urls should be is included as url_lol.txt

A third argument can be specified which allows the aggregator to filter news items and only output
news items on and after the date specified (Begin date) Time zone is also ignored. 
FORMAT: dd/mm/yy

Example
./aggregator LIST_OF_URLS.txt output.txt 22/04/2013

The saved files are typically saved in the current directory where the script is stored

=head1 KNOWN BUGS
Due to certain libraries on yallara being out of date, UTF8 HTML Hex entites will show in the xml RSS
(Discussed on discussion board) - Used all soulutions provided to no avail

Was unable to output dc:creator to rss, although my data stucture did have it. I followed 
the cpan documentation for the module but still didnt output

Some text viewers may see funny chracters if the text viewer is not in UTF8 Encode mode
(may be seen by others as a bug)

=head1 ASSUMPTIONS

=item * Users will not modify the template which is used for outputing to html
=item * Assume the txt file containing the rss urls is a text file with the .txt extension
=item * Users not entering directory paths into arguments
=item * Certain HTML entities text is counted as content, eg img text 
=item * Each rss url is on a new line in the txt file
=item * User will not input a future date as the third argument
=item * Each rss url being valid



=head1 AUTHOR

Joshua Yu s323 5184
COSC1093 - Scripting Language Programming Sem 1 2013

=cut

__END__




