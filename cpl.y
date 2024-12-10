%code{
#include <stdio.h>
#include <stdlib.h>

extern int yylex(void);
void yyerror(const char* s);
}

%code requires {
    #define MAX_STRING_SIZE 512
    #define MAX_CAST_TYPE_SIZE 6 // float = 5 + 1 terminating
    #define MAX_RELOP_SIZE 3 // >= = 2 + 1 terminating
    enum operator {PLUS='+', MINUS='-', MUL='*', DIV='/'};
}

%union {
    float numeric_value;
    char string_value[MAX_STRING_SIZE];
    char cast_type[MAX_CAST_TYPE_SIZE];
    char single_op;
    char relop[MAX_RELOP_SIZE];
}


/* expressions and types */
%token <numeric_value> NUMBER
%token <string_value> IDENTIFIER

/* I/O */
%token INPUT OUTPUT

/* keywords */
%token IF ELSE WHILE SWITCH CASE DEFAULT BREAK
%token FLOAT INT

/* operation */
%token OR AND NOT
%token <relop> RELOP
%token <cast_type> CAST
%token <single_op> ADDOP MULOP

/* symbols */
%token '(' ')' '{' '}' ',' ':' ';' '='

%nterm program declarations declaration idlist
%nterm stmt assignment_stmt input_stmt output_stmt if_stmt while_stmt
%nterm switch_stmt caselist break_stmt
%nterm stmt_block stmtlist
%nterm type
%nterm expression term factor
%nterm boolexpr boolterm boolfactor

/* doesnt work for some reason, probably need newer bison version? */
/* %define parser.error verbose */

%start program

%% /* grammar */

program:
    declarations stmt_block
    ;

declarations:
    declarations declaration
    | /* epsilon */
    ;

declaration:
    idlist ':' type ';'
    ;

idlist:
    idlist ',' IDENTIFIER
    | IDENTIFIER
    ;

stmt:
    assignment_stmt
    | input_stmt
    | output_stmt
    | if_stmt
    | while_stmt
    | switch_stmt
    | break_stmt
    | stmt_block
    ;

assignment_stmt:
    IDENTIFIER '=' expression ';'
    ;

input_stmt:
    INPUT '(' IDENTIFIER ')' ';'
    ;

output_stmt:
    OUTPUT '(' expression ')' ';'
    ;

if_stmt:
    IF '(' boolexpr ')' stmt ELSE stmt
    ;

while_stmt:
    WHILE '(' boolexpr ')' stmt
    ;

switch_stmt:
    SWITCH '(' expression ')' '{' caselist
    DEFAULT ':' stmtlist '}'
    ;

caselist:
    caselist CASE NUMBER ':' stmtlist
    | /* epsilon */
    ;

break_stmt:
    BREAK ';'
    ;

stmt_block:
    '{' stmtlist '}'
    ;

stmtlist:
    stmtlist stmt
    | /* epsilon */
    ;

boolexpr:
    boolexpr OR boolterm
    | boolterm
    ;

boolterm:
    boolterm AND boolfactor
    | boolfactor
    ;

boolfactor:
    NOT '(' boolexpr ')'
    | expression RELOP expression
    ;

expression:
    expression ADDOP term
    | term
    ;

term:
    term MULOP factor
    | factor
    ;

factor:
    '(' expression ')'
    | CAST '(' expression ')'
    | IDENTIFIER
    | NUMBER
    ;

type:
    FLOAT
    | INT
    ;

%%

int main(int argc, char** argv) {
    extern FILE* yyin; /* defined by flex */
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <file_name.ou>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Error while opening file %s\n", argv[1]);
        return 2;
    }
    #if YYDEBUG
    extern int yydebug;
    yydebug = 1;
    #endif
    yyparse();
    fclose(yyin);
    return 0;
}

void yyerror(const char *s) {
    extern char* yytext;
    fprintf(stderr, "Error near '%s': %s\n", yytext, s);
}
