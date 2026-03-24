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

parser grammar VerilogParser;

options {
    tokenVocab = VerilogLexer;
}

source_text: description* EOF;

description
    : attribute_instance*
      module_keyword identifier module_parameter_port_list? list_of_port_declarations? ';'
      module_item*
      'endmodule'
    | udp_declaration
    | 'config' identifier ';' 'design' design_statement_item* ';' config_rule_statement* 'endconfig'
    ;

module_keyword: 'module' | 'macromodule';

module_parameter_port_list: '#' '(' parameter_declaration (',' parameter_declaration)* ')';
// comma_parameter_declaration: ',' parameter_declaration;

list_of_port_declarations
    : '(' port_declaration (',' port_declaration)* ')'
    | '(' port ( ',' port)* ')'
    | '(' ')'
    ;
// comma_port_declaration: ',' port_declaration;
// comma_port: ',' port;

port: port_expression? | '.' identifier '(' port_expression? ')';

port_expression: identifier_and_const_range_expr | '{' identifier_and_const_range_expr (',' identifier_and_const_range_expr)* '}';
// comma_idcre: ',' identifier_and_const_range_expr;

// TODO FROM HERE
port_declaration
    : attribute_instance* 'inout' net_type? signrange list_of_port_identifiers
    | attribute_instance* 'input' net_type? signrange list_of_port_identifiers
    | attribute_instance* 'output' net_type? signrange list_of_port_identifiers
    | attribute_instance* 'output' 'reg' signrange list_of_variable_port_identifiers
    | attribute_instance* 'output' output_variable_type list_of_variable_port_identifiers
    ;

module_item
    : port_declaration ';'
    | module_or_generate_item
    | 'generate' module_or_generate_item* 'endgenerate'
    | 'specify' (specify_item ';')* 'endspecify'
    | attribute_instance* parameter_declaration ';'
    | attribute_instance* specparam_declaration ';'
    ;
// specitem_semi: specify_item ';';

module_or_generate_item: attribute_instance* mgi;

mgi
    : net_declaration
    | 'reg' signrange list_of_variable_identifiers ';'
    | 'integer' list_of_variable_identifiers ';'
    | 'real' list_of_real_identifiers ';'
    | 'time' list_of_variable_identifiers ';'
    | 'realtime' list_of_real_identifiers ';'
    | event_declaration ';'
    | genvar_declaration
    | task_declaration
    | function_declaration
    | local_parameter_declaration ';'
    | 'defparam' list_of_defparam_assignments ';'
    | continuous_assign
    | gate_instantiation
    | module_instantiation
    | udp_instantiation
    | initial_construct
    | always_construct
    | loop_generate_construct
    | conditional_generate_construct
    ;

design_statement_item: (identifier '.')? identifier;
// identifier_dot: identifier '.';

config_rule_statement: crs ';';
crs: 'default' liblist_clause | inst_or_cell liblist_or_use;

inst_or_cell: 'instance' inst_name | 'cell' (identifier '.')? identifier;

liblist_or_use: liblist_clause | 'use' (identifier '.')? identifier (':' 'config')?;
// colon_config: ':' 'config';

inst_name: identifier ('.' identifier)*;
// dot_identifier: '.' identifier;

liblist_clause: 'liblist' identifier*;

local_parameter_declaration: 'localparam' parameter_type list_of_param_assignments;

parameter_declaration: 'parameter' parameter_type list_of_param_assignments;

specparam_declaration: 'specparam' range_? list_of_specparam_assignments;

// REDO FROM HERE
parameter_type: signrange | 'integer' | 'real' | 'realtime' | 'time';
signrange: 'signed'? range_?

event_declaration: 'event' event_id (',' event_id)*;

net_declaration
    : net_type 'signed'? delay3? list_of_net_identifiers ';'
    | net_type drive_strength? 'signed'? delay3? list_of_net_decl_assignments ';'
    | net_type ('vectored' | 'scalared')? 'signed'? range_ delay3? list_of_net_identifiers ';'
    | net_type drive_strength? ('vectored' | 'scalared')? 'signed'? range_ delay3? list_of_net_decl_assignments ';'
    | 'trireg' charge_strength? 'signed'? delay3? list_of_net_identifiers ';'
    | 'trireg' drive_strength? 'signed'? delay3? list_of_net_decl_assignments ';'
    | 'trireg' charge_strength? ('vectored' | 'scalared')? 'signed'? range_ delay3? list_of_net_identifiers ';'
    | 'trireg' drive_strength? ('vectored' | 'scalared')? 'signed'? range_ delay3? list_of_net_decl_assignments ';'
    ;

