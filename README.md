# BNF Grammars for SQL-92, SQL-99 and SQL-2003

This repository contains the BNF (Backus-Naur Form) grammars for three versions of standard SQL — SQL-92, SQL-99 and SQL-2003.

You should be able to find a version of this site with 'active HTML' at:

* https://ronsavage.github.io/SQL/

It may not be the most recent release, but the technical content is mostly valid.
The download link is not functional — you can obtain the material for the latest
release from https://github.com/ronsavage/SQL/releases/latest.

*This project is still in transition to GitHub.
The links in this README.md file lead to the pages in the GitHub source tree.
Most of them will display the HTML source — not a rendered HTML image.
There probably are ways around that; we're learning GitHub as we go.*

For a long time, this material was hosted by Ron Savage at
[http://savage.net.au/SQL](http://savage.net.au) — many thanks, Ron! —
but that site now points to here.

At the moment, the suggested method of operation is:

* Clone this repository to your machine — e.g. into the `/home/somebody/SQL` directory
* Point your browser to `file:///home/somebody/SQL/index.html`.

This should give you full HTML access to the material.
Alternatively, you can download the latest release of this material
(instead of cloning the repo), and then extract that into a directory
and point your browser to the `index.html` file in that directory.

Yes: it is sub-optimal.
Yes: we'll fix it when we know how to fix it.

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

You should be able to get the downloadable version of the latest release of this
repository from the releases area:

* https://github.com/ronsavage/SQL/releases/latest

## SQL 2016 Released

[ISO/IEC JTC 1/SC 32 Publishes Updated SQL Database Language Standard](https://www.ansi.org/news_publications/news_story?menuid=7&articleid=753a952d-1244-415b-bb92-0010750bb8cd) — SQL 2016.


<hr>
Please send feedback to Jonathan Leffler
(<a href="mailto:jonathan.leffler@gmail.com"> jonathan.leffler@gmail.com </a>) _and_
Ron Savage (<a href="mailto:ron@savage.net.au"> ron@savage.net.au </a>).

Last modified:
13th March 2017
