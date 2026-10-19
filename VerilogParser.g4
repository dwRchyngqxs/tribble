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

// NOT TESTED
// library_text: library_description* EOF;

// library_description: library_declaration | include_statement | config_declaration;

// library_declaration: 'library' IDENTIFIER file_path_spec (',' file_path_spec)* library_incdir? ';';

// library_incdir: '-incdir' file_path_spec (',' file_path_spec)*;

// include_statement: 'include' file_path_spec ';';

// file_path_spec: FILE_PATH_SPEC;

source_text
    : description*
    ;

description
    : attribute_instance* module_keyword IDENTIFIER module_parameter_port_list? port_and_module_items 'endmodule'
    | attribute_instance* 'primitive' IDENTIFIER udp_ports udp_body 'endprimitive'
    | config_declaration
    | compiler_directive WHITE_SPACE
    ;

port_and_module_items 
    : '(' port (',' port)* ')' ';' module_item* 
    | list_of_port_declarations? ';' non_port_module_item* 
    ;

module_keyword
    : 'module'
    | 'macromodule'
    ;

module_parameter_port_list
    : '#' '(' parameter_declaration (',' parameter_declaration)* ')'
    ;

list_of_port_declarations
    : '(' (port_declaration (',' port_declaration)*)? ')'
    ;

port
    : port_expression?
    | '.' IDENTIFIER '(' port_expression? ')'
    ;

port_expression
    : port_reference
    | '{' port_reference (',' port_reference)* '}'
    ;

port_reference
    : IDENTIFIER constant_range_expression?
    ;

port_declaration
    : attribute_instance* 'inout' net_type? 'signed'? range? list_of_identifiers
    | attribute_instance* 'input' net_type? 'signed'? range? list_of_identifiers
    | attribute_instance* output_declaration
    ;

module_item
    : port_declaration ';'
    | non_port_module_item
    ;

non_port_module_item
    : attributed_module_or_generate_item
    | 'generate' attributed_module_or_generate_item* 'endgenerate'
    | 'specify' specify_item* 'endspecify'
    | attribute_instance* parameter_declaration ';'
    | attribute_instance* specparam_declaration
    ;

attributed_module_or_generate_item
    : attribute_instance* module_or_generate_item
    ;

module_or_generate_item
    : (net_type | 'trireg' charge_strength?) net_properties delay3? list_of_identifier_ranges ';'
    | (net_type | 'trireg') drive_strength? net_properties delay3? net_decl_assignment (',' net_decl_assignment)* ';'
    | output_variable_type variable_type (',' variable_type)* ';'
    | ('real' | 'realtime') real_type (',' real_type)* ';'
    | event_declaration
    | 'genvar' list_of_identifiers ';'
    | 'task' 'automatic'? IDENTIFIER task_header_and_decls statement_or_null 'endtask'
    | 'function' 'automatic'? function_range_or_type? IDENTIFIER function_header_and_decls function_statement 'endfunction'
    | local_parameter_declaration ';'
    | 'defparam' defparam_assignment (',' defparam_assignment)* ';'
    | 'assign' drive_strength? delay3? net_assignment (',' net_assignment)* ';'
    | cmos_switchtype delay3? cmos_switch_instance (',' cmos_switch_instance)* ';'
    | enable_gatetype drive_strength? delay3? enable_gate_instance (',' enable_gate_instance)* ';'
    | mos_switchtype delay3? mos_switch_instance (',' mos_switch_instance)* ';'
    | n_input_gatetype drive_strength? delay2? n_input_gate_instance (',' n_input_gate_instance)* ';'
    | n_output_gatetype drive_strength? delay2? n_output_gate_instance (',' n_output_gate_instance)* ';'
    | pass_en_switchtype delay2? pass_enable_switch_instance (',' pass_enable_switch_instance)* ';'
    | pass_switchtype pass_switch_instance (',' pass_switch_instance)* ';'
    | ('pulldown' pulldown_strength? | 'pullup' pullup_strength?) pull_gate_instance (',' pull_gate_instance)* ';'
    | IDENTIFIER parameter_value_assignment? module_instance (',' module_instance)* ';'
    | IDENTIFIER drive_strength? delay2? udp_instance (',' udp_instance)* ';'
    | ('initial' | 'always') attributed_statement
    | 'for' '(' constant_assignment ';' constant_expression ';' constant_assignment ')' generate_block
    | 'if' '(' constant_expression ')' generate_block_or_null ('else' generate_block_or_null)?
    | 'case' '(' constant_expression ')' case_generate_item+ 'endcase'
    ;

