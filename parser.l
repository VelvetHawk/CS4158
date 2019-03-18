%{
	// C code here
	#include <stdlib.h>
	#include <ctype.h>
	#include <string.h>
	#include "parser.tab.h"
%}

%option noyywrap
%option caseless
%option yylineno

space		[\n\t ]
integer		(\-?|\+)[0-9]
id 			[A-Za-z][\-a-zA-Z0-9]*

%%
{space}+ 			/* Ignore whitespace */ ;
"BEGINNING"			{ return BEGINNING; }
"BODY"				{ return BODY; }
"END"				{ return END; }
"PRINT"				{ return PRINT; }
"MOVE"				{ return MOVE; }
"INPUT"				{ return INPUT; }
"ADD"				{ return ADD; }
"TO"				{ return TO; }
[X]+				{ yylval.value = strlen(yytext); return CAPACITY; }
{id}				{ yylval.id = yytext; return IDENTIFIER; }
\"(\\.|[^\"])*\"	{ return STRING_LITERAL; }
{integer}+			{ yylval.value = atoi(yytext); return INTEGER_LITERAL; }
\.					{ return LINE_TERMINATOR; }
;					{ return SEMICOLON; }
.					{ return UNKNOWN; }
%%
