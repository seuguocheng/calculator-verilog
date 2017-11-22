// Project #1: Calculator
// Verilog sample source file for "System LSI design"
//                                                  2017.10  T. Ikenaga
// 

// AP600: Interface between top_moudule of calculator and FPGA board
module AP600 (clk, reset, pswA, pswB, pswC, pswD, dipA, dipB,
	      hexA, hexB, buzzer, ledA, ledB, ledC, ledD, 
             segA, segB, segC, segD, segE, segF, segG, segH);

  input      clk, reset;             // Clock, Reset
  input[4:0] pswA, pswB, pswC, pswD; // Push Switch
  input[7:0] dipA, dipB;             // DIP Switch
  input[3:0] hexA, hexB;             // Rotary Switch
  output     buzzer;		     // Buzzer
  output[7:0] ledA, ledB, ledC, ledD;// LED
  output[7:0] segA, segB, segC, segD, segE, segF, segG, segH; // 7SEG LED

  wire [7:0] ledh, ledl;
  wire [9:0] push;
  wire overflow, sign, ce, plus, minus, equal;

  // for Debug
  wire [1:0] state;
  wire [8:0] regb;
  wire [6:0] rega;
  wire [1:0] count;
  wire add_or_sub;

  // Input Assignment
  assign push[0] = pswD[0];
  assign push[1] = pswC[0];
  assign push[2] = pswC[1];
  assign push[3] = pswC[2];
  assign push[4] = pswB[0];
  assign push[5] = pswB[1];
  assign push[6] = pswB[2];
  assign push[7] = pswA[0];
  assign push[8] = pswA[1];
  assign push[9] = pswA[2];
  assign plus    = pswD[3];
  assign minus   = pswC[3];
  assign ce      = pswA[4];
  assign equal   = pswD[4];

  // Output Asignment
  assign buzzer = overflow;

  assign ledA = {overflow,2'b00, count[0],count[1], 
                 add_or_sub, state[0], state[1]};
  assign ledB = {regb[8], 7'b0000000};
  assign ledC = {regb[0],regb[1],regb[2],regb[3],
                 regb[4],regb[5],regb[6],regb[7]};
  assign ledD = {rega[0],rega[1],rega[2],rega[3],
                 rega[4],rega[5],rega[6],1'b0};

  assign segA = 8'b00000000;
  assign segB = 8'b00000000;
  assign segC = 8'b00000000;
  assign segD = 8'b00000000;
  assign segE = 8'b00000000;
  assign segF = {6'b000000,sign,1'b0};
  assign segG = ledh;
  assign segH = ledl;

  calctop calctop(clk, reset, push, ce, plus, minus, equal, 
                  sign, ledh, ledl, overflow, state, rega, regb,
                  count, add_or_sub);

endmodule

// Calctop: Calculator top_module
module calctop(clk, reset, push, ce, plus, minus, equal, 
               sign, ledh, ledl, overflow, state, rega, regb,
               count, add_or_sub);
  input plus, minus, equal, ce, reset, clk;
  input [9:0] push;
  output overflow, sign;
  output [7:0] ledh, ledl;

  // for Debug
  output [1:0] state;
  output [8:0] regb;
  output [6:0] rega;
  output [1:0] count;
  output add_or_sub;

  wire plusout, minusout, equalout, ceout;
  wire [9:0] pushout;
  wire [6:0] wout;

  calc calc(pushout, plusout, minusout, equalout, clk, reset, ceout, 
            sign, overflow, wout, state, rega, regb, count, 
            add_or_sub);

  binled binled(wout, ledl, ledh);

  syncro syncroce(ceout, ce, clk, reset);
  syncro syncropuls(plusout, plus, clk, reset);
  syncro syncrominus(minusout, minus, clk, reset);
  syncro syncroequal(equalout, equal, clk, reset);

  syncro10 syncropush(pushout, push, clk, reset) ;

endmodule

`define DECIMAL 0
`define OPE 1
`define HALT 2

// Calc: Calculation main module
module calc(decimal, plus, minus, equal, clk, reset, 
            ce, sign, overflow, out, state, REGA, REGB, count, add_or_sub);
  input [9:0] decimal;
  input clk, ce, reset, plus, minus, equal;
  output sign, overflow;
  output [6:0] out;

  // for Debug
  output [1:0] state;
  output [8:0] REGB;
  output [6:0] REGA;
  output [1:0] count;
  output add_or_sub;

  wire [3:0] d;
  wire [8:0] alu_out;
  reg  [1:0] state;
  reg  [8:0] REGB;
  reg  [6:0] REGA;
  reg  [1:0] count;
  reg        add_or_sub ;

  function [3:0] dectobin;
   input [9:0] in;
    if(in[9])
     dectobin = 9;
    else if(in[8])
     dectobin = 8;
    else if(in[7])
     dectobin = 7;
    else if(in[6])
     dectobin = 6;
    else if(in[5])
     dectobin = 5;
    else if(in[4])
     dectobin = 4;
    else if(in[3])
     dectobin = 3;
    else if(in[2])
     dectobin = 2;
    else if(in[1])
     dectobin = 1;
    else if(in[0])
     dectobin = 0;
   endfunction

  assign d=dectobin(decimal);

  always @(posedge clk or negedge reset)
    begin
     if(!reset)
       begin
         REGA <= 0; REGB <= 0; count <= 0;
         add_or_sub <= 0;
         state<= `DECIMAL;
       end
     else
       begin
        case (state)
         `DECIMAL :
            begin
             if((decimal != 0) && (count < 2))
               begin
                 count <= count + 1;
                 REGA <= REGA * 10 + d;
               end
             else if(ce)
               begin
                 REGA <= 0; 
                 count <= 0;
               end
             else if(plus || minus || equal)
               begin
                 if (add_or_sub==0)
                   REGB <= REGB + REGA;
                 else
                   REGB <= REGB - REGA;
                if (plus)
                   add_or_sub <= 0;
                else if(minus)
                   add_or_sub <= 1;
                state <= `OPE;
               end
            end
         `OPE:
            if (((REGB [8] ==1)&&(REGB<413))
                || ((REGB[8]==0)&&(REGB>99)))
               state<=`HALT;
            else if(decimal) begin
                REGA <= d; 
                count <= 1;
                state <= `DECIMAL;
               end

         `HALT:
            if(ce) begin
                REGA <= 0; 
                REGB <= 0;
                add_or_sub <= 0; 
                count <= 0;
                state <= `DECIMAL;
               end
         endcase
       end
    end

  assign overflow=(state==`HALT)?1:0;
  assign sign=(state==`DECIMAL)?0: ((state==`OPE)?(REGB[8]) :0);
  assign out=out_func (state, REGA, REGB);

  function [6:0] out_func;
    input [1:0] s; input [6:0] a; input [8:0] b;
    case(s)
      `DECIMAL :
        out_func = a;

      `OPE :
        if(b[8]==1)
          out_func = ~b + 1;
        else
          out_func = b;
    endcase
  endfunction