config_declaration
    : 'config' IDENTIFIER ';' 'design' dotted_identifier* ';' config_rule_statement* 'endconfig'
    ;

dotted_identifier
    : (IDENTIFIER '.')? IDENTIFIER
    ;

config_rule_statement
    : 'default' liblist_clause ';'
    | inst_or_cell liblist_clause ';'
    | inst_or_cell 'use' dotted_identifier (':' 'config')? ';'
    ;

inst_or_cell
    : 'instance' IDENTIFIER ('.' IDENTIFIER)*
    | 'cell' dotted_identifier
    ;

liblist_clause
    : 'liblist' IDENTIFIER*
    ;

local_parameter_declaration
    : 'localparam' (common_type | 'signed'? range?) list_of_param_assignments
    ;

parameter_declaration
    : 'parameter' (common_type | 'signed'? range?) list_of_param_assignments
    ;

specparam_declaration
    : 'specparam' range? specparam_assignment (',' specparam_assignment)* ';'
    ;

output_declaration
    : 'output' net_type? 'signed'? range? list_of_identifiers
    | 'output' output_variable_type var_port_id (',' var_port_id)*
    ;

event_declaration
    : 'event' list_of_identifier_ranges ';'
    ;

net_properties
    : 'signed'?
    | ('vectored' | 'scalared')? 'signed'? range
    ;

net_type
    : 'supply0'
    | 'supply1'
    | 'tri'
    | 'triand'
    | 'trior'
    | 'tri0'
    | 'tri1'
    | 'uwire'
    | 'wire'
    | 'wand'
    | 'wor'
    ;

output_variable_type
    : 'reg' 'signed'? range?
    | 'integer'
    | 'time'
    ;

real_type
    : identifier_ranges
    | constant_assignment
    ;

variable_type
    : identifier_ranges
    | constant_assignment
    ;

drive_strength
    : '(' strength0 ',' strength1 ')'
    | '(' strength1 ',' strength0 ')'
    | '(' strength0 ',' 'highz1' ')'
    | '(' strength1 ',' 'highz0' ')'
    | '(' 'highz0' ',' strength1 ')'
    | '(' 'highz1' ',' strength0 ')'
    ;

strength0
    : 'supply0'
    | 'strong0'
    | 'pull0'
    | 'weak0'
    ;

strength1
    : 'supply1'
    | 'strong1'
    | 'pull1'
    | 'weak1'
    ;

charge_strength
    : '(' 'small' ')'
    | '(' 'medium' ')'
    | '(' 'large' ')'
    ;

delay3
    : '#' delay_value
    | '#' '(' mintypmax_expression (',' mintypmax_expression){0,2} ')'
    ;

delay2
    : '#' delay_value
    | '#' '(' mintypmax_expression (',' mintypmax_expression)? ')'
    ;

delay_value
    : UNSIGNED_NUMBER
    | real_number
    | IDENTIFIER
    ;

list_of_param_assignments
    : param_assignment (',' param_assignment)*
    ;

var_port_id
    : IDENTIFIER ('=' constant_expression)?
    ;

defparam_assignment
    : hierarchical_identifier '=' constant_mintypmax_expression
    ;

net_decl_assignment
    : IDENTIFIER '=' expression
    ;

param_assignment
    : IDENTIFIER '=' constant_mintypmax_expression
    ;

specparam_assignment
    : param_assignment
    | 'PATHPULSE$' (specify_terminal_descriptor '$' specify_terminal_descriptor)? '=' '(' constant_mintypmax_expression (',' constant_mintypmax_expression)? ')'
    ;

