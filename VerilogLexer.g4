/*
MIT License

Copyright (c) 2022 Mustafa Said Ağca

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

CO     : ',';
EQ     : '=';
LP     : '(';
RP     : ')';
SL     : '/';

BINARY_BASE: /'[sS]?[bB]/;
BLOCK_COMMENT: ' /*' ASCII_ANY '*/ ';
DECIMAL_BASE: /'[sS]?[dD]/;
ESCAPED_IDENTIFIER: /\\[!-~]*[ \t\r\n]/;
EXPONENTIAL_NUMBER: /[0-9][0-9_]*(\.[0-9][0-9_]*)?[eE][+\-]?[0-9][0-9_]*/;
FIXED_POINT_NUMBER: /[0-9][0-9_]*\.[0-9][0-9_]*/;
HEX_BASE: /'[sS]?[hH]/;
LINE_COMMENT: ' //' ASCII_NO_NEWLINE '\n';
OCTAL_BASE: /'[sS]?[oO]/;
SIMPLE_IDENTIFIER: /[a-zA-Z_][a-zA-Z0-9_$]*/;
STRING: /\"([\u0000-\u0009\u000b-\u000c\u000e-\u0021\u0023-\u005b\u005d-\u007f]|\\([nt\\"]|[0-7]{1,3}))*\"/;
SYSTEM_TF_IDENTIFIER: /$[a-zA-Z0-9_$]+/;
UNSIGNED_NUMBER: /[0-9][0-9_]*/;
SIZE: /[1-9][0-9_]*/;
WHITE_SPACE: /[ \t\n\f]+/;

BINARY_VALUE: /[01xXzZ?][01xXzZ?_]*/;

X_OR_Z_UNDERSCORE: /[xXzZ?]_*/;

EDGE_DESCRIPTOR
    : '01'
    | '10'
    | /[xXzZ][01]/
    | /[01][xXzZ]/
    ;

HEX_VALUE: /[0-9a-fA-FxXzZ?][0-9a-fA-FxXzZ?_]*/;

// [WRONG ANYWAYS] FILE_PATH_SPEC       : ( [a-zA-Z0-9_./] | ESC_ASCII_PRINTABLE)+ | STRING;

OCTAL_VALUE: /[0-7xXzZ?][0-7xXzZ?_]*/;

EDGE_SYMBOL: /[rRfFpPnN*]/;
LEVEL_ONLY_SYMBOL: /[?bB]/;
OUTPUT_OR_LEVEL_SYMBOL: /[01xX]/;

// MACRO_USAGE     : IDENTIFIER MACRO_ARGS?;

VERSION_SPECIFIER
    : '"1364-2005"'
    | '"1364-2001"'
    | '"1364-2001-noconfig"'
    | '"1364-1995"'
    ;

DEFAULT_NETTYPE_VALUE
    : 'wire'
    | 'tri'
    | 'tri0'
    | 'tri1'
    | 'wand'
    | 'triand'
    | 'wor'
    | 'trior'
    | 'trireg'
    | 'uwire'
    | 'none'
    ;

// MACRO_NAME   : IDENTIFIER MACRO_ARGS?;

// MACRO_DELIMITER   : '``';
// MACRO_ESC_NEWLINE : ESC_NEWLINE;
// MACRO_ESC_QUOTE   : '`\\`"';
// MACRO_ESC_SEQ     : ESC_ASCII_NO_NEWLINE;
// MACRO_QUOTE       : '`"';
// MACRO_TEXT        : ASCII_NO_NEWLINE_QUOTE_SLASH_BACKSLASH_GRAVE_ACCENT+;

// SOURCE_TEXT     : ASCII_NO_SLASH_GRAVE_ACCENT+;

TIME_UNIT: /[munpf]?s/;
TIME_VALUE
    : '1'
    | '10'
    | '100'
    ;

UNCONNECTED_DRIVE_VALUE
    : 'pull0'
    | 'pull1'
    ;

MACRO_IDENTIFIER: IDENTIFIER;

ASCII_ANY: /[\u0000-\u007f]*/;
ASCII_NO_NEWLINE: /[\u0000-\u0009\u000b-\u000c\u000e-\u007f]*/;
// ASCII_NO_NEWLINE_QUOTE_SLASH_BACKSLASH_GRAVE_ACCENT: [\u0000-\u0009\u000b-\u000c\u000e-\u0021\u0023-\u002e\u0030-\u005b\u005d-\u005f\u0061-\u007f];
// ASCII_NO_PARENTHESES: [\u0000-\u0027\u002a-\u007f];
// ASCII_NO_SLASH_GRAVE_ACCENT: [\u0000-\u002e\u0030-\u005f\u0061-\u007f];
// ESC_ASCII_NO_NEWLINE: '\\' ASCII_NO_NEWLINE;
// ESC_ASCII_PRINTaBLE: /\\[ -~]/;
// ESC_NEWLINE: '\\\n';
IDENTIFIER
    : ESCAPED_IDENTIFIER
    | SIMPLE_IDENTIFIER
    ;
// MACRO_ARGS: '(' (MACRO_ARGS | ASCII_NO_PARENTHESES)* ')';