// A.2.2.1 Net and variable types
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
    : 'integer'
    | 'time'
    ;

real_type
    : identifier dimension*
    | identifier '=' constant_expression
    ;

variable_type
    : identifier dimension*
    | identifier '=' constant_expression
    ;

// A.2.2.2 Strengths
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

// A.2.2.3 Delays
delay3
    : '#' delay_value
    | '#' '(' mintypmax_expression (',' mintypmax_expression ( ',' mintypmax_expression)?)? ')'
    ;

delay2
    : '#' delay_value
    | '#' '(' mintypmax_expression ( ',' mintypmax_expression)? ')'
    ;

delay_value
    : UNSIGNED_NUMBER
    | real_number
    | identifier
    ;

// A.2.3 Declaration lists
list_of_defparam_assignments
    : defparam_assignment (',' defparam_assignment)*
    ;

event_id
    : identifier dimension*
    ;

list_of_net_decl_assignments
    : net_decl_assignment (',' net_decl_assignment)*
    ;

list_of_net_identifiers
    : net_id (',' net_id)*
    ;

net_id
    : identifier dimension*
    ;

list_of_param_assignments
    : param_assignment (',' param_assignment)*
    ;

list_of_port_identifiers
    : identifier (',' identifier)*
    ;

list_of_real_identifiers
    : real_type (',' real_type)*
    ;

list_of_specparam_assignments
    : specparam_assignment (',' specparam_assignment)*
    ;

list_of_variable_identifiers
    : variable_type (',' variable_type)*
    ;

list_of_variable_port_identifiers
    : var_port_id (',' var_port_id)*
    ;

var_port_id
    : identifier ('=' constant_expression)?
    ;

// A.2.4 Declaration assignments
defparam_assignment
    : hierarchical_identifier '=' constant_mintypmax_expression
    ;

net_decl_assignment
    : identifier '=' expression
    ;

param_assignment
    : identifier '=' constant_mintypmax_expression
    ;

specparam_assignment
    : identifier '=' constant_mintypmax_expression
    | pulse_control_specparam
    ;

pulse_control_specparam
    : 'PATHPULSE$' '=' '(' limit_value (',' limit_value)? ')'
    | 'PATHPULSE$' identifier_and_const_range_expr '$' identifier_and_const_range_expr '=' '(' limit_value (
        ',' limit_value
    )? ')'
    ;

limit_value
    : constant_mintypmax_expression
    ;

dimension
    : '[' dimension_constant_expression ':' dimension_constant_expression ']'
    ;

range_
    : '[' msb_constant_expression ':' lsb_constant_expression ']'
    ;

// A.2.6 Function declarations
function_declaration
    : 'function' 'automatic'? function_range_or_type? identifier ';' function_item_declaration+ function_statement 'endfunction'
    | 'function' 'automatic'? function_range_or_type? identifier '(' function_port_list ')' ';' block_item_declaration* function_statement
        'endfunction'
    ;

function_item_declaration
    : block_item_declaration
    | attribute_instance* tf_input_declaration ';'
    ;

function_port_list
    : func_port_item (',' func_port_item)*
    ;

func_port_item
    : attribute_instance* tf_input_declaration
    ;

function_range_or_type
    : range_
    | 'signed' range_?
    | 'integer'
    | 'real'
    | 'realtime'
    | 'time'
    ;

// A.2.7 Task declarations
task_declaration
    : 'task' 'automatic'? identifier ';' task_item_declaration* statement_or_null 'endtask'
    | 'task' 'automatic'? identifier '(' task_port_list? ')' ';' block_item_declaration* statement_or_null 'endtask'
    ;

task_item_declaration
    : block_item_declaration
    | attribute_instance* tf_input_declaration ';'
    | attribute_instance* tf_output_declaration ';'
    | attribute_instance* tf_inout_declaration ';'
    ;

task_port_list
    : task_port_item (',' task_port_item)*
    ;

task_port_item
    : attribute_instance* tf_input_declaration
    | attribute_instance* tf_output_declaration
    | attribute_instance* tf_inout_declaration
    ;

tf_input_declaration
    : 'input' 'reg'? signrange list_of_port_identifiers
    | 'input' task_port_type list_of_port_identifiers
    ;

