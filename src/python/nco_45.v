
module nco_45(
    input CK,
    input START,
    input [8:0] v_pos,
    output signed [17:0] cos0, sin0, cos1, sin1
);
    assign cos0 = cos0r[35:18];
    assign sin0 = sin0r[35:18];
    assign cos1 = cos1r[35:18];
    assign sin1 = sin1r[35:18];
    nco_rom rom( .clock(CK), .ce(ce), .oce(1'd1), .addr(addr), .dataout(dataout));
    reg signed [35:0] cos0r;
    reg signed [35:0] sin0r;
    reg signed [35:0] cos1r;
    reg signed [35:0] sin1r;
    reg signed [17:0] cosd;
    reg signed [17:0] sind;
    reg [2:0] counter = 0;
    wire [10:0] addr = {v_pos, counter[1:0]};
    wire ce = ~counter[2];
    wire [17:0] dataout;
    always @ (posedge CK) begin
        if( START ) begin
            counter <= 3'd0;
        end else if (counter != 5) begin
            counter <= counter+1;
        end
    end
    always@(posedge CK) begin
        if ( counter == 0 ) begin
        end else if (counter == 1) begin
            cosd <= dataout; // rom[adr,0]
            cos0r = 36'h400000000; // fiedpoint one
        end else if (counter == 2) begin
            sind <= dataout; // rom[adr,1]
            sin0r <= 36'h000000000; // Zero
        end else if (counter == 3) begin
            cos1r <= {dataout, 18'b0}; // rom[adr,2]
        end else if (counter == 4) begin
            sin1r <= {dataout, 18'b0}; // rom[adr,3]
        end else begin
            cos0r <= $signed($signed(cos0r[35:18])*$signed(18'h1fff0)); // -$signed($signed(sin0)*$signed(sind));
            sin0r <= $signed($signed(sin0)*$signed(cosd))+$signed($signed(cos0)*$signed(sind));
            cos1r <= $signed($signed(cos1)*$signed(cosd))-$signed($signed(sin1)*$signed(sind));
            sin1r <= $signed($signed(sin1)*$signed(cosd))+$signed($signed(cos1)*$signed(sind));
        end
    end
endmodule

module nco_45_tb_main();
    reg CK = 0;
    always #4 CK = ~CK;

    localparam bits = 20;
    reg [19:0] theta = 0;
    reg [31:0] count = 0;
    wire signed [17:0] cos0;
    wire signed [17:0] sin0;
    wire signed [17:0] cos1;
    wire signed [17:0] sin1;
    reg [35:0] test0 = 0;
    reg [17:0] testd = 0;
    wire [17:0] test = {test0[35],test0[33:16]};
    wire start = (count<2);
    always@(posedge CK) begin
        if( start ) begin
            test0 <= 36'h200000000;
            testd <= 18'h0fff0;
        end else begin
            test0 <= $signed($signed(test)*$signed(testd));
        end
    end
    nco_45 nco( .CK(CK), .START(start), .v_pos(9'd0),
         .cos0(cos0), .sin0(sin0), .cos1(cos1), .sin1(sin1) );
    always@(posedge CK) begin
        count <= count+1;
        if ( 128*4 < count ) $finish;
    end
    initial begin
        $dumpfile( "nco_45.vcd" );
        $dumpvars( -1, CK, start, test, test0, testd, cos0, sin0, cos1, sin1, count,
            nco.dataout, nco.counter, nco.cos0r, nco.sin0r, nco.cos1r, nco.sin1r, nco.cosd, nco.sind );
    end
endmodule
