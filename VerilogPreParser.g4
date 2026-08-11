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

ignore: (' ' | '\t' | '\n' | '\f' | BLOCK_COMMENT | LINE_COMMENT | anywhere_compiler_directive WHITE_SPACE)+;

compiler_directive
    : resetall_directive
    | unconnected_drive_directive
    | nounconnected_drive_directive
    | default_nettype_directive
    | begin_keywords_directive
    | end_keywords_directive
    | timescale_directive
    ;

anywhere_compiler_directive
    : celldefine_directive
    | endcelldefine_directive
//    | text_macro_definition
    | undef_directive
//    | ifdef_directive
//    | ifndef_directive
//    | include_directive
    | line_directive
    | pragma_directive
//    | text_macro_usage
    ;

begin_keywords_directive
    : '`begin_keywords' WHITE_SPACE version_specifier
    ;

celldefine_directive
    : '`celldefine'
    ;

default_nettype_directive
    : '`default_nettype' WHITE_SPACE default_nettype_value
    ;

default_nettype_value
    : DEFAULT_NETTYPE_VALUE
    ;

// else_directive: '`else' group_of_lines;
// elsif_directive: '`elsif' macro_identifier group_of_lines;

end_keywords_directive
    : '`end_keywords'
    ;

endcelldefine_directive
    : '`endcelldefine'
    ;

// endif_directive: '`endif';

filename
    : /\"([ !#-[\]-~]|\\[ -~])+\"/
    ;

// group_of_lines: (source_text_ | compiler_directive)*;

// ifdef_directive: '`ifdef' macro_identifier group_of_lines elsif_directive* else_directive? endif_directive;

// ifndef_directive: '`ifndef' macro_identifier group_of_lines elsif_directive* else_directive? endif_directive;

// include_directive: '`include' filename;

level
    : '0'
    | '1'
    | '2'
    ;

line_directive
    : '\n`line' WHITE_SPACE UNSIGNED_NUMBER WHITE_SPACE filename WHITE_SPACE level '\n'
    ;

// macro_delimiter: MACRO_DELIMITER;

// macro_esc_newline: MACRO_ESC_NEWLINE;

// macro_esc_quote: MACRO_ESC_QUOTE;

macro_identifier
    : MACRO_IDENTIFIER
    ;

// macro_name: MACRO_NAME;

// macro_quote: MACRO_QUOTE;

// macro_text: (macro_text_ | macro_delimiter | macro_esc_newline | macro_esc_quote | macro_quote | string_)*;

// macro_text_: MACRO_TEXT;

// macro_usage: MACRO_USAGE;

nounconnected_drive_directive
    : '`nounconnected_drive'
    ;

pragma_directive
    : '`pragma' WHITE_SPACE pragma_name (WHITE_SPACE pragma_expression (CO WHITE_SPACE pragma_expression)*)?
    ;

pragma_expression
    : (pragma_keyword WHITE_SPACE EQ WHITE_SPACE)? pragma_value
    ;

pragma_keyword
    : SIMPLE_IDENTIFIER
    ;

pragma_name
    : SIMPLE_IDENTIFIER
    ;

pragma_value
    : LP pragma_expression (CO WHITE_SPACE pragma_expression)* RP
    | unsigned_number
    | STRING
    | SIMPLE_IDENTIFIER
    ;

resetall_directive
    : '`resetall'
    ;

// source_text_: SOURCE_TEXT;

// text_macro_definition: '`define' macro_name macro_text;

// text_macro_usage: '`' macro_usage;

time_precision
    : TIME_VALUE WHITE_SPACE TIME_UNIT
    ;

time_unit
    : TIME_VALUE WHITE_SPACE TIME_UNIT
    ;

timescale_directive
    : '`timescale' WHITE_SPACE time_unit WHITE_SPACE SL WHITE_SPACE time_precision
    ;

unconnected_drive_directive
    : '`unconnected_drive' WHITE_SPACE unconnected_drive_value
    ;

unconnected_drive_value
    : UNCONNECTED_DRIVE_VALUE
    ;

undef_directive
    : '`undef' WHITE_SPACE macro_identifier
    ;

version_specifier
    : VERSION_SPECIFIER
    ;
