`default_nettype none
/*
 *
 */

module user_proj_aes #(
	parameter BITS = 32
)(
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output reg wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oen,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb
);
    // Addresses
    // localparam BASE_ADDR = 32'h3000_0000;
    localparam CTRL_ADDR = 4'h0;

    localparam ENC_KEY_1 = 4'h1;
    localparam ENC_KEY_2 = 4'h2;
    localparam ENC_KEY_3 = 4'h3;
    localparam ENC_KEY_4 = 4'h4;

    localparam ENC_TXT_1 = 4'h5;
    localparam ENC_TXT_2 = 4'h6;
    localparam ENC_TXT_3 = 4'h7;
    localparam ENC_TXT_4 = 4'h8;

    // Base signals
    wire clk;
    wire rst;
    wire valid = wbs_stb_i && wbs_cyc_i;
    wire done = 1;
    reg [31:0] rdata;

    assign clk = wb_clk_i;
    assign rst = wb_rst_i;
    assign wbs_dat_o = rdata;
    assign la_data_out = 128'h00000000000000000000000000000000;
    assign io_out = 128'h00000000000000000000000000000000;
    assign io_oeb = 128'h00000000000000000000000000000000;

    // Selectors

    reg ctrl_sel;
    reg e_key_1_sel;
    reg e_key_2_sel;
    reg e_key_3_sel;
    reg e_key_4_sel;
    reg e_txt_1_sel;
    reg e_txt_2_sel;
    reg e_txt_3_sel;
    reg e_txt_4_sel;

    always @* begin

        ctrl_sel = 0;
        e_key_1_sel = 0;
        e_key_2_sel = 0;
        e_key_3_sel = 0;
        e_key_4_sel = 0;
        e_txt_1_sel = 0;
        e_txt_2_sel = 0;
        e_txt_3_sel = 0;
        e_txt_4_sel = 0;

        if (valid) begin
            case (wbs_adr_i[5:2])
                4'h0: ctrl_sel = 1'b1;
                4'h1: e_key_1_sel = 1'b1;
                4'h2: e_key_2_sel = 1'b1;
                4'h3: e_key_3_sel = 1'b1;
                4'h4: e_key_4_sel = 1'b1;
                4'h5: e_txt_1_sel = 1'b1;
                4'h6: e_txt_2_sel = 1'b1;
                4'h7: e_txt_3_sel = 1'b1;
                4'h8: e_txt_4_sel = 1'b1;
            endcase
        end
    end

    // AES128 Control
    /*Layout of aes_ctrl:
     * Bit 0: e_rst
     * Bit 1: e_ld
     * Bit 2: e_done
     */

    // AES128 Encryption core
    reg e_rst;
    reg e_ld;
    reg e_ld_i;
    wire e_done;

    reg [127:0] e_key;
    reg [127:0] e_text;
    reg [127:0] e_key_i;
    reg [127:0] e_text_i;
    wire [127:0] e_text_o;
    reg [127:0] e_text_o_p;

    aes_cipher_top aes_cipher_top(
        .clk( clk ),
        .rst( e_rst ),
        .ld( e_ld_i ),
        .done( e_done ),
        .key( e_key ),
        .text_in( e_text_i ),
        .text_out( e_text_o )
    );

    always @(posedge clk) begin
        e_ld_i <= e_ld;
        if (e_ld) begin
            e_text_i <= e_text;
            e_key_i <= e_key;
        end

        if (e_done == 1) e_text_o_p <= e_text_o;
        if (e_rst == 0) e_text_o_p <= 128'h00000000000000000000000000000000;
    end

    always @(posedge clk) begin
        // Unset wbs_ack_o
        wbs_ack_o <= 1'b0;

        // Input/Output for 128 bit wide data
        // Encryption Key
        if (e_key_1_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_key[31:0] <= wbs_dat_i[31:0];
            else rdata <= e_key[31:0];
            wbs_ack_o <= 1'b1;
        end
        if (e_key_2_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_key[63:32] <= wbs_dat_i[31:0];
            else rdata <= e_key[63:32];
            wbs_ack_o <= 1'b1;
        end
        if (e_key_3_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_key[95:64] <= wbs_dat_i[31:0];
            else rdata <= e_key[95:64];
            wbs_ack_o <= 1'b1;
        end
        if (e_key_4_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_key[127:96] <= wbs_dat_i[31:0];
            else rdata <= e_key[127:96];
            wbs_ack_o <= 1'b1;
        end

        // Encryption text
        if (e_txt_1_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_text[31:0] <= wbs_dat_i[31:0];
            else rdata <= e_text_o_p[31:0];
            wbs_ack_o <= 1'b1;
        end
        if (e_txt_2_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_text[63:32] <= wbs_dat_i[31:0];
            else rdata <= e_text_o_p[63:32];
            wbs_ack_o <= 1'b1;
        end
        if (e_txt_3_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_text[95:64] <= wbs_dat_i[31:0];
            else rdata <= e_text_o_p[95:64];
            wbs_ack_o <= 1'b1;
        end
        if (e_txt_4_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) e_text[127:96] <= wbs_dat_i[31:0];
            else rdata <= e_text_o_p[127:96];
            wbs_ack_o <= 1'b1;
        end

        // CTRL-Register data
        if (ctrl_sel == 1 && wbs_ack_o == 0) begin
            if (wbs_we_i == 1) begin
                e_rst <= wbs_dat_i[0];
                e_ld <= wbs_dat_i[1];
            end
            else begin
                rdata <= {{29{1'b0}}, e_done, e_ld, e_rst};
            end
            wbs_ack_o <= 1'b1;
        end

    end

endmodule