endmodule

// Syncronous: Asyncronous to Syncronous (1 bit width)
module syncro(out, in, clk, reset);
  parameter WIDTH = 1;
  input    [WIDTH-1:0] in;
  output   [WIDTH-1:0] out;
  input     clk,reset;
  reg      [WIDTH-1:0] qO,q1,q2;

  always @(posedge clk or negedge reset)
   begin
    if(!reset)
     begin
       qO <= 0;
       q1 <= 0;
       q2 <= 0;
     end
    else
     begin
       qO <= ~in;
       q1 <= qO;
       q2 <= q1;
     end
   end
  assign out=q1 & (~q2) ;
endmodule

// Syncronous: Asyncronous to Syncronous (10 bit width)
module syncro10(out, in, clk, reset) ;
  parameter WIDTH = 10;
  input    [WIDTH-1:0] in;
  output   [WIDTH-1:0] out;
  input    clk,reset;
  reg      [WIDTH-1:0] qO,q1,q2;

  always @(posedge clk or negedge reset)
   begin
    if(!reset)
     begin
       qO <= 0;
       q1 <= 0;
       q2 <= 0;
     end
    else
     begin
       qO <= ~in;
       q1 <= qO;
       q2 <= q1;
     end
   end
  assign out=q1 & (~q2);
endmodule

// Binled: Code translation
module binled(in, ledl, ledh);
  input [6:0] in;
  output [7:0] ledl, ledh;
  wire [3:0] wireh, wirel;

  bintobcd bintobcd(in,wirel,wireh);
  ledout ledouthigh(wireh, ledh);
  ledout ledoutlow(wirel, ledl);
endmodule

// Bintobcd: Translation from Binary to BCD format
module bintobcd(in,outl,outh);
  input [6:0] in;
  output [3:0] outl,outh;
  wire [6:0] temp1,temp2,temp3;

  assign outh[3] = (in >= 80)    ? 1            : 0;
  assign temp1   = (in >= 80)    ? in - 80      : in;
  assign outh[2] = (temp1 >= 40) ? 1            : 0;
  assign temp2   = (temp1 >= 40) ? temp1 - 40   : temp1;
  assign outh[1] = (temp2 >= 20) ? 1            : 0;
  assign temp3   = (temp2 >= 20) ? temp2 - 20   : temp2;
  assign outh[0] = (temp3 >= 10) ? 1            : 0;
  assign outl    = (temp3 >= 10) ? temp3 - 10   : temp3;
endmodule

// Ledout: translation from BCD to LED-out format
module ledout(in, out);
  input  [3:0] in;
  output [7:0] out;
  reg [7:0] out ;
 
  always @(in)
   begin
     case(in)
        0: out = 8'b11111100;
        1: out = 8'b01100000;
        2: out = 8'b11011010;
        3: out = 8'b11110010;
        4: out = 8'b01100110;
        5: out = 8'b10110110;
        6: out = 8'b10111110;
        7: out = 8'b11100000;
        8: out = 8'b11111110;
        9: out = 8'b11110110;
        default: out = 8'bXXXXXXXX;
      endcase
   end
endmodule
