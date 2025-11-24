# EVM Utilities 
The EVM utils package contains enhancements for UVM.

## Dependancies
This package requires the following 
- UVM 
- [CLuelib](https://github.com/cluelogic/cluelib)

## Usage
Include `src` in your `incdir` list and `evm_utils_pkg.sv` in your manifest.  Optionally, import the package
contents.

## Reporting
Useful UVM messaging utilities to delegate non-component messages to a UVM component, single line printing, typename 
macros, and report server.  

## RAL Utilities
RAL field modeling edge triggered events, field coverage, memory mirroring and register access logging utilities.  

### Field Edge Modeling
This package provides a utility for detecting and reporting (thru a SV event) an edge on a RAL field.  This is 
useful for modeling design features that occur on a RAL field value change.

### Field Coverage
RAL fields will require different types of coverage to be collected at different times.  One example is a 
configuration field with a small set of legal values that controls the operation of a state-machine.  Covering 
*all the legal values* when the *state machine is started* is the appropriate coverage.  Another example is a
large configuration field that specifies a value range that transactions are compared against.  Covering each 
*bit has been set and clr* when a *transaction is checked* is the correct coverage goal in this case.  

These examples show that register fields can have different coverage goals that should be collected under different 
conditions.  There are also cases where coverage should be collected per-field instance. 

The register coverage classes in this package provide a wide set of coverage policies that define *WHAT* to cover
on any register field.  It also provides a field coverage collectors that define *HOW and WHEN* that coverage is
collected.  This structure allows the right coverage, to be collected under the right conditions, and attached to 
any field.

The header comments in ral_field_coverage_policies.sv is the recommended starting place.

### Memory Mirror
This package provides a memory backdoor wrapper that wraps a generated backdoor to optionally call callbacks on 
all backdoor accesses.  It also provides a predictive model of the memory contents, similiar to the RAL mirror 
model for register fields.

### Register Access Logging
This component logs all register accesses to a single, dedicated log file.  This includes read(), write(), mirror(), 
update(), (thru any path or map), peek(), and poke().  It logs the returned read value and the provided write value.  
Both access types log the final *mirror* value for all fields; this is verification's expected value for the design 
after the access completes.

## RAL Virtual Environment
An environment that provides RAL register read and write access with only the RAL model.  This environment can be 
used to develop and test RAL environment components, such as RAL sequences, before the design is available.

## Comparer 
When two uvm_sequence_item objects are compare()'d, the uvm_comparer policy class is used to implement how fields 
are compared and the side effects.  

In a similiar manner, this directory contains uvm_comparer policy extensions that are used to compare a series of 
actual and expected uvm_sequence_item(s).  The actual and expected sequence items are stored, checked if they adhere 
or violate the specific policy when possible, and discarded when they are no longer needed.

The evm_series_comparer class is the base for all policies and does not implement a specific series comparer policy.  Its
class description is the recommended starting place.

## Contents

### Reporting
| File | Purpose |
|------|---------|
| evm_report_delegation.sv | Delegate messages from an object to a component like UVM sequences |
| evm_type_name.sv | typename() and get_type_name() implementations for parameterized classes |
| evm_single_line_printer.sv | uvm_line_printer without its trailing newline |
| evm_report_server.sv | Print a more distinct pass or fail status |


### RAL Utilties
| File | Purpose |
|------|---------|
| evm_ral_field_edge_event.sv | Detects edge event on a RAL field update |
| evm_ral_mem_bkdr_wrapper.sv | Wrap existing backdoor to allow callbacks and modify behaviour |
| evm_ral_mem_mirror.sv | Mirror model of memories.  Parameterized on predict and ral bit widths  |  
| evm_ral_field_coverage_policies.sv | RAL field coverage policies | 
| evm_ral_field_read_cov_collector.sv | RAL field coverage collection on frontdoor read, parameterized on policy |
| evm_ral_reg_logger.sv | RAL register access transaction logging |

### Ral Virtual Environment
| File | Purpose |
|------|---------|
| evm_ral_venv.sv | Environment providing register access with just the RAL model |
| evm_ral_venv_agent.sv | Agent executes register access with just the RAL model |
| evm_ral_venv_backdoor.sv | Backdoor register access with just the RAL model |

### Comparer
| File | Purpose |
|------|---------|
| evm_series_comparer.sv | Base for all act-exp series comparer policies |
| evm_in_order_lossless_comparer.sv | Policy of act and exp match in-order, without losses |
| evm_out_of_order_lossless_comparer.sv | Policy of act and exp match out-of-order, without losses |
| evm_series_comparer_analysis_imp_if.sv | Provides analysis_imp interface to any series comparer | 


## Future Development 
- RAL Access log enhacements
    - Log field accesses
    - Table format 
    - Only log unique subset of full register name 
- Add memory mirroring to unit test

## Unit Tests
The unit_test subdirectory contains a full UVM testcase for testing basic functionality of 
most of the EVM Utilities.  The tests can be run using the Makefile in the run dir and were 
tested under `verilator 5.049`.
