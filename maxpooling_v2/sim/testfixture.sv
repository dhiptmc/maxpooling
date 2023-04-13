`timescale 1ns/10ps
`define CYCLE      20.0						// Modify your clock period here
//`define SDFFILE    "./syn/CONV_syn.sdf"	// Modify your sdf file name
`define End_CYCLE  100000000              	// Modify cycle times once your design need more cycle times!

`define INPUTVAL         "./input128.dat"        // Modify your "dat" directory path
`define OUTPUTVAL        "./output128.dat"       
//`define L1_EXP0        "./cnn_layer1_exp0.dat"     


module testfixture;

parameter inputsize = 128;
parameter countersize = 7;
parameter outputsize = inputsize/2;

reg	[7:0]	INPUTVAL [0:inputsize*inputsize-1];

reg	[7:0]	OUTPUTVAL [0:outputsize*outputsize-1];  
reg	[7:0]	ANSWER [0:outputsize*outputsize-1]; 


reg		reset = 0;
reg		clk   = 0;
reg		ready = 0;
wire 	busy;

wire		ren;
wire		wen;
//logic 	[15:0]	cdata_rd [7:0]; //version 2; read 16byte in 1 cycle
logic 	[15:0]	cdata_rd7;
logic 	[15:0]	cdata_rd6;
logic 	[15:0]	cdata_rd5;
logic 	[15:0]	cdata_rd4;
logic 	[15:0]	cdata_rd3;
logic 	[15:0]	cdata_rd2;
logic 	[15:0]	cdata_rd1;
logic 	[15:0]	cdata_rd0;



wire	[2*countersize-1:0]	caddr_rd;
wire	[7:0]	mdata_wr;
wire	[2*(countersize-1)-1:0]	maddr_wr;

integer		p0;
integer 	counter = 0;
integer		err00;

integer		pat_num;
reg			check0=0;

`ifdef SDF
	initial $sdf_annotate(`SDFFILE, u_maxpooling);
`endif

maxpooling u_maxpooling(
			.clk(clk),
			.rst(reset),
			.ready(ready),
			.busy(busy),

			.ren(ren),
			.wen(wen),

			.cdata_rd7(cdata_rd7),
			.cdata_rd6(cdata_rd6),
			.cdata_rd5(cdata_rd5),
			.cdata_rd4(cdata_rd4),
			.cdata_rd3(cdata_rd3),
			.cdata_rd2(cdata_rd2),
			.cdata_rd1(cdata_rd1),
			.cdata_rd0(cdata_rd0),
	
			.caddr_rd(caddr_rd),
			.mdata_wr(mdata_wr),
			.maddr_wr(maddr_wr)
			);
			


always begin #(`CYCLE/2) clk = ~clk; end

initial begin
	$fsdbDumpfile("maxpooling.fsdb");
	$fsdbDumpvars;
	$fsdbDumpMDA;
end

initial begin  // global control
	$display("-----------------------------------------------------\n");
 	$display("START!!! Simulation Start .....\n");
 	$display("-----------------------------------------------------\n");
	@(negedge clk); #1; reset = 1'b1;  ready = 1'b1;
   	#(`CYCLE*3);  #1;   reset = 1'b0;  
   	wait(busy == 1); #(`CYCLE/4); ready = 1'b0;
end

initial begin // initial pattern and expected result
	wait(reset==1);
	wait ((ready==1) && (busy ==0) ) begin
		$readmemh(`INPUTVAL, INPUTVAL);
		$readmemh(`OUTPUTVAL, OUTPUTVAL);
	end
		
end

always@(negedge clk) begin // generate the stimulus input data
	if(ren == 1)
	begin
		if ((ready == 0) & (busy == 1))
		begin
			cdata_rd0 <= {INPUTVAL[caddr_rd]			   		,INPUTVAL[caddr_rd+1]};
			cdata_rd1 <= {INPUTVAL[caddr_rd+inputsize]  		,INPUTVAL[caddr_rd+inputsize+1]};
			cdata_rd2 <= {INPUTVAL[caddr_rd+2*inputsize]		,INPUTVAL[caddr_rd+2*inputsize+1]};
			cdata_rd3 <= {INPUTVAL[caddr_rd+3*inputsize]		,INPUTVAL[caddr_rd+3*inputsize+1]};
			cdata_rd4 <= {INPUTVAL[caddr_rd+2]				,INPUTVAL[caddr_rd+3]};
			cdata_rd5 <= {INPUTVAL[caddr_rd+inputsize+2]  	,INPUTVAL[caddr_rd+inputsize+3]};
			cdata_rd6 <= {INPUTVAL[caddr_rd+2*inputsize+2]	,INPUTVAL[caddr_rd+2*inputsize+3]};
			cdata_rd7 <= {INPUTVAL[caddr_rd+3*inputsize+2]	,INPUTVAL[caddr_rd+3*inputsize+3]};
		end
		else 
		begin
			cdata_rd0 <= 'hx;
			cdata_rd1 <= 'hx;
			cdata_rd2 <= 'hx;
			cdata_rd3 <= 'hx;
			cdata_rd4 <= 'hx;
			cdata_rd5 <= 'hx;
			cdata_rd6 <= 'hx;
			cdata_rd7 <= 'hx;
		end
	end
	end

always@(posedge clk) begin 
	if(wen == 1)
	begin
		check0 <= 1;
		ANSWER[maddr_wr] <= mdata_wr;
	end
end


//-------------------------------------------------------------------------------------------------------------------
initial begin
check0<= 0;
wait(busy==1); wait(busy==0);
if (check0 == 1) begin 
	err00 = 0;
	for (p0=0; p0<=outputsize*outputsize-1; p0=p0+1) begin
		if (ANSWER[p0] == OUTPUTVAL[p0]) ;
		else begin
			err00 = err00 + 1;
			begin 
				$display("WRONG! Pixel %d is wrong!", p0);
				$display("               The output data is %h, but the expected data is %h ", ANSWER[p0], OUTPUTVAL[p0]);
			end
		end
	end
	if (err00 == 0) $display("maxpooling data is correct !");
	else		 $display("found %d error !", err00);
end
end

//-------------------------------------------------------------------------------------------------------------------
initial  begin
 #`End_CYCLE ;
 	$display("-----------------------------------------------------\n");
 	$display("Error!!! The simulation can't be terminated under normal operation!\n");
 	$display("-------------------------FAIL------------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
end

initial begin
      wait(busy == 1);
      wait(busy == 0);      
    $display(" ");
	$display("-----------------------------------------------------\n");
	$display("--------------------- S U M M A R Y -----------------\n");
	if( (check0==1)&(err00==0) ) $display("Congratulations! maxpooling data have been generated successfully! The result is PASS!!\n");
		else if (check0 == 0) $display("maxpooling output was fail! \n");
		else $display("FAIL!!!  There are %d errors!\n", err00);
	$display("-----------------------------------------------------\n");
      #(`CYCLE/2); $finish;
end



   
endmodule