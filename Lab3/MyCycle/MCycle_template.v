// The multiplier template is provided, and you should modify it to the improved one and share the hardware resource to implement division.
module MCycle
#(
    parameter WIDTH = 32  // 32-bits for ARMv3
) 
(
    input CLK,   // Connect to CPU clock
    input RESET, // Connect to the reset of the ARM processor.
    input Start, // Multi-cycle Enable. The control unit should assert this when MUL or DIV instruction is detected.
    input MCycleOp, // Multi-cycle Operation. "0" for unsigned multiplication, "1" for unsigned division. Generated by Control unit.
    input [WIDTH-1:0] Operand1, // Multiplicand / Dividend
    input [WIDTH-1:0] Operand2, // Multiplier / Divisor
    output [WIDTH-1:0] Result,  //For MUL, assign the lower-32bits result; For DIV, assign the quotient.
    output reg Busy = 1'b0 // Set immediately when Start is set. Cleared when the Results become ready. This bit can be used to stall the processor while multi-cycle operations are on.
);

    localparam IDLE = 1'b0;
    localparam COMPUTING = 1'b1;

    reg state, n_state;
    reg done;
    reg reg_op;

    // state machine
    always @(posedge CLK or posedge RESET) begin
      if(RESET)
        state <= IDLE;
      else
        state <= n_state;
    end

    always @(*) begin
      case(state)
        IDLE: begin
          if(Start) begin
            n_state = COMPUTING;
            Busy = 1'b1;
          end
          else  begin
            n_state = IDLE;
            Busy = 1'b0;
          end
        end

        COMPUTING:  begin
          if(~done) begin
            n_state = COMPUTING;
            Busy = 1'b1 ;
          end
          else begin
            n_state = IDLE;
            Busy = 1'b0;
          end
        end
      endcase
    end

    reg [5:0] count = 0 ; // assuming no computation takes more than 64 cycles.
    // reg [2*WIDTH-1:0] temp_sum = 0 ;
    reg [2*WIDTH-1:0] shifted_op1 = 0;
    reg [WIDTH-1:0] op2 = 0 ;
    
    // assign shifted_op1_ready = MCycleOp ? {{(WIDTH-1){1'b0}}, Operand1, 1'b0}:{{(WIDTH){1'b0}}, Operand1};

    // reg sign_extend = 0;
    // wire sign_extend_re;

    wire DIVIDE_READY = (op2 <= shifted_op1[2*WIDTH-2:WIDTH-1]) ? 1: 0;
    wire [WIDTH-1:0] divide_temp_result = (DIVIDE_READY) ? shifted_op1[2*WIDTH-2:WIDTH-1] - op2 : shifted_op1[2*WIDTH-2:WIDTH-1];
    
    // Multi-cycle Multiplier & divider
    always@(posedge CLK or posedge RESET) begin: COMPUTING_PROCESS // process which does the actual computation
      if(RESET) begin
        count <= 0 ;
        shifted_op1 <= {{(WIDTH-1){1'b0}},Operand1};
        op2 <= Operand2;
        done <= 0;
        // sign_extend <= 1'b0;
      end
      // state: IDLE
      else if(state == IDLE) begin
        if(n_state == COMPUTING) begin
          count <= 0 ;
          shifted_op1 <= {{(WIDTH-1){1'b0}},Operand1};
          op2 <= Operand2;
          done <= 0;
          reg_op <= MCycleOp;
          // sign_extend <= 1'b0;
        end
        // else IDLE->IDLE: registers unchanged
      end
      // state: COMPUTINGq
      else if(n_state == COMPUTING)
      begin
        if(~reg_op)
        begin // Multiply operation
          // The intial version of multiplier template, modify it to the improved one
          if(count == WIDTH-1)
          begin // last cycle
            done <= 1'b1;
            count <= 0;
          end
          else
          begin 
            done <= 1'b0;
            count <= count + 1;
          end 
          if(shifted_op1[0])  begin
            shifted_op1 <= {op2, {(WIDTH-1){1'b0}}} + shifted_op1[2*WIDTH-1:1];
          end
          else  begin
            shifted_op1 <= {1'b0, shifted_op1[2*WIDTH-1:1]};
          end
          // else temp_sum unchanged
          op2 <= op2;
          // sign_extend <= 1'b0;
        end
        // Multiplier end
        else
        begin // Divide operation
          if(reg_op)
          begin // Multiply operation
            // The intial version of multiplier template, modify it to the improved one
            if(count == WIDTH-1) begin // last cycle
              done <= 1'b1;
              count <= 0;
            end
            else begin
              done <= 1'b0;
              count <= count + 1;
            end
            shifted_op1 <= {divide_temp_result, shifted_op1[WIDTH-2:0], DIVIDE_READY};
            
            // else temp_sum unchanged
            op2 <= op2;
          end
        end
      end
      // else COMPUTING->IDLE: registers unchanged
    end
    wire [WIDTH-1:0] test = shifted_op1[2*WIDTH-2:WIDTH-1];

    assign Result = shifted_op1[WIDTH-1:0];
endmodule