range
    : '[' constant_expression ':' constant_expression ']'
    ;

function_header_and_decls
    : ';' function_item_declaration+
    | '(' function_port_list ')' ';' block_item_declaration*
    ;

function_item_declaration
    : block_item_declaration
    | function_input_declaration ';'
    ;

function_port_list
    : function_input_declaration (',' function_input_declaration)*
    ;

function_input_declaration
    : attribute_instance* 'input' tf_type list_of_identifiers
    ;

function_range_or_type
    : range
    | 'signed' range?
    | 'integer'
    | 'real'
    | 'realtime'
    | 'time'
    ;

task_header_and_decls
    : ';' task_item_declaration*
    | '(' task_port_list? ')' ';' block_item_declaration*
    ;

task_item_declaration
    : block_item_declaration
    | task_port_item ';'
    ;

task_port_list
    : attributed_task_port_item (',' attributed_task_port_item)*
    ;

attributed_task_port_item
    : attribute_instance* task_port_item
    ;

task_port_item
    : task_port_direction tf_type list_of_identifiers
    ;

task_port_direction
    : 'input'
    | 'output'
    | 'inout'
    ;

tf_type
    : 'reg'? 'signed'? range?
    | 'integer'
    | 'real'
    | 'realtime'
    | 'time'
    ;

block_item_declaration
    : attribute_instance* (common_type | 'reg' 'signed'? range?) list_of_identifier_ranges ';'
    | attribute_instance* event_declaration
    | attribute_instance* local_parameter_declaration ';'
    | attribute_instance* parameter_declaration ';'
    ;

common_type
    : 'integer'
    | 'real'
    | 'realtime'
    | 'time'
    ;

list_of_identifier_ranges
    : identifier_ranges (',' identifier_ranges)*
    ;

identifier_ranges
    : IDENTIFIER range*
    ;

cmos_switch_instance
    : identifier_range? '(' net_lvalue (',' expression){3} ')'
    ;

enable_gate_instance
    : identifier_range? '(' net_lvalue (',' expression){2} ')'
    ;

mos_switch_instance
    : identifier_range? '(' net_lvalue (',' expression){2} ')'
    ;

n_input_gate_instance
    : identifier_range? '(' net_lvalue ',' list_of_expressions ')'
    ;

n_output_gate_instance
    : identifier_range? '(' net_lvalue (',' net_lvalue)* ',' expression ')'
    ;

pass_switch_instance
    : identifier_range? '(' net_lvalue ',' net_lvalue ')'
    ;

pass_enable_switch_instance
    : identifier_range? '(' (net_lvalue ','){2} expression ')'
    ;

pull_gate_instance
    : identifier_range? '(' net_lvalue ')'
    ;

pulldown_strength
    : '(' strength0 ',' strength1 ')'
    | '(' strength1 ',' strength0 ')'
    | '(' strength0 ')'
    ;

pullup_strength
    : '(' strength0 ',' strength1 ')'
    | '(' strength1 ',' strength0 ')'
    | '(' strength1 ')'
    ;

cmos_switchtype
    : 'cmos'
    | 'rcmos'
    ;

enable_gatetype
    : 'bufif0'
    | 'bufif1'
    | 'notif0'
    | 'notif1'
    ;

mos_switchtype
    : 'nmos'
    | 'pmos'
    | 'rnmos'
    | 'rpmos'
    ;

n_input_gatetype
    : 'and'
    | 'nand'
    | 'or'
    | 'nor'
    | 'xor'
    | 'xnor'
    ;

n_output_gatetype
    : 'buf'
    | 'not'
    ;

pass_en_switchtype
    : 'tranif0'
    | 'tranif1'
    | 'rtranif1'
    | 'rtranif0'
    ;

pass_switchtype
    : 'tran'
    | 'rtran'
    ;

parameter_value_assignment
    : '#' '(' list_of_parameter_assignments ')'
    ;

list_of_parameter_assignments
    : list_of_expressions
    | named_parameter_assignment (',' named_parameter_assignment)*
    ;

