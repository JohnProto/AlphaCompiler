%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <ctype.h>
    #include <string.h>

    #define YY_DECL int yylex(void *yylval)

    struct alpha_token_t {
        unsigned int            numLine;    //1:
        unsigned int            numToken;   //#1
        char                    *tokenName; //"if"
        char                    *AType;     //KEYWORD
        char                    *content;   //IF
        char                    *BType;     //<- enumerated
        struct alpha_token_t    *next;      //Next
    };
    
    int token_count = 0, buffer_size = 0, curr_line_string;
    void* yylval = NULL;
    char* modified_buffer = NULL;

    int get_digit_count(int num) {
        int count = 0;
        do {
            num /= 10;
            ++count;
        } while (num);
        return count;
    }

    char* upper_case(char* input) {
        int buf_size = sizeof(char) * (strlen(input) + 1);
        char* output = malloc(buf_size);
        if (!output) return NULL;
        strcpy(output, input);
        char* tmp = output;

        while (*tmp != '\0') {
            *tmp = toupper(*tmp);
            tmp++;
        }

        return output;
    }

    void print_tokens() {
        struct alpha_token_t *node = yylval;
        fprintf(yyout, "--------------------------     Lexical Analysis     --------------------------\n\n");
        while (node) {
            fprintf(yyout, "%u: #%u, \"%s\" %s %s  <-%s\n", node->numLine, node->numToken, node->tokenName, node->AType, node->content, node->BType);
            node = node->next;
        }
    }

    struct alpha_token_t *generate_token(unsigned int numLine, unsigned int numToken, char* tokenName, char* AType, char* content, char* BType) {
        struct alpha_token_t *node = malloc(sizeof(struct alpha_token_t));
        if (!node) return NULL;
        node->numLine = numLine;
        node->numToken = numToken;
        node->tokenName = malloc(sizeof(char) * (strlen(tokenName) + 1));
        strcpy(node->tokenName, tokenName);
        node->AType = AType;
        node->content = malloc(sizeof(char) * (strlen(content) + 1));
        strcpy(node->content, content);
        node->BType = BType;
        node->next = NULL;
        return node;
    }

    void clean_tokens() {
        struct alpha_token_t *node = (struct alpha_token_t *) yylval;
        struct alpha_token_t *next_node;
        while (node) {
            next_node = node->next;
            free(node->tokenName);
            free(node->content);
            free(node);
            node = next_node;
        }
    }

    int add_token(unsigned int numLine, char* tokenName, char* AType, char* content, char* BType) {
        //char                    *tokenName; 
        //char                    *AType;     
        //char                    *content;   
        //char                    *BType;     
        struct alpha_token_t *token = generate_token(numLine, ++token_count, tokenName, AType, content, BType);
        if (!token) return 0;
        struct alpha_token_t *tmp = yylval;
        struct alpha_token_t *prev = NULL;
        while (tmp) {
           prev = tmp;
           tmp = tmp->next;
        }
        //First element
        if (!prev) {
            yylval = token;
        } else {
            prev->next = token;
        }
        return 1;
    }

    char* get_operator(char* text) {
        if (!strcmp(text, "+")) {
            return "PLUS";
        } else if (!strcmp(text, "-")) {
            return "MINUS";
        } else if (!strcmp(text, "=")) {
            return "ASSIGN";
        } else if (!strcmp(text, "*")) {
            return "MULTIPLY";
        } else if (!strcmp(text, "/")) {
            return "DIVISION";
        } else if (!strcmp(text, "%%")) {
            return "MOD";
        } else if (!strcmp(text, ">")) {
            return "GREATER";
        } else if (!strcmp(text, "<")) {
            return "LESS";
        } else if (!strcmp(text, "==")) {
            return "EQUALS";
        } else if (!strcmp(text, "!=")) {
            return "DIFFERENT";
        } else if (!strcmp(text, "++")) {
            return "PLUS_PLUS";
        } else if (!strcmp(text, "--")) {
            return "MINUS_MINUS";
        } else if (!strcmp(text, ">=")) {
            return "GREATER_OR_EQUAL";
        } else if (!strcmp(text, "<=")) {
            return "LESS_OR_EQUAL";
        }
        return "UNKNOWN";
    }

    char* get_punctuation(char* text) {
        if (!strcmp(text, "{")) {
            return "LEFT_BRACKET";
        } else if (!strcmp(text, "}")) {
            return "RIGHT_BRACKET";
        } else if (!strcmp(text, "[")) {
            return "LEFT_BRACE";
        } else if (!strcmp(text, "]")) {
            return "RIGHT_BRACE";
        } else if (!strcmp(text, "(")) {
            return "LEFT_PARENTHESIS";
        } else if (!strcmp(text, ")")) {
            return "RIGHT_PARENTHESIS";
        } else if (!strcmp(text, ";")) {
            return "SEMICOLON";
        } else if (!strcmp(text, ",")) {
            return "COMMA";
        } else if (!strcmp(text, ":")) {
            return "COLON";
        } else if (!strcmp(text, "::")) {
            return "DOUBLE_COLON";
        } else if (!strcmp(text, ".")) {
            return "DOT";
        } else if (!strcmp(text, "..")) {
            return "DOUBLE_DOT";
        }
        return "UNKNOWN";
    }

    char* add_to_buffer(char* text) {
        buffer_size += strlen(text);
        //fprintf(stdout, "Str size is %d\n", strlen(text));
        if (!modified_buffer) {
            modified_buffer = malloc(sizeof(char) * (buffer_size + 1));
            if (!modified_buffer) return NULL;
            strcpy(modified_buffer, text);
        } else {
            modified_buffer = realloc(modified_buffer, sizeof(char) * (buffer_size + 1));
            if (!modified_buffer) return NULL;
            strcat(modified_buffer, text);
        };
    }

    char* add_quotes(char* text) {
        int buf_len = sizeof(char) * (strlen(text) + 3);
        char* tmp_buffer = malloc(buf_len);
        if (!tmp_buffer) return NULL;
        tmp_buffer[0] = '\"';
        strcpy(tmp_buffer + 1, text);
        tmp_buffer[buf_len - 2] = '\"';
        tmp_buffer[buf_len - 1] = '\0';
        return tmp_buffer;
    }

    void reset_buffer() {
        free(modified_buffer);
        modified_buffer = NULL;
        buffer_size = 0;
    }

    void flush_buffer() {
        if (modified_buffer) {
            int buf_len = sizeof(char) * (strlen(modified_buffer) + 3);
            char* tmp_buffer = add_quotes(modified_buffer);
            if (tmp_buffer) {
                add_token(curr_line_string, modified_buffer, "STRING", tmp_buffer, "char*");
                free(tmp_buffer);
            }
            reset_buffer();
        } else {
            add_token(curr_line_string, "", "STRING", "\"\"", "char*");
        }
    }
