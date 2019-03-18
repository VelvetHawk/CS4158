%{
	// C code here
	#include<stdio.h>
	#include <stdlib.h>
	#include <ctype.h>
	#include <string.h>
	#include <stdbool.h>

	extern int yylex();
	extern int yyparse();
	extern FILE *yyin;
	extern int yylineno;

	// Prototypes
	void yyerror(const char *message);
	void add_declaration(char *name, const int size);
	void trim(char *name);
	void lookup(char *name);
	void check_size(char *name, int passed_size);
	void check_sizes(char *name, char *second_identifier);
	void get_identifier(char *name);

	// Tables and such
	#define MAX_IDENTIFIERS 100
	char identifiers[MAX_IDENTIFIERS][32]; // 32 characters max
	int sizes[MAX_IDENTIFIERS];

	int current_identifiers = 0;

%}

%union { int value; char *id; }
%start beginning
%token <value> CAPACITY
%token <id> IDENTIFIER
%token <id> STRING_LITERAL
%token <value> INTEGER_LITERAL
%token BEGINNING BODY END PRINT MOVE INPUT ADD TO
%token SEMICOLON INDENTIFIER LINE_TERMINATOR UNKNOWN

%%
beginning:			BEGINNING LINE_TERMINATOR declarations {}
					;
declarations:		declaration declarations {}
					| body {}
					;
declaration:		CAPACITY IDENTIFIER LINE_TERMINATOR { add_declaration($2, $1); }
					| error {}
					;
body:				BODY LINE_TERMINATOR statements {}
					;
statements:			statement statements {}
					| end {}
					;
statement:			print {}
					| move {}
					| input {}
					| add {}
					| error {}
					;
print:				PRINT print_expression {}
					;
print_expression:	STRING_LITERAL SEMICOLON print_expression {}
					| STRING_LITERAL LINE_TERMINATOR {}
					| IDENTIFIER SEMICOLON print_expression { lookup($1); }
					| IDENTIFIER LINE_TERMINATOR { lookup($1); }
					;
move:				MOVE INTEGER_LITERAL TO IDENTIFIER LINE_TERMINATOR { lookup($4); check_size($4, $2); }
					| MOVE IDENTIFIER TO IDENTIFIER LINE_TERMINATOR { lookup($2); lookup($4); check_sizes($2, $4); }
					;
input:				INPUT input_expression {}
					;
input_expression:	IDENTIFIER LINE_TERMINATOR { lookup($1); }
					| IDENTIFIER SEMICOLON input_expression { lookup($1); }
					;
add:				ADD INTEGER_LITERAL TO IDENTIFIER LINE_TERMINATOR { lookup($4); check_size($4, $2); }
					| ADD IDENTIFIER TO IDENTIFIER LINE_TERMINATOR { lookup($2); lookup($4); check_sizes($2, $4); }
					;
end:				END LINE_TERMINATOR { exit(EXIT_SUCCESS); }
					;
%%

int main(int argc, char **argv)
{
	if (argc > 1)	yyin = fopen(argv[1], "r");
	else			yyin = stdin;

	yyparse();
	return 0;
}

void yyerror(const char *message)
{
	fprintf(stderr, "An error occured on line %d: %s\n", yylineno, message);
}

void add_declaration(char *name, const int size)
{
	trim(name); // Remove terminator
	get_identifier(name); // Remove excess
	strupr(name);

	// Check if identifier already declared
	bool exists = false;
	for (int i = 0; i < current_identifiers && !exists; i++)
		if (strcmp(identifiers[i], name) == 0)
			exists = true;
	// If declared, notify user
	if (exists)
		printf("Warning on line %d: %s has already been declared.\n", yylineno, name);

	strcpy(identifiers[current_identifiers], name);
	sizes[current_identifiers] = size;
	current_identifiers++;
}

void trim(char *name)
{
	if (name[strlen(name)-1] == '.')
		name[strlen(name)-1] = 0;
}

void get_identifier(char *name)
{
	bool stop = false;
	for (int i = 0; i < strlen(name) && !stop; i++)
		if (name[i] == ';' || name[i] == ' ')
		{
			name[i] = '\0';
			stop = true;
		}
}

void lookup(char *name)
{
	trim(name); // Remove terminator
	get_identifier(name); // Remove excess
	strupr(name);

	bool exists = false;
	for (int i = 0; i < current_identifiers && !exists; i++)
		if (strcmp(identifiers[i], name) == 0)
			exists = true;
	// Output error message if variable doesn't exist
	if (!exists)
		printf("Error on line %d: Identifier %s is not declared.\n", yylineno, name);
}

void check_size(char *name, int passed_size)
{
	trim(name); // Remove terminator
	get_identifier(name); // Remove excess
	strupr(name);

	bool found = false;
	bool valid = false;
	int size;
	for (int i = 0; i < current_identifiers && !found; i++)
		if (strcmp(identifiers[i], name) == 0)
		{
			found = true;
			if (passed_size <= (sizes[i] * 9))
				valid = true;
		}
	// Output error
	if (!valid)
		printf("Error on line %d: %d is not a valid size.\n", yylineno, passed_size);
}

void check_sizes(char *name, char *second_identifier)
{
	trim(name); // Remove terminator
	get_identifier(name); // Remove excess
	strupr(name);
	strupr(second_identifier);

	trim(second_identifier); // Remove terminator
	get_identifier(second_identifier); // Remove excess

	bool found = false;
	bool valid = false;

	int size_first = 0;
	int size_second = 0;

	// Size of first identifier
	for (int i = 0; i < current_identifiers && !found; i++)
		if (strcmp(identifiers[i], name) == 0)
		{
			found = true;
			size_first = sizes[i] * 9;
		}
	// Size of second identifier
	found = false;
	for (int i = 0; i < current_identifiers && !found; i++)
		if (strcmp(identifiers[i], second_identifier) == 0)
		{
			found = true;
			size_second = sizes[i] * 9;
		}

	if (size_first <= size_second)
		valid = true;

	// Output error
	if (!valid)
		printf("Error on line %d: %s does not have a valid size for %s.\n", yylineno, name, second_identifier);
}