tf_output_declaration
    : 'output' 'reg'? signrange list_of_port_identifiers
    | 'output' task_port_type list_of_port_identifiers
    ;

tf_inout_declaration
    : 'inout' 'reg'? signrange list_of_port_identifiers
    | 'inout' task_port_type list_of_port_identifiers
    ;

task_port_type
    : 'integer'
    | 'real'
    | 'realtime'
    | 'time'
    ;

// A.2.8 Block item declarations
block_item_declaration
    : attribute_instance* 'reg' signrange list_of_block_identifiers ';'
    | attribute_instance* 'integer' list_of_block_identifiers ';'
    | attribute_instance* 'time' list_of_block_identifiers ';'
    | attribute_instance* 'real' list_of_block_identifiers ';'
    | attribute_instance* 'realtime' list_of_block_identifiers ';'
    | attribute_instance* event_declaration ';'
    | attribute_instance* local_parameter_declaration ';'
    | attribute_instance* parameter_declaration ';'
    ;

list_of_block_identifiers
    : block_type (',' block_type)*
    ;

block_type
    : identifier dimension*
    ;

// A.3.1 Primitive instantiation and instances
gate_instantiation
    : cmos_switchtype delay3? cmos_switch_instance (',' cmos_switch_instance)* ';'
    | enable_gatetype drive_strength? delay3? enable_gate_instance (',' enable_gate_instance)* ';'
    | mos_switchtype delay3? mos_switch_instance ( ',' mos_switch_instance)* ';'
    | n_input_gatetype drive_strength? delay2? n_input_gate_instance (',' n_input_gate_instance)* ';'
    | n_output_gatetype drive_strength? delay2? n_output_gate_instance (',' n_output_gate_instance)* ';'
    | pass_en_switchtype delay2? pass_enable_switch_instance (',' pass_enable_switch_instance)* ';'
    | pass_switchtype pass_switch_instance ( ',' pass_switch_instance)* ';'
    | 'pulldown' pulldown_strength? pull_gate_instance (',' pull_gate_instance)* ';'
    | 'pullup' pullup_strength? pull_gate_instance ( ',' pull_gate_instance)* ';'
    ;

cmos_switch_instance
    : name_of_gate_instance? '(' net_lvalue ',' expression ',' expression ',' expression ')'
    ;

enable_gate_instance
    : name_of_gate_instance? '(' net_lvalue ',' expression ',' expression ')'
    ;

mos_switch_instance
    : name_of_gate_instance? '(' net_lvalue ',' expression ',' expression ')'
    ;

n_input_gate_instance
    : name_of_gate_instance? '(' net_lvalue ',' expression (',' expression)* ')'
    ;

n_output_gate_instance
    : name_of_gate_instance? '(' net_lvalue (',' net_lvalue)* ',' expression ')'
    ;

pass_switch_instance
    : name_of_gate_instance? '(' net_lvalue ',' net_lvalue ')'
    ;

pass_enable_switch_instance
    : name_of_gate_instance? '(' net_lvalue ',' net_lvalue ',' expression ')'
    ;

pull_gate_instance
    : name_of_gate_instance? '(' net_lvalue ')'
    ;

name_of_gate_instance
    : identifier range_?
    ;

// A.3.2 Primitive strengths
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

// A.4.1 Module instantiation
module_instantiation
    : identifier parameter_value_assignment? module_instance (',' module_instance)* ';'
    ;

parameter_value_assignment
    : '#' '(' list_of_parameter_assignments ')'
    ;

list_of_parameter_assignments
    : expression (',' expression)*
    | named_parameter_assignment ( ',' named_parameter_assignment)*
    ;

named_parameter_assignment
    : '.' identifier '(' mintypmax_expression? ')'
    ;

module_instance
    : name_of_module_instance '(' list_of_port_connections ')'
    ;

name_of_module_instance
    : identifier range_?
    ;

list_of_port_connections
    : ordered_port_connection (',' ordered_port_connection)*
    | named_port_connection ( ',' named_port_connection)*
    ;

ordered_port_connection
    : attribute_instance* expression?
    ;

named_port_connection
    : attribute_instance* '.' identifier '(' expression? ')'
    ;

// A.4.2 Generate construct
genvar_declaration
    : 'genvar' list_of_genvar_identifiers ';'
    ;

list_of_genvar_identifiers
    : identifier (',' identifier)*
    ;