%}

%option yylineno
%option noyywrap

keywords        ("if")|("else")|("while")|("for")|("function")|("return")|("break")|("continue")|("and")|("not")|("or")|("local")|("true")|("false")|("nil")
operators       [\+\-\=\*\/\%\>\<]|("==")|("!=")|("++")|("--")|(">")|("<")|(">=")|("<=")
intNums         [0-9]+
realNums        ([-+]?[0-9]+\.[0-9]+)([eE][-+]?[0-9]+)?
punctuations    (\{)|(\})|(\[)|(\])|(\()|(\))|(\;)|(\,)|(\:)|(\:\:)|(\.)|(\.\.)        
identifiers     [A-Za-z][A-Za-z0-9_]*
whiteSpaces     [ \t\n]+

%x STRING INCLUDE

%%

{keywords}      {
                    char* text = upper_case(yytext);
                    if (!text) return 1;
                    if(!add_token(yylineno, yytext, "KEYWORD", text, "enumerated")) {
                        free(text);
                        return 1;
                    }
                    free(text);
                }
{operators}     {if(!add_token(yylineno, yytext, "OPERATOR", get_operator(yytext), "enumerated")) return 1;}
{intNums}       {if(!add_token(yylineno, yytext, "CONST_INT", yytext, "integer")) return 1;}
{realNums}      {if(!add_token(yylineno, yytext, "CONST_REAL", yytext, "float")) return 1;}
{punctuations}  {if(!add_token(yylineno, yytext, "PUNCTUATION", get_punctuation(yytext), "enumerated")) return 1;}
{identifiers}   {
                    char* text = add_quotes(yytext);
                    if (!text) return 1;
                    if(!add_token(yylineno, yytext, "ID", text, "char*")) {
                        free(text);
                        return 1;
                    }
                    free(text);
                }
{whiteSpaces}   {}

