`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/17 10:49:43
// Design Name: 
// Module Name: tb_topModuleV2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// the storage of kernel is via row priority, and we get kernel via row priority!
// the storage of data is via row priority, but we get data via column priority!!
module tb_topModuleV2();
	// Configuration of the CONV-Project
	integer numOfKernels=32;
	integer numOfChannels=32;
	
	parameter lenOfInput=8;    //the number of input-data bits 
    parameter lenOfOutput=25;  //the number of output-data bits
	parameter numOfPerKnl=16;  //the number of kernel value
	parameter numOfPerFMap=4096;  //the number of kernel value
	
	// module variables
	//input
	reg clk=0;
	reg signed [lenOfInput-1:0] in_wdata0, in_wdata1,  in_wdata2,  in_wdata3,  in_wdata4,  in_wdata5,  in_wdata6,  in_wdata7;
	reg signed [lenOfInput-1:0] in_fdata0, in_fdata1,  in_fdata2,  in_fdata3,  in_fdata4,  in_fdata5,  in_fdata6,  in_fdata7;
	reg in_start_conv=0;	//start signal of the top module
	reg [2:0] in_cfg_ci;  //the number of channels,  		0 means 8, 1 means 16, 3 means 24, 3 means 32
    reg [2:0] in_cfg_co;      //the number of kernels,         0 means 8, 1 means 16, 3 means 24, 3 means 32
	//output
	wire signed [lenOfOutput-1:0] out_data0, out_data1;
	wire out_readw_ctl, out_readi_ctl;		// the signal to get fmap or weights
	wire out_write_ctl;
	wire out_end_conv;
	
	topModuleV2 top( in_start_conv, clk, 			// the signal for begining and clk
	in_cfg_ci, in_cfg_co, 			// the number of channels, and the number of kernels,
	in_wdata0, in_wdata1, in_wdata2, in_wdata3, in_wdata4, in_wdata5, in_wdata6, in_wdata7,  // weights data and feature map data
	in_fdata0, in_fdata1, in_fdata2, in_fdata3, in_fdata4, in_fdata5, in_fdata6, in_fdata7,  
	out_data0, out_data1,			// output data
	out_readw_ctl,out_readi_ctl,	// the signal to get fmap or weights
	out_write_ctl,					// the signal to write output
	out_end_conv		);

	// internal variables
	reg signed [lenOfInput-1:0] kernel[0:numOfPerKnl*32*32-1];  	//store the value of a kernel, 32 kernels with 32 channels
	reg signed [lenOfInput-1:0] fMap[0:numOfPerFMap*32-1];			//Only one fMap with multiple channels

	// standard result regs
	reg signed [lenOfOutput-1:0] result[0:61*61*32-1];
	
	// initial all data and testbench variables
	integer temp; //temporary variable
	integer i_knl,j_chnl,k_value; //variables for kernel initialization
	
	initial begin	
		$readmemb("D:/project_1/testbench/ifm_bin_c32xh64xw64.txt", fMap);
		$readmemb("D:/project_1/testbench/weight_bin_co32xci32xk4xk4.txt", kernel);
		$readmemb("D:/project_1/testbench/ofm_bin_c32xh61xw61.txt", result);
		//inital the control signal
		case(numOfChannels)
			8: in_cfg_ci=0;
			16: in_cfg_ci=1;
			24: in_cfg_ci=2;
			32: in_cfg_ci=3;
			default: in_cfg_ci=3;
		endcase
		case(numOfKernels)
			8: in_cfg_co=0;
			16: in_cfg_co=1;
			24: in_cfg_co=2;
			32: in_cfg_co=3;
			default: in_cfg_co=3;
		endcase

		//All inital works Done! 		
		# 0.015 in_start_conv=1;	// inital work is done and the top module can start work!
	end
	
	//inital the clk: 500ps turns, T=1000ps
	// debug, the cycle T=100ps.
	initial begin	
		forever #0.005 clk=~clk;
	end
	
	// begin to send data and count the cycle
	integer i,j;
	integer kernelCounter=0; 	// to count the id of this kernel
	integer channelCounter=0; 	// to count the id of this channel
	integer rowCounter=0;		// to count the id of the beginning row of data in this CONV, the row position of FMap
	// to count the id of this cycle, the number of cycles during CONV
	integer cycleCounter=0;	// [0,1] is read kernel; [2,3] is read the first 4*4 data; [4,33] is read flowing data in the same row
		
	always @(posedge clk) begin
		// Sending data.
		if(in_start_conv)begin	//wait until initial work is done!
			
			if(cycleCounter<2) begin	//read kernel
				if(out_readw_ctl==1) begin
					temp=kernelCounter*numOfChannels*numOfPerKnl+channelCounter*numOfPerKnl;
					in_wdata0=kernel[temp+cycleCounter*8+0];
					in_wdata1=kernel[temp+cycleCounter*8+1];
					in_wdata2=kernel[temp+cycleCounter*8+2];
					in_wdata3=kernel[temp+cycleCounter*8+3];
					in_wdata4=kernel[temp+cycleCounter*8+4];
					in_wdata5=kernel[temp+cycleCounter*8+5];
					in_wdata6=kernel[temp+cycleCounter*8+6];
					in_wdata7=kernel[temp+cycleCounter*8+7];
				end
				
				if(out_readi_ctl==1) begin
					temp=channelCounter*numOfPerFMap;
					j=cycleCounter*2;
					
					in_fdata0=fMap[temp+rowCounter*64+j];
					in_fdata1=fMap[temp+(rowCounter+1)*64+j];
					in_fdata2=fMap[temp+(rowCounter+2)*64+j];
					in_fdata3=fMap[temp+(rowCounter+3)*64+j];
					
					in_fdata4=fMap[temp+rowCounter*64+j+1];
					in_fdata5=fMap[temp+(rowCounter+1)*64+j+1];
					in_fdata6=fMap[temp+(rowCounter+2)*64+j+1];
					in_fdata7=fMap[temp+(rowCounter+3)*64+j+1];
				end
			end
			else if(cycleCounter>=2 && cycleCounter<=31) begin  	//testbench is 31
				if(out_readi_ctl==1) begin
					temp=channelCounter*numOfPerFMap;
					j=cycleCounter*2;
					
					in_fdata0=fMap[temp+rowCounter*64+j];
					in_fdata1=fMap[temp+(rowCounter+1)*64+j];
					in_fdata2=fMap[temp+(rowCounter+2)*64+j];
					in_fdata3=fMap[temp+(rowCounter+3)*64+j];
					
					in_fdata4=fMap[temp+rowCounter*64+j+1];
					in_fdata5=fMap[temp+(rowCounter+1)*64+j+1];
					in_fdata6=fMap[temp+(rowCounter+2)*64+j+1];
					in_fdata7=fMap[temp+(rowCounter+3)*64+j+1];
				end
			end 
			
			//cycleCounter: 32 is for sending data and closing output-signal
			if(cycleCounter!=33)
				cycleCounter<=cycleCounter+1;
			else begin										// new row
				cycleCounter<=0;
				if(rowCounter!=60)
					rowCounter<=rowCounter+1;
				else begin 									// new channel
					rowCounter<=0;
					temp<=0;
					if(channelCounter!=numOfChannels-1)
						channelCounter<=channelCounter+1;
						
					else begin								// new kernel
						channelCounter<=0;
						if(kernelCounter!=numOfKernels-1)
							kernelCounter<=kernelCounter+1;				
					end
				end
			end
		end
	end
		
	integer numError=0;
	integer index=0;
	integer temp_pos=0;
	integer debug_flag=0;
	always @(posedge clk) begin
		// Receiving data.
		if(out_write_ctl) begin
			//Code for recieving data...
			/*
			if(debug_flag==0 && index / 3721==2 && index % 3721 <8 ) begin
				$display("the index is %d,  the result[index] is %d, the out_data0 is %d ", index, result[index], out_data0);
				$display("the index is %d, the result[index+1] is %d, the out_data1 is %d ", index, result[index+1], out_data1);
				
			end*/
			if(temp_pos%31==0) begin
				if(result[index] != out_data0) numError=numError+1;
				index=index+1;
			end
			else begin
				if(result[index] != out_data0) numError=numError+1;
				if(result[index+1] != out_data1) numError=numError+1;
				index=index+2;
			end
			temp_pos=(temp_pos+1)%31;
		end
	end
	
	//Write the final result: How many errors with the expected output!!!!
	integer fid;
	always @( posedge out_end_conv ) begin
		fid = $fopen("./numError.txt", "w");
		$fwrite(fid, "The number of error between our results and expected output is %d !", numError);
		$fclose(fid);
		$finish;
	end 
endmodule