loop_generate_construct
    : 'for' '(' genvar_initialization ';' constant_expression ';' genvar_iteration ')' generate_block
    ;

genvar_initialization
    : identifier '=' constant_expression
    ;

genvar_iteration
    : identifier '=' constant_expression
    ;

conditional_generate_construct
    : if_generate_construct
    | case_generate_construct
    ;

if_generate_construct
    : 'if' '(' constant_expression ')' generate_block_or_null ('else' generate_block_or_null)?
    ;

case_generate_construct
    : 'case' '(' constant_expression ')' case_generate_item+ 'endcase'
    ;

case_generate_item
    : constant_expression (',' constant_expression)* ':' generate_block_or_null
    | 'default' ':'? generate_block_or_null
    ;

generate_block
    : module_or_generate_item
    | 'begin' generate_block_name? module_or_generate_item* 'end'
    ;

generate_block_name
    : ':' identifier
    ;

generate_block_or_null
    : generate_block
    | ';'
    ;

// A.5.1 UDP declaration
udp_declaration
    : attribute_instance* 'primitive' identifier '(' udp_port_list ')' ';' udp_port_declaration+ udp_body 'endprimitive'
    | attribute_instance* 'primitive' identifier '(' udp_declaration_port_list ')' ';' udp_body 'endprimitive'
    ;

// A.5.2 UDP ports
udp_port_list
    : identifier ',' identifier (',' identifier)*
    ;

udp_declaration_port_list
    : udp_output_declaration ',' udp_input_declaration (',' udp_input_declaration)*
    ;

udp_port_declaration
    : udp_output_declaration ';'
    | udp_input_declaration ';'
    | udp_reg_declaration ';'
    ;

udp_output_declaration
    : attribute_instance* 'output' identifier
    | attribute_instance* 'output' 'reg' identifier ('=' constant_expression)?
    ;

udp_input_declaration
    : attribute_instance* 'input' list_of_port_identifiers
    ;

udp_reg_declaration
    : attribute_instance* 'reg' identifier
    ;

// A.5.3 UDP body
udp_body
    : combinational_body
    | sequential_body
    ;

combinational_body
    : 'table' combinational_entry+ 'endtable'
    ;

combinational_entry
    : level_symbol+ ':' OUTPUT_OR_LEVEL_SYMBOL ';'
    ;

sequential_body
    : udp_initial_statement? 'table' sequential_entry+ 'endtable'
    ;

udp_initial_statement
    : 'initial' identifier '=' init_val ';'
    ;

init_val
    : binary_number
    | UNSIGNED_NUMBER
    ;

sequential_entry
    : seq_input_list ':' level_symbol ':' next_state ';'
    ;

seq_input_list
    : level_symbol+
    | edge_input_list
    ;

edge_input_list
    : level_symbol* edge_indicator level_symbol*
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

// A.5.4 UDP instantiation
udp_instantiation
    : identifier drive_strength? delay2? udp_instance (',' udp_instance)* ';'
    ;

udp_instance
    : name_of_udp_instance? '(' net_lvalue ',' expression (',' expression)* ')'
    ;

name_of_udp_instance
    : identifier range_?
    ;

// A.6.1 Continuous assignment statements
continuous_assign
    : 'assign' drive_strength? delay3? list_of_net_assignments ';'
    ;

list_of_net_assignments
    : net_assignment (',' net_assignment)*
    ;

net_assignment
    : net_lvalue '=' expression
    ;

// A.6.2 Procedural blocks and assignments
initial_construct
    : 'initial' statement
    ;

always_construct
    : 'always' statement
    ;

blocking_assignment
    : variable_lvalue '=' delay_or_event_control? expression
    ;

nonblocking_assignment
    : variable_lvalue '<=' delay_or_event_control? expression
    ;

procedural_continuous_assignments
    : 'assign' variable_assignment
    | 'deassign' variable_lvalue
    | 'force' variable_assignment
    | 'release' variable_lvalue
    ;

variable_assignment
    : variable_lvalue '=' expression
    ;

// A.6.3 Parallel and sequential blocks
par_block
    : 'fork' (block_name block_item_declaration*)? statement* 'join'
    ;

block_name
    : ':' identifier
    ;

seq_block
    : 'begin' (block_name block_item_declaration*)? statement* 'end'
    ;