named_parameter_assignment
    : '.' IDENTIFIER '(' mintypmax_expression? ')'
    ;

module_instance
    : identifier_range '(' list_of_port_connections ')'
    ;

list_of_port_connections
    : ordered_port_connection (',' ordered_port_connection)*
    | named_port_connection (',' named_port_connection)*
    ;

ordered_port_connection
    : attribute_instance* expression?
    ;

named_port_connection
    : attribute_instance* '.' IDENTIFIER '(' expression? ')'
    ;

list_of_identifiers
    : IDENTIFIER (',' IDENTIFIER)*
    ;

constant_assignment
    : IDENTIFIER '=' constant_expression
    ;

case_generate_item
    : list_of_constant_expressions ':' generate_block_or_null
    | 'default' ':'? generate_block_or_null
    ;

generate_block
    : attributed_module_or_generate_item
    | 'begin' block_name? attributed_module_or_generate_item* 'end'
    ;

generate_block_or_null
    : generate_block
    | ';'
    ;

udp_ports
    : '(' IDENTIFIER ',' list_of_identifiers ')' ';' udp_port_declaration+
    | '(' udp_output_declaration ',' udp_input_declaration (',' udp_input_declaration)* ')' ';'
    ;

udp_port_declaration
    : udp_output_declaration ';'
    | udp_input_declaration ';'
    | attribute_instance* 'reg' IDENTIFIER ';'
    ;

udp_output_declaration
    : attribute_instance* 'output' (IDENTIFIER | 'reg' IDENTIFIER ('=' constant_expression)?)
    ;

udp_input_declaration
    : attribute_instance* 'input' list_of_identifiers
    ;

udp_body
    : 'table' combinational_entry+ 'endtable'
    | udp_initial_statement? 'table' sequential_entry+ 'endtable'
    ;

combinational_entry
    : level_symbol+ ':' OUTPUT_OR_LEVEL_SYMBOL ';'
    ;

udp_initial_statement
    : 'initial' IDENTIFIER '=' init_val ';'
    ;

init_val
    : binary_number
    | UNSIGNED_NUMBER
    ;

sequential_entry
    : level_symbol* seq_input_list ':' level_symbol ':' next_state ';'
    ;

seq_input_list
    : level_symbol
    | edge_indicator level_symbol*
    ;

edge_indicator
    : '(' level_symbol level_symbol ')'
    | EDGE_SYMBOL
    ;

next_state
    : OUTPUT_OR_LEVEL_SYMBOL
    | '-'
    ;

level_symbol
    : LEVEL_ONLY_SYMBOL
    | OUTPUT_OR_LEVEL_SYMBOL
    ;

udp_instance
    : identifier_range? '(' net_lvalue ',' expression (',' expression)* ')'
    ;

identifier_range
    : IDENTIFIER range?
    ;

net_assignment
    : net_lvalue '=' expression
    ;

procedural_continuous_assignments
    : ('assign' | 'force') variable_assignment
    | ('deassign' | 'release') variable_lvalue
    ;

variable_assignment
    : variable_lvalue '=' expression
    ;

block_name
    : ':' IDENTIFIER
    ;

attributed_statement
    : attribute_instance* statement
    ;

statement
    : variable_lvalue ('=' | '<=') delay_or_event_control? expression ';'
    | case_type '(' expression ')' case_item+ 'endcase'
    | 'if' '(' expression ')' statement_or_null ('else' statement_or_null)?
    | 'disable' hierarchical_identifier ';'
    | '->' hierarchical_identifier bit_select* ';'
    | loop_header attributed_statement
    | 'fork' (block_name block_item_declaration*)? attributed_statement* 'join'
    | procedural_continuous_assignments ';'
    | timing_control statement_or_null
    | 'begin' (block_name block_item_declaration*)? attributed_statement* 'end'
    | SYSTEM_TF_IDENTIFIER sys_task_en_port_list? ';'
    | hierarchical_identifier parenthesised_list_of_expressions? ';'
    ;

statement_or_null
    : attribute_instance* (statement | ';')
    ;

