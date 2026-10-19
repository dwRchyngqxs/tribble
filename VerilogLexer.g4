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

WHITE_SPACE: /[ \t\n\f]+/;

// ` '/*' .* '*/' ` determinized is ` '/*' [^*]* '*'+ ([^*/] [^*]* '*'+)* '/' `
ASCII_NO_STAR: /[\u0000-\u0029\u002b-\u007f]*/;
// white space forced because '/' '/*' = '//*' = line comment
BLOCK_COMMENT: WHITE_SPACE '/*' ASCII_NO_STAR '*'+ (/[\u0000-\u0029\u002b-\u002e\u0030-\u007f]/ ASCII_NO_STAR '*'+) '/';

// white space forced because '/' '//' = '///' = line comment
LINE_COMMENT: WHITE_SPACE '//' ASCII_NO_NEWLINE '\n';

EXPONENTIAL_NUMBER: /[0-9][0-9_]*(\.[0-9][0-9_]*)?[eE][+\-]?[0-9][0-9_]*/;
FIXED_POINT_NUMBER: /[0-9][0-9_]*\.[0-9][0-9_]*/;
UNSIGNED_NUMBER: /[0-9][0-9_]*/;
SIZE: /[1-9][0-9_]*/;

STRING: /\"([\u0000-\u0009\u000b-\u000c\u000e-\u0021\u0023-\u005b\u005d-\u007f]|\\([nt\\"]|[0-7]{1,3}))*\"/;

SIMPLE_IDENTIFIER: /[a-zA-Z_][a-zA-Z0-9_$]*/;
ESCAPED_IDENTIFIER: /\\[!-~]*[ \t\n]/;
SYSTEM_TF_IDENTIFIER: /$[a-zA-Z0-9_$]+/;
IDENTIFIER
    : ESCAPED_IDENTIFIER
    | SIMPLE_IDENTIFIER
    ;

BINARY_VALUE: /[01xXzZ?][01xXzZ?_]*/;
OCTAL_VALUE: /[0-7xXzZ?][0-7xXzZ?_]*/;
HEX_VALUE: /[0-9a-fA-FxXzZ?][0-9a-fA-FxXzZ?_]*/;
X_OR_Z_UNDERSCORE: /[xXzZ?]_*/;

EDGE_DESCRIPTOR
    : '01'
    | '10'
    | /[xXzZ][01]/
    | /[01][xXzZ]/
    ;

// FILE_PATH_SPEC       : ( /[a-zA-Z0-9_.\/]/ | /\\[ -~]/)+ | STRING; // not tested, wrong anyways

EDGE_SYMBOL: /[rRfFpPnN*]/;
LEVEL_ONLY_SYMBOL: /[?bB]/;
OUTPUT_OR_LEVEL_SYMBOL: /[01xX]/;

// MACRO_USAGE     : IDENTIFIER MACRO_ARGS?; // not tested

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

// MACRO_NAME   : IDENTIFIER MACRO_ARGS?; // not tested

// MACRO_ESC_SEQ     : '\\' ASCII_NO_NEWLINE; // not tested
// MACRO_QUOTE       : '`"'; // not tested
// MACRO_TEXT        : [\u0000-\u0009\u000b-\u000c\u000e-\u0021\u0023-\u002e\u0030-\u005b\u005d-\u005f\u0061-\u007f]+; // not tested

// SOURCE_TEXT     : [\u0000-\u002e\u0030-\u005f\u0061-\u007f]+; // not tested

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

ASCII_NO_NEWLINE: /[\u0000-\u0009\u000b-\u000c\u000e-\u007f]*/;
// MACRO_ARGS: '(' (MACRO_ARGS | [\u0000-\u0027\u002a-\u007f])* ')'; // not tested
