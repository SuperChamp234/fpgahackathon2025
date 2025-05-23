
`timescale 1 ns / 1 ps

  module axi_mm_master #
  (
    parameter integer C_M_AXI_ADDR_WIDTH = 32,
    parameter integer C_M_AXI_DATA_WIDTH = 32,
    parameter integer C_RX_DATA_WIDTH = 32,
    parameter integer C_TX_FIFO_DEPTH = 128,
    parameter integer C_RX_FIFO_DEPTH = 128,
    parameter integer C_REQ_FIFO_DEPTH = 128
  )
  (
    input wire M_AXI_ACLK,
    input wire M_AXI_ARESETN,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 AWADDR" *)  output [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_AWADDR,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 AWVALID" *) output                          M_AXI_AWVALID,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 AWREADY" *) input                           M_AXI_AWREADY,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 WDATA" *)   output [C_M_AXI_DATA_WIDTH-1:0] M_AXI_WDATA,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 WVALID" *)  output                          M_AXI_WVALID,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 WREADY" *)  input                           M_AXI_WREADY,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 BRESP" *)   input [1:0]                     M_AXI_BRESP,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 BVALID" *)  input                           M_AXI_BVALID,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 BREADY" *)  output                          M_AXI_BREADY,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 ARADDR" *)  output [C_M_AXI_ADDR_WIDTH-1:0] M_AXI_ARADDR,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 ARVALID" *) output                          M_AXI_ARVALID,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 ARREADY" *) input                           M_AXI_ARREADY,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 RDATA" *)   input [C_M_AXI_DATA_WIDTH-1:0]  M_AXI_RDATA,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 RRESP" *)   input [1:0]                     M_AXI_RRESP,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 RVALID" *)  input                           M_AXI_RVALID,
  (*X_INTERFACE_INFO="xilinx.com:interface:aximm:1.0 axi_mm_00 RREADY" *)  output                          M_AXI_RREADY,
  input wire [C_M_AXI_DATA_WIDTH-1:0] TX_FIFO_DATA_IN,
  input wire [C_M_AXI_DATA_WIDTH-1:0] TX_FIFO_ADDR_IN,
  input wire                          TX_FIFO_WR_EN,
  output wire                         TX_FIFO_FULL,
  output wire                         TX_FIFO_EMPTY,
  output wire [C_RX_DATA_WIDTH-1:0] RX_FIFO_DATA_OUT,
  input wire                        RX_FIFO_RD_EN,
  output wire                       RX_FIFO_EMPTY,
  output wire                       RX_FIFO_DATA_VALID,
  input wire [C_M_AXI_ADDR_WIDTH-1:0] REQ_ADDR_FIFO_IN,
  input wire                          REQ_ADDR_FIFO_WR_EN,
  output wire                         REQ_ADDR_FIFO_FULL,
  input wire                          RX_FIFO_FLUSH
);

  localparam [1:0] IDLE      = 2'd0,
                  INIT_WRITE = 2'd1,
                  INIT_READ  = 2'd2; 
  reg [1:0] mst_exec_state;
  reg  axi_awvalid;  //write address valid
  reg  axi_wvalid;   //write data valid
  reg  axi_arvalid;  //read address valid
  reg  axi_rready;   //read data acceptance
  reg  axi_bready;   //write response acceptance
  wire write_resp_error;  //Asserts when there is a write response error
  wire read_resp_error;   //Asserts when there is a read response error
  reg  start_single_write; //A pulse to initiate a write transaction
  reg  start_single_read;  //A pulse to initiate a read transaction

  reg  tx_fifo_rd_en;
  wire rx_fifo_full;
  wire tx_fifo_empty_w;
  wire [C_M_AXI_DATA_WIDTH-1:0] tx_data;
  wire [C_M_AXI_ADDR_WIDTH-1:0] tx_addr, rx_addr;
  reg  req_addr_fifo_rd_en;
  wire req_addr_fifo_empty;


  sync_fifo #(
    .FIFO_WIDTH(C_M_AXI_DATA_WIDTH+C_M_AXI_ADDR_WIDTH),
    .FIFO_DEPTH(C_TX_FIFO_DEPTH),
    .MEMORY_TYPE("distributed")
  ) tx_fifo (
    .clk(M_AXI_ACLK),
    .resetn(M_AXI_ARESETN),
    .rd_en(tx_fifo_rd_en),
    .wr_en(TX_FIFO_WR_EN),
    .din({TX_FIFO_DATA_IN,TX_FIFO_ADDR_IN}),
    .dout({tx_data,tx_addr}),
    .empty(tx_fifo_empty_w),
    .full(),
    .almost_empty(),
    .almost_full(),
    .prog_full(TX_FIFO_FULL),
    .data_valid()
  );

  sync_fifo #(
    .FIFO_WIDTH (C_M_AXI_DATA_WIDTH),
    .FIFO_DEPTH (C_RX_FIFO_DEPTH),
    .MEMORY_TYPE("bram")
  ) rx_fifo (
    .clk(M_AXI_ACLK),
    .resetn(M_AXI_ARESETN && ~RX_FIFO_FLUSH),
    .rd_en(RX_FIFO_RD_EN),
    .wr_en(axi_rready),
    .din(M_AXI_RDATA),
    .dout(RX_FIFO_DATA_OUT),
    .empty(RX_FIFO_EMPTY),
    .full(),
    .almost_empty(),
    .almost_full(rx_fifo_full),
    .prog_full(),
    .data_valid(RX_FIFO_DATA_VALID)
  );


  sync_fifo #(
    .FIFO_WIDTH(C_M_AXI_ADDR_WIDTH),
    .FIFO_DEPTH(C_REQ_FIFO_DEPTH),
    .MEMORY_TYPE("bram")
  ) req_fifo (
    .clk(M_AXI_ACLK),
    .resetn(M_AXI_ARESETN),
    .rd_en(req_addr_fifo_rd_en),
    .wr_en(REQ_ADDR_FIFO_WR_EN),
    .din(REQ_ADDR_FIFO_IN),
    .dout(rx_addr),
    .empty(req_addr_fifo_empty),
    .full(),
    .almost_empty(),
    .almost_full(REQ_ADDR_FIFO_FULL),
    .prog_full(),
    .data_valid()
  );

  assign M_AXI_AWADDR  = tx_addr;
  assign M_AXI_WDATA   = tx_data;
  assign M_AXI_AWVALID = axi_awvalid;
  assign M_AXI_WVALID  = axi_wvalid;
  assign M_AXI_BREADY  = axi_bready;
  assign M_AXI_ARADDR  = rx_addr;
  assign M_AXI_ARVALID = axi_arvalid;
  assign M_AXI_RREADY  = axi_rready;

  assign TX_FIFO_EMPTY = tx_fifo_empty_w;
  //--------------------
  //Write Address Channel
  //--------------------
/*
  // The purpose of the write address channel is to request the address and
  // command information for the entire transaction.  It is a single beat
  // of information.

  // Note for this example the axi_awvalid/axi_wvalid are asserted at the same
  // time, and then each is deasserted independent from each other.
  // This is a lower-performance, but simplier control scheme.

  // AXI VALID signals must be held active until accepted by the partner.

  // A data transfer is accepted by the slave when a master has
  // VALID data and the slave acknoledges it is also READY. While the master
  // is allowed to generated multiple, back-to-back requests by not
  // deasserting VALID, this design will add rest cycle for
  // simplicity.

  // Since only one outstanding transaction is issued by the user design,
  // there will not be a collision between a new request and an accepted
  // request on the same clock cycle.
*/
  always @(posedge M_AXI_ACLK) begin
    //Only VALID signals must be deasserted during reset per AXI spec
    if (M_AXI_ARESETN == 0 )
      axi_awvalid <= 1'b0;
    else begin
      if (start_single_write)
        axi_awvalid <= 1'b1;
      else if (M_AXI_AWREADY && axi_awvalid)
        axi_awvalid <= 1'b0;
    end
  end

  //--------------------
  //Write Data Channel
  //--------------------
/*
  //The write data channel is for transfering the actual data.
  //The data generation is speific to the example design, and
  //so only the WVALID/WREADY handshake is shown here
*/
  always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0)
      axi_wvalid <= 1'b0;
    else if (start_single_write)
      axi_wvalid <= 1'b1;
    else if (M_AXI_WREADY && axi_wvalid)
      axi_wvalid <= 1'b0;
  end


  //----------------------------
  //Write Response (B) Channel
  //----------------------------
/*
    //The write response channel provides feedback that the write has committed
    //to memory. BREADY will occur after both the data and the write address
    //has arrived and been accepted by the slave, and can guarantee that no
    //other accesses launched afterwards will be able to be reordered before it.

    //The BRESP bit [1] is used indicate any errors from the interconnect or
    //slave for the entire write burst. This example will capture the error.

    //While not necessary per spec, it is advisable to reset READY signals in
    //case of differing reset latencies between master/slave.
*/
  always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0)
      axi_bready <= 1'b0;
    else if (M_AXI_BVALID && ~axi_bready)
      axi_bready <= 1'b1;
    else if (axi_bready)
      axi_bready <= 1'b0;
    else
      axi_bready <= axi_bready;
  end

  assign write_resp_error = (axi_bready & M_AXI_BVALID & M_AXI_BRESP[1]);

  //----------------------------
  //Read Address Channel
  //----------------------------
/*
      // A new axi_arvalid is asserted when there is a valid read address
      // available by the master. start_single_read triggers a new read
      // transaction
*/
  always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0)
      axi_arvalid <= 1'b0;
    else if (start_single_read)
      axi_arvalid <= 1'b1;
    else if (M_AXI_ARREADY && axi_arvalid)
       axi_arvalid <= 1'b0;
  end

  //--------------------------------
  //Read Data (and Response) Channel
  //--------------------------------
/*
  //The Read Data channel returns the results of the read request
  //The master will accept the read data by asserting axi_rready
  //when there is a valid read data available.
  //While not necessary per spec, it is advisable to reset READY signals in
  //case of differing reset latencies between master/slave.
*/
  always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 0)
      axi_rready <= 1'b0;
    else if (M_AXI_RVALID && ~axi_rready)
      axi_rready <= 1'b1;
    else if (axi_rready)
      axi_rready <= 1'b0;
  end

  assign read_resp_error = (axi_rready & M_AXI_RVALID & M_AXI_RRESP[1]);


  //--------------------------------
  //User Logic
  //--------------------------------

  always @(posedge M_AXI_ACLK) begin
    if (M_AXI_ARESETN == 1'b0) begin
      mst_exec_state      <= IDLE;
      start_single_write  <= 1'b0;
      start_single_read   <= 1'b0;
      tx_fifo_rd_en       <= 1'b0;
      req_addr_fifo_rd_en <= 1'b0;
    end else begin
      case (mst_exec_state)
        IDLE:
          if (~req_addr_fifo_empty & ~rx_fifo_full)
             mst_exec_state <= INIT_READ;
          else if (~tx_fifo_empty_w)
            mst_exec_state <= INIT_WRITE;
          else
            mst_exec_state <= IDLE;
        INIT_WRITE:
          if (tx_fifo_empty_w)
            mst_exec_state <= IDLE;
          else begin
            mst_exec_state  <= INIT_WRITE;
            if (~axi_awvalid && ~axi_wvalid && ~M_AXI_BVALID && ~start_single_write) begin
              start_single_write <= 1'b1;
              tx_fifo_rd_en      <= 1'b1;
            end else begin
              start_single_write <= 1'b0; //Negate to generate a pulse
              tx_fifo_rd_en      <= 1'b0;
            end
          end
        INIT_READ:
          if (req_addr_fifo_empty || rx_fifo_full)
            mst_exec_state <= IDLE;
          else begin
            mst_exec_state <= INIT_READ;
            if (~axi_arvalid && ~M_AXI_RVALID && ~start_single_read) begin
              start_single_read   <= 1'b1;
              req_addr_fifo_rd_en <= 1'b1;
            end else if (axi_rready) begin
              req_addr_fifo_rd_en <= 1'b0;
            end else begin
              start_single_read   <= 1'b0; //Negate to generate a pulse
              req_addr_fifo_rd_en <= 1'b0;
            end
          end
        default:
          mst_exec_state <= IDLE;
      endcase
    end
  end

  endmodule
