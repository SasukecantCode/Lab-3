%{
#include "y.tab.h"
#include <stdlib.h>
#include <string.h>
%}

%%

"ldc"      { return LDC; }
"iload"    { return ILOAD; }
"istore"   { return ISTORE; }
"iadd"     { return IADD; }
"imul"     { return IMUL; }
"idiv"     { return IDIV; }
"isub"     { return ISUB; }
"ifeq"     { return IFEQ; }
"ifgt"     { return IFGT; }
"iflt"     { return IFLT; }
"jsr"      { return JSR; }
"ret"      { return RET; }
"read"     { return READ; }
"print"    { return PRINT; }
"halt"     { return HALT; }

".start"   { return START; }
".end"     { return END; }       /* end of program marker */
".reserve" { return RESERVE; }   /* data directive: reserve N words */
".constant" { return CONSTANT; } /* data directive: define a constant */

[0-9]+     { yylval.num = atoi(yytext); return NUMBER; }

[a-zA-Z_][a-zA-Z0-9_]*: {
              yytext[yyleng-1] = '\0';
              yylval.str = strdup(yytext);
              return LABEL;
           }

[a-zA-Z_][a-zA-Z0-9_]* {
              yylval.str = strdup(yytext);
              return IDENTIFIER;
           }

[ \t\r]+   ;
\n         { return NEWLINE; }

"#".*      ;

.          ;

%%

int yywrap() { return 1; }
