/*
sc_fifo sc_fifo_inst
(
	.clk(),
	.reset_n(),
		
	.wr(),
	.rd(),
	.data_in(),
		
	.data_out(),
	.full(),
	.empty(),
		
	.almost_full(),
	.almost_empty()
	
);

defparam 	sc_fifo_inst.data_width = 32,
			sc_fifo_inst.fifo_depth = 10,
			sc_fifo_inst.fifo_almost_full = 2130,
			sc_fifo_inst.fifo_almost_empty = 12;
*/
module sc_fifo
#
(
	parameter data_width = 256,
	parameter fifo_depth = 12,
	parameter fifo_almost_full_val = 900,
	parameter fifo_almost_empty_val = 12
)
(
	input logic clk,
	input logic reset_n,
	
	input logic wr,
	input logic rd,
	input [data_width-1:0] data_in,
	
	output logic [data_width-1:0] data_out,
	output logic full,
	output logic empty,
	
	output logic almost_full,
	output logic almost_empty
	
);

localparam size_register = $clog2(data_width);

reg [data_width-1:0] ram [2**fifo_depth-1:0];
reg [fifo_depth-1:0] wr_ptr, rd_ptr;
logic [fifo_depth-1:0] cnt_word;





//current point--------------------------------------------------------------
always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n)	wr_ptr <= {fifo_depth{1'b0}};
	else 	if(wr && ~full)	wr_ptr <= wr_ptr + 1'b1;

	
always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n)	rd_ptr <= {fifo_depth{1'b0}};
	else 	if(rd && ~empty)	rd_ptr <= rd_ptr + 1'b1;

always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n)	cnt_word <= {fifo_depth{1'b0}};
	else 	case({rd && ~empty, wr && ~full})
				2'b01:	cnt_word <= cnt_word + 1'b1;
				2'b10: 	cnt_word <= cnt_word - 1'b1;
				default: cnt_word <= cnt_word;
			endcase 

//RAM R/W--------------------------------------------------------------
always_ff @ (posedge clk)
	if(wr && ~full)	ram[wr_ptr] <= data_in;

always_ff @ (posedge clk)
	if(rd && ~empty)	data_out <= ram[rd_ptr];	

//----------------------------------------------------------------------------
//status signal
always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n)	full <= 1'b0;
	else 	if(full)	full <= &cnt_word & rd ? 1'b0 : 1'b1;
			else 		full <= &cnt_word[fifo_depth-1:1] & ~cnt_word[0] & wr & ~rd;

always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n)	empty <= 1'b1;
	else 	if(empty)	empty <= wr ? 1'b0 : 1'b1;
			else 		empty <= ~(|cnt_word[fifo_depth-1:1]) & cnt_word[0] & rd & ~wr;


always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n)	almost_full <= 1'b0;
	else 	if(almost_full)	almost_full <= (cnt_word == fifo_almost_full_val) & rd & ~wr ? 1'b0 : 1'b1;
	else 			almost_full <= (cnt_word == fifo_almost_full_val-1'b1) & wr & ~rd;

always_ff @ (posedge clk or negedge reset_n)
	if(!reset_n)	almost_empty <= 1'b1;
	else 	if(almost_empty)	almost_empty <= (cnt_word == fifo_almost_empty_val) & wr & ~rd ? 1'b0 : 1'b1;
	else 				almost_empty <= (cnt_word == fifo_almost_empty_val + 1'b1) & rd & ~wr;
	

endmodule 
