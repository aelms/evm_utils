`ifndef EVM_UTILS_PKG__SV
`define EVM_UTILS_PKG__SV
package evm_utils_pkg;

  import uvm_pkg::*;
  import cl::*;

  typedef enum bit { FALSE = 1'b0,    TRUE = 1'b1 }    boolean_t;

  /* Defines coverage bins for each bit of value to be set and clr  .  Up to a maximum bit size 
   * of 32, which is reasonable for things like register fields.  If more are needed you can
   * cover 32 bit slices OR make a larger gosh darn macro.   
   * 
   * MASK sets which bits are valid in value.  The coverpoints for non-valid bits are still created
   * with 0 weight and never covered.
   */
  `define EVM_WILDCARD_32_BIT_VECTOR_SET_CLR_BINS( VALUE, MASK ) \
    coverpoint VALUE[0] iff(MASK[0]) { option.weight = MASK[0]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[1] iff(MASK[1]) { option.weight = MASK[1]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[2] iff(MASK[2]) { option.weight = MASK[2]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[3] iff(MASK[3]) { option.weight = MASK[3]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[4] iff(MASK[4]) { option.weight = MASK[4]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[5] iff(MASK[5]) { option.weight = MASK[5]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[6] iff(MASK[6]) { option.weight = MASK[6]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[7] iff(MASK[7]) { option.weight = MASK[7]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[8] iff(MASK[8]) { option.weight = MASK[8]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[9] iff(MASK[9]) { option.weight = MASK[9]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[10] iff(MASK[10]) { option.weight = MASK[10]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[11] iff(MASK[11]) { option.weight = MASK[11]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[12] iff(MASK[12]) { option.weight = MASK[12]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[13] iff(MASK[13]) { option.weight = MASK[13]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[14] iff(MASK[14]) { option.weight = MASK[14]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[15] iff(MASK[15]) { option.weight = MASK[15]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[16] iff(MASK[16]) { option.weight = MASK[16]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[17] iff(MASK[17]) { option.weight = MASK[17]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[18] iff(MASK[18]) { option.weight = MASK[18]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[19] iff(MASK[19]) { option.weight = MASK[19]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[20] iff(MASK[20]) { option.weight = MASK[20]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[21] iff(MASK[21]) { option.weight = MASK[21]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[22] iff(MASK[22]) { option.weight = MASK[22]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[23] iff(MASK[23]) { option.weight = MASK[23]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[24] iff(MASK[24]) { option.weight = MASK[24]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[25] iff(MASK[25]) { option.weight = MASK[25]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[26] iff(MASK[26]) { option.weight = MASK[26]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[27] iff(MASK[27]) { option.weight = MASK[27]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[28] iff(MASK[28]) { option.weight = MASK[28]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[29] iff(MASK[29]) { option.weight = MASK[29]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[30] iff(MASK[30]) { option.weight = MASK[30]; bins clr_b = {0}; bins set_b = {1}; } \
    coverpoint VALUE[31] iff(MASK[31]) { option.weight = MASK[31]; bins clr_b = {0}; bins set_b = {1}; } 
        
  // Reporting
  `include "single_line_printer.sv"
  `include "evm_report_delegation.svh"

  // RAL Field Utils
  `include "ral_field_edge_event.sv"

  // RAL Field Coverage
  `include "ral_field_coverage_policies.sv"
  `include "ral_field_read_cov_collector.sv"

  // RAL Memory Utils   
  `include "ral_mem_bkdr_wrapper.sv"
  `include "ral_mem_mirror_base.sv"
  `include "ral_mem_mirror.sv"

  // RAL Register Virtual Environment
  `include "ral_venv_object.sv"
  `include "ral_venv_adapter.sv"
  `include "ral_venv_agent.sv"
  `include "ral_venv.sv"

  // Compare
  `include "series_comparer.sv"
  `include "in_order_lossless_comparer.sv"
  `include "out_of_order_lossless_comparer.sv"
  `include "series_comparer_analysis_imp_if.sv"


endpackage: evm_utils_pkg
`endif