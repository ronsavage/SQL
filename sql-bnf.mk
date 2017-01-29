# @(#)$Id: sql-bnf.mk,v 1.18 2017/01/21 16:29:04 jleffler Exp $
#
# Makefile for SQL-92, SQL-99 and SQL-2003 BNF and HTML files

.NO_PENDING_GET:

WEBCODE.tgz  = webcode-1.09.tgz
FILE1.bnf    = sql-92.bnf
FILE2.bnf    = sql-99.bnf
FILE3.bnf    = sql-2003-1.bnf
FILE4.bnf    = sql-2003-2.bnf
FILES.bnf    = ${FILE1.bnf} ${FILE2.bnf} ${FILE3.bnf} ${FILE4.bnf}
FILES.html   = ${FILES.bnf:bnf=bnf.html}
FILE1.aux    = index.html
FILE2.aux    = outer-joins.html
FILE3.aux    = sql-2003-core-features.html
FILE4.aux    = sql-2003-noncore-features.html
FILES.aux    = ${FILE1.aux} ${FILE2.aux} ${FILE3.aux} ${FILE4.aux}
FILE1.pl     = bnf2html.pl
FILE2.pl     = bnf2yacc.pl
FILES.pl     = ${FILE1.pl} ${FILE2.pl}
FILE1.txt    = bnf2html.perl.txt
FILE2.txt    = bnf2yacc.perl.txt
FILES.txt    = ${FILE1.txt} ${FILE2.txt}
FILES.mk     = sql-bnf.mk
FILES.all    = ${FILES.bnf} ${FILES.html} ${FILES.mk} ${FILES.pl} ${FILES.txt} \
               ${FILES.aux} ${WEBCODE.tgz}

# Dummy datestamp - just in case.
VERNUM       = 00000000
VRSNFILE.tgz = sql-bnf-${VERNUM}.tgz
DISTFILE.tgz = sql-bnf.tgz
RCSFILES.tgz = sql-bnf-rcs-${VERNUM}.tgz

APACHE_HOME  = /opt/apache/webserver
APACHE_HTML  = htdocs/SQL
APACHE_DIR   = ${APACHE_HOME}/${APACHE_HTML}

TAR          = tar
TARFLAGS     = -cvzf
COPY         = cp
COPYFLAGS    = -fp
PERL         = perl
RM_F         = rm -f
CHMOD        = chmod
WEBPERMS     = 444
LN           = ln
MKPATH       = mkdir -p

all:
	${MAKE} VERNUM=`date +'%Y''%m''%d'` all-vrsn

all-vrsn: ${VRSNFILE.tgz} ${RCSFILES.tgz}

${VRSNFILE.tgz}:  ${FILES.all}
	${TAR} ${TARFLAGS} ${VRSNFILE.tgz} ${FILES.all}
	${RM_F} ${DISTFILE.tgz}
	${LN} ${VRSNFILE.tgz} ${DISTFILE.tgz}

${RCSFILES.tgz}: RCS
	${TAR} ${TARFLAGS} ${RCSFILES.tgz} RCS

${FILES.html}: $${@:.html=} ${FILE1.pl}
	${RM_F} $@
	${PERL} ${FILE1.pl} ${@:.html=} > $@

${FILES.txt}:	$${@:.perl.txt=.pl}
	${RM_F} $@
	${LN} $? $@

install: all
	${MKPATH} ${APACHE_DIR}
	${COPY} ${COPYFLAGS} ${DISTFILE.tgz} ${FILES.all} ${WEBCODE.tgz} ${APACHE_DIR}
	cd ${APACHE_DIR}; ${CHMOD} ${WEBPERMS} ${DISTFILE.tgz} ${WEBCODE.tgz} ${FILES.all}
