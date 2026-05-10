%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
int yyerror(char* s);

#define MAGIC 0x4D4A564D
#define VERSION 1

extern FILE* yyin;

int pass = 1;
int pc = 0;
int entry_point = 0;
char entry_label[50];
int entry_label_set = 0;

int code[1000];
int code_size = 0;
int instr_count = 0;  /* instruction words only (no data) */

/* -------- Relocation Table (NEW) --------
 * Offsets (word indexes) within the object code that contain addresses.
 * The loader/simulator can add a base address to these words when loading.
 * Example from spec: istore/iload/jsr/if* label operands are relocatable.
 */
int reloc_offsets[1000];
int reloc_count = 0;

/* -------- Data Segment -------- */

typedef struct {
    int value;
    int is_reserve;
    char label[50];
} DataEntry;

DataEntry data_seg[200];
int data_count = 0;
char data_label_buf[50];
int data_label_set = 0;

/* -------- Symbol Table -------- */

typedef struct {
    char name[50];
    int address;
} Symbol;

Symbol symtab[200];
int symcount = 0;

void insert_symbol(char* name, int addr) {
    for(int i=0;i<symcount;i++) {
        if(strcmp(symtab[i].name,name)==0) {
            printf("Duplicate label %s\n", name);
            exit(1);
        }
    }
    strcpy(symtab[symcount].name,name);
    symtab[symcount].address = addr;
    symcount++;
}

void add_constant_entry(const char* label, int value) {
    if(data_count >= 200) {
        printf("Too many data entries\n");
        exit(1);
    }
    data_seg[data_count].value = value;
    data_seg[data_count].is_reserve = 0;
    if(label && label[0] != '\0')
        strcpy(data_seg[data_count].label, label);
    else
        data_seg[data_count].label[0] = '\0';
    data_count++;
}

void add_reserve_entries(const char* label, int count) {
    for(int i=0; i<count; i++) {
        const char* entry_label = (i==0 ? label : "");
        if(data_count >= 200) {
            printf("Too many data entries\n");
            exit(1);
        }
        data_seg[data_count].value = 0;
        data_seg[data_count].is_reserve = 1;
        if(entry_label && entry_label[0] != '\0')
            strcpy(data_seg[data_count].label, entry_label);
        else
            data_seg[data_count].label[0] = '\0';
        data_count++;
    }
}

int lookup_symbol(char* name) {
    for(int i=0;i<symcount;i++) {
        if(strcmp(symtab[i].name,name)==0)
            return symtab[i].address;
    }
    printf("Undefined label %s\n", name);
    exit(1);
}

/* -------- Emit -------- */

void emit(int value) {
    code[pc++] = value;
}

/* Record that the *next* emitted word (current pc) is an address that must be relocated. */
void mark_reloc_here(void) {
    if(reloc_count >= 1000) {
        printf("Too many relocation entries\n");
        exit(1);
    }
    reloc_offsets[reloc_count++] = pc;
}

void write_output(char* filename) {
    FILE* f = fopen(filename,"w");
    /* NEW object format (per assignment spec):
     *  <entry point offset>
     *  <relocation table length>
     *  <relocation offsets... one per line>
     *  <object code words... one per line>
     */
    fprintf(f, "%d\n", entry_point);
    fprintf(f, "%d\n", reloc_count);
    for(int i=0; i<reloc_count; i++)
        fprintf(f, "%d\n", reloc_offsets[i]);
    for(int i=0; i<code_size; i++)
        fprintf(f, "%d\n", code[i]);
    fclose(f);
}

void reset() {
    pc = 0;
}

%}

%union {
    int num;
    char* str;
}

%token <num> NUMBER
%token <str> IDENTIFIER LABEL
%token LDC ILOAD ISTORE IADD IMUL IDIV ISUB
%token IFEQ IFGT IFLT JSR RET READ PRINT HALT
%token START END RESERVE CONSTANT NEWLINE

%%

program:
    lines
    ;

lines:
      lines line
    | line
    ;

line:
      instruction NEWLINE
    | label_instruction NEWLINE
    | label_def NEWLINE
    | directive NEWLINE
        | data_line NEWLINE
    | NEWLINE
    ;

label_instruction:
    LABEL { if(pass==1) insert_symbol($1, instr_count); } instruction /* label + instruction */
    ;

label_def:
    LABEL
    {
        if(pass==1)
            insert_symbol($1, instr_count);
    }
    ;

directive:
    START IDENTIFIER
    {
        if(pass==1) {
            strcpy(entry_label, $2);
            entry_label_set = 1;
        }
    }
  | START NUMBER
    {
        if(pass==1) {
            entry_point = $2; /* allow numeric entry point */
            entry_label_set = 0;
        }
    }
  | END
    {
        /* .end is a no-op for this assembler */
    }
    ;

