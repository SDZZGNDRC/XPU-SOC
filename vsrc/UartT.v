module UartT (
    input wire                      clk,
    input wire                      rst,

    input wire[7:0]                 data_i,
    input wire                      en_i,

    output wire                     busy_o,
    output wire                     Tx_o
);

/*     parameter   CLK_FREQ 	 = 50000000;				
    parameter   BAUD_RATE 	 = 9600; */
    parameter   BAUD_CNT_MAX = 16'd5208 + 16'd1;

/* data */
    wire[7:0] data;
    wire reg_data_wen;
    Reg #(8, 8'd0) reg_data (clk, rst, data_i, data, reg_data_wen);
    assign reg_data_wen = (pre_state==4'b0) ? 1'b1 : 1'b0;

/* reg_baud_counter */
    wire[15:0] baud_counter_next;
    wire[15:0] baud_counter_next_t_Trans;
    wire[15:0] baud_counter_next_t_Default;
    wire[15:0] baud_counter;
    Reg #(16, 16'd0) reg_baud_counter (clk, rst, baud_counter_next, baud_counter, 1'b1);
    MuxKeyWithDefault #(1, 4, 16) mux_baud_counter_next (baud_counter_next, pre_state, baud_counter_next_t_Trans, {
        4'd0,                       baud_counter_next_t_Default
    });
    assign baud_counter_next_t_Default = (en_i==1'b1) ? 16'd1 : 16'd0;
    assign baud_counter_next_t_Trans = (baud_counter >= BAUD_CNT_MAX) ? 16'd0 : baud_counter + 16'b1;

/* event_send_flag */
    wire event_send_flag;
    assign event_send_flag = (baud_counter==BAUD_CNT_MAX) ? 1'b1 : 1'b0;


/* pre_state */
    wire[3:0] next_state;
    wire[3:0] pre_state;
    Reg #(4, 4'd0) reg_pre_state (clk, rst, next_state, pre_state, 1'b1);

/* next_state */
    wire[3:0] next_state_t_Default;
    wire[3:0] next_state_t_Tran;
    wire[3:0] next_state_t_End;
    MuxKeyWithDefault #(2, 4, 4) mux_next_state (next_state, pre_state, next_state_t_Tran, {
        4'd0,                       next_state_t_Default,
        4'd10,                      next_state_t_End
    });

/* next_state_t_Default */
    assign next_state_t_Default = (en_i==1'b1) ? 4'd1 : 4'd0;

/* next_state_t_Tran */
    assign next_state_t_Tran = (event_send_flag==1'b1) ? pre_state+4'd1 : pre_state;

/* next_state_t_End */
    assign next_state_t_End = (event_send_flag==1'b1) ? (en_i==1'b1) ? 4'd1 : 4'd0 : pre_state;

/* busy_o */
    assign busy_o = (pre_state==4'd0) ? 1'd0 : 1'd1;

/* Tx_o */
    MuxKeyWithDefault #(11, 4, 1) mux_Tx (Tx_o, pre_state, 1'b1, {
        4'd0,                       1'b1,
        4'd1,                       1'b0,
        4'd2,                       data[0],
        4'd3,                       data[1],
        4'd4,                       data[2],
        4'd5,                       data[3],
        4'd6,                       data[4],
        4'd7,                       data[5],
        4'd8,                       data[6],
        4'd9,                       data[7],
        4'd10,                      1'b1
    });


endmodule
