module UartR (
    input clk,
    input rst,
    
    input Rx_i,
    output reg [7:0] dout_o,
    output reg error_o
);

localparam bps600   = 17'd8_3333;
localparam bps1200  = 17'd4_1667;
localparam bps2400  = 17'd2_0833;
localparam bps4800  = 17'd1_0417;
localparam bps9600  = 17'd5208;
localparam bps19200 = 17'd2604;
localparam bps38400 = 17'd1302;
//波特率计数器
reg [16:0] bps_mode;
reg [16:0] bps_cnt; //最慢的bps600模式需要17位计数器

reg [14:0] start_cnt;//最大的bps_mode/4
reg [14:0] real_data_cnt;//最大的bps_mode/4
reg real_data;

reg n_cnt_flag;
reg [3:0] n_cnt;

reg [3:0] bps_sel;
reg check_sel;

reg [7:0] dout_o_reg;

reg Rx_i_d1,Rx_i_d2,Rx_i_d3; //d1,d2为消除亚稳态，d3为下降沿检测
wire dec_Rx_i;//下降沿检测
wire start;

wire e_check;
wire o_check;
wire check;

reg [2:0] state;

localparam idle       = 3'b001;
localparam start_search = 3'b010;
localparam transmit    = 3'b100;


//配置寄存器
initial begin
  bps_sel = 'd4;
  check_sel = 1'b0;
end
	 
//波特率选择
always@(*)begin
  case(bps_sel)
    0: bps_mode = bps600;   
    1: bps_mode = bps1200;  
    2: bps_mode = bps2400; 
    3: bps_mode = bps4800;  
    4: bps_mode = bps9600;  
    5: bps_mode = bps19200; 
    6: bps_mode = bps38400; 
    default : bps_mode = bps600; 
  endcase
end  

always@(posedge clk)
  if(rst)
    bps_cnt <= 'd0;
  else if(bps_cnt == bps_mode-1) 
    bps_cnt <= 'd0;
  else if(state == start_search || state == transmit)	//与发送端波特率同步
    bps_cnt <= bps_cnt + 1'b1;
  else
    bps_cnt <= 'd0;  

//开始信号检测	
always@(posedge clk) 
  if(rst)
    state <= idle;
  else begin
    case(state)      
	 idle : begin
      if(dec_Rx_i) 
     	  state <= start_search;
      else
        state <= idle; end

    start_search : begin
      if(start) 
     	  state <= transmit;
      else if(~start && bps_cnt == {1'b0, bps_mode[16:1]})//去掉最低位表示bps_mode/2
          state <= idle;		
      else 
	  state <= start_search; end

	 transmit : begin
      if(n_cnt == 'd10 && Rx_i_d2 == 1'b1 && bps_cnt == bps_mode-1) 
     	  state <= idle;
      else
        state <= transmit;end
	 default : state <= idle;
    endcase
  end	
 
always@(posedge clk) 
  if(rst)begin
    Rx_i_d1 <= 1'b0;
	 Rx_i_d2 <= 1'b0;
	 Rx_i_d3 <= 1'b0;end
  else begin
    Rx_i_d1 <= Rx_i;  
    Rx_i_d2 <= Rx_i_d1;
    Rx_i_d3 <= Rx_i_d2;end
	
assign dec_Rx_i = Rx_i_d3 && ~Rx_i_d2;//下降沿检测

assign start = (state == start_search)&&(start_cnt == bps_mode[16:2]);//去掉低两位表示bps_mode/4

always@(posedge clk)
  if(rst)
    start_cnt <= 'd0;
  else if(state == start_search)
    start_cnt <= start_cnt + {14'd0, {1{!Rx_i_d2}}};
  else 
    start_cnt <= 'd0;  
	

always@(posedge clk)
  if(rst)
    real_data_cnt <= 'd0;
  else if(bps_cnt == bps_mode-1)
    real_data_cnt <= 'd0;
  else if(state == transmit)
    real_data_cnt <= real_data_cnt + {14'd0, {1{Rx_i_d2}}}; 
  else 	
    real_data_cnt <= 'd0;

always@(posedge clk)
  if(rst)
    real_data <= 'd0;
  else if(~n_cnt_flag)
    real_data <= 'd0;  
  else if(bps_cnt == {1'b0, bps_mode[16:1]})begin
    if(real_data_cnt > bps_mode[16:2])
      real_data <= 1'b1;
    else
      real_data <= 1'b0;end	 
 

//线性序列机
always@(posedge clk)
  if(rst)
    n_cnt_flag <= 1'b0;
  else if(n_cnt == 'd11)
    n_cnt_flag <= 1'b0; 
  else if(state != idle)
    n_cnt_flag <= 1'b1;  

always@(posedge clk)	
  if(rst)
    n_cnt <= 'd0;
  else if(n_cnt_flag) begin
    if(bps_cnt == bps_mode-1)
      n_cnt <= n_cnt + 1'b1;
	 else
	   n_cnt <= n_cnt; end 
  else
    n_cnt <= 'd0;


always@(posedge clk)
  if(rst)
    dout_o_reg <= 'd0;
  else if(~n_cnt_flag)	
    dout_o_reg <= 'd0;
  else if(bps_cnt == bps_mode[16:1] + 1)begin
    case(n_cnt)
      1:dout_o_reg[0] <= real_data;
      2:dout_o_reg[1] <= real_data;
      3:dout_o_reg[2] <= real_data;
      4:dout_o_reg[3] <= real_data;
      5:dout_o_reg[4] <= real_data;
      6:dout_o_reg[5] <= real_data;
      7:dout_o_reg[6] <= real_data;	  
      8:dout_o_reg[7] <= real_data;
    default  dout_o_reg <= dout_o_reg; 
    endcase
  end	 
   
always@(posedge clk)
  if(rst)
    dout_o <= 'd0;            
  else if(n_cnt == 'd10 && bps_cnt == bps_mode-1)
    dout_o <= dout_o_reg; 

always@(posedge clk)
  if(rst)
    error_o <= 1'b0;  
  else if(~n_cnt_flag)
    error_o <= 1'b0;  
  else if(n_cnt == 'd9 && bps_cnt == bps_mode[16:1] + 1)begin
    if(check != real_data)
      error_o <= 1'b1; end
     	
//奇偶校验
assign e_check = ^dout_o_reg; //偶校验
assign o_check = ~e_check; //奇校验

assign check =(check_sel)? o_check : e_check;//奇偶校验选择

endmodule
