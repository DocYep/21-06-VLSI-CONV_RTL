`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/17 10:48:29
// Design Name: 
// Module Name: topModuleV2
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


// ---Version 2.0
// This is the top level module of the CONV project.
// The bandwidth of input data and kernel is 8 bit.
// The bandwidth of output result is 25bit.

module topModuleV2(     
    in_start_conv, clk, 			// the signal for begining and clk
	in_cfg_ci, in_cfg_co, 			// the number of channels, and the number of kernels,
	in_wdata0, in_wdata1, in_wdata2, in_wdata3, in_wdata4, in_wdata5, in_wdata6, in_wdata7,  // weights data and feature map data
	in_fdata0, in_fdata1, in_fdata2, in_fdata3, in_fdata4, in_fdata5, in_fdata6, in_fdata7,  
	out_data0, out_data1,			// output data
	out_readw_ctl,out_readi_ctl,	// the signal to get fmap or weights
	out_write_ctl,					// the signal to write output
	out_end_conv					// the signal for ending
);
	// ======== 1. The part for setting parameters
    parameter lenOfInput=8;    		//the number of input-data bits 
    parameter lenOfOutput=25;  		//the number of output-data bits
    parameter numOfPerKnl=16; 		//the number of kernel value
	parameter numOfPerOutFmp=61*61; 	//the number of values in out-fMap
     
	// ======== 2. The part for declaring input or output variables of this module. And getting control information from testbench.
    // input data
	input clk, in_start_conv;
	input [2:0] in_cfg_ci;  		//the number of channels,  		0 means 8, 1 means 16, 3 means 24, 3 means 32
	input [2:0] in_cfg_co;      	//the number of kernels,         0 means 8, 1 means 16, 3 means 24, 3 means 32
    input signed [lenOfInput-1:0] in_wdata0, in_wdata1, in_wdata2, in_wdata3, in_wdata4, in_wdata5, in_wdata6, in_wdata7;
	input signed [lenOfInput-1:0] in_fdata0, in_fdata1, in_fdata2, in_fdata3, in_fdata4, in_fdata5, in_fdata6, in_fdata7;
	//output data
    output signed [lenOfOutput-1:0] out_data0, out_data1;
	output out_readw_ctl,out_readi_ctl;		// the signals to get fmap and weights, 1 is yes
    output out_write_ctl; 			// the signal we are going to output data, 1 is yes.
	output out_end_conv;   			//the finish signal of CONV, 1 means finish
	
	// ======== 3. The part for setting register for every output variables.
	// reg for out_data0, out_data1;
	reg signed [lenOfOutput-1:0] reg_out_data0, reg_out_data1;
	assign out_data0=reg_out_data0;
	assign out_data1=reg_out_data1;
	
	//set one reg to connect out_readw_ctl and out_readi_ctl
	reg reg_out_readw_ctl;
	assign out_readw_ctl=reg_out_readw_ctl;
	reg reg_out_readi_ctl;
	assign out_readi_ctl=reg_out_readi_ctl;
	
	//set one reg to connect out_writeCtl and out_end_conv
	reg reg_out_write_ctl;
	assign out_write_ctl=reg_out_write_ctl;
	
	//set one reg to connect out_end_conv and reg_out_end_conv
	reg reg_out_end_conv;
	assign out_end_conv=reg_out_end_conv;
	
	
	// ======== 4. The part for declaring our variables for calculation, such as kernel and data array.
    //kernel 4*4, store the value of a kernel, 4*4
    reg signed [lenOfInput-1:0] kernel00, kernel01, kernel02, kernel03, 
			kernel10, kernel11, kernel12, kernel13, 
			kernel20, kernel21, kernel22, kernel23, 
			kernel30, kernel31, kernel32, kernel33;
	
	//data 4*4, store the value of a data, 4*4
	reg signed [lenOfInput-1:0] data00, data01, data02, data03, 
			data10, data11, data12, data13, 
			data20, data21, data22, data23, 
			data30, data31, data32, data33;
	
	// ======== 5. The part for declaring our variables for CONV modules.
	// the data should be shifting 2 bits.
	reg signed [lenOfInput-1:0] tmpData0,tmpData1,tmpData2,tmpData3;
	//wire for recieving the data from CONVs
	wire signed [lenOfOutput-1:0] convOut0,convOut1; //the output of conv0 and conv1.
	
	// set two CONV modules. One for the first CONV, and two for consecutive CONVs
	convMod conv0( tmpData0, data00, data01, data02, tmpData1, data10, data11, data12, tmpData2, data20, data21, data22, tmpData3, data30, data31, data32, kernel00, kernel01, kernel02, kernel03, kernel10, kernel11, kernel12, kernel13, kernel20, kernel21, kernel22, kernel23, kernel30, kernel31,kernel32, kernel33, 	convOut0 );
	
	convMod conv1( data00, data01, data02, data03, data10, data11, data12, data13, data20, data21, data22, data23, data30, data31, data32, data33,	kernel00, kernel01, kernel02, kernel03, kernel10, kernel11, kernel12, kernel13, kernel20, kernel21, kernel22, kernel23, kernel30, kernel31, kernel32, kernel33,   convOut1 );
	
	// ======== 6. The part for Memory variables for storing results.
	// Set the control information from the crontrol signal
	integer numOfKernels;
	integer numOfChannels;
	// the memory for results.
	reg signed [lenOfOutput-1:0] convResults [numOfPerOutFmp-1:0];
	integer i_conv;
	
	// ======== 7. The part for getting data from testbench and doing calculation.
	integer kernelCounter; 	// to count the id of this kernel
	integer channelCounter; 	// to count the id of this channel
	integer rowCounter;		// to count the id of the beginning row of data in this CONV, the row position of FMap
	integer cycleCounter; //the number of cycles during CONV
    // begin to recieve data and count the cycle
	integer temp; //temporary variable
	
	reg reset_memory;
	
    always @(posedge clk) begin
		//reset the memory
		if(reset_memory==1) begin
			for(i_conv=0;i_conv<numOfPerOutFmp;i_conv=i_conv+1) begin
				convResults[i_conv]<=0;
			end
			reset_memory<=0;
		end
	
		if(in_start_conv==0) begin	//the initial value of variables
			case(in_cfg_ci) // set numOfChannels
				'b00: numOfChannels<=8;
				'b01: numOfChannels<=16;
				'b10: numOfChannels<=24;
				'b11: numOfChannels<=32;
			endcase
			case(in_cfg_co) // set numOfKernels
				'b00: numOfKernels<=8;
				'b01: numOfKernels<=16;
				'b10: numOfKernels<=24;
				'b11: numOfKernels<=32;
			endcase
			
			reg_out_readw_ctl<=1;
			reg_out_readi_ctl<=1;
			reg_out_write_ctl<=0;
			reg_out_end_conv<=0;
			
			reset_memory<=0;
			
			kernelCounter<=0;
			channelCounter<=0;
			rowCounter<=0;
			cycleCounter<=0;
			temp<=0;
		end
		else if(in_start_conv==1) begin					// beginning working!
			if(cycleCounter==0) begin			//get kernel of a channel: 0-1st row; get fmap: 0-1st column.
				if(reg_out_readw_ctl==1) begin	
					kernel00<=in_wdata0;
					kernel01<=in_wdata1;
					kernel02<=in_wdata2;
					kernel03<=in_wdata3;
					
					kernel10<=in_wdata4;
					kernel11<=in_wdata5;
					kernel12<=in_wdata6;
					kernel13<=in_wdata7;
				end
				if(reg_out_readi_ctl==1) begin
					data00<=in_fdata0;
					data10<=in_fdata1;
					data20<=in_fdata2;
					data30<=in_fdata3;
					
					data01<=in_fdata4;
					data11<=in_fdata5;
					data21<=in_fdata6;
					data31<=in_fdata7;
				end
			end
			else if(cycleCounter==1) begin		//get kernel of a channel: 2nd-3rd row; get fmap: 2nd-3rd column.
				if(reg_out_readw_ctl==1) begin
					kernel20<=in_wdata0;
					kernel21<=in_wdata1;
					kernel22<=in_wdata2;
					kernel23<=in_wdata3;
					
					kernel30<=in_wdata4;
					kernel31<=in_wdata5;
					kernel32<=in_wdata6;
					kernel33<=in_wdata7;
					
					reg_out_readw_ctl<=0;		// close the signal of getting kernel.
				end
				if(reg_out_readi_ctl==1) begin
					data02<=in_fdata0;
					data12<=in_fdata1;
					data22<=in_fdata2;
					data32<=in_fdata3;
					
					data03<=in_fdata4;
					data13<=in_fdata5;
					data23<=in_fdata6;
					data33<=in_fdata7;
				end
			end
			else if(cycleCounter==2) begin  	//get last result of 1 CONV and move 2 column fmap (getting new fmap).
				//get last result of 1 CONV
				convResults[temp] <= convResults[temp]+convOut1;
				temp<=temp+1;
				
				// Left move 2 column
				tmpData0<=data01;
				tmpData1<=data11;
				tmpData2<=data21;
				tmpData3<=data31;
				
				data00<=data02;
				data10<=data12;
				data20<=data22;
				data30<=data32;
				
				data01<=data03;
				data11<=data13;
				data21<=data23;
				data31<=data33;
				
				data02<=in_fdata0;
				data12<=in_fdata1;
				data22<=in_fdata2;
				data32<=in_fdata3;
								
				data03<=in_fdata4;
				data13<=in_fdata5;
				data23<=in_fdata6;
				data33<=in_fdata7;
			end
			else if(cycleCounter>=3 && cycleCounter<=31) begin		//get last result of 2 CONV and move 2 column fmap (getting new fmap).
				//get last result of 2 CONV
				convResults[temp] <= convResults[temp]+convOut0; 		// doing CONV once
				convResults[temp+1] <= convResults[temp+1]+convOut1;	// doing CONV twice	
				temp<=temp+2;
				
				// Left move 2 column
				tmpData0<=data01;
				tmpData1<=data11;
				tmpData2<=data21;
				tmpData3<=data31;
				
				data00<=data02;
				data10<=data12;
				data20<=data22;
				data30<=data32;
				
				data01<=data03;
				data11<=data13;
				data21<=data23;
				data31<=data33;
				
				data02<=in_fdata0;
				data12<=in_fdata1;
				data22<=in_fdata2;
				data32<=in_fdata3;
								
				data03<=in_fdata4;
				data13<=in_fdata5;
				data23<=in_fdata6;
				data33<=in_fdata7;
				
				if(cycleCounter==31)reg_out_readi_ctl<=0;	//close the signal of getting fmap
			end 
			else if(cycleCounter==32) begin 	//get last result of 2 CONV.			
				//get last result of 2 CONV
				convResults[temp] <= convResults[temp]+convOut0;
				convResults[temp+1] <= convResults[temp+1]+convOut1;
				temp<=temp+2;
			end
			else if(cycleCounter==33)
				reg_out_readi_ctl<=1;	//open the signal of getting fmap
			
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
					reg_out_readw_ctl<=1;					// open the signal of getting kernel
					if(channelCounter!=numOfChannels-1)
						channelCounter<=channelCounter+1;
					else begin								// new kernel
						reset_memory<=1;//new kernel, initial the MEMORY!!!
						channelCounter<=0;
						if(kernelCounter!=numOfKernels-1)
							kernelCounter<=kernelCounter+1;				
					end
				end
			end
		end
    end

	// ======== 8. The part for sending data to testbench.
	always @( posedge clk ) begin
		if(channelCounter==numOfChannels-1) begin
			if(cycleCounter==2)	begin
				reg_out_write_ctl<= 1;				//open the output-signal
				reg_out_data0<= (convResults[temp]+convOut1)<0?0:(convResults[temp]+convOut1);
				reg_out_data1<=-1;
			end
			else if(cycleCounter>=3 && cycleCounter<=31) begin
				reg_out_data0<= (convResults[temp]+convOut0)<0?0:(convResults[temp]+convOut0);
				reg_out_data1<= (convResults[temp+1]+convOut1)<0?0:(convResults[temp+1]+convOut1);
			end
			else if(cycleCounter==32) begin
				reg_out_data0<= (convResults[temp]+convOut0)<0?0:(convResults[temp]+convOut0);
				reg_out_data1<= (convResults[temp+1]+convOut1)<0?0:(convResults[temp+1]+convOut1);
			end
			else if(cycleCounter==33) begin
				reg_out_write_ctl<=0;				//closing the output-signal
				if(kernelCounter==numOfKernels-1 && rowCounter==60)	//the last data, all works done!
					reg_out_end_conv<=1;
			end
		end
	end
		
endmodule