// A.6.4 Statements
statement
    : attribute_instance* blocking_assignment ';'
    | attribute_instance* case_statement
    | attribute_instance* conditional_statement
    | attribute_instance* disable_statement
    | attribute_instance* event_trigger
    | attribute_instance* loop_statement
    | attribute_instance* nonblocking_assignment ';'
    | attribute_instance* par_block
    | attribute_instance* procedural_continuous_assignments ';'
    | attribute_instance* procedural_timing_control_statement
    | attribute_instance* seq_block
    | attribute_instance* system_task_enable
    | attribute_instance* task_enable
    | attribute_instance* wait_statement
    ;

statement_or_null
    : statement
    | attribute_instance* ';'
    ;

function_statement
    : statement
    ;

// A.6.5 Timing control statements
delay_control
    : '#' delay_value
    | '#' '(' mintypmax_expression ')'
    ;

delay_or_event_control
    : delay_control
    | event_control
    | 'repeat' '(' expression ')' event_control
    ;

disable_statement
    : 'disable' hierarchical_identifier ';'
    ;

event_control
    : '@' hierarchical_identifier
    | '@' '(' event_expression ')'
    | '@' '*'
    | '@' '(' '*' ')'
    ;

event_trigger
    : '->' hierarchical_identifier bit_select? ';'
    ;

event_expression
    : expression
    | 'posedge' expression
    | 'negedge' expression
    | event_expression 'or' event_expression
    | event_expression ',' event_expression
    ;

procedural_timing_control
    : delay_control
    | event_control
    ;

procedural_timing_control_statement
    : procedural_timing_control statement_or_null
    ;

wait_statement
    : 'wait' '(' expression ')' statement_or_null
    ;

// A.6.6 Conditional statements
conditional_statement
    : 'if' '(' expression ')' statement_or_null ('else' statement_or_null)?
    ;

// A.6.7 Case statements
case_statement
    : 'case' '(' expression ')' case_item+ 'endcase'
    | 'casez' '(' expression ')' case_item+ 'endcase'
    | 'casex' '(' expression ')' case_item+ 'endcase'
    ;
case_item
    : expression (',' expression)* ':' statement_or_null
    | 'default' ':'? statement_or_null
    ;

// A.6.8 Looping statements
loop_statement
    : 'forever' statement
    | 'repeat' '(' expression ')' statement
    | 'while' '(' expression ')' statement
    | 'for' '(' variable_assignment ';' expression ';' variable_assignment ')' statement
    ;

// A.6.9 Task enable statements
system_task_enable
    : SYSTEM_TF_IDENTIFIER sys_task_en_port_list? ';'
    ;

sys_task_en_port_list
    : '(' expression? (',' expression?)* ')'
    ;

task_enable
    : hierarchical_identifier task_en_port_list? ';'
    ;

task_en_port_list
    : '(' expression (',' expression)* ')'
    ;

// A.7.1 Specify block declaration
specify_item
    : specparam_declaration
    | pulsestyle_declaration
    | showcancelled_declaration
    | path_declaration
    | system_timing_check
    ;

pulsestyle_declaration
    : 'pulsestyle_onevent' list_of_path_outputs
    | 'pulsestyle_ondetect' list_of_path_outputs
    ;

showcancelled_declaration
    : 'showcancelled' list_of_path_outputs
    | 'noshowcancelled' list_of_path_outputs
    ;

// A.7.2 Specify path declarations
path_declaration
    : simple_path_declaration
    | edge_sensitive_path_declaration
    | state_dependent_path_declaration
    ;

simple_path_declaration
    : parallel_path_description '=' path_delay_value
    | full_path_description '=' path_delay_value
    ;

parallel_path_description
    : '(' identifier_and_const_range_expr polarity_operator? '=>' identifier_and_const_range_expr ')'
    ;

full_path_description
    : '(' list_of_path_inputs polarity_operator? '*>' list_of_path_outputs ')'
    ;

list_of_path_inputs
    : identifier_and_const_range_expr (',' identifier_and_const_range_expr)*
    ;

list_of_path_outputs
    : identifier_and_const_range_expr (',' identifier_and_const_range_expr)*
    ;

identifier_and_const_range_expr: identifier ('[' constant_range_expression ']')?;
// brk_cre: '[' constant_range_expression ']'; in several places

// A.7.4 Specify path delays
path_delay_value
    : list_of_path_delay_expressions
    | '(' list_of_path_delay_expressions ')'
    ;

