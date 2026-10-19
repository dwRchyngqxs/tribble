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

// Expressed this way so that comments and compiler directives are less likely
ignore: (WHITE_SPACE | ' ' | '\t' | '\n' | '\f' | BLOCK_COMMENT | LINE_COMMENT | anywhere_compiler_directive WHITE_SPACE)+;

compiler_directive
    : '`resetall'
    | '`unconnected_drive' WHITE_SPACE UNCONNECTED_DRIVE_VALUE
    | '`nounconnected_drive'
    | '`default_nettype' WHITE_SPACE DEFAULT_NETTYPE_VALUE
    | '`begin_keywords' WHITE_SPACE VERSION_SPECIFIER
    | '`end_keywords'
    | '`timescale' WHITE_SPACE time_unit WHITE_SPACE '/' WHITE_SPACE time_precision
    ;

anywhere_compiler_directive
    : '`celldefine'
    | '`endcelldefine'
//    | '`define' MACRO_NAME macro_text; // not tested
    | '`undef' WHITE_SPACE IDENTIFIER
//    | '`ifdef' IDENTIFIER group_of_lines elsif_directive* else_directive? endif_directive; // not tested
//    | '`ifndef' IDENTIFIER group_of_lines elsif_directive* else_directive? endif_directive; // not tested
//    | '`include' filename; // not tested
// 19.7: only white space may appear on the same line as the `line directive
    | '\n`line' WHITE_SPACE UNSIGNED_NUMBER WHITE_SPACE filename WHITE_SPACE level '\n'
    | '`pragma' WHITE_SPACE SIMPLE_IDENTIFIER (WHITE_SPACE pragma_expression (',' WHITE_SPACE pragma_expression)*)?
//    | '`' MACRO_USAGE; // not tested
    ;

// else_directive: '`else' group_of_lines; // not tested
// elsif_directive: '`elsif' IDENTIFIER group_of_lines; // not tested
// endif_directive: '`endif';

filename: /\"([ !#-[\]-~]|\\[ -~])+\"/;

// group_of_lines: (SOURCE_TEXT | compiler_directive)*; // not tested

level
    : '0'
    | '1'
    | '2'
    ;

// macro_text: (MACRO_TEXT | '``' | '\\\n' | '`\\`"' | MACRO_QUOTE | STRING)*; // not tested

pragma_expression
    : (SIMPLE_IDENTIFIER WHITE_SPACE '=' WHITE_SPACE)? pragma_value
    ;

pragma_value
    : '(' pragma_expression (',' WHITE_SPACE pragma_expression)* ')'
    | UNSIGNED_NUMBER
    | STRING
    | SIMPLE_IDENTIFIER
    ;

time_precision
    : TIME_VALUE WHITE_SPACE TIME_UNIT
    ;

time_unit
    : TIME_VALUE WHITE_SPACE TIME_UNIT
    ;