// standard unclear on what is allowed, will refine for each tool
function_statement
    : attributed_statement
    ;

delay_control
    : '#' delay_value
    | '#' '(' mintypmax_expression ')'
    ;

delay_or_event_control
    : delay_control
    | ('repeat' '(' expression ')')? '@' event_control
    ;

event_control
    : hierarchical_identifier
    | '(' event_expression ')'
    | '*'
    | '(' '*' ')'
    ;

event_expression
    : edge_identifier? expression (('or' | ',') event_expression)?
    ;

timing_control
    : delay_control
    | '@' event_control
    | 'wait' '(' expression ')' 
    ;

case_type
    : 'case'
    | 'casez'
    | 'casex'
    ;

case_item
    : (list_of_expressions ':' | 'default' ':'?) statement_or_null
    ;

loop_header
    : 'forever'
    | 'repeat' '(' expression ')'
    | 'while' '(' expression ')'
    | 'for' '(' variable_assignment ';' expression ';' variable_assignment ')'
    ;

sys_task_en_port_list
    : '(' expression? (',' expression?)* ')'
    ;

specify_item
    : specparam_declaration
    | pulsestyle_showcancelled list_of_paths ';'
    | simple_path_declaration ';'
    | edge_sensitive_path_declaration ';'
    | 'if' '(' module_path_expression ')' simple_path_declaration ';'
    | 'if' '(' module_path_expression ')' edge_sensitive_path_declaration ';'
    | 'ifnone' simple_path_declaration ';'
    | ('$setup' | '$hold') '(' timing_check_event ',' timing_check_event ',' expression notifier_opt? ')' ';'
    | '$setuphold' '(' timing_check_event ',' timing_check_event ',' expression ',' expression timing_check_opt? ')' ';'
    | ('$recovery' | '$removal') '(' timing_check_event ',' timing_check_event ',' expression notifier_opt? ')' ';'
    | '$recrem' '(' timing_check_event ',' timing_check_event ',' expression ',' expression timing_check_opt? ')' ';'
    | '$skew' '(' timing_check_event ',' timing_check_event ',' expression notifier_opt? ')' ';'
    | '$timeskew' '(' timing_check_event ',' timing_check_event ',' expression skew_timing_check_opt? ')' ';'
    | '$fullskew' '(' timing_check_event ',' timing_check_event ',' expression ',' expression skew_timing_check_opt? ')' ';'
    | '$period' '(' controlled_reference_event ',' expression notifier_opt? ')' ';'
    | '$width' '(' controlled_reference_event ',' expression threshold_opt? ')' ';'
    | '$nochange' '(' timing_check_event ',' timing_check_event ',' mintypmax_expression ',' mintypmax_expression notifier_opt? ')' ';'
    ;

pulsestyle_showcancelled
    : 'pulsestyle_onevent'
    | 'pulsestyle_ondetect'
    | 'showcancelled'
    | 'noshowcancelled'
    ;

simple_path_declaration
    : '(' full_parallel_path_description ')' '=' path_delay_value
    ;

full_parallel_path_description
    : specify_terminal_descriptor additive_operator? '=>' specify_terminal_descriptor
    | list_of_paths additive_operator? '*>' list_of_paths
    ;

list_of_paths
    : specify_terminal_descriptor (',' specify_terminal_descriptor)*
    ;

specify_terminal_descriptor
    : IDENTIFIER constant_range_expression?
    ;

path_delay_value
    : list_of_path_delay_expressions
    | '(' list_of_path_delay_expressions ')'
    ;

list_of_path_delay_expressions
    : constant_mintypmax_expression (',' constant_mintypmax_expression){0,2}
    | constant_mintypmax_expression (',' constant_mintypmax_expression){5} ((',' constant_mintypmax_expression){6})?
    ;

edge_sensitive_path_declaration
    : '(' edge_identifier? full_parallel_path_declaration additive_operator? ':' expression ')' ')' '=' path_delay_value
    ;

full_parallel_path_declaration
    : specify_terminal_descriptor '=>' '(' specify_terminal_descriptor
    | list_of_paths '*>' '(' list_of_paths
    ;