"\""                {curr_line_string = yylineno; BEGIN(STRING); }
<STRING>[^\"\\]+    {add_to_buffer(yytext);}
<STRING>\\[n]       {add_to_buffer("\n");}
<STRING>\\(.)       {
                        switch(yytext[1]){
                            case 't':
                                add_to_buffer("\t");
                                break;
                            case '\\':
                                add_to_buffer("\\");
                                break;
                            case '\"':
                                add_to_buffer("\"");
                                break;
                            case '\'':
                                add_to_buffer("\'");
                                break;
                            default:
                                fprintf(stderr, "Warning: %s is not a valid escape sequence\n", yytext);
                                add_to_buffer(yytext);
                        }
                    }
<STRING>\"          {flush_buffer(); BEGIN(INITIAL);}
<STRING><<EOF>>     {flush_buffer(); fprintf(stderr, "Error: Unmatched string literal\n"); exit(1);}

"/*"                {
                        int open_comments = 0, allocation_count = 2;
                        char c;
                        int *comments = malloc(sizeof(int) * allocation_count);
                        if (!comments) return 1;
                        comments[open_comments++] = yylineno;
                        while ((c = input()) != EOF) {
                            if (c == '/') {
                                c = input();
                                if (c == '*') {
                                    if (open_comments == allocation_count) {
                                        allocation_count *= 2;
                                        comments = realloc(comments, sizeof(int) * allocation_count);
                                    }
                                    comments[open_comments++] = yylineno;
                                } else {
                                    unput(c);
                                }
                            } else if (c == '*') {
                                c = input();
                                if (c == '/') {
                                    --open_comments;
                                    int tokenNameSize = sizeof(char) * (get_digit_count(comments[open_comments]) + strlen(" - ") + get_digit_count(yylineno) + 1);
                                    char* tokenName = malloc(tokenNameSize);
                                    if (!tokenName) {
                                        free(comments);
                                        return 1;
                                    }
                                    tokenName[tokenNameSize - 1] = '\0';
                                    sprintf(tokenName, "%d - %d", comments[open_comments], yylineno);
                                    add_token(comments[open_comments], tokenName, "COMMENT", "BLOCK_COMMNET", "enumerated");
                                    free(tokenName);
                                    if (!open_comments) break;
                                } else {
                                    unput(c);
                                }
                            }
                        }
                        free(comments);
                        if (c == EOF) {
                            fprintf(stderr, "Multiline comment didn't close!\n");
                            return 1;
                        }
                    }

"//"                {
                        char c = input();
                        while (c != EOF && c != '\n') {
                            c = input();
                        }
                        if (c == EOF) {
                            add_token(yylineno, "", "COMMENT", "LINE_COMMENT", "enumerated");
                            print_tokens();
                            clean_tokens();
                            return 0;
                        }
                        add_token(yylineno-1, "", "COMMENT", "LINE_COMMENT", "enumerated");
                        unput(c);
                    }


<<EOF>>             {
    print_tokens();
    clean_tokens();
    return 0;
}

.               {fprintf(stderr, "Unknown sequence found at line %d (%s)\n", yylineno, yytext); return 1;} 

%%
int main(int argc, char** argv) {
    if (argc == 1) {
        yyin = stdin;
        yyout = stdout;
    } else if (argc == 2) {
        if (!(yyin = fopen(argv[1], "r"))) {
            fprintf(stderr, "Couldn't open input file\n");
            return 1;
        }
        yyout = stdout;
    } else if (argc == 3) {
        if (!(yyin = fopen(argv[1], "r"))) {
            fprintf(stderr, "Couldn't open input file\n");
            return 1;
        }
        if (!(yyout = fopen(argv[2], "w"))) {
            fprintf(stderr, "Couldn't open output file\n");
            return 1;
        }
    } else {
        printf("Invalid amount of arguments\n");
        return 1;
    }
    yylex(&yylval);
    return 0;
}
