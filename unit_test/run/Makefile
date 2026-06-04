# Makefile for running unit-tests on UVM 2017 and 2020 releases with verilator.
# - compiles to build/cmp_u<uvm_release>
# - simulates to build/sim_u<uvm_release>_s<seed>.
# make help for usage.

.PHONY: all cmp sim clean clean_cmp clean_sim help regr

# Typical user options
UVM_VER   ?= 2020
SEED      ?= 1
QUIET     ?= no

EVM_HOME  := $(abspath ${CURDIR}/../..)

ifeq (${UVM_VER},2020)
	UVM_HOME ?= ${EVM_HOME}/unit_test/deps/uvm/1800.2-2020-3.1
	UVM_DPI_CC ?= ${EVM_HOME}/unit_test/deps/verilator/test_regress/t/uvm/v2020_3_1/dpi/uvm_dpi.cc
else ifeq (${UVM_VER},2017)
  	UVM_HOME ?= ${EVM_HOME}/unit_test/deps/uvm/1800.2-2017-1.0
	UVM_DPI_CC ?= ${EVM_HOME}/unit_test/deps/verilator/test_regress/t/uvm/v2017_1_0/dpi/uvm_dpi.cc
else ifeq ($(and ${UVM_HOME},${UVM_DPI_CC}),)
  $(error "Unsupported UVM_VER (${UVM_VER}) requires both UVM_HOME (${UVM_HOME}) and UVM_DPI_CC (${UVM_DPI_CC}) to be set.")
endif

CL_HOME   ?= ${EVM_HOME}/unit_test/deps/cluelib


CMP_DIR ?= ${CURDIR}/build/cmp_u${UVM_VER}
SIM_DIR ?= ${CURDIR}/build/sim_u${UVM_VER}_s${SEED}
CMP_LOG ?= ${CMP_DIR}/cmp.log
SIM_LOG ?= ${SIM_DIR}/sim.log

all: cmp sim

cmp:
	@echo "Compiling ${CMP_DIR}"
	@rm -rf ${CMP_DIR} && mkdir -p ${CMP_DIR}/build
	@cmd="verilator -Wno-fatal -Wno-WIDTHEXPAND --Wno-WIDTHTRUNC --Wno-COVERIGN -Wno-CASTCONST -Wno-ZERODLY \
	--binary --exe --vpi --timescale 1ns/1ns -j 4 -Mdir ${CMP_DIR}/build  ${CMP_OPTS} \
	+define+UVM_REG_ADDR_WIDTH=32 +define+UVM_REG_DATA_WIDTH=32 +incdir+${UVM_HOME}/src ${UVM_HOME}/src/uvm.sv ${UVM_DPI_CC} \
	+incdir+${CL_HOME}/src ${CL_HOME}/src/cl_pkg.sv ${CL_HOME}/src/cl_dpi.cc \
	+incdir+${EVM_HOME}/src ${EVM_HOME}/evm_utils_pkg.sv \
	+incdir+${EVM_HOME}/unit_test/src ${EVM_HOME}/unit_test/src/ut_wallclock_ns.cc ${EVM_HOME}/unit_test/src/ut_pkg.sv \
	-o ${CMP_DIR}/sim_verilator --top-module ut_testbench"; \
	echo "$$cmd" > ${CMP_LOG}; \
	if [ "${QUIET}" = "yes" ]; then \
	  eval "$$cmd >> ${CMP_LOG} 2>&1"; \
	else \
	  echo "$$cmd"; \
	  eval "$$cmd 2>&1 | tee -a ${CMP_LOG}"; \
	fi; \
	ret=$$?; \
	exit $$ret

sim: 
	@echo "Simulating ${SIM_DIR}"
	@rm -rf ${SIM_DIR} && mkdir -p ${SIM_DIR}
	@cmd="${CMP_DIR}/sim_verilator +UVM_TESTNAME=ut_testcase +verilator+seed+${SEED} +EVM_RAL_LOG_NAME=${SIM_DIR}/uvm_reg.log ${SIM_OPTS}"; \
	echo "$$cmd" > ${SIM_LOG} 2>&1; \
	if [ "${QUIET}" = "yes" ]; then \
	  eval "$$cmd > ${SIM_LOG} 2>&1"; \
	else \
	  echo "$$cmd"; \
	  eval "$$cmd 2>&1 | tee ${SIM_LOG}"; \
	fi; \
	ret=$$?; \
	exit $$ret


REGR_UVM_LIST ?= 2017 2020

regr: clean
	@echo "Running full regression for UVM versions: $(REGR_UVM_LIST)"
	@for version in $(REGR_UVM_LIST); do \
	  $(MAKE) --no-print-directory -f $(CURDIR)/Makefile UVM_VER=$$version QUIET=yes all || exit 1; \
	  log=$(CURDIR)/build/sim_u$${version}_s$(SEED)/sim.log; \
	  if [ ! -f "$$log" ]; then echo "FULL REGRESSION: FAIL (missing sim log $$log)"; exit 1; fi; \
	  if grep -q "Test FAILED" "$$log"; then echo "FULL REGRESSION: FAIL (Test FAILED found in $$log)"; exit 1; fi; \
	  if ! grep -q "Test PASSED" "$$log"; then echo "FULL REGRESSION: UNKNOWN (no Test PASSED found in $$log)"; exit 1; fi; \
	done; \
	echo "FULL REGRESSION: PASS"; 

clean:
	@echo "Cleaning cmp and sim"
	rm -rf build 

clean_cmp: 
	@echo "Cleaning cmp"
	rm -rf build/cmp*

clean_sim: 
	@echo "Cleaning sim"
	rm -rf build/sim*

help:
	@echo "Usage: make [target(s)] [options]"
	@echo "Targets:"
	@echo "  all   - cmp and sim (default)"
	@echo "  cmp   - Compile the unit test to build/cmp_u{UVM_VER} dir"
	@echo "  sim   - Run the compiled unit in build/sim_u{UVM_VER}_s{SEED} dir"
	@echo "  clean - Remove build directory (cmp and sim)"
	@echo "    clean_cmp - Remove build/cmp*"
	@echo "    clean_sim - Remove build/sim*"
	@echo "  regr  - clean then cmp and sim for UVM_VER 2020 and 2017"
	@echo "Options:"
	@echo "  CMP_OPTS - Additional options for cmp"
	@echo "  SIM_OPTS - Additional options for sim"
	@echo "  SEED     - Random seed for sim (default: 1)"	
	@echo "  UVM_VER  - 2020 (default), 2017, or other for cmp and sim. Other requires UVM_HOME and UVM_DPI_CC to be set."

echo:
	@echo "EVM_UTILS_HOME: ${EVM_HOME}"
	@echo "UVM_VER: ${UVM_VER}"
	@echo "UVM_HOME: ${UVM_HOME}"
	@echo "UVM_DPI_CC: ${UVM_DPI_CC}"
	@echo "CL_HOME: ${CL_HOME}"