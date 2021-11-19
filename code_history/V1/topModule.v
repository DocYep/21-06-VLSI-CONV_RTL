`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/27 21:49:58
// Design Name: 
// Module Name: topModule
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

// This is the top level module of the CONV project.
// The bandwidth of input data and kernel is 8 bit.
// The bandwidth of output result is 25bit.

module topModule(     
    in_start_conv, clk, 
	in_cfg_ci, in_cfg_co, 	////the number of channels, and the number of kernels,
	in_data0, in_data1, in_data2, in_data3, in_data4, in_data5, in_data6, in_data7,  
	out_data0, out_data1,
	out_writeCtl,
	out_end_conv
);
	// ======== 1. The part for setting parameters
    parameter lenOfInput=8;    //the number of input-data bits 
    parameter lenOfOutput=25;  //the number of output-data bits
    parameter numOfPerKnl=16;  //the number of kernel value
	parameter numOfPerOutFmp=61*61; 	//the number of values in out-fMap
     
	 
	// ======== 2. The part for declaring input or output variables of this module. And getting control information from testbench.
    // input data
	input clk, in_start_conv;    //the start signal of CONV
    input signed [lenOfInput-1:0] in_data0,  in_data1,  in_data2,  in_data3,  in_data4,  in_data5,  in_data6,  in_data7;
	input [2:0] in_cfg_ci;  //the number of channels,  		0 means 8, 1 means 16, 3 means 24, 3 means 32
	input [2:0] in_cfg_co;      //the number of kernels,         0 means 8, 1 means 16, 3 means 24, 3 means 32
	//output data
    output signed [lenOfOutput-1:0] out_data0, out_data1;
    output out_writeCtl; 	// the signal we are going to output data, 1 is yes.
	output out_end_conv;    //the finish signal of CONV, 1 means finish
	
	// read the control information from the crontrol signal
	integer numOfKernels;
	integer numOfChannels;
	always @(*) begin 
		if(in_start_conv) begin
			case(in_cfg_ci) // set numOfChannels
				'b00: numOfChannels=8;
				'b01: numOfChannels=16;
				'b10: numOfChannels=24;
				'b11: numOfChannels=32;
			endcase
			case(in_cfg_co) // set numOfKernels
				'b00: numOfKernels=8;
				'b01: numOfKernels=16;
				'b10: numOfKernels=24;
				'b11: numOfKernels=32;
			endcase
		end
	end 
	
	// ======== 3. The part for setting register for every output variables.
	// reg for out_data0, out_data1;
	reg signed [lenOfOutput-1:0] reg_out_data0, reg_out_data1;
	assign out_data0=reg_out_data0;
	assign out_data1=reg_out_data1;
	
	//set one reg to connect out_writeCtl and out_end_conv
	reg reg_out_writeCtl=0;
	assign out_writeCtl=reg_out_writeCtl;
	
	//set one reg to connect out_end_conv and reg_out_end_conv
	reg reg_out_end_conv=0;
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
	convMod conv0( tmpData0, data00, data01, data02, tmpData1, data10, data11, data12, tmpData2, data20, data21, data22, tmpData3, data30, data31, data32, kernel00, kernel01, kernel02, kernel03, kernel10, kernel11, kernel12, kernel13, kernel20, kernel21, kernel22, kernel23, kernel30, kernel31, kernel32, kernel33, 	convOut0 );
	
	convMod conv1( data00, data01, data02, data03, data10, data11, data12, data13, data20, data21, data22, data23, data30, data31, data32, data33,	kernel00, kernel01, kernel02, kernel03, kernel10, kernel11, kernel12, kernel13, kernel20, kernel21, kernel22, kernel23, kernel30, kernel31, kernel32, kernel33, 	convOut1 );
	
	reg signed [lenOfOutput-1:0] buffer_convOut0, buffer_convOut1; //buffer to get CONV results
	

	// ======== 6. The part for Memory variables for storing results.
	// the memory for results.
	reg signed [lenOfOutput-1:0] convResults0 [numOfPerOutFmp-1:0];
	reg signed [lenOfOutput-1:0] convResults1 [numOfPerOutFmp-1:0];
	reg idOfCalMem; //the id of Memory that is under calculation, to be 0 or 1
	// initial the convResults
	integer i_conv;
	initial begin //just inital the first kernel of convResults for speeding up
		for(i_conv=0;i_conv<numOfPerOutFmp;i_conv=i_conv+1) begin
			convResults0[i_conv]=0;
			convResults1[i_conv]=0;
		end
		idOfCalMem=0;
	end
	
	//for debug
	integer debug_flag=0;
	// ======== 7. The part for getting data from testbench and doing calculation.
	integer kernelCounter=0; 	// to count the id of this kernel
	integer channelCounter=0; 	// to count the id of this channel
	integer rowCounter=0;		// to count the id of the beginning row of data in this CONV, the row position of FMap
	integer cycleCounter=0; //the number of cycles during CONV
    // begin to recieve data and count the cycle
	integer temp=0; //temporary variable
    always @(posedge clk) begin
		if(in_start_conv) begin	//wait until initial work is done!
			if(cycleCounter==0) begin			//read kernel: 1st-2nd row
				//new kernel, get the last two CONV value: the first kernel don't do this
				if( !(kernelCounter==0&&channelCounter==0) ) begin 
					buffer_convOut0=convOut0; //get last value
					buffer_convOut1=convOut1; //get last value
					if(~idOfCalMem) begin //idOfCalMem==0, we are going to use convResults0
						if(debug_flag==0) begin
							//$display("###   the value of array is %d , the value of CONV is ",convResults1[temp+1], convOut1);
						end
						
						convResults0[temp] = convResults0[temp]+buffer_convOut0; 		// doing CONV once
						convResults0[temp+1] = convResults0[temp+1]+buffer_convOut1;	// doing CONV twice
					end
					else begin	//idOfCalMem==1, we are going to use convResults1
						convResults1[temp] = convResults1[temp]+buffer_convOut0;		// doing CONV once
						convResults1[temp+1] = convResults1[temp+1]+buffer_convOut1;	// doing CONV twice
					end
					temp=(temp+2)%numOfPerOutFmp; //next position
					/*
					if(kernelCounter==numOfKernels) begin 	// All works finish. Send the last part of data.
						// turn the idOfCalMem to send the last part of results manually.
						idOfCalMem=~idOfCalMem;
					end*/
					
					// this is not the first channel in this project but is the first channel in this kernel.
					if(channelCounter==0) begin
						// Considering that rowCounter=0, it shows that we are going to write a new memory, inital the next memory
											// Doing CONV calculation in a new memory.
						idOfCalMem=~idOfCalMem;
						// inital next area (kernel) of convResults
						if(~idOfCalMem) begin //idOfCalMem==0, we are going to initial convResults0
							for(i_conv=0;i_conv<kernelCounter*numOfChannels*numOfPerOutFmp;i_conv=i_conv+1) begin
								convResults0[i_conv]=0;
							end
						end 
						else begin //idOfCalMem==1, we are going to initial convResults1
							for(i_conv=0;i_conv<kernelCounter*numOfChannels*numOfPerOutFmp;i_conv=i_conv+1) begin
								convResults1[i_conv]=0;
							end
						end
					end
				end
				kernel00=in_data0;
				kernel01=in_data1;
				kernel02=in_data2;
				kernel03=in_data3;
				
				kernel10=in_data4;
				kernel11=in_data5;
				kernel12=in_data6;
				kernel13=in_data7;
			end
			else if(cycleCounter==1) begin		//read kernel: 3rd-4th row
				kernel20=in_data0;
				kernel21=in_data1;
				kernel22=in_data2;
				kernel23=in_data3;
				
				kernel30=in_data4;
				kernel31=in_data5;
				kernel32=in_data6;
				kernel33=in_data7;
			end
			else if(cycleCounter==2) begin  	//read data: 0st-1nd column
				
				//new channel, get the last two CONV value, the first channel don't do this
				//if( channelCounter != 0 && rowCounter==0 ) begin 
				if( rowCounter !=0 ) begin 
					buffer_convOut0=convOut0; //get last value
					buffer_convOut1=convOut1; //get last value
					if(~idOfCalMem) begin //idOfCalMem==0, we are going to use convResults0
						if(debug_flag==0) begin
							//$display("###   the value of array is %d , the value of CONV is ",convResults1[temp+1], convOut1);
						end
						
						convResults0[temp] = convResults0[temp]+buffer_convOut0; 		// doing CONV once
						convResults0[temp+1] = convResults0[temp+1]+buffer_convOut1;	// doing CONV twice
					end
					else begin	//idOfCalMem==1, we are going to use convResults1
						convResults1[temp] = convResults1[temp]+buffer_convOut0;		// doing CONV once
						convResults1[temp+1] = convResults1[temp+1]+buffer_convOut1;	// doing CONV twice
					end
					temp=(temp+2)%numOfPerOutFmp; //next position
				end
				
				data00=in_data0;
				data10=in_data1;
				data20=in_data2;
				data30=in_data3;
				
				data01=in_data4;
				data11=in_data5;
				data21=in_data6;
				data31=in_data7;
			end
			else if(cycleCounter==3) begin		//read data: 2rd-3th column
				data02=in_data0;
				data12=in_data1;
				data22=in_data2;
				data32=in_data3;
				
				data03=in_data4;
				data13=in_data5;
				data23=in_data6;
				data33=in_data7;
								
				// call the first CONV in conv1
				
			end 
			else begin 	//read 4*2 data columns and calculte 2 CONV for each cycle!				
				if(cycleCounter==4) begin //get the first CONV of this row, only one!
					buffer_convOut1=convOut1; //get last value
					// debug
					/*
					if( kernelCounter==0 && rowCounter==0 ) begin
						$display();
						$display("#######  before add operation, temp is %d, buffer_convOut1 is %d, and convResults0[0] is %d", temp, buffer_convOut1, convResults0[0]);
						$display("####### now the idOfCalMem is %d",idOfCalMem);
						//convResults0[temp]= convResults0[temp] +buffer_convOut1;
					end
					*/
					
					if(~idOfCalMem) begin //idOfCalMem==0, we are going to use convResults0
						convResults0[temp] = convResults0[temp]+buffer_convOut1;
					end
					else begin	//idOfCalMem==1, we are going to use convResults1
						convResults1[temp] = convResults1[temp]+buffer_convOut1;
					end
					
					/*
					// debug
					if( kernelCounter==0 && rowCounter==0 ) $display("#######  before add operation, temp is %d, buffer_convOut1 is %d, and convResults0[0] is %d", temp, buffer_convOut1, convResults0[0]);
					*/
					
					temp=(temp+1)%numOfPerOutFmp; //next position
				end
				else begin	//get two CONVs
					buffer_convOut0=convOut0; //get last value
					buffer_convOut1=convOut1; //get last value
					if(~idOfCalMem) begin //idOfCalMem==0, we are going to use convResults0
						convResults0[temp] = convResults0[temp]+buffer_convOut0; 		// doing CONV once
						convResults0[temp+1] = convResults0[temp+1]+buffer_convOut1;	// doing CONV twice	
					end
					else begin	//idOfCalMem==1, we are going to use convResults1
						convResults1[temp] = convResults1[temp]+buffer_convOut0;		// doing CONV once
						convResults1[temp+1] = convResults1[temp+1]+buffer_convOut1;	// doing CONV twice
					end
					temp=(temp+2)%numOfPerOutFmp; //next position
				end
				
				
				// Left move 2 column
				tmpData0=data01;
				tmpData1=data11;
				tmpData2=data21;
				tmpData3=data31;
				
				data00=data02;
				data10=data12;
				data20=data22;
				data30=data32;
				
				data01=data03;
				data11=data13;
				data21=data23;
				data31=data33;
				
				data02=in_data0;
				data12=in_data1;
				data22=in_data2;
				data32=in_data3;
								
				data03=in_data4;
				data13=in_data5;
				data23=in_data6;
				data33=in_data7;
				
				// call two CONVs
			end
			
			cycleCounter=cycleCounter+1;
			if(cycleCounter==34) begin
				cycleCounter=2;	//next row data in the fMap
				rowCounter=rowCounter+1; //next row
			end
			if(rowCounter==61) begin	//One channel of fMap is over! Next channel of kernel and fMap...
				cycleCounter=0;	//this is new kernel, we should re-send the kernel data.
				rowCounter=0;
				channelCounter=channelCounter+1;
			end
			if(channelCounter==numOfChannels) begin	//One kernel is over! Next kernel...
				channelCounter=0;
				kernelCounter=kernelCounter+1;
			end
		end
    end

	
	// ======== 8. The part for sending data to testbench.
	// monitor whether idOfCalMem is changing, 1 is changing, then we will output the results
	reg signalForOutput=0;
	
	always @( idOfCalMem ) begin
		if( kernelCounter!=0 ) begin	//Let signalForOutput not be set in the initialization of the idOfCalMem. 
			signalForOutput=1;
		end
	end
	
	//output the results
	integer outputKernelCounter=0; // count how many kernels we have output.
	integer outputCounterPerMem=0; // count how many values we have output in Mem.
	
	always @( posedge clk ) begin
		if(in_start_conv & signalForOutput) begin // if the programming is running and one memory is calculated over!
			
			// Attention! This logic is oppsite with the code above!
			
			/*
			//debug
			if(outputKernelCounter==1 && debug_flag==0) begin
				$display(" ######degbug: the cycleCounter is %d, now idOfCalMem is %d, the first CONV value is %d", cycleCounter, idOfCalMem, convResults1[0] );
				debug_flag=1;
			end
			*/
			if(~idOfCalMem) begin //if idOfCalMem==0, it shows [Mem1] can be output.
				reg_out_data0=convResults1[outputCounterPerMem] <0 ? 0 : convResults1[outputCounterPerMem];
				if( outputCounterPerMem!=3720)	begin 		//the last one
					reg_out_data1=convResults1[outputCounterPerMem+1] <0 ? 0 : convResults1[outputCounterPerMem+1];
				end
			end
			else begin			//if idOfCalMem==1, it shows [Mem0] can be output
				reg_out_data0=convResults0[outputCounterPerMem] <0 ? 0 : convResults0[outputCounterPerMem];
				if(outputCounterPerMem!=3720)	begin 		//the last one
					reg_out_data1=convResults0[outputCounterPerMem+1] <0 ? 0 : convResults0[outputCounterPerMem+1];
				end
			end
			
			reg_out_writeCtl=1;	// tell testbench we are going to output.
			
			outputCounterPerMem= outputCounterPerMem+2;
			if(outputCounterPerMem==3724) begin	// Let the signal be 0, Output Over! 3724???? Need to wait a cycle.
				signalForOutput=0;	//Stop to send data.
				reg_out_writeCtl=0;
				
				outputCounterPerMem=0;	//Prepare for next output.
				
				outputKernelCounter=outputKernelCounter+1; //One is done!
			end
			if(outputKernelCounter==numOfKernels) begin // All data have been sent!
				reg_out_end_conv=1; // the finish signal!!
			end
			
			
		end
	end

endmodule
