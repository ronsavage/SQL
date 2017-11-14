#!/usr/bin/perl -w
#
# @(#)$Id: bnf2yacc.pl,v 1.16 2017/11/14 06:53:22 jleffler Exp $
#
# Convert SQL-92, SQL-99 BNF plain text file into YACC grammar.

use strict;
$| = 1;

use constant debug => 0;

my $heading = "";
my %tokens;
my %nonterminals;
my %rules;
my %used;
my $start;
my @grammar;

my $nt_number = 0;

# Generate a new non-terminal identifier
sub new_non_terminal
{
    my($prefix) = @_;
    $prefix = "" unless defined $prefix;
    return sprintf "${prefix}nt_%03d", ++$nt_number;
}

# map_non_terminal converts names that are not acceptable to Yacc into names that are.
# Non-identifier characters are converted to underscores.
# If the first character is not alphabetic, prefix 'j_'.
# Case-convert to lower case.
sub map_non_terminal
{
    my($nt) = @_;
    $nt =~ s/\W+/_/go;
    $nt = "j_$nt" unless $nt =~ m/^[a-zA-Z]/o;
    $nt =~ tr/[A-Z]/[a-z]/;
    $nt =~ s/__+/_/go;
    return $nt;
}

# scan_rhs breaks up the RHS of a rule into a token stream
# Keywords (terminals) are prefixed with a '#' marker.
sub scan_rhs
{
    my($tail) = @_;
    my(@rhs);
    while ($tail)
    {
        print "RHS: $tail\n" if debug;
        my $name;
        if ($tail =~ m%^(\s*<([-:/()_\w\s]+)>\s*)%o)
        {
            # Simpler regex for non-terminal: <[^>]+>
            # Non-terminal
            my $n = $2;
            print "N: $n\n" if debug;
            $tail = substr $tail, length($1);
            $name = map_non_terminal($n);
            $nonterminals{$name} = 1;
            $used{$name} = 1;
            push @rhs, $name;
        }
        elsif ($tail =~ m%^(\s*(\w[-\w\d_.]*)\s*)%o)
        {
            # Terminal (keyword)
            # Dot '.' is used in Interfaces.SQL in Ada syntax
            # Dash '-' is used in EXEC-SQL in the keywords.
            my $t = $2;
            print "T: $t\n" if debug;
            $tail = substr $tail, length($1);
            $name = $t;
            $tokens{$name} = 1;
            push @rhs, "#$name";
        }
        elsif ($tail =~ m%^\s*(\.\.\.omitted\.\.\.)\s*%o)
        {
            # Something omitted from the grammar.
            # Triple punctuation detected before double.
            my $str = "/* $1 */";
            push @rhs, $str;
            last;
        }
        elsif ($tail =~ m{^(\s*([-.<=>|]{2})\s*)$}o)
        {
            # Double-punctuation (non-metacharacters)
            # .., <=, >=, <>, ||, ->
            my $p = $2;
            print "DP: $p\n" if debug;
            $tail = substr $tail, length($1);
            $name = "'$p'";
            push @rhs, $name;
        }
        elsif ($tail =~ m{^(\s*([][{}"'%&()*+,-./:;<=>?^_|])\s*)$}o)
        {
            # Punctuation (non-metacharacters)
            # Note that none of '@', '~', '!' or '\' have any significance in SQL
            my $p = $2;
            print "P: $p\n" if debug;
            $tail = substr $tail, length($1);
            $p = "\\'" if $p eq "'";
            $name = "'$p'";
            push @rhs, $name;
        }
        elsif ($tail =~ m%^(\s*('[^']*'))\s*%o ||
               $tail =~ m%^(\s*("[^"]*"))\s*%o)
        {
            # Terminal in quotes - single or double.
            # (Possibly a multi-character string).
            my $q = $2;
            print "Q: $q\n" if debug;
            $tail = substr $tail, length($1);
            $q =~ m%^(['"])(.+)['"]$%o;
            # Expand multi-character string constants.
            # into repeated single-character constants.
            my($o) = $1;
            my($l) = $2;
            while (length($l))
            {
                my($c) = substr $l, 0, 1;
                $name = "$o$c$o";
                $l = substr $l, 1, length($l)-1;
                push @rhs, $name;
            }
        }
        elsif ($tail =~ m%^(\s*([{}\|\[\]]|\.\.\.)\s*)%o)
        {
            # Punctuation (metacharacters)
            my $p = $2;
            print "M: $p\n" if debug;
            $tail = substr $tail, length($1);
            $name = $p;
            push @rhs, $name;
        }
        elsif ($tail =~ m%^\s*!!%o)
        {
            # Exhortation to see the syntax rules - usually.
            my $str = "/* $tail */";
            push @rhs, $str;
            last;
        }
        else
        {
            # Unknown!
            print "/* UNK: $tail */\n";
            print STDERR "UNK:$.: $tail\n";
            last;
        }
    }
    return(@rhs);
}

# Format a Yacc rule given LHS and RHS array
sub record_rule
{
    my($lhs, $comment, @rule) = @_;
    my($production) = "";
    print "==>> record_rule ($lhs : @rule)\n" if debug;
    $production .= "/*\n" if $comment;
    $production .= "$lhs\n\t:\t";
    my $pad = "";
    my $br_count = 0;
    for (my $i = 0; $i <= $#rule; $i++)
    {
        my $item = $rule[$i];
        print "==== item $item\n" if debug;
        if ($item eq "|" && $br_count == 0)
        {
            $production .= "\n\t|\t";
            $pad = "";
        }
        else
        {
            $production .= "$pad$item";
            $pad = " ";
            $br_count++ if ($item eq '[' or $item eq '{');
            $br_count-- if ($item eq ']' or $item eq '}');
        }
    }
    $production .= "\n\t;\n";
    $production .= "*/\n" if $comment;
    $production .= "\n";
    print "$production" if debug;
    push @grammar, $production;
    print "<<== record_rule\n" if debug;
}

sub print_iterator
{
    my($lhs,$rhs) = @_;
    my($production) = "";
    print "==>> print_iterator ($lhs $rhs)\n" if debug;
    $production .= "$lhs\n\t:\t$rhs\n\t|\t$lhs $rhs\n\t;\n\n";
    print "<<== print_iterator\n" if debug;
    push @grammar, $production;
}

# Process an optional item enclosed in square brackets
sub find_balanced_bracket
{
    my($lhs,@rhs) = @_;
    my(@rule) = ( "/* Nothing */", "|");
    print "==>> find_balanced_bracket ($lhs : @rhs)\n" if debug;
    while (my $name = shift @rhs)
    {
        print "     name = $name\n" if debug;
        if ($name eq ']')
        {
            # Found closing bracket
            # Terminate search
            last;
        }
        elsif ($name eq '[')
        {
            # Found nested optional clause
            my $tag = new_non_terminal('opt_');
            @rhs = find_balanced_bracket($tag, @rhs);
            push @rule, $tag;
        }
        elsif ($name eq '{')
        {
            # Found start of sequence
            my $tag = new_non_terminal('seq_');
            @rhs = find_balanced_brace($tag, @rhs);
            push @rule, $tag;
        }
        elsif ($name eq '}')
        {
            # Found unbalanced close brace.
            # Error!
        }
        elsif ($name eq '...')
        {
            # Found iteration.
            my $tag = new_non_terminal('lst_');
            print "==== find_balanced_bracket: iterator (@rule)\n" if debug;
            my($old) = pop @rule;
            push @rule, $tag;
            print "==== find_balanced_bracket: iterator ($tag/$old - @rule)\n" if debug;
            print_iterator($tag, $old);
        }
        else
        {
            $name =~ s/^#//;
            push @rule, $name;
            $used{$name} = 1;
        }
    }
    record_rule($lhs, 0, @rule);
    print "<<== find_balanced_bracket: @rhs)\n" if debug;
    return(@rhs);
}

# Process an sequence item enclosed in curly braces
sub find_balanced_brace
{
    my($lhs,@rhs) = @_;
    my(@rule);
    print "==>> find_balanced_brace ($lhs : @rhs)\n" if debug;
    while (my $name = shift @rhs)
    {
        print "     name = $name\n" if debug;
        if ($name eq '}')
        {
            # Found closing brace
            # Terminate search
            last;
        }
        elsif ($name eq '[')
        {
            # Found nested optional clause
            my $tag = new_non_terminal('opt_');
            @rhs = find_balanced_bracket($tag, @rhs);
            push @rule, $tag;
        }
        elsif ($name eq '{')
        {
            # Found start of sequence
            my $tag = new_non_terminal('seq_');
            @rhs = find_balanced_brace($tag, @rhs);
            push @rule, $tag;
        }
        elsif ($name eq ']')
        {
            # Found unbalanced close brace.
            # Error!
        }
        elsif ($name eq '...')
        {
            # Found iteration.
            my $tag = new_non_terminal('lst_');
            print "==== find_balanced_brace: iterator (@rule)\n" if debug;
            my($old) = pop @rule;
            push @rule, $tag;
            print "==== find_balanced_brace: iterator ($tag/$old - @rule)\n" if debug;
            print_iterator($tag, $old);
        }
        else
        {
            $name =~ s/^#//;
            push @rule, $name;
            $used{$name} = 1;
        }
    }
    record_rule($lhs, 0, @rule);
    print "<<== find_balanced_brace: @rhs)\n" if debug;
    return(@rhs);
}

# Note that the [ and { parts are nice and easy because they are
# balanced operators.  The iteration operator ... is much harder to
# process because it is a trailing modifier.  When processing the list
# of symbols, you need to establish whether there is a trailing iterator
# after the current symbol, and modify the behaviour appropriately.
sub process_rhs
{
    my($lhs, $tail) = @_;
    my(@rhs) = scan_rhs($tail);
    print "==>> process_rhs ($lhs : @rhs)\n" if debug;
    # List parsed rule in output only if debugging.
    record_rule($lhs, 1, @rhs) if debug;
    my(@rule);
    while (my $name = shift @rhs)
    {
        print "name = $name\n" if debug;
        if ($name eq '[')
        {
            my $tag = new_non_terminal('opt_');
            @rhs = find_balanced_bracket($tag, @rhs);
            push @rule, $tag;
        }
        elsif ($name eq ']')
        {
            # Found a close bracket for something unbalanced.
            # Error!
        }
        elsif ($name eq '{')
        {
            # Start of mandatory sequence of items, possibly containing alternatives.
            my $tag = new_non_terminal('seq_');
            @rhs = find_balanced_brace($tag, @rhs);
            push @rule, $tag;
        }
        elsif ($name eq '}')
        {
            # Found a close brace for something unbalanced.
            # Error!
        }
        elsif ($name eq '|')
        {
            # End of one alternative and start of a new one.
            print "==== process_rhs: alternative $name\n" if debug;
            push @rule, $name;
        }
        elsif ($name eq '...')
        {
            # Found iteration.
            my $tag = new_non_terminal('lst_');
            my($old) = pop @rule;
            push @rule, $tag;
            print "==== process_rhs: iterator\n" if debug;
            print_iterator($tag, $old);
        }
        elsif ($name =~ m/^#/)
        {
            # Keyword token
            print "==== process_rhs: token $name\n" if debug;
            $name =~ s/^#//;
            push @rule, $name;
        }
        else
        {
            # Non-terminal (or comment)
            print "==== process_rhs: non-terminal $name\n" if debug;
            push @rule, $name;
        }
    }
    print "==== process_rhs: @rule\n" if debug;
    record_rule($lhs, 0, @rule);
    print "<<== process_rhs\n" if debug;
}

sub count_unmatched_keys
{
    my($ref1, $ref2) = @_;
    my(%keys) = %$ref1;
    my(%match) = %$ref2;
    my($count) = 0;
    foreach my $key (keys %keys)
    {
        $count++ unless defined $match{$key};
    }
    return $count;
}

# ------------------------------------------------------------

open INPUT, "cat @ARGV |" or die "$!";
$_ = <INPUT>;
exit 0 unless defined($_);
chomp;
$heading = "%{\n/*\n** $_\n*/\n%}\n\n" unless m/^\s*$/;

# Commentary appears in column 1.
# Continuations of rules have a blank in column 1.
# Blank lines, dash lines and equals lines separate rules (are not embedded within them)..

while (<INPUT>)
{
    chomp;
    print "DBG:$.: $_\n" if debug;
    next if /^===*$/o;
    next if /^\s*$/o;	# Blank lines
    next if /^---*$/o;	# Horizontal lines
    if (/^--/o)
    {
        # Various HTML pseudo-directives
        if (m%^--/?\w+\b%)
        {
            print "/* $' */\n" if $';
        }
        elsif (/^--%start (\w+)/)
        {
            $start = $1;
            print "/* Start symbol - $start */\n";
        }
        elsif (/^--##/)
        {
            print "/* $_ */\n";
        }
        else
        {
            print "/* Unrecognized 2: $_ */\n";
        }
    }
    elsif (/^@.#..Id:/)
    {
        # Convert what(1) string identifier into version information
        s%^@.#..Id: %%;
        s% \$$%%;
        s%,v % %;
        s%\w+ Exp( \w+)?$%%;
        my @words = split;
        print "/*\n";
        print "** Derived from file $words[0] version $words[1] dated $words[2] $words[3]\n";
        print "*/\n";
    }
    elsif (/ ::=/)
    {
        # Definition line
        my $def = $_;
        $def =~ s%<([-:/()\w\s]+)>.*%$1%o;
        $def = map_non_terminal($def);
        $rules{$def} = 1;
        $nonterminals{$def} = 1;
        my $tail = $_;
        $tail =~ s%.*::=\s*%%;	# Remove LHS of statement
        while (<INPUT>)
        {
            chomp;
            last unless /^\s/;
            $tail .= $_;
        }
        process_rhs($def, $tail);
    }
    else
    {
        # Anything unrecognized passed through as a comment!
        print "/* $_ */\n";
    }
}

close INPUT;

print "==== End of input phase ====\n" if debug;

print $heading if $heading;

# List of tokens
foreach my $token (sort keys %tokens)
{
    print "\%token $token\n";
}
print "\n";

# Undefined non-terminals might need to be treated as tokens
if (count_unmatched_keys(\%nonterminals, \%rules) > 0)
{
    print "/* The following non-terminals were not defined */\n";
    foreach my $nt (sort keys %nonterminals)
    {
        print "%token $nt\n" unless defined $rules{$nt};
    }
    print "/* End of undefined non-terminals */\n\n";
}

# List the rules that are defined in the original grammar.
# Do not list the rules defined by this conversion process.
print "/*\n";
foreach my $nt (sort keys %nonterminals)
{
    print "\%rule $nt\n";
}
print "*/\n\n";


if (defined $start)
{
    print "%start $start\n\n";
    print "%%\n\n";
}
else
{
    # No start symbol defined - let's see if we can work out what to use.
    # If there's more than one unused non-terminal, then treat them
    # all as simple alternatives to a list of statements.
    my $count = count_unmatched_keys(\%nonterminals, \%used);

    if ($count > 1)
    {
        my $prog = "bnf_program";
        my $stmt = "bnf_statement";
        print "%start $prog\n\n";
        print "%%\n\n";
        print "$prog\n\t:\t$stmt\n\t|\t$prog $stmt\n\t;\n\n";
        print "$stmt\n";
        my $pad = "\t:\t";
        foreach my $nt (sort keys %nonterminals)
        {
            unless (defined $used{$nt})
            {
                print "$pad$nt\n";
                $pad = "\t|\t";
            }
        }
        print "\t;\n\n";
    }
    elsif ($count == 1)
    {
        foreach my $nt (sort keys %nonterminals)
        {
            print "%start $nt" unless defined $used{$nt};
        }
        print "%%\n\n";
    }
    else
    {
        # No single start symbol - loop?
        # Error!
        print STDERR "$0: no start symbol recognized!\n";
        print "%%\n\n";
    }
}

# Output the complete grammar
while (my $line = shift @grammar)
{
    print $line;
}

print "\n%%\n\n";

__END__

=pod

Given a rule:

  abc:  def ghi jkl

The Yacc output is:

  abc
      : def ghi jkl
      ;

Given a rule:

  abc:  def [ ghi ] jkl

The Yacc output is:

  abc
      : def opt_nt_0001 jkl
      ;

  opt_nt_0001
      : /* Nothing */
      | ghi
      ;

Given a rule:

  abc:  def { ghi } jkl

The Yacc output is:

  abc
      : def seq_nt_0002 jkl
      ;

  seq_nt_0002
      : ghi
      ;

Note that such rules are seldom used in isolation; either the contents
of the '{' to '}' contains alternatives, or the construct as a whole is
followed by a repetition.

Given a rule:

  abc: def | ghi

The Yacc output is:

  abc
      : def
      | ghi
      ;

Given a rule:

  abc: def ghi... jkl

The Yacc output is:

  abc
      : def lst_nt_0003 jkl
      ;

  lst_nt_0003
      : ghi
      | lst_nt_0003 ghi
      ;

These rules can be, and often are, combined.  The following examples
come from the SQL-99 grammar which is the target of this effort.  The
target of this program is to produce Yacc rules equivalent to those
which follow each fragment.  Note that keywords (equivalently,
terminals) are in upper case only; mixed case or lower case symbols are
non-terminals.

  <SQL-client module definition> ::=
                  <module name clause>
                  <language clause>
                  <module authorization clause>
                  [ <module path specification> ]
                  [ <module transform group specification> ]
                  [ <temporary table declaration>... ]
                  <module contents>...

  SQL_client_module_definition
        : module_name_clause language_clause module_authorization_clause opt_nt_0001 opt_nt_0002 opt_nt_0003 lst_nt_0004
        ;
  opt_nt_0001
        : /* Nothing */
        | module_path_specification
        ;
  opt_nt_0002
        : /* Nothing */
        | module_transform_group_specification
        ;
  opt_nt_0003
        : /* Nothing */
        | lst_nt_0005
        ;
  lst_nt_0004
        : module_contents
        | lst_nt_0004 module_contents
        ;
  lst_nt_0005
        : temporary_table_declaration
        | lst_nt_0005 temporary_table_declaration
        ;

The next example is interesting - it is fairly typical of the grammar,
but is not minimal.  The rule could be written '<identifier body> ::=
<identifier start> [ <identifier part> ... ]' without altering the
meaning.  It is not clear whether this program should apply this
transformation automatically.

  <identifier body> ::= <identifier start> [ { <identifier part> }... ]

  identifier_body
        : identifier_start opt_nt_0006
        ;
  opt_nt_0006
        : /* Nothing */
        | lst_nt_0007
        ;
  lst_nt_0007
        : seq_nt_0008
        | lst_nt_0007 seq_nt_0008
        ;
  seq_nt_0008
        : identifier_part
        ;

  /* Optimized alternative to lst_nt_0007 */
  lst_nt_0007
        : identifier_part
        | lst_nt_0007 identifier_part
        ;

  <SQL language identifier> ::=
                  <SQL language identifier start> [ { <underscore> | <SQL language identifier part> }... ]

  sql_language_identifier
        : sql_language_identifier_start opt_nt_0009
        ;
  opt_nt_0009
        : /* Nothing */
        | lst_nt_0010
        ;
  lst_nt_0010
        : seq_nt_0011
        | lst_nt_0010 seq_nt_0011
        ;
  seq_nt_0011
        : underscore
        | sql_language_identifier_part
        ;

The next rule is the first example with keywords.

  <module authorization clause> ::=
                SCHEMA <schema name>
          |     AUTHORIZATION <module authorization identifier>
          |     SCHEMA <schema name> AUTHORIZATION <module authorization identifier>

  module_authorization_clause
        : SCHEMA schema_name
        | AUTHORIZATION module_authorization_identifier
        | SCHEMA schema_name AUTHORIZATION module_authorization_identifier
        ;

  <transform group specification> ::=
                  TRANSFORM GROUP { <single group specification> | <multiple group specification> }

  transform_group_specification
        : TRANSFORM GROUP seq_nt_0012
        ;
  seq_nt_0012
        : single_group_specification
        | multiple_group_specification
        ;

  <multiple group specification> ::= <group specification> [ { <comma> <group specification> }... ]

  multiple_group_specification
        : group_specification opt_nt_0013
        ;
  opt_nt_0013
        : /* Nothing */
        | lst_nt_0014
        ;
  lst_nt_0014
        : seq_nt_0015
        | lst_nt_0014 seq_nt_0015
        ;
  seq_nt_0015
        : comma group_specification
        ;

Except for the presence of a token (<right paren>) after the optional
list, the next example is equivalent to the previous one.  It does show,
however, that there is an element of lookahead required to tell whether
an optional item contains a list or a sequence or a simple list of
terminals and non-terminals.

  <table element list> ::=
                  <left paren> <table element> [ { <comma> <table element> }... ] <right paren>

  table_element_list
        : left_paren table_element opt_nt_0016 right_paren
        ;
  opt_nt_0016
        : /* Nothing */
        | lst_nt_0017
        ;
  lst_nt_0017
        : seq_nt_0018
        | lst_nt_0017 seq_nt_0018
        ;
  seq_nt_0018
        : comma table_element
        ;

The next example is interesting because the sequence item contains
alternatives with no optionality or iteration.  It suggests that the
term 'sequence' is not necessarily the 'mot juste'.

  <column definition> ::=
                  <column name>
                  { <data type> | <domain name> }
                  [ <reference scope check> ]
                  [ <default clause> ]
                  [ <column constraint definition>... ]
                  [ <collate clause> ]

  column_definition
        : column_name seq_nt_0019 opt_nt_0020 opt_nt_0021 opt_nt_0022 opt_nt_0023
        ;
  seq_nt_0019
        : data_type
        | domain_name
        ;
  opt_nt_0020
        : /* Nothing */
        | reference_scope_check
        ;
  opt_nt_0021
        : /* Nothing */
        | default_clause
        ;
  opt_nt_0022
        : /* Nothing */
        | lst_nt_0024
        ;
  opt_nt_0023
        : /* Nothing */
        | collate_clause
        ;
  lst_nt_0024
        : column_constraint_definition
        | lst_nt_0024 column_constraint_definition
        ;


  <select list> ::= <asterisk> | <select sublist> [ { <comma> <select sublist> }... ]

  select_list
        : asterisk
        | select_sublist opt_nt_0025
        ;
  opt_nt_0025
        : /* Nothing */
        | lst_nt_0026
        ;
  lst_nt_0026
        : seq_nt_0027
        | lst_nt_0026 seq_nt_0027
        ;
  seq_nt_0027
        : comma select_sublist
        ;

The next statement does not introduce any new grammatical features.  It
does, however, trigger a shift/reduce conflict because an LALR(1)
grammar cannot resolve with one lookahead token whether the token WITH
is part of the WITH HIERARCHY OPTION or part of the WITH GRANT OPTION.
Note that should use a non-terminal such as <non-empty comma list of
grantees>, but such structural changes cannot readily be done by this
program.

  <grant privilege statement> ::=
                  GRANT <privileges> TO <grantee> [ { <comma> <grantee> }... ]
                  [ WITH HIERARCHY OPTION ] [ WITH GRANT OPTION ] [ GRANTED BY <grantor> ]

  grant_privilege_statement
        : GRANT privileges TO grantee opt_nt_0028 opt_nt_0029 opt_nt_0030 opt_nt_0031
        ;
  opt_nt_0028
        : /* Nothing */
        | lst_nt_0032
        ;
  opt_nt_0029
        : /* Nothing */
        | WITH HIERARCHY OPTION
        ;
  opt_nt_0030
        : /* Nothing */
        | WITH GRANT OPTION
        ;
  opt_nt_0031
        : /* Nothing */
        | GRANTED BY grantor
        ;
  lst_nt_0032
        : seq_nt_0033
        | lst_nt_0032 seq_nt_0033
        ;
  seq_nt_0033
        : comma grantee
        ;

The next statement reuses material introduced previously, but in a
slightly more complex manner.

  <set descriptor information> ::=
                <set header information> [ { <comma> <set header information> }... ]
          |     VALUE <item number> <set item information> [ { <comma> <set item information> }... ]

  set_descriptor_information
        : set_header_information opt_nt_0034
        | VALUE item_number set_item_information opt_nt_0035
        ;
  opt_nt_0034
        : /* Nothing */
        | lst_nt_0036
        ;
  opt_nt_0035
        : /* Nothing */
        | lst_nt_0037
        ;
  lst_nt_0036
        : seq_nt_0038
        | lst_nt_0036 seq_nt_0038
        ;
  lst_nt_0037
        : seq_nt_0039
        | lst_nt_0037 seq_nt_0039
        ;
  seq_nt_0038
        : comma set_header_information
        ;
  seq_nt_0039
        : comma set_item_information
        ;

The next statement introduces deeper nesting than any of the previous
ones.  The expansion produces two rules (opt_nt_0040 and opt_nt_0044)
that are identical.  This is indicative of problems with the grammar on
which it is working, which would be better written with a couple of new
non-terminals, <possibly initialized c host identifier> and <non-empty
comma list of possibly initialized c host identifiers>.  However, this
is a stylistic change that should also be made in many other places in
the grammar.

  <C CLOB locator variable> ::=
                  SQL TYPE IS CLOB AS LOCATOR
                  <C host identifier> [ <C initial value> ] [ { <comma> <C host identifier> [ <C initial value> ] } ... ]

  c_blob_locator_variable
        : SQL TYPE IS CLOB AS LOCATOR c_host_identifier opt_nt_0040 opt_nt_0041
        ;
  opt_nt_0040
        : /* Nothing */
        | c_initial_value
        ;
  opt_nt_0041
        : /* Nothing */
        | lst_nt_0042
        ;
  lst_nt_0042
        : seq_nt_0043
        | lst_nt_0042 seq_nt_0043
        ;
  seq_nt_0043
        : comma c_host_identifier opt_nt_0044
        ;
  opt_nt_0044
        : /* Nothing */
        | c_initial_value
        ;

=cut