list_of_path_delay_expressions
    : constant_mintypmax_expression
    | constant_mintypmax_expression ',' constant_mintypmax_expression (',' constant_mintypmax_expression)?
    | constant_mintypmax_expression ',' constant_mintypmax_expression ',' constant_mintypmax_expression ',' constant_mintypmax_expression ','
        constant_mintypmax_expression ',' constant_mintypmax_expression (
        ',' constant_mintypmax_expression ',' constant_mintypmax_expression ',' constant_mintypmax_expression ',' constant_mintypmax_expression ','
            constant_mintypmax_expression ',' constant_mintypmax_expression
    )?
    ;

edge_sensitive_path_declaration
    : parallel_edge_sensitive_path_description '=' path_delay_value
    | full_edge_sensitive_path_description '=' path_delay_value
    ;

parallel_edge_sensitive_path_description
    : '(' edge_identifier? identifier_and_const_range_expr '=>' '(' identifier_and_const_range_expr polarity_operator? ':' expression
        ')' ')'
    ;

full_edge_sensitive_path_description
    : '(' edge_identifier? list_of_path_inputs '*>' '(' list_of_path_outputs polarity_operator? ':' expression ')' ')'
    ;

edge_identifier
    : 'posedge'
    | 'negedge'
    ;

state_dependent_path_declaration
    : 'if' '(' module_path_expression ')' simple_path_declaration
    | 'if' '(' module_path_expression ')' edge_sensitive_path_declaration
    | 'ifnone' simple_path_declaration
    ;

polarity_operator
    : '+'
    | '-'
    ;

// A.7.5.1 System timing check commands
system_timing_check
    : setup_timing_check
    | hold_timing_check
    | setuphold_timing_check
    | recovery_timing_check
    | removal_timing_check
    | recrem_timing_check
    | skew_timing_check
    | timeskew_timing_check
    | fullskew_timing_check
    | period_timing_check
    | width_timing_check
    | nochange_timing_check
    ;

setup_timing_check
    : '$setup' '(' timing_check_event ',' timing_check_event ',' timing_check_limit notifier_opt? ')'
    ;

notifier_opt
    : ',' identifier?
    ;

hold_timing_check
    : '$hold' '(' timing_check_event ',' timing_check_event ',' timing_check_limit notifier_opt? ')'
    ;

setuphold_timing_check
    : '$setuphold' '(' timing_check_event ',' timing_check_event ',' timing_check_limit ',' timing_check_limit timing_check_opt? ')'
    ;

timing_check_opt
    : ',' identifier? stamptime_cond_opt?
    ;

stamptime_cond_opt
    : ',' mintypmax_expression? checktime_cond_opt?
    ;

checktime_cond_opt
    : ',' mintypmax_expression? delayed_ref_opt?
    ;

delayed_ref_opt
    : ',' delayed_reference? delayed_data_opt?
    ;

delayed_data_opt
    : ',' delayed_data?
    ;

recovery_timing_check
    : '$recovery' '(' timing_check_event ',' timing_check_event ',' timing_check_limit notifier_opt? ')'
    ;

removal_timing_check
    : '$removal' '(' timing_check_event ',' timing_check_event ',' timing_check_limit notifier_opt? ')'
    ;

recrem_timing_check
    : '$recrem' '(' timing_check_event ',' timing_check_event ',' timing_check_limit ',' timing_check_limit timing_check_opt? ')'
    ;

skew_timing_check
    : '$skew' '(' timing_check_event ',' timing_check_event ',' timing_check_limit notifier_opt? ')'
    ;

timeskew_timing_check
    : '$timeskew' '(' timing_check_event ',' timing_check_event ',' timing_check_limit skew_timing_check_opt? ')'
    ;

skew_timing_check_opt
    : ',' identifier? event_based_flag_opt?
    ;

event_based_flag_opt
    : ',' constant_expression? remain_active_flag_opt?
    ;

remain_active_flag_opt
    : ',' constant_expression?
    ;

fullskew_timing_check
    : '$fullskew' '(' timing_check_event ',' timing_check_event ',' timing_check_limit ',' timing_check_limit skew_timing_check_opt? ')'
    ;

period_timing_check
    : '$period' '(' controlled_timing_check_event ',' timing_check_limit notifier_opt? ')'
    ;

width_timing_check
    : '$width' '(' controlled_timing_check_event ',' timing_check_limit threshold_opt? ')'
    ;

threshold_opt
    : ',' threshold (',' identifier)?
    ;

