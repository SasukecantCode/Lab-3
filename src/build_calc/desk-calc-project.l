%{
#include "y.tab.h"
#include <stdlib.h>
struct symtab {
	char *name; int address;
	};
int symlook(char* s);
/* Ternary tokens '?' and ':' are handled by the catch-all rule. */
%}
name	[A-Za-z][A-Za-z0-9]*
number	[0-9]+
%%
[ ]*	{/* skip blanks */}
{number}	{sscanf(yytext,"%d",&yylval); return NUMBER;}
{name}		{yylval = symlook(yytext); return NAME;}
"++"	{return POSTPLUS;}
"--"	{return POSTMINUS;}
\n|.	{return yytext[0];}
