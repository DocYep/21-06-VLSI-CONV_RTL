`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/29 10:23:45
// Design Name: 
// Module Name: convMod
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

//muxCtl=1
module convModV3( 
			last_result,
			data00, data01, data02, data03, 
			data10, data11, data12, data13, 
			data20, data21, data22, data23, 
			data30, data31, data32, data33,

			kernel00, kernel01, kernel02, kernel03, 
			kernel10, kernel11, kernel12, kernel13, 
			kernel20, kernel21, kernel22, kernel23, 
			kernel30, kernel31, kernel32, kernel33,
			
			out_result
    );
	
	parameter lenOfInput=8;    //the number of input-data bits 
    parameter lenOfOutput=25;  //the number of output-data bits
	
	input signed [lenOfOutput-1:0] last_result;
	
	input signed [lenOfInput-1:0] data00, data01, data02, data03, 
			data10, data11, data12, data13, 
			data20, data21, data22, data23, 
			data30, data31, data32, data33;
			
	input signed [lenOfInput-1:0] kernel00, kernel01, kernel02, kernel03, 
			kernel10, kernel11, kernel12, kernel13, 
			kernel20, kernel21, kernel22, kernel23, 
			kernel30, kernel31, kernel32, kernel33;
	
	output signed [lenOfOutput-1:0] out_result;
	
	wire signed [lenOfOutput-1:0] tag00, tag01, tag10, tag11, tag20, tag21, tag30, tag31, row0, row1, row2, row3;
	reg signed [lenOfOutput-1:0] result;
	// Considering HDL not suggests deep logic, we use 2 level add operation as the simple logic and for speeding up.
	assign tag00=data00*kernel00+data01*kernel01;
	assign tag01=data02*kernel02+data03*kernel03;
	assign row0=tag00+tag01;
	
	assign tag10=data10*kernel10+data11*kernel11;
	assign tag11=data12*kernel12+data13*kernel13;
	assign row1=tag10+tag11;
	
	assign tag20=data20*kernel20+data21*kernel21;
	assign tag21=data22*kernel22+data23*kernel23;
	assign row2=tag20+tag21;
	
	assign tag30=data30*kernel30+data31*kernel31;
	assign tag31=data32*kernel32+data33*kernel33;
	assign row3=tag30+tag31;

	assign out_result=row0+row1+row2+row3+last_result;
endmodule
