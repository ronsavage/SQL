#!/usr/bin/env perl
#
# @(#)$Id: bnf2html.pl,v 3.16 2017/11/14 06:53:22 jleffler Exp $
#
# Convert SQL-92, SQL-99 BNF plain text file into hyperlinked HTML.

use strict;
use warnings;
use POSIX qw(strftime);
#use Data::Dumper;

use constant debug => 0;

my(%rules);     # Indexed by rule names w/o angle-brackets; each entry is a ref to a hash.
my(%keywords);  # Index by keywords; each entry is a ref to a hash.
my(%names);     # Indexed by rule names w/o angle-brackets; each entry is a ref to an array of line numbers

sub top
{
print "<p><a href='#top'>Top</a></p>\n\n";
}

# Usage: add_rule_name(\%names, $rulename, $.);
sub add_rule_name
{
    my($reflist, $lhs, $line) = @_;
    #print "\nrulename = $lhs; line = $line\n";
    if (defined ${$reflist}{$lhs})
    {
        #print Data::Dumper->Dump([ ${$reflist}{$lhs} ], qw[ ${$reflist}{$lhs} ]);
        #print Data::Dumper->Dump([ \@{${$reflist}{$lhs}} ], qw[ \@{${$reflist}{$lhs}} ]);
        my @lines = @{${$reflist}{$lhs}};
        print STDERR "\n$0: Rule <$lhs> at line $line already seen at line(s) ", join(", ", @lines), "\n\n";
    }
    else
    {
        ${$reflist}{$lhs} = [];
    }
    push @{${$reflist}{$lhs}}, $line;
}

# Usage: add_entry(\%keywords, $keyword, $rule);
# Usage: add_entry(\%rules, $rhs, $rule);
sub add_entry
{
    my($reflist, $lhs, $rhs) = @_;
    ${$reflist}{$lhs} = {} unless defined ${$reflist}{$lhs};
    ${$reflist}{$lhs}{$rhs} = 1;
}

sub add_refs
{
    my($def, $tail) = @_;
    print "\n<!-- ADD REFS ($def) ($tail) -->\n" if debug;
    return if $tail =~ m/^!!/;
    return if $tail =~ m/^&(?:lt|gt|amp);$/;
    while ($tail)
    {
        $tail =~ s/^\s*//;
        if ($tail =~ m%^\&lt;([-:/\w\s]+)\&gt;%)
        {
            print "<!-- Rule - LHS: $def - RHS $1 -->\n" if debug;
            add_entry(\%rules, $1, $def);
            $tail =~ s%^\&lt;([-:/\w\s]+)\&gt;%%;
        }
        elsif ($tail =~ m%^([-:/\w]+)%)
        {
            my($token) = $1;
            print "<!-- KyWd - LHS: $def - RHS $token -->\n" if debug;
            add_entry(\%keywords, $token, $def) if $token =~ m%[[:alpha:]][[:alpha:]]% || $token eq 'C';
            $tail =~ s%^[-:/\w]+%%;
        }
        else
        {
            # Otherwise, it is punctuation (such as the BNF metacharacters).
            $tail =~ s%^[^-:/\w]%%;
        }
    }
}

# NB: webcode replaces tabs with blanks!
open( my $WEBCODE, "-|", "webcode @ARGV") or die "$!";

# Read first line of file - use as title in head and in H1 heading in body
$_ = <$WEBCODE>;
exit 0 unless defined($_);
chomp;

# Is it wicked to use double quoting with single quotes, as in qq'text'?
# It is used quite extensively in this script - beware!
print qq'<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">\n';
print "<!-- Generated HTML - Modify at your own peril! -->\n";
print "<html>\n<head>\n";
print "<title> $_ </title>\n</head>\n<body>\n\n";
print "<h1> $_ </h1>\n\n";
print qq'<a name="top">&nbsp;</a>\n';

