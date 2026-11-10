# Makefile for Icarus Verilog + cocotb

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Correct relative path from python_tb/tb/I_cache_tb to src/01_Fetch/
VERILOG_SOURCES = l1_instr_cache_tb.sv ../../../src/01_Fetch/L1_instr_cache.sv

# Name of testbench file
TOPLEVEL = l1_instr_cache_tb

# Module name NOT FILE NAME
MODULE = l1_cache_tb

include $(shell cocotb-config --makefiles)/Makefile.sim