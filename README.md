# BNF Grammars for SQL-92, SQL-99 and SQL-2003


## SQL-92

The file [`sql-92.bnf.html`](sql-92.bnf.html) is a heavily hyperlinked HTML
version of the BNF grammar for SQL-92 (ISO/IEC 9075:1992 - Database Language -
SQL).

The plain text file [`sql-92.bnf`](sql-92.bnf), from which it was
automatically converted, is more useful (read legible) for reading
without a browser.

## SQL-99

The file [`sql-99.bnf.html`](sql-99.bnf.html) is a heavily hyperlinked HTML
version of the BNF grammar for SQL-99 (ISO/IEC 9075-2:1999 - Database
Languages - SQL - Part 2: Foundation (SQL/Foundation)).

The plain text file [`sql-99.bnf`](sql-99.bnf), from which it was
automatically converted, is more useful (read legible) for reading
without a browser.

## SQL-2003

The file [`sql-2003-2.bnf.html`](sql-2003-2.bnf.html) is a heavily hyperlinked HTML
version of the BNF grammar for SQL-2003 (ISO/IEC 9075-2:2003 - Database
Languages - SQL - Part 2: Foundation (SQL/Foundation)).

The plain text file [`sql-2003-2.bnf`](sql-2003-2.bnf), from which it was
automatically converted, is more useful (read legible) for reading
without a browser.


There is a separate file [`sql-2003-1.bnf.html`](sql-2003-1.bnf.html) for
the information from ISO/IEC 9075-1:2003 - Database Languages - SQL - Part
1: Framework (SQL/Framework).

It was automatically converted from the plain text file [`sql-2003-1.bnf`](sql-2003-1.bnf),
which is more useful (read legible) for reading without a browser.


Also available:
<bl>
<li> <a href="sql-2003-core-features.html"> SQL 2003 Core Features </a> </li>
<li> <a href="sql-2003-noncore-features.html"> SQL 2003 Non-Core Features </a> </li>
</bl>

## Informix OUTER Join Syntax

The file [`outer-joins.html`](outer-joins.html) is an explanation of the
non-standar Informix OUTER join syntax and semantics.

## Conversion tools


The plain text was converted to HTML by the Perl script
[`bnf2html`](bnf2html.perl.txt) which you may use if you wish.
The `bnf2html` script also uses the C program
WEBCODE version 1.09
which you can download as a [gzipped tar file](webcode-1.09.tgz).

See also [`bnf2yacc`](bnf2yacc.perl.txt), an experimental
script to convert BNF into an outline Yacc grammar.
The generated grammar typically includes some unacceptable tokens, such
as _`%token 0`_, that should be handled by the lexical analyzer
rather than the grammar.
The SQL standard includes such rules as grammar rules; consequently, you won't
get a clean Yacc grammar from the SQL BNF files.

_(The Perl scripts should normally be renamed after downloading.)_

## Download

You can download a gzipped tar file containing the raw grammars, the
HTML versions of those grammars, and the conversion tools as the gzipped
tar file <a href="sql-bnf.tgz"> sql-bnf.tgz </a>.

<hr>
Please send feedback to Jonathan Leffler:
<a href="mailto:jonathan.leffler@gmail.com"> jonathan.leffler@gmail.com </a>.

Last modified:
4th February 2017
