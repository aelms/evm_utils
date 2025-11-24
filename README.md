# EVM Utilities 
The EVM utils package contains enhancements for UVM.

## Dependancies
This package requires the following 
- UVM 
- [CLuelib](https://github.com/cluelogic/cluelib)

## Usage
Include evm_utils.f in your simulator manifest `-f evm_utils.f` and (optionally) import the package
contents `import evm_utils_pkg::*`.

## Reporting
Useful UVM messaging utilities.  

## RAL Utilities
RAL field modeling edge triggered events, field coverage, and memory mirroring utilities.  

### Field Edge Modeling
This package provides a utility for detecting and reporting (thru a SV event) an edge on a RAL field.  This is 
useful for modeling design features that occur on a RAL field value change.

### Memory Mirror
This package provides a memory backdoor wrapper that wraps a generated backdoor to optionally call callbacks on 
all backdoor accesses.  It also provides a predictive model of the memory contents, similiar to the RAL mirror 
model for register fields.

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

## RAL Virtual Environment
An environment with all the UVM components to read and write registers and memory in a user supplied RAL without a
physical bus interface.  This environment can be used to develop and test environment components, such as RAL sequences, 
before the design is available.

## Comparer 
When two uvm_sequence_item objects are compare()'d, the uvm_comparer policy class is used to implement how fields 
are compared and the side effects.  

In a similiar manner, this directory contains uvm_comparer policy extensions that are used to compare a series of 
actual and expected uvm_sequence_item(s).  The actual and expected sequence items are stored, checked if they adhere 
or violate the specific policy when possible, and discarded when they are no longer needed.

The series_comparer class is the base for all policies and does not implement a specific series comparer policy.  Its
class description is the recommended starting place.

## Contents

### Reporting
| File | Purpose |
|------|---------|
| evm_report_delegation.sv | Delegate messages from an object to a component like UVM sequences |
| evm_type_name.sv | typename() and get_type_name() implementations for parameterized classes |
| single_line_printer.sv | uvm_line_printer without annoying and superfluous trailing newline |


### RAL Utilties
| File | Purpose |
|------|---------|
| ral_field_edge_event.sv | Detects edge event on a RAL field update |
| ral_mem_bkdr_wrapper.sv | Remap snakenado backdoor and optionally enable callbacks on backdoor access |
| ral_mem_mirror.sv | Mirror model of memories.  Parameterized on predict and ral bit widths  |  
| ral_field_coverage_policies.sv | RAL field coverage policies | 
| ral_field_read_cov_collector.sv | RAL field coverage collection on frontdoor read, parameterized on policy |

### Ral Virtual Environment
| File | Purpose |
|------|---------|
| ral_venv_object.sv | Sequence item wrapper for uvm_reg_bus_op structure |
| ral_venv_adapter.sv | Translates between uvm_reg_bus_op and ral_venv_object |
| ral_venv_agent.sv | Agent for executing register access transactions |
| ral_venv.sv | Environment for RAL register access without a physical interface |

### Comparer
| File | Purpose |
|------|---------|
| series_comparer.sv | Base for all act-exp series comparer policies |
| in_order_lossless_comparer.sv | Policy of act and exp match in-order, without losses |
| out_of_order_lossless_comparer.sv | Policy of act and exp match out-of-order, without losses |
| series_comparer_analysis_imp_if.sv | Provides analysis_imp interface to any series comparer | 

## Future Development 
- RAL Access log to record *all* accesses to design registers.  Reads and writes, frontdoor and backdoor. 