nochange_timing_check
    : '$nochange' '(' timing_check_event ',' timing_check_event ',' start_edge_offset ',' mintypmax_expression notifier_opt? ')'
    ;

delayed_data
    : identifier ('[' constant_mintypmax_expression ']')?
    ;

delayed_reference
    : identifier ('[' constant_mintypmax_expression ']')?
    ;

// TODO FROM HERE
start_edge_offset
    : mintypmax_expression
    ;

threshold
    : constant_expression
    ;

timing_check_limit
    : expression
    ;

// A.7.5.3 System timing check event definitions
timing_check_event
    : timing_check_event_control? identifier_and_const_range_expr ('&&&' timing_check_condition)?
    ;

controlled_timing_check_event
    : timing_check_event_control identifier_and_const_range_expr ('&&&' timing_check_condition)?
    ;

timing_check_event_control
    : 'posedge'
    | 'negedge'
    | edge_control_specifier
    ;

edge_control_specifier
    : 'edge' '[' edge_descriptor (',' edge_descriptor)* ']'
    ;

edge_descriptor
    : EDGE_DESCRIPTOR
    ;

timing_check_condition
    : scalar_timing_check_condition
    | '(' scalar_timing_check_condition ')'
    ;

scalar_timing_check_condition
    : expression
    | '~' expression
    | expression '==' scalar_constant
    | expression '===' scalar_constant
    | expression '!=' scalar_constant
    | expression '!==' scalar_constant
    ;

scalar_constant
    : binary_number
    | UNSIGNED_NUMBER
    ;

// A.8.1 Concatenations
concatenation
    : '{' expression (',' expression)* '}'
    ;

constant_concatenation
    : '{' constant_expression (',' constant_expression)* '}'
    ;

constant_multiple_concatenation
    : '{' constant_expression constant_concatenation '}'
    ;

module_path_concatenation
    : '{' module_path_expression (',' module_path_expression)* '}'
    ;

module_path_multiple_concatenation
    : '{' constant_expression module_path_concatenation '}'
    ;

multiple_concatenation
    : '{' constant_expression concatenation '}'
    ;

// A.8.2 Function calls
constant_function_call
    : identifier attribute_instance* '(' constant_expression (',' constant_expression)* ')'
    ;

constant_system_function_call
    : SYSTEM_TF_IDENTIFIER '(' constant_expression (',' constant_expression)* ')'
    ;

function_call
    : hierarchical_identifier attribute_instance* '(' expression (',' expression)* ')'
    ;

system_function_call
    : SYSTEM_TF_IDENTIFIER sys_func_call_port_list?
    ;

sys_func_call_port_list
    : '(' expression (',' expression)* ')'
    ;

// A.8.3 Expressions
base_expression
    : expression
    ;

constant_base_expression
    : constant_expression
    ;

constant_expression
    : constant_primary
    | unary_operator attribute_instance* constant_primary
    | constant_expression '**' attribute_instance* constant_expression
    | constant_expression ('*' | '/' | '%') attribute_instance* constant_expression
    | constant_expression ( '+' | '-') attribute_instance* constant_expression
    | constant_expression ('>>' | '<<' | '>>>' | '<<<') attribute_instance* constant_expression
    | constant_expression ('<' | '<=' | '>' | '>=') attribute_instance* constant_expression
    | constant_expression ('==' | '!=' | '===' | '!==') attribute_instance* constant_expression
    | constant_expression '&' attribute_instance* constant_expression
    | constant_expression ('^' | '^~' | '~^') attribute_instance* constant_expression
    | constant_expression '|' attribute_instance* constant_expression
    | constant_expression '&&' attribute_instance* constant_expression
    | constant_expression '||' attribute_instance* constant_expression
    | <assoc = right> constant_expression '?' attribute_instance* constant_expression ':' constant_expression
    ;

constant_mintypmax_expression
    : constant_expression (':' constant_expression ':' constant_expression)?
    ;

constant_range_expression
    : constant_expression
    | msb_constant_expression ':' lsb_constant_expression
    | constant_base_expression '+:' width_constant_expression
    | constant_base_expression '-:' width_constant_expression
    ;

dimension_constant_expression
    : constant_expression
    ;

