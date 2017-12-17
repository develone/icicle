`ifndef RV32
`define RV32

`include "rv32_decode.sv"
`include "rv32_execute.sv"
`include "rv32_fetch.sv"
`include "rv32_hazard.sv"
`include "rv32_mem.sv"

module rv32 (
    input clk,

    /* data memory bus */
    output logic [31:0] data_address_out,
    output logic data_read_out,
    output logic data_write_out,
    input [31:0] data_read_value_in,
    output logic [3:0] data_write_mask_out,
    output logic [31:0] data_write_value_out
);
    /* hazard -> fetch control */
    logic fetch_stall;
    logic fetch_flush;

    /* hazard -> decode control */
    logic decode_stall;
    logic decode_flush;

    /* hazard -> execute control */
    logic execute_stall;
    logic execute_flush;

    /* hazard -> mem control */
    logic mem_stall;
    logic mem_flush;

    /* fetch -> decode data */
    logic [31:0] fetch_pc;
    logic [31:0] fetch_instr;

    /* decode -> hazard control */
    logic [4:0] decode_rs1_unreg;
    logic [4:0] decode_rs2_unreg;

    /* decode -> execute control */
    logic [4:0] decode_rs1;
    logic [4:0] decode_rs2;
    logic [2:0] decode_alu_op;
    logic decode_alu_sub_sra;
    logic [1:0] decode_alu_src1;
    logic [1:0] decode_alu_src2;
    logic decode_mem_read;
    logic decode_mem_write;
    logic [1:0] decode_mem_width;
    logic decode_mem_zero_extend;
    logic [1:0] decode_branch_op;
    logic decode_branch_pc_src;
    logic [4:0] decode_rd;
    logic decode_rd_write;

    /* decode -> execute data */
    logic [31:0] decode_pc;
    logic [31:0] decode_rs1_value;
    logic [31:0] decode_rs2_value;
    logic [31:0] decode_imm;

    /* execute -> mem control */
    logic execute_mem_read;
    logic execute_mem_write;
    logic [1:0] execute_mem_width;
    logic execute_mem_zero_extend;
    logic [1:0] execute_branch_op;
    logic [4:0] execute_rd;
    logic execute_rd_write;

    /* execute -> mem data */
    logic [31:0] execute_result;
    logic [31:0] execute_rs2_value;
    logic [31:0] execute_branch_pc;

    /* mem -> writeback control */
    logic [4:0] mem_rd;
    logic mem_rd_write;

    /* mem -> fetch control */
    logic mem_branch_taken;

    /* mem -> writeback data */
    logic [31:0] mem_rd_value;

    /* mem -> fetch data */
    logic [31:0] mem_branch_pc;

    rv32_hazard_unit hazard_unit (
        /* control in */
        .decode_rs1_in(decode_rs1_unreg),
        .decode_rs2_in(decode_rs2_unreg),

        .decode_mem_read_in(decode_mem_read),
        .decode_rd_in(decode_rd),
        .decode_rd_write_in(decode_rd_write),

        .mem_branch_taken_in(mem_branch_taken),

        /* control out */
        .fetch_stall_out(fetch_stall),
        .fetch_flush_out(fetch_flush),

        .decode_stall_out(decode_stall),
        .decode_flush_out(decode_flush),

        .execute_stall_out(execute_stall),
        .execute_flush_out(execute_flush),

        .mem_stall_out(mem_stall),
        .mem_flush_out(mem_flush)
    );

    rv32_fetch fetch (
        .clk(clk),

        /* control in (from hazard) */
        .stall_in(fetch_stall),
        .flush_in(fetch_flush),

        /* control in (from mem) */
        .branch_taken_in(mem_branch_taken),

        /* data in (from mem) */
        .branch_pc_in(mem_branch_pc),

        /* data out */
        .pc_out(fetch_pc),
        .instr_out(fetch_instr)
    );

    rv32_decode decode (
        .clk(clk),

        /* control in (from hazard) */
        .stall_in(decode_stall),
        .flush_in(decode_flush),

        /* control in (from writeback) */
        .rd_in(mem_rd),
        .rd_write_in(mem_rd_write),

        /* data in */
        .pc_in(fetch_pc),
        .instr_in(fetch_instr),

        /* data in (from writeback) */
        .rd_value_in(mem_rd_value),

        /* control out (to hazard) */
        .rs1_unreg_out(decode_rs1_unreg),
        .rs2_unreg_out(decode_rs2_unreg),

        /* control out */
        .rs1_out(decode_rs1),
        .rs2_out(decode_rs2),
        .alu_op_out(decode_alu_op),
        .alu_sub_sra_out(decode_alu_sub_sra),
        .alu_src1_out(decode_alu_src1),
        .alu_src2_out(decode_alu_src2),
        .mem_read_out(decode_mem_read),
        .mem_write_out(decode_mem_write),
        .mem_width_out(decode_mem_width),
        .mem_zero_extend_out(decode_mem_zero_extend),
        .branch_op_out(decode_branch_op),
        .branch_pc_src_out(decode_branch_pc_src),
        .rd_out(decode_rd),
        .rd_write_out(decode_rd_write),

        /* data out */
        .pc_out(decode_pc),
        .rs1_value_out(decode_rs1_value),
        .rs2_value_out(decode_rs2_value),
        .imm_out(decode_imm)
    );

    rv32_execute execute (
        .clk(clk),

        /* control in (from hazard) */
        .stall_in(execute_stall),
        .flush_in(execute_flush),

        /* control in */
        .rs1_in(decode_rs1),
        .rs2_in(decode_rs2),
        .alu_op_in(decode_alu_op),
        .alu_sub_sra_in(decode_alu_sub_sra),
        .alu_src1_in(decode_alu_src1),
        .alu_src2_in(decode_alu_src2),
        .mem_read_in(decode_mem_read),
        .mem_write_in(decode_mem_write),
        .mem_width_in(decode_mem_width),
        .mem_zero_extend_in(decode_mem_zero_extend),
        .branch_op_in(decode_branch_op),
        .branch_pc_src_in(decode_branch_pc_src),
        .rd_in(decode_rd),
        .rd_write_in(decode_rd_write),

        /* control in (from writeback) */
        .writeback_rd_in(mem_rd),
        .writeback_rd_write_in(mem_rd_write),

        /* data in */
        .pc_in(decode_pc),
        .rs1_value_in(decode_rs1_value),
        .rs2_value_in(decode_rs2_value),
        .imm_in(decode_imm),

        /* data in (from writeback) */
        .writeback_rd_value_in(mem_rd_value),

        /* control out */
        .mem_read_out(execute_mem_read),
        .mem_write_out(execute_mem_write),
        .mem_width_out(execute_mem_width),
        .mem_zero_extend_out(execute_mem_zero_extend),
        .branch_op_out(execute_branch_op),
        .rd_out(execute_rd),
        .rd_write_out(execute_rd_write),

        /* data out */
        .result_out(execute_result),
        .rs2_value_out(execute_rs2_value),
        .branch_pc_out(execute_branch_pc)
    );

    rv32_mem mem (
        .clk(clk),

        /* control in (from hazard) */
        .stall_in(mem_stall),
        .flush_in(mem_flush),

        /* control in */
        .read_in(execute_mem_read),
        .write_in(execute_mem_write),
        .width_in(execute_mem_width),
        .zero_extend_in(execute_mem_zero_extend),
        .branch_op_in(execute_branch_op),
        .rd_in(execute_rd),
        .rd_write_in(execute_rd_write),

        /* data in */
        .result_in(execute_result),
        .rs2_value_in(execute_rs2_value),
        .branch_pc_in(execute_branch_pc),

        /* data in (from memory bus) */
        .data_read_value_in(data_read_value_in),

        /* control out */
        .branch_taken_out(mem_branch_taken),
        .rd_out(mem_rd),
        .rd_write_out(mem_rd_write),

        /* control out (to memory bus) */
        .data_read_out(data_read_out),
        .data_write_out(data_write_out),
        .data_write_mask_out(data_write_mask_out),

        /* data out */
        .rd_value_out(mem_rd_value),
        .branch_pc_out(mem_branch_pc),

        /* data out (to memory bus) */
        .data_address_out(data_address_out),
        .data_write_value_out(data_write_value_out)
    );
endmodule

`endif
