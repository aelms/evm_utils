`ifndef UT_PKG__SV
`define UT_PKG__SV

`ifndef MEM_RAL_BIT_WIDTH
  `define MEM_RAL_BIT_WIDTH 32
`endif

`ifndef MEM_PREDICT_BIT_WIDTH
  `define MEM_PREDICT_BIT_WIDTH 8
`endif

`ifndef MEM_SIZE
  `define MEM_SIZE 1024
`endif

package ut_pkg;

  import "DPI-C" function longint ut_wallclock_ns ();

  import uvm_pkg::*;
  import evm_utils_pkg::*;

  `include "ut_design_mem.sv"
  `include "ut_reg.sv"
  `include "ut_block.sv"
  `include "ut_field_edge_event.sv"

  `include "ut_sequence_item.sv"
  `include "ut_sequence.sv"
  
  `include "ut_driver.sv"
  `include "ut_agent.sv"
  `include "ut_comparer.sv"
  `include "ut_design_queue.sv"

  `include "ut_env.sv"
  `include "ut_testcase.sv"
  
endpackage : ut_pkg

`include "ut_testbench.sv"
`endif