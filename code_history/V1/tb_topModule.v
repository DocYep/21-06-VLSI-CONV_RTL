`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/27 21:50:42
// Design Name: 
// Module Name: tb_topModule
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
module tb_topModule();
	// Configuration of the CONV-Project
	integer numOfKernels=8;
	integer numOfChannels=16;
	
	parameter lenOfInput=8;    //the number of input-data bits 
    parameter lenOfOutput=25;  //the number of output-data bits
	parameter numOfPerKnl=16;  //the number of kernel value
	parameter numOfPerFMap=4096;  //the number of kernel value
	
	// module variables
	//input
	reg clk=0;
	reg signed [lenOfInput-1:0] in_data0, in_data1,  in_data2,  in_data3,  in_data4,  in_data5,  in_data6,  in_data7;
	reg in_start_conv=0;	//start signal of the top module
	reg [2:0] in_cfg_ci;  //the number of channels,  		0 means 8, 1 means 16, 3 means 24, 3 means 32
    reg [2:0] in_cfg_co;      //the number of kernels,         0 means 8, 1 means 16, 3 means 24, 3 means 32
	//output
	wire signed [lenOfOutput-1:0] out_data0, out_data1;
	wire out_end_conv;
	wire out_writeCtl;
	
	
	// internal variables
	reg signed [lenOfInput-1:0] kernel[0:numOfPerKnl*32*32-1];  	//store the value of a kernel, 32 kernels with 32 channels
	reg signed [lenOfInput-1:0] fMap[0:numOfPerFMap*32-1];			//Only one fMap with multiple channels

	// standard result regs
	reg signed [lenOfOutput-1:0] ans[0:61*61*32-1];
	
	// initial all data and testbench variables
	integer temp; //temporary variable
	integer i_knl,j_chnl,k_value; //variables for kernel initialization
	
	initial begin	
		$readmemb("D:/project_1/testbench/ifm_bin_c32xh64xw64.txt", fMap);
		$readmemb("D:/project_1/testbench/weight_bin_co32xci32xk4xk4.txt", kernel);
		$readmemb("D:/project_1/testbench/ofm_bin_c32xh61xw61.txt", ans);
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
		in_start_conv=1;	// inital work is done and the top module can start work!
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
				temp=kernelCounter*numOfChannels*numOfPerKnl+channelCounter*numOfPerKnl;
				
				in_data0=kernel[temp+cycleCounter*8+0];
				in_data1=kernel[temp+cycleCounter*8+1];
				in_data2=kernel[temp+cycleCounter*8+2];
				in_data3=kernel[temp+cycleCounter*8+3];
				in_data4=kernel[temp+cycleCounter*8+4];
				in_data5=kernel[temp+cycleCounter*8+5];
				in_data6=kernel[temp+cycleCounter*8+6];
				in_data7=kernel[temp+cycleCounter*8+7];
			end
			else if(cycleCounter>=2) begin  	//read 4*2 data columns with column priority for each cycle!
				temp=channelCounter*numOfPerFMap;
				j=(cycleCounter-2)*2;
				
				in_data0=fMap[temp+rowCounter*64+j];
				in_data1=fMap[temp+(rowCounter+1)*64+j];
				in_data2=fMap[temp+(rowCounter+2)*64+j];
				in_data3=fMap[temp+(rowCounter+3)*64+j];
				
				in_data4=fMap[temp+rowCounter*64+j+1];
				in_data5=fMap[temp+(rowCounter+1)*64+j+1];
				in_data6=fMap[temp+(rowCounter+2)*64+j+1];
				in_data7=fMap[temp+(rowCounter+3)*64+j+1];
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
			if(channelCounter==numOfChannels) begin	//One kernel is over! Next kernel and reset fMap...
				channelCounter=0;
				kernelCounter=kernelCounter+1;
			end
			/* if(kernelCounter==numOfKernels) begin 	// All works finish.
				$finish;
			end */
			if(out_end_conv==1) begin
				$finish;
			end 
		end
	end

	topModule top( in_start_conv, clk,
		in_cfg_ci, in_cfg_co,
		in_data0, in_data1, in_data2, in_data3, in_data4, in_data5, in_data6, in_data7,  
		out_data0, out_data1,
		out_writeCtl,
		out_end_conv		);
		
	/*
	//recieve data
	reg signed [lenOfOutput-1:0] reg_out_data0, reg_out_data1;
	always @(*) begin
		reg_out_data0=out_data0;
		reg_out_data1=out_data1;
	end
	*/
	
	integer numError=0;
	integer index=0;
	integer debug_flag=0;
	always @(negedge clk) begin
		// Receiving data.
		if(out_writeCtl) begin
			//Code for recieving data...
			
			//if(out_data0==128182) $display("the cycleCounter is %d, index is %d, gooooood!!!!!!!!!\n the ans[3720] is %d", cycleCounter,index,ans[3720]);
			
			if(debug_flag==0 && index / 3721==2 && index % 3721 <8 ) begin
				$display("the index is %d,  the ans[index] is %d, the out_data0 is %d ", index, ans[index], out_data0);
				$display("the index is %d, the ans[index+1] is %d, the out_data1 is %d ", index, ans[index+1], out_data1);
			end
			
			if( ans[index] != out_data0 )	numError=numError+1;
			index=index+1;
			
			if( index % 3721 !=0 ) begin
				if( ans[index]!= out_data1 )	numError=numError+1;
				//if( ans[index] != reg_out_data0 )	numError=numError+1;
				//if( ans[index+1]!= reg_out_data1 )	numError=numError+1;
				index=index+1;
			end
		end
	end
	
	
	//Write the final result: How many errors with the expected output!!!!
	integer fid;
	always @( posedge out_end_conv ) begin
		fid = $fopen("./numError.txt", "w");
		$fwrite(fid, "The number of error between our results and expected output is %d !", numError);
		$fclose(fid);
	end 
endmodule