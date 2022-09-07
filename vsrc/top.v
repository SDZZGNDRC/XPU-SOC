/* (* DONT_TOUCH= "true" *) */
module top(
	input clk,
	input rst, 

    output wire Tx_o
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

/* The following code only for simulating */
	initial begin
		$dumpfile("logs/vlt_dump.vcd");
		$dumpvars();
	end
endmodule
