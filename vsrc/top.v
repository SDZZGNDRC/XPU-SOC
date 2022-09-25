/* (* DONT_TOUCH= "true" *) */
module top(
	input clk,
	input rst, 

    output wire Tx_o, 
    output wire[7:0] data_o
);
    wire uart_busy;
    wire[7:0] send_data_next;
    wire[7:0] send_data;
    Reg #(8, 8'd0) reg_send_data (clk, rst, send_data_next, send_data, ~uart_busy);
    assign send_data_next = (send_data==8'd255) ? 8'd0 : send_data+8'd1;

    UartT uart0(
        .clk(clk),
        .rst(rst),

        .data_i(send_data),
        .en_i(~uart_busy),

        .busy_o(uart_busy),
        .Tx_o(Tx_o)
    );
    wire bps_en_rx;
    wire bps_clk_rx;
    UartR1 uart1(
        .clk(clk),
        .rst(rst),
        .bps_en(bps_en_rx),
        .bps_clk(bps_clk_rx),
        .rs232_rx(Tx_o),
        .rx_data(data_o)
    );

    Baud #(.BPS_PARA(5208)) baud0(
        .clk_in(clk),
        .rst_n_in(~rst), 
        .bps_en(bps_en_rx), 
        .bps_clk(bps_clk_rx)
    );

/* The following code only for simulating */
	initial begin
		$dumpfile("logs/vlt_dump.vcd");
		$dumpvars();
	end
endmodule
