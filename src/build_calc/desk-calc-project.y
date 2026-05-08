%{
#define NSYMS 20
struct symtab {
	char *name; int address;
	}symboltab[NSYMS];
int symlook(char* s);
int loc_num = 2; /* reserve address 1 for ternary temp (0 is scratch) */
int label_count = 0; /* unique label counter for ternary codegen */
int label_sp = 0; /* stack pointer for nested ternary labels */
char false_label_stack[100][20];
char end_label_stack[100][20];
char namaddr[10];
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
extern int yylex();
int yyerror(char* s);

char code[1000][100];
int code_index = 0;
char num[10];
void emit(char* s1, char* s2){
   strcpy(code[code_index],s1);
   strcat(code[code_index++],s2);
}

void new_label(char* buf) { sprintf(buf, "L%d", label_count++); }

void emit_label(char* label) { /* emit label definition as its own line */
	char buf[20];
	sprintf(buf, "%s:", label);
	emit(buf, "");
}

void init_code(){
	emit(".start ","main");
   for (int i=0; i<10; i++)
      emit(".constant ","0");
	emit("main:", ""); /* entry label for code section */
}

void finish_code(){
   emit("print "," ");
   emit("halt "," ");
   emit(".end ", " ");
}

void print_code(){
   for (int i=0; i<code_index; i++)
      printf("%s\n", code[i]);
}

#define YYSTYPE int /* int type for Yacc stack */
%}

%token NUMBER NAME
%token POSTPLUS
%token POSTMINUS
%right '?' ':' /* ternary has lowest precedence */
%left '='
%left '>' /* comparison lower precedence than + and - */
%left '+' '-'
%left '*' '/'
%left POSTPLUS
%left POSTMINUS
%right UMINUS

%%
lines	:	lines expr '\n' {/* Typing CTRL-D exits the program */}
	|	/* empty */
	|	error '\n' {yyerror("reenter last line:"); yyerrok; }
	;
expr	:	NAME '=' expr {sprintf(namaddr, "%d", $1);
                    emit("istore ",namaddr);}
        |       NAME {sprintf(namaddr, "%d", $1); emit("iload ",namaddr);}
        |       expr '+' expr {emit("iadd "," ");}
	|	expr '-' expr {emit("isub "," ");}
	|	expr '>' expr { /* produce 1 if lhs > rhs, else 0 */
					char true_label[20];
					char end_label[20];
					new_label(true_label);
					new_label(end_label);
					emit("isub "," ");
					emit("ifgt ", true_label);
					emit("ldc ","0");
					emit("ldc ","1");
					emit("ifgt ", end_label);
					emit_label(true_label);
					emit("ldc ","1");
					emit_label(end_label);
				}
	|	expr '*' expr {emit("imul "," ");}
	|	expr '/' expr {emit("idiv "," ");}
	| 	expr '?' {
					char false_label[20];
					char end_label[20];
					new_label(false_label);
					new_label(end_label);
					strcpy(false_label_stack[label_sp], false_label);
					strcpy(end_label_stack[label_sp], end_label);
					label_sp++;
					emit("ifeq ", false_label);
				} expr ':' {
					int idx = label_sp - 1;
					emit("istore ","1");
					emit("ldc ","1");
					emit("ifgt ", end_label_stack[idx]);
					emit_label(false_label_stack[idx]);
				} expr {
					int idx = label_sp - 1;
					emit("istore ","1");
					emit_label(end_label_stack[idx]);
					emit("iload ","1");
					label_sp--;
				}
	|	'(' expr ')' { }
	|	'-' expr %prec UMINUS {emit("istore ","0");  emit("ldc ","0");
                        emit("iload ","0"); emit("isub "," ");}
	|	expr POSTPLUS   {emit("ldc ","1"); emit("iadd "," ");}
	|	expr POSTMINUS  {emit("ldc ","1"); emit("isub "," ");}
	|	NUMBER {sprintf(num, "%d", $1); emit("ldc ",num);} 
	;
%%
void initsymtab() 
{	int i = 0;
	for(i=0; i<NSYMS; i++) symboltab[i].name = NULL;
}
int symlook(char* s)
{	struct symtab* sp = symboltab; int i = 0;
	while ((i < NSYMS) && (sp -> name != NULL))
	{ if(strcmp(s,sp -> name) == 0) return sp->address;
	  sp++; i++;
	}
	
	if(i == NSYMS) {
		yyerror("too many symbols"); exit(1);
	}
	else {
		sp -> name = strdup(s);
		sp -> address = loc_num++; 
                return sp->address;
	}
}
int yywrap(){return 1;}
int yyerror( char* s){ printf("%s\n",s);return 0;}
int main(){init_code(); initsymtab(); yyparse(); finish_code(); print_code();}