print "<br>\n";
print qq'<a href="#xref-rules"> Cross-Reference: rules </a>\n';
print "<br>\n";
print qq'<a href="#xref-keywords"> Cross-Reference: keywords </a>\n';
print "<br>\n";

sub rcs_id
{
    my($id) = @_;
    $id =~ s%^(@\(#\))?\$[I]d: %%o;
    $id =~ s% \$$%%o;
    $id =~ s%,v % %o;
    $id =~ s%\w+ Exp( \w+)?$%%o;
    my(@words) = split / /, $id;
    my($version) = "file $words[0] version $words[1] dated $words[2] $words[3]";
    return $version;
}

sub iso8601_format
{
    my($tm) = @_;
    my $today = strftime("%Y-%m-%d %H:%M:%S+00:00", gmtime($tm));
    return($today);
}

# Print hrefs for non-terminals and keywords.
# Also substitute /* Nothing */ for an absence of productions between alternatives.
sub print_tail
{
    my($tail, $tcount) = @_;
    while ($tail)
    {
        my($newtail);
        if ($tail =~ m%^\s+%)
        {
            my($spaces) = $&;
            $newtail = $';
            print "<!-- print_tail: SPACES = '$spaces', NEWTAIL = '$newtail' -->\n" if debug;
            $spaces =~ s% {4,8}%&nbsp;&nbsp;&nbsp;&nbsp;%g;
            print $spaces;
            # Spaces are not a token - don't count them!
        }
        elsif ($tail =~ m%^'[^']*'% || $tail =~ m%^"[^"]*"% || $tail =~ m%^!!.*$%)
        {
            # Quoted literal - print and ignore.
            # Or meta-expression...
            my($quote) = $&;
            $newtail = $';
            print "<!-- print_tail: QUOTE = <$quote>, NEWTAIL = '$newtail' -->\n" if debug;
            $quote =~ s%!!.*%<font color="red"> $quote </font>%;
            print $quote;
            $tcount++;
        }
        elsif ($tail =~ m%^\&lt;([-:/\w\s]+)\&gt;%)
        {
            my($nonterm) = $&;
            $newtail = $';
            print "<!-- print_tail: NONTERM = '$nonterm', NEWTAIL = '$newtail' -->\n" if debug;
            $nonterm =~ s%\&lt;([-:/\w\s]+)\&gt;%<a href='#$1'>\&lt;$1\&gt;</a>%;
            print " $nonterm";
            $tcount++;
        }
        elsif ($tail =~ m%^[\w_]([-._\w]*[\w_])?%)
        {
            # Keyword
            my($keyword) = $&;
            $newtail = $';
            print "<!-- print_tail: KEYWORD = '$keyword', NEWTAIL = '$newtail' -->\n" if debug;
            print(($keyword =~ m/^\d\d+$/) ? $keyword : qq' <a href="#xref-$keyword"> $keyword </a>');
            $tcount++;
        }
        else
        {
            # Metacharacter, string literal, etc.
            $tail =~ m%\S+%;
            my($symbol) = $&;
            $newtail = $';
            print "<!-- print_tail: SYMBOL = '$symbol', NEWTAIL = '$newtail' -->\n" if debug;
            if ($symbol eq '|')
            {
                print "<font color=red>/* Nothing */</font> " if $tcount == 0;
                $tcount = 0;
            }
            else
            {
                $symbol =~ s%...omitted...%<font color=red>/* $& */</font>%i;
                $tcount++;
            }
            print " $symbol";
        }
        $tail = $newtail;
    }
    return($tcount);
}

sub undo_web_coding
{
    my($line) = @_;
    $line =~ s%&gt;%>%g;
    $line =~ s%&lt;%<%g;
    $line =~ s%&amp;%&%g;
    return $line;
}

my $hr_count = 0;
my $tcount = 0;                 # Ick!
my $def;                        # Current rule

# Don't forget - the input has been web-encoded!

while (<$WEBCODE>)
{
    chomp;
    next if /^===*$/o;
    s/\s+$//o;  # Remove trailing white space
    if (/^$/)
    {
        print "\n";
    }
    elsif (/^---*$/)
    {
        print "<hr>\n";
    }
    elsif (/^--@@\s*(.*)$/)
    {
        my $comment = undo_web_coding($1);
        print "<!-- $comment -->\n";
    }
    elsif (/^@.#..Id:/)
    {
        # Convert what(1) string identifier into version information
        my $id = '$Id: bnf2html.pl,v 3.16 2017/11/14 06:53:22 jleffler Exp $';
        my($v1) = rcs_id($_);
        my $v2 = rcs_id($id);
        print "<p><font color=green><i><small>\n";
        print "Derived from $v1\n";
        my $today = iso8601_format(time);
        print "<br>\n";
        print "Generated on $today by $v2\n";
        print "</small></i></font></p>\n";
    }
    elsif (/\s+::=/)
    {
        # Definition line
        $def = $_;
        $def =~ s%\&lt;([-:/()\w\s]+)\&gt;.*%$1%;
        my($tail) = $_;
        $tail =~ s%.*::=\s*%%;
        print qq'<p><a href="#xref-$def" name="$def"> &lt;$def&gt; </a>&nbsp;&nbsp;&nbsp;::=';
        $tcount = 0;
        add_rule_name(\%names, $def, $.);
        if ($def eq "vertical bar")
        {
            # Needs special case attention to avoid a /* Nothing */ comment appearing.
            # Problem pointed out by Jens Odborg (jho1965us@gmail.com) 2016-04-14.
            # This builds knowledge of the SQL language definition into this script;
            # ugly, but trying to fix it in the print_tail function is probably worse.
            print "&nbsp;&nbsp;|";
        }
        elsif ($tail)
        {
            add_refs($def, $tail);
            print "&nbsp;&nbsp;";
            $tcount = print_tail($tail, $tcount);
        }
        print "\n";
    }
    elsif (/^\s/)
    {
        # Expansion line
        add_refs($def, $_);
        print "<br>";
        $tcount = print_tail($_, $tcount);
    }
    elsif (m/^--[\/]?(\w+)/)
    {
        # Pseudo-directive line in lower-case
        # Print a 'Top' link before <hr> tags except first.
        top if /--hr/ && $hr_count++ > 0;
        s%--(/?[a-z][a-z\d]*)%<$1>%;
        s%\&lt;([-:/\w\s]+)\&gt;%<a href='#$1'>\&lt;$1\&gt;</a>%g;
        print "$_\n";
    }
    elsif (m%^--##%)
    {
        $_ = undo_web_coding($_);
        s%^--##\s*%%;
        print "$_\n";
    }
    elsif (m/^--%start\s+(\w+)/)
    {
        # Designated start symbol
        my $start = $1;
        print qq'<p><b>Start symbol: </b> <a href="#$start"> $start </a></p>\n';
    }
    else
    {
        # Anything unrecognized passed through unchanged!
        print "$_\n";
    }
}

close $WEBCODE;

# Print index of initial letters for keywords.
sub print_index_key
{
    my($prefix, @keys) = @_;
    my %letters = ();
    foreach my $keyword (@keys)
    {
        my $initial = uc substr $keyword, 0, 1;
        $letters{$initial} = 1;
    }
    foreach my $letter ('A' .. 'Z')
    {
        if (defined($letters{$letter}))
        {
            print qq'<a href="#$prefix-$letter"> $letter </a>\n';
        }
        else
        {
            print qq'$letter\n';
        }
    }
    print "\n";
}

### Generate cross-reference tables

{
print "<br>\n\n";
print "<hr>\n";
print qq'<a name="xref-rules"></a>\n';
print "<h2> Cross-Reference Table: Rules </h2>\n";

print_index_key("rules", keys %rules);

print "<table border=1>\n";
print "<tr> <th> Rule (non-terminal) </th> <th> Rules using it </th> </tr>\n";
my %letters = ();

foreach my $rule (sort { uc $a cmp uc $b } keys %rules)
{
    my $initial = uc substr $rule, 0, 1;
    my $label = "";
    if (!defined($letters{$initial}))
    {
        $letters{$initial} = 1;
        $label = qq'<a name="rules-$initial"> </a>';
    }
    print qq'<tr> <td> $label <a href="#$rule" name="xref-$rule"> $rule </a> </td>\n     <td> ';
    my $pad = "";
    foreach my $ref (sort { uc $a cmp uc $b } keys %{$rules{$rule}})
    {
        print qq'$pad<a href="#$ref"> &lt;$ref&gt; </a>\n';
        $pad = "          ";
    }
    print "     </td>\n</tr>\n";
}
print "</table>\n";
print "<br>\n";
top;
}

{
print "<hr>\n";
print qq'<a name="xref-keywords"></a>\n';
print "<h2> Cross-Reference Table: Keywords </h2>\n";

print_index_key("keywords", keys %keywords);

print "<table border=1>\n";
print "<tr> <th> Keyword </th> <th> Rules using it </th> </tr>\n";
my %letters = ();
foreach my $keyword (sort { uc $a cmp uc $b } keys %keywords)
{
    my $initial = uc substr $keyword, 0, 1;
    my $label = "";
    if (!defined($letters{$initial}))
    {
        $letters{$initial} = 1;
        $label = qq'<a name="keywords-$initial"> </a>';
    }
    print qq'<tr> <td> $label <a name="xref-$keyword"> </a> $keyword </td>\n     <td> ';
    my $pad = "";
    foreach my $ref (sort { uc $a cmp uc $b } keys %{$keywords{$keyword}})
    {
        print qq'$pad<a href="#$ref"> &lt;$ref&gt; </a>\n';
        $pad = "          ";
    }
    print "     </td>\n</tr>\n";
}
print "</table>\n";
print "<br>\n";
top;
print "<hr>\n";
}

printf "%s\n", q'Please send feedback to Jonathan Leffler:';
printf "%s\n", q'<a href="mailto:jonathan.leffler@gmail.com"> jonathan.leffler@gmail.com </a>.';

print "\n</body>\n</html>\n";

__END__

=pod

=head1 PROGRAM

bnf2html - Convert (ISO SQL) BNF Notation to Hyperlinked HTML

=head1 SYNTAX

bnf2html [file ...]

=head1 DESCRIPTION

The bnf2html filters the annotated BNF (Backus-Naur Form) from its input
files and converts it into HTML on standard output.

The HTML is heavily hyperlinked.
Each rule (LHS) links to a table of other rules where it is used on the
RHS.
Similarly, each symbol on the RHS is linked to the rule that defines it.
Thus, it is possible to find where items are used and defined quite
easily.

=head1 INPUT FORMAT

This script is adapted to the BNF notation using in the SQL standard
(ISO/IEC 9075:2003, for example).
It also takes various forms of annotations.

The first line of the file is used as the title in the head section.
It is also used as the text for a H1 header at the top of the body.

Lines consisting of two or more equal signs are ignored.

Lines consisting of two or more dashes are converted to a horizontal
rule.

Lines starting with the SCCS identification string '@(#)' are used to
print version information about the file converted and the script doing
the converting.

Lines containing space, colon, colon, equals are treated as rules.

Lines starting with white space are treated as continuations of a rule.

Lines starting dash, dash, (optionally a slash) and then one or more tag
letters are converted into an HTML start or end tag.

Any line starting dash, dash, hash, hash has any HTML entities
introduced by the WEBCODE program removed.

The should be at most one line starting '--%start'; this indicates the
start symbol for the bnf2yacc converter, but is effectively ignored by
bnf2html.

Any other line is passed through verbatim.

=head1 AUTHOR

Jonathan Leffler <jonathan.leffler@gmail.com>

=cut