data_line:
      data_directive
    | LABEL { strcpy(data_label_buf, $1); data_label_set = 1; } data_directive
    ;

data_directive:
      CONSTANT NUMBER
        {
            if(pass==1) {
                const char* label = (data_label_set ? data_label_buf : "");
                add_constant_entry(label, $2);
                data_label_set = 0;
            }
        }
    | RESERVE NUMBER
        {
            if(pass==1) {
                const char* label = (data_label_set ? data_label_buf : "");
                add_reserve_entries(label, $2);
                data_label_set = 0;
            }
        }
    ;

instruction:

      LDC NUMBER
        {
                        if(pass==1) instr_count+=2;
            else { emit(1); emit($2); }
        }

    | ILOAD NUMBER
        {
            if(pass==1) instr_count+=2;
            else { emit(2); emit($2); }
        }

    | ILOAD IDENTIFIER
        {
            if(pass==1) instr_count+=2;
            else {
                emit(2);
                /* NEW: label address operand needs relocation */
                mark_reloc_here();
                emit(lookup_symbol($2));
            }
        }

    | ISTORE NUMBER
        {
            if(pass==1) instr_count+=2;
            else { emit(3); emit($2); }
        }

    | ISTORE IDENTIFIER
        {
            if(pass==1) instr_count+=2;
            else {
                emit(3);
                /* NEW: label address operand needs relocation */
                mark_reloc_here();
                emit(lookup_symbol($2));
            }
        }

    | IADD
        {
            if(pass==1) instr_count+=1;
            else emit(4);
        }

    | IMUL
        {
            if(pass==1) instr_count+=1;
            else emit(5);
        }

    | IDIV
        {
            if(pass==1) instr_count+=1;
            else emit(6);
        }

    | ISUB
        {
            if(pass==1) instr_count+=1;
            else emit(7);
        }

    | IFEQ IDENTIFIER
        {
            if(pass==1) instr_count+=2;
            else {
                emit(8);
                /* NEW: jump target address operand needs relocation */
                mark_reloc_here();
                emit(lookup_symbol($2));
            }
        }

    | IFGT IDENTIFIER
        {
            if(pass==1) instr_count+=2;
            else {
                emit(9);
                /* NEW: jump target address operand needs relocation */
                mark_reloc_here();
                emit(lookup_symbol($2));
            }
        }

    | IFLT IDENTIFIER
        {
            if(pass==1) instr_count+=2;
            else {
                emit(10);
                /* NEW: jump target address operand needs relocation */
                mark_reloc_here();
                emit(lookup_symbol($2));
            }
        }

    | JSR IDENTIFIER
        {
            if(pass==1) instr_count+=2;
            else {
                emit(11);
                /* NEW: call target address operand needs relocation */
                mark_reloc_here();
                emit(lookup_symbol($2));
            }
        }

    | RET
        {
            if(pass==1) instr_count+=1;
            else emit(12);
        }

    | READ
        {
            if(pass==1) instr_count+=1;
            else emit(13);
        }

    | PRINT
        {
            if(pass==1) instr_count+=1;
            else emit(14);
        }

    | HALT
        {
            if(pass==1) instr_count+=1;
            else emit(15);
        }
    ;

%%

//int yywrap(){return 1;}
int yyerror( char* s){ printf("%s\n",s);return 0;}

int main(int argc, char* argv[]) {

    if(argc != 3) {
        printf("Usage: ./assembler input.asm output.mjvm\n");
        return 1;
    }

    /* -------- PASS 1 -------- */
    yyin = fopen(argv[1],"r");
    pass = 1;
    pc = 0;
    instr_count = 0;
    data_count = 0;
    data_label_set = 0;
    entry_label_set = 0;
    yyparse();
    fclose(yyin);

    for(int i=0; i<data_count; i++) { /* assign data labels after instructions */
        if(data_seg[i].label[0] != '\0')
            insert_symbol(data_seg[i].label, instr_count + i);
    }
    if(entry_label_set)
        entry_point = lookup_symbol(entry_label);

    /* -------- PASS 2 -------- */
    yyin = fopen(argv[1],"r");
    pass = 2;
    pc = 0;
    reloc_count = 0; /* NEW: clear relocation table before emitting */
    yyparse();
    fclose(yyin);

    for(int i=0; i<data_count; i++) /* append data values after instructions */
        emit(data_seg[i].value);
    code_size = pc;

    write_output(argv[2]);

    printf("Assembly successful.\n");
    return 0;
}
