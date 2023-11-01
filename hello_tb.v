module testbench;

  // Instantiate the hello_world module
  hello_world dut();

  // Define the simulation time
  reg clk;
  initial begin
    clk = 0;
    forever begin
      #5 clk = ~clk;
    end
  end

  // Monitor the output
  always @(posedge clk) begin
    if ($time == 10)
      $display("Time = %0t: Message: Hello, World!", $time);
    if ($time == 20)
      $finish;
  end

endmodule