edge_identifier
    : 'posedge'
    | 'negedge'
    ;

notifier_opt
    : ',' IDENTIFIER?
    ;

timing_check_opt
    : ',' IDENTIFIER? stamptime_cond_opt?
    ;

stamptime_cond_opt
    : ',' mintypmax_expression? checktime_cond_opt?
    ;

checktime_cond_opt
    : ',' mintypmax_expression? delayed_ref_opt?
    ;

delayed_ref_opt
    : ',' delayed_dataref? delayed_data_opt?
    ;

delayed_data_opt
    : ',' delayed_dataref?
    ;

skew_timing_check_opt
    : ',' IDENTIFIER? event_based_flag_opt?
    ;

event_based_flag_opt
    : ',' constant_expression? remain_active_flag_opt?
    ;

remain_active_flag_opt
    : ',' constant_expression?
    ;

threshold_opt
    : ',' constant_expression (',' IDENTIFIER)?
    ;

controlled_reference_event
    : timing_check_event_control specify_terminal_descriptor ('&&&' timing_check_condition)?
    ;

delayed_dataref
    : IDENTIFIER ('[' constant_mintypmax_expression ']')?
    ;

timing_check_event
    : timing_check_event_control? specify_terminal_descriptor ('&&&' timing_check_condition)?
    ;

timing_check_event_control
    : 'posedge'
    | 'negedge'
    | 'edge' '[' EDGE_DESCRIPTOR (',' EDGE_DESCRIPTOR)* ']'
    ;

timing_check_condition
    : scalar_timing_check_condition
    | '(' scalar_timing_check_condition ')'
    ;

scalar_timing_check_condition
    : '~'? expression
    | expression equality_operator scalar_constant
    ;

scalar_constant
    : binary_number
    | UNSIGNED_NUMBER
    ;

list_of_expressions
    : expression (',' expression)*
    ;

parenthesised_list_of_expressions
    : '(' list_of_expressions ')'
    ;

list_of_constant_expressions
    : constant_expression (',' constant_expression)*
    ;

concatenation
    : '{' list_of_expressions '}'
    ;

constant_concatenation
    : '{' list_of_constant_expressions '}'
    ;

attribute_concatenation
    : '{' attribute_expression (',' attribute_expression)* '}'
    ;

module_path_concatenation
    : '{' module_path_expression (',' module_path_expression)* '}'
    ;

function_call
    : hierarchical_identifier attribute_instance* parenthesised_list_of_expressions
    ;

system_function_call
    : SYSTEM_TF_IDENTIFIER parenthesised_list_of_expressions?
    ;

constant_expression
    : constant_conditional_expression ('?' attribute_instance* constant_expression ':' constant_expression)?
    ;

constant_conditional_expression
    : (constant_conditional_expression '||' attribute_instance*)? constant_disjunctive_expression
    ;

constant_disjunctive_expression
    : (constant_disjunctive_expression '&&' attribute_instance*)? constant_conjunctive_expression
    ;

constant_conjunctive_expression
    : (constant_conjunctive_expression '|' attribute_instance*)? constant_or_expression
    ;

constant_or_expression
    : (constant_or_expression xor_operator attribute_instance*)? constant_xor_expression
    ;

constant_xor_expression
    : (constant_xor_expression '&' attribute_instance*)? constant_and_expression
    ;

constant_and_expression
    : (constant_and_expression equality_operator attribute_instance*)? constant_eq_expression
    ;

constant_eq_expression
    : (constant_eq_expression inequality_operator attribute_instance*)? constant_cmp_expression
    ;

constant_cmp_expression
    : (constant_cmp_expression shift_operator attribute_instance*)? constant_shift_expression
    ;

constant_shift_expression
    : (constant_shift_expression additive_operator attribute_instance*)? constant_additive_expression
    ;

constant_additive_expression
    : (constant_additive_expression multiplicative_operator attribute_instance*)? constant_multiplicative_expression
    ;

