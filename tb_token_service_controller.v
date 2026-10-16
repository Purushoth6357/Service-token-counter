`timescale 1ns/1ps
module tb_token_service_controller;
reg CLK_50MHZ;
    reg KEY0;
    reg SW0;
    reg SW1;
    wire [7:0] LED_DATA;
// Use a short debounce interval for simulation
    token_service_controller #(
        .DEBOUNCE_COUNT(4)
    ) DUT (
        .CLK_50MHZ(CLK_50MHZ),
        .KEY0(KEY0),
        .SW0(SW0),
        .SW1(SW1),
        .LED_DATA(LED_DATA)
    );
// 50 MHz clock: 20 ns period
    initial begin
        CLK_50MHZ = 1'b0;
        forever #10 CLK_50MHZ = ~CLK_50MHZ;
    end
// Simulate one press and release
    task press_button;
    begin
        KEY0 = 1'b0;
        #200;
KEY0 = 1'b1;
        #200;
    end
    endtask
// Check the current token
    task check_token;
        input [3:0] expected_tens;
        input [3:0] expected_ones;
    begin
        if ((DUT.token_tens !== expected_tens) ||
            (DUT.token_ones !== expected_ones)) begin
$display("FAIL at time %0t", $time);
            $display("Expected token: %0d%0d",
                     expected_tens, expected_ones);
            $display("Actual token:   %0d%0d",
                     DUT.token_tens, DUT.token_ones);
            $stop;
        end
        else begin
            $display("PASS at time %0t: token = %0d%0d",
                     $time, DUT.token_tens, DUT.token_ones);
        end
    end
    endtask
    initial begin
// Initial inputs
        KEY0 = 1'b1;  // Released
        SW0  = 1'b1;  // Reset ON
        SW1  = 1'b0;  // Service OFF
#100;
        check_token(0, 0);
// Enable normal operation
        SW0 = 1'b0;
        SW1 = 1'b1;
        #100;
// TEST 1: Sequential counting
        press_button;
        check_token(0, 1);
press_button;
        check_token(0, 2);
press_button;
        check_token(0, 3);
// TEST 2: Service mode OFF
        SW1 = 1'b0;
        press_button;
        check_token(0, 3);  // Must remain unchanged
// TEST 3: Reset
        SW0 = 1'b1;
        #100;
        check_token(0, 0);
SW0 = 1'b0;
        SW1 = 1'b1;
        #100;
press_button;
        check_token(0, 1);
// TEST 4: Decimal rollover 09 -> 10
        // Hierarchical assignments are simulation-only.
        @(negedge CLK_50MHZ);
        DUT.token_tens = 4'd0;
        DUT.token_ones = 4'd9;
press_button;
        check_token(1, 0);
// TEST 5: Maximum rollover 99 -> 00
        @(negedge CLK_50MHZ);
        DUT.token_tens = 4'd9;
        DUT.token_ones = 4'd9;
press_button;
        check_token(0, 0);
$display("All test cases completed successfully.");
        $finish;
    end
// Print signals to the Transcript
    initial begin
        $monitor(
            "Time=%0t KEY0=%b RESET=%b SERVICE=%b PULSE=%b TENS=%d ONES=%d LED=%b",
            $time, KEY0, SW0, SW1,
            DUT.next_pulse,
            DUT.token_tens,
            DUT.token_ones,
            LED_DATA
        );
    end
endmodule