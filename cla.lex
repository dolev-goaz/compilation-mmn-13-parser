%{
#include <string.h> 
#include <stdlib.h>
#include "cpl.tab.h"

// buffer sizes for attributes
#define MAX_STRING_SIZE 512
#define MAX_CAST_TYPE_SIZE 6 // float = 5 + 1 terminating
#define MAX_RELOP_SIZE 3 // >= = 2 + 1 terminating

union token_attribute {
  float numeric_value;
  char string_value[MAX_STRING_SIZE];
  char cast_type[MAX_CAST_TYPE_SIZE];
  char single_op;
  char relop[MAX_RELOP_SIZE];
} token_attribute;

int line = 1;
int comment_line = -1; // initial value doesn't really matter, since we only use it after initializing it
%}

%option noyywrap

%x C_STYLE_COMMENT

%%
 /* keywords */
break   { return KW_BREAK; }
case    { return KW_CASE; }
default { return KW_DEFAULT; }
else    { return KW_ELSE; }
if      { return KW_IF; }
input   { return KW_INPUT; }
output  { return KW_OUTPUT; }
switch  { return KW_SWITCH; }
while   { return KW_WHILE; }
float   { return KW_FLOAT; }
int     { return KW_INT; }

 /* symbols */
\( { return '('; }
\) { return ')'; } 
\{ { return '{'; }
\} { return '}'; }
,  { return ','; }
:  { return ':'; }
;  { return ';'; } 
=  { return '='; }

 /* operators */
"!="|[><]|[>=<]=  { strcpy(token_attribute.relop, yytext); return RELOP; }
[+-]              { token_attribute.single_op = yytext[0]; return ADDOP; }
[*/]              { token_attribute.single_op = yytext[0]; return MULOP; }
"||"              { return OR; }
&&                { return AND; }
!                 { return NOT; }
cast<(int|float)> { char* start = yytext + 5; size_t read_count = strlen(yytext) - 6; /* copy from offset 5(after <), and we ignore 6 characters(cast<>) */
                    strncpy(token_attribute.cast_type, start, read_count);
                    token_attribute.cast_type[read_count] = 0;
                    return CAST; }

[0-9]+(\.?[0-9]*)     { token_attribute.numeric_value = atof(yytext); return NUMBER; }
[a-zA-Z][a-zA-Z0-9]*  { strcpy (token_attribute.string_value, yytext); return IDENTIFIER; }

[\t\r ]+  { /* skip white space */ }
[\n]+     { line += yyleng; /* line += strlen(yytext); */ }

"/*"  { comment_line = line; BEGIN(C_STYLE_COMMENT); }
<C_STYLE_COMMENT>[^*\n]+    { /* skip chars in comment */ }
<C_STYLE_COMMENT>"*"+"/"  { BEGIN(INITIAL); }  //
<C_STYLE_COMMENT>[\n]+     { line += yyleng; }
<C_STYLE_COMMENT>"*"+    { /* skip  *'s. */ } 

 /* validating comments- using comment_line for error info */
<C_STYLE_COMMENT>"/*" { fprintf(stderr, "Error: No nested comments! Initial comment starts in line %d, nested comment in line %d\n", comment_line, line); }
<C_STYLE_COMMENT><<EOF>> { fprintf(stderr, "Error: Unterminated comment beginning in line %d!\n", comment_line); }

. { fprintf(stderr, "Error: Unknown token in line %d: '%s'", line, yytext); }
							   
%%