constant_multiplicative_expression
    : (constant_multiplicative_expression '**' attribute_instance*)? (unary_operator attribute_instance*)? constant_primary
    ;

constant_mintypmax_expression
    : constant_expression (':' constant_expression ':' constant_expression)?
    ;

constant_range_expression
    : '[' constant_expression (range_type constant_expression)? ']'
    ;

attribute_expression
    : attribute_conditional_expression ('?' attribute_expression ':' attribute_expression)?
    ;

attribute_conditional_expression
    : (attribute_conditional_expression '||')? attribute_disjunctive_expression
    ;

attribute_disjunctive_expression
    : (attribute_disjunctive_expression '&&')? attribute_conjunctive_expression
    ;

attribute_conjunctive_expression
    : (attribute_conjunctive_expression '|')? attribute_or_expression
    ;

attribute_or_expression
    : (attribute_or_expression xor_operator)? attribute_xor_expression
    ;

attribute_xor_expression
    : (attribute_xor_expression '&')? attribute_and_expression
    ;

attribute_and_expression
    : (attribute_and_expression equality_operator)? attribute_eq_expression
    ;

attribute_eq_expression
    : (attribute_eq_expression inequality_operator)? attribute_cmp_expression
    ;

attribute_cmp_expression
    : (attribute_cmp_expression shift_operator)? attribute_shift_expression
    ;

attribute_shift_expression
    : (attribute_shift_expression additive_operator)? attribute_additive_expression
    ;

attribute_additive_expression
    : (attribute_additive_expression multiplicative_operator)? attribute_multiplicative_expression
    ;

attribute_multiplicative_expression
    : (attribute_multiplicative_expression '**')? unary_operator? attribute_primary
    ;

attribute_mintypmax_expression
    : attribute_expression (':' attribute_expression ':' attribute_expression)?
    ;

attribute_range_expression
    : attribute_expression (range_type attribute_expression)?
    ;

expression
    : conditional_expression ('?' attribute_instance* expression ':' expression)?
    ;

conditional_expression
    : (conditional_expression '||' attribute_instance*)? disjunctive_expression
    ;

disjunctive_expression
    : (disjunctive_expression '&&' attribute_instance*)? conjunctive_expression
    ;

conjunctive_expression
    : (conjunctive_expression '|' attribute_instance*)? or_expression
    ;

or_expression
    : (or_expression xor_operator attribute_instance*)? xor_expression
    ;

xor_expression
    : (xor_expression '&' attribute_instance*)? and_expression
    ;

and_expression
    : (and_expression equality_operator attribute_instance*)? eq_expression
    ;

eq_expression
    : (eq_expression inequality_operator attribute_instance*)? cmp_expression
    ;

cmp_expression
    : (cmp_expression shift_operator attribute_instance*)? shift_expression
    ;

shift_expression
    : (shift_expression additive_operator attribute_instance*)? additive_expression
    ;

additive_expression
    : (additive_expression multiplicative_operator attribute_instance*)? multiplicative_expression
    ;

multiplicative_expression
    : (multiplicative_expression '**' attribute_instance*)? (unary_operator attribute_instance*)? primary
    ;

mintypmax_expression
    : expression (':' expression ':' expression)?
    ;

module_path_expression
    : module_path_conditional_expression ('?' attribute_instance* module_path_expression ':' module_path_expression)?
    ;

module_path_conditional_expression
    : (module_path_conditional_expression '||' attribute_instance*)? module_path_disjunctive_expression
    ;

module_path_disjunctive_expression
    : (module_path_disjunctive_expression '&&' attribute_instance*)? module_path_conjunctive_expression
    ;

module_path_conjunctive_expression
    : (module_path_conjunctive_expression '|' attribute_instance*)? module_path_or_expression
    ;

module_path_or_expression
    : (module_path_or_expression xor_operator attribute_instance*)? module_path_xor_expression
    ;

module_path_xor_expression
    : (module_path_xor_expression '&' attribute_instance*)? module_path_and_expression
    ;

module_path_and_expression
    : (module_path_and_expression module_path_equality_operator attribute_instance*)? (unary_module_path_operator attribute_instance*)? module_path_primary
    ;