expression
    : primary
    | unary_operator attribute_instance* primary
    | expression '**' attribute_instance* expression
    | expression ( '*' | '/' | '%') attribute_instance* expression
    | expression ( '+' | '-') attribute_instance* expression
    | expression ( '>>' | '<<' | '>>>' | '<<<') attribute_instance* expression
    | expression ( '<' | '<=' | '>' | '>=') attribute_instance* expression
    | expression ( '==' | '!=' | '===' | '!==') attribute_instance* expression
    | expression '&' attribute_instance* expression
    | expression ( '^' | '^~' | '~^') attribute_instance* expression
    | expression '|' attribute_instance* expression
    | expression '&&' attribute_instance* expression
    | expression '||' attribute_instance* expression
    | <assoc = right> expression '?' attribute_instance* expression ':' expression
    ;

lsb_constant_expression
    : constant_expression
    ;

mintypmax_expression
    : expression (':' expression ':' expression)?
    ;

module_path_expression
    : module_path_primary
    | unary_module_path_operator attribute_instance* module_path_primary
    | module_path_expression ('==' | '!=') attribute_instance* module_path_expression
    | module_path_expression '&' attribute_instance* module_path_expression
    | module_path_expression ('^' | '^~' | '~^') attribute_instance* module_path_expression
    | module_path_expression '|' attribute_instance* module_path_expression
    | module_path_expression '&&' attribute_instance* module_path_expression
    | module_path_expression '||' attribute_instance* module_path_expression
    | <assoc = right> module_path_expression '?' attribute_instance* module_path_expression ':' module_path_expression
    ;

module_path_mintypmax_expression
    : module_path_expression (':' module_path_expression ':' module_path_expression)?
    ;

msb_constant_expression
    : constant_expression
    ;

range_expression
    : expression
    | msb_constant_expression ':' lsb_constant_expression
    | base_expression '+:' width_constant_expression
    | base_expression '-:' width_constant_expression
    ;

width_constant_expression
    : constant_expression
    ;

// A.8.4 Primaries
constant_primary
    : number
    | identifier_and_const_range_expr
    | constant_concatenation
    | constant_multiple_concatenation
    | constant_function_call
    | constant_system_function_call
    | '(' constant_mintypmax_expression ')'
    | STRING
    ;

module_path_primary
    : number
    | identifier
    | module_path_concatenation
    | module_path_multiple_concatenation
    | function_call
    | system_function_call
    | '(' module_path_mintypmax_expression ')'
    ;

primary
    : number
    | hierarchical_identifier select_?
    | concatenation
    | multiple_concatenation
    | function_call
    | system_function_call
    | '(' mintypmax_expression ')'
    | STRING
    ;

select_
    : bit_select? '[' range_expression ']'
    ;

bit_select
    : ('[' expression ']')+
    ;

// A.8.5 Expression left-side values
net_lvalue
    : hierarchical_identifier const_select?
    | '{' net_lvalue ( ',' net_lvalue)* '}'
    ;

const_select
    : const_bit_select? '[' constant_range_expression ']'
    ;

const_bit_select
    : ('[' constant_expression ']')+
    ;

variable_lvalue
    : hierarchical_identifier select_?
    | '{' variable_lvalue ( ',' variable_lvalue)* '}'
    ;

// A.8.6 Operators
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

// A.8.7 Numbers
number
    : decimal_number
    | octal_number
    | binary_number
    | hex_number
    | real_number
    ;

real_number
    : FIXED_POINT_NUMBER
    | EXPONENTIAL_NUMBER
    ;

decimal_number
    : UNSIGNED_NUMBER
    | NON_ZERO_UNSIGNED_NUMBER? DECIMAL_BASE decimal_value
    ;

binary_number
    : NON_ZERO_UNSIGNED_NUMBER? BINARY_BASE BINARY_VALUE
    ;

octal_number
    : NON_ZERO_UNSIGNED_NUMBER? OCTAL_BASE OCTAL_VALUE
    ;

hex_number
    : NON_ZERO_UNSIGNED_NUMBER? HEX_BASE HEX_VALUE
    ;

decimal_value
    : UNSIGNED_NUMBER
    | X_OR_Z_UNDERSCORE
    ;

// A.9.1 Attributes
attribute_instance
    : '(' '*' attr_spec (',' attr_spec)* '*' ')'
    ;

attr_spec
    : identifier ('=' constant_expression)?
    ;

// A.9.3 Identifiers
hierarchical_identifier
    : hier_ref* identifier
    ;

hier_ref
    : identifier const_bit_select? '.'
    ;

identifier
    : ESCAPED_IDENTIFIER
    | SIMPLE_IDENTIFIER
    ;