module_path_mintypmax_expression
    : module_path_expression (':' module_path_expression ':' module_path_expression)?
    ;

range_expression
    : expression (('+:' | '-:') constant_expression)?
    | constant_expression ':' constant_expression
    ;

constant_primary
    : number
    | IDENTIFIER constant_range_expression?
    | constant_concatenation
    | '{' constant_expression constant_concatenation '}'
    | IDENTIFIER attribute_instance* '(' list_of_constant_expressions ')'
    | SYSTEM_TF_IDENTIFIER '(' list_of_constant_expressions ')'
    | '(' constant_mintypmax_expression ')'
    | STRING
    ;

attribute_primary
    : number
    | IDENTIFIER ('[' attribute_range_expression ']')?
    | attribute_concatenation
    | '{' attribute_expression attribute_concatenation '}'
    | IDENTIFIER '(' attribute_expression (',' attribute_expression)* ')'
    | SYSTEM_TF_IDENTIFIER '(' attribute_expression (',' attribute_expression)* ')'
    | '(' attribute_mintypmax_expression ')'
    | STRING
    ;

module_path_primary
    : number
    | IDENTIFIER
    | module_path_concatenation
    | '{' constant_expression module_path_concatenation '}'
    | function_call
    | system_function_call
    | '(' module_path_mintypmax_expression ')'
    ;

primary
    : number
    | hierarchical_identifier select?
    | concatenation
    | '{' constant_expression concatenation '}'
    | function_call
    | system_function_call
    | '(' mintypmax_expression ')'
    | STRING
    ;

select
    : bit_select* '[' range_expression ']'
    ;

bit_select
    : '[' expression ']'
    ;

net_lvalue
    : hierarchical_identifier const_select?
    | '{' net_lvalue (',' net_lvalue)* '}'
    ;

const_select
    : const_bit_select* constant_range_expression
    ;

const_bit_select
    : '[' constant_expression ']'
    ;

variable_lvalue
    : hierarchical_identifier select?
    | '{' variable_lvalue (',' variable_lvalue)* '}'
    ;

range_type
    : ':'
    | '+:'
    | '-:'
    ;

equality_operator
    : '=='
    | '!='
    | '==='
    | '!=='
    ;

inequality_operator
    : '<'
    | '<='
    | '>'
    | '>='
    ;

shift_operator
    : '>>'
    | '<<'
    | '>>>'
    | '<<<'
    ;

additive_operator
    : '+'
    | '-'
    ;

multiplicative_operator
    : '*'
    | '/'
    | '%'
    ;

xor_operator
    : '^'
    | '^~'
    | '~^'
    ;

module_path_equality_operator
    : '=='
    | '!='
    ;

unary_operator
    : '+'
    | '-'
    | '!'
    | '~'
    | '&'
    | '~&'
    | '|'
    | '~|'
    | '^'
    | '~^'
    | '^~'
    ;

unary_module_path_operator
    : '!'
    | '~'
    | '&'
    | '~&'
    | '|'
    | '~|'
    | '^'
    | '~^'
    | '^~'
    ;

number
    : UNSIGNED_NUMBER
    | SIZE? /'[sS]?[dD]/ (UNSIGNED_NUMBER | X_OR_Z_UNDERSCORE)
    | SIZE? /'[sS]?[oO]/ OCTAL_VALUE
    | binary_number
    | SIZE? /'[sS]?[hH]/ HEX_VALUE
    | real_number
    ;

real_number
    : FIXED_POINT_NUMBER
    | EXPONENTIAL_NUMBER
    ;

binary_number
    : SIZE? /'[sS]?[bB]/ BINARY_VALUE
    ;

attribute_instance
    : '(*' attr_spec (',' attr_spec)* '*)'
    ;

attr_spec
    : IDENTIFIER ('=' attribute_expression)?
    ;

hierarchical_identifier
    : hier_ref* IDENTIFIER
    ;

hier_ref
    : IDENTIFIER const_bit_select* '.'
    ;
