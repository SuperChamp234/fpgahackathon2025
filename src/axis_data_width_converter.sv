// Description  : Converts data width between streams. When input sample:
// - is wider than output sample the module sends the input sample in chunks:
//   (The leftmost sample is first in time and | separates samples)
//   Example where S_TDATA_WIDTH / M_TDATA_WIDTH = 4
//   Input sample:   ABCD | EFGH
//   Output samples: D | C | B | A | H | G | F | E
// - is smaller than output sample the module glues together input samples:
//   Example where S_TDATA_WIDTH / M_TDATA_WIDTH = 0.5
//   Input sample:   AB | CD
//   Output sample:  CDAB
// - has the same width as output sample the module is a passthrouh with
//   zero latency.
module axis_data_width_converter #(
    // Width of input AXI stream interface in bits
    parameter S_TDATA_WIDTH  = 16,
    // Propagate tstrb signal on input interface
    // If disabled, tstrb assumed to be 1'b1
    parameter S_STRB_ENABLE = (S_TDATA_WIDTH > 8),
    // tstrb signal width (words per cycle) on input interface
    parameter S_STRB_WIDTH  = ((S_TDATA_WIDTH + 7) / 8),
    // Width of output AXI stream interface in bits
    parameter M_TDATA_WIDTH  = 32,
    // Propagate tstrb signal on output interface
    // If disabled, tstrb assumed to be 1'b1
    parameter M_STRB_ENABLE = (M_TDATA_WIDTH > 8),
    // tstrb signal width (words per cycle) on output interface
    parameter M_STRB_WIDTH  = ((M_TDATA_WIDTH + 7) / 8)
) (
    input                      clk,
    input                      rst,
    input  [S_TDATA_WIDTH-1:0] s_axis_tdata,
    input  [S_STRB_WIDTH-1:0]  s_axis_tstrb,
    input                      s_axis_tvalid,
    output                     s_axis_tready,
    input                      s_axis_tlast,
    input                      s_axis_tfirst,

    output [M_TDATA_WIDTH-1:0] m_axis_tdata,
    output [M_STRB_WIDTH-1:0]  m_axis_tstrb,
    output                     m_axis_tvalid,
    input                      m_axis_tready,
    output                     m_axis_tlast,
    output                     m_axis_tfirst
);

  // force strb width to 1 when disabled
  localparam S_BYTE_LANES = S_STRB_ENABLE ? S_STRB_WIDTH : 1;
  localparam M_BYTE_LANES = M_STRB_ENABLE ? M_STRB_WIDTH : 1;

  // bus byte sizes (must be identical)
  localparam S_BYTE_SIZE = S_TDATA_WIDTH / S_BYTE_LANES;
  localparam M_BYTE_SIZE = M_TDATA_WIDTH / M_BYTE_LANES;

  logic [S_STRB_WIDTH-1:0] s_axis_tstrb_int;
  assign s_axis_tstrb_int = S_STRB_ENABLE ? s_axis_tstrb : {S_STRB_WIDTH{1'b1}};

  generate
    if (M_BYTE_LANES == S_BYTE_LANES) begin : bypass
      // same width; bypass
      assign s_axis_tready = m_axis_tready;
      assign m_axis_tdata = s_axis_tdata;
      assign m_axis_tstrb  = (M_STRB_ENABLE && S_STRB_ENABLE) ? s_axis_tstrb : {M_STRB_WIDTH{1'b1}};
      assign m_axis_tvalid = s_axis_tvalid;
      assign m_axis_tlast = s_axis_tlast;
      assign m_axis_tfirst = s_axis_tfirst;
    end else if (M_BYTE_LANES > S_BYTE_LANES) begin : upsize
      // output is wider; upsize
      // required number of segments in wider bus
      localparam SEG_COUNT = M_BYTE_LANES / S_BYTE_LANES;
      // data width and strb width per segment
      localparam SEG_DATA_WIDTH = M_TDATA_WIDTH / SEG_COUNT;
      localparam SEG_STRB_WIDTH = M_BYTE_LANES / SEG_COUNT;

      logic [$clog2(SEG_COUNT)-1:0] seg_reg;
      logic [S_TDATA_WIDTH-1:0] s_axis_tdata_reg;
      logic [S_STRB_WIDTH-1:0] s_axis_tstrb_reg;
      logic s_axis_tvalid_reg;
      logic s_axis_tlast_reg;
      logic s_axis_tfirst_reg;
      logic [M_TDATA_WIDTH-1:0] m_axis_tdata_reg;
      logic [M_STRB_WIDTH-1:0] m_axis_tstrb_reg;
      logic m_axis_tvalid_reg;
      logic m_axis_tlast_reg;
      logic m_axis_tfirst_reg;

      assign s_axis_tready = !s_axis_tvalid_reg;
      assign m_axis_tdata = m_axis_tdata_reg;
      assign m_axis_tstrb  = M_STRB_ENABLE ? m_axis_tstrb_reg : {M_STRB_WIDTH{1'b1}};
      assign m_axis_tvalid = m_axis_tvalid_reg;
      assign m_axis_tlast = m_axis_tlast_reg;
      assign m_axis_tfirst = m_axis_tfirst_reg;

      always_ff @(posedge clk) begin
        m_axis_tvalid_reg <= m_axis_tvalid_reg && !m_axis_tready;
        if (!m_axis_tvalid_reg || m_axis_tready) begin
          // output register empty
          if (seg_reg == 0) begin
            m_axis_tdata_reg[seg_reg*SEG_DATA_WIDTH +: SEG_DATA_WIDTH] <= s_axis_tvalid_reg ? s_axis_tdata_reg : s_axis_tdata;
            m_axis_tstrb_reg <= s_axis_tvalid_reg ? s_axis_tstrb_reg : s_axis_tstrb_int;
          end else begin
            m_axis_tdata_reg[seg_reg*SEG_DATA_WIDTH +: SEG_DATA_WIDTH] <= s_axis_tdata;
            m_axis_tstrb_reg[seg_reg*SEG_STRB_WIDTH +: SEG_STRB_WIDTH] <= s_axis_tstrb_int;
          end
          m_axis_tlast_reg <= s_axis_tvalid_reg ? s_axis_tlast_reg : s_axis_tlast;
          m_axis_tfirst_reg <= s_axis_tvalid_reg ? s_axis_tfirst_reg : s_axis_tfirst;

          if (s_axis_tvalid_reg) begin
            // consume data from buffer
            s_axis_tvalid_reg <= 1'b0;

            if (s_axis_tlast_reg || seg_reg == SEG_COUNT - 1) begin
              seg_reg <= 0;
              m_axis_tvalid_reg <= 1'b1;
            end else begin
              seg_reg <= seg_reg + 1;
            end
          end else if (s_axis_tvalid) begin
            // data direct from input
            if (s_axis_tlast || seg_reg == SEG_COUNT - 1) begin
              seg_reg <= 0;
              m_axis_tvalid_reg <= 1'b1;
            end else begin
              seg_reg <= seg_reg + 1;
            end
          end
        end else if (s_axis_tvalid && s_axis_tready) begin
          // store input data in skid buffer
          s_axis_tdata_reg  <= s_axis_tdata;
          s_axis_tstrb_reg  <= s_axis_tstrb_int;
          s_axis_tvalid_reg <= 1'b1;
          s_axis_tlast_reg  <= s_axis_tlast;
          s_axis_tfirst_reg  <= s_axis_tfirst;
        end
        if (rst) begin
          seg_reg <= 0;
          s_axis_tvalid_reg <= 1'b0;
          m_axis_tvalid_reg <= 1'b0;
          m_axis_tdata_reg <= '0;
        end
      end
    end else begin : downsize
      // output is narrower; downsize

      // required number of segments in wider bus
      localparam SEG_COUNT = S_BYTE_LANES / M_BYTE_LANES;
      // data width and strb width per segment
      localparam SEG_DATA_WIDTH = S_TDATA_WIDTH / SEG_COUNT;
      localparam SEG_STRB_WIDTH = S_BYTE_LANES / SEG_COUNT;

      logic [S_TDATA_WIDTH-1:0] s_axis_tdata_reg;
      logic [S_STRB_WIDTH-1:0] s_axis_tstrb_reg;
      logic s_axis_tvalid_reg;
      logic s_axis_tlast_reg;
      logic s_axis_tfirst_reg;

      logic [M_TDATA_WIDTH-1:0] m_axis_tdata_reg;
      logic [M_STRB_WIDTH-1:0] m_axis_tstrb_reg;
      logic m_axis_tvalid_reg;
      logic m_axis_tlast_reg;

      assign s_axis_tready = !s_axis_tvalid_reg;

      assign m_axis_tdata = m_axis_tdata_reg;
      assign m_axis_tstrb  = M_STRB_ENABLE ? m_axis_tstrb_reg : {M_STRB_WIDTH{1'b1}};
      assign m_axis_tvalid = m_axis_tvalid_reg;
      assign m_axis_tlast = m_axis_tlast_reg;
      assign m_axis_tfirst = s_axis_tfirst_reg;

      always_ff @(posedge clk) begin
        m_axis_tvalid_reg <= m_axis_tvalid_reg && !m_axis_tready;
        if (!m_axis_tvalid_reg || m_axis_tready) begin
          // output register empty
          m_axis_tdata_reg <= s_axis_tvalid_reg ? s_axis_tdata_reg : s_axis_tdata;
          m_axis_tstrb_reg <= s_axis_tvalid_reg ? s_axis_tstrb_reg : s_axis_tstrb_int;
          m_axis_tlast_reg <= 1'b0;
          if (s_axis_tvalid_reg) begin
            // buffer has data; shift out from buffer
            s_axis_tdata_reg  <= s_axis_tdata_reg >> SEG_DATA_WIDTH;
            s_axis_tstrb_reg  <= s_axis_tstrb_reg >> SEG_STRB_WIDTH;
            m_axis_tvalid_reg <= 1'b1;
            if ((s_axis_tstrb_reg >> SEG_STRB_WIDTH) == 0) begin
              s_axis_tvalid_reg <= 1'b0;
              m_axis_tlast_reg  <= s_axis_tlast_reg;
            end
          end else if (s_axis_tvalid && s_axis_tready) begin
            // buffer is empty; store from input
            s_axis_tdata_reg  <= s_axis_tdata >> SEG_DATA_WIDTH;
            s_axis_tstrb_reg  <= s_axis_tstrb_int >> SEG_STRB_WIDTH;
            s_axis_tlast_reg  <= s_axis_tlast;
            s_axis_tfirst_reg  <= s_axis_tfirst;
            m_axis_tvalid_reg <= 1'b1;
            if (S_STRB_ENABLE && (s_axis_tstrb_int >> SEG_STRB_WIDTH) == 0) begin
              s_axis_tvalid_reg <= 1'b0;
              m_axis_tlast_reg  <= s_axis_tlast;
            end else begin
              s_axis_tvalid_reg <= 1'b1;
            end
          end
        end else if (s_axis_tvalid && s_axis_tready) begin
          // store input data
          s_axis_tdata_reg  <= s_axis_tdata;
          s_axis_tstrb_reg  <= s_axis_tstrb_int;
          s_axis_tvalid_reg <= 1'b1;
          s_axis_tlast_reg  <= s_axis_tlast;
          s_axis_tfirst_reg  <= s_axis_tfirst;
        end
        if (rst) begin
          s_axis_tvalid_reg <= 1'b0;
          m_axis_tvalid_reg <= 1'b0;
          s_axis_tfirst_reg <= 1'b0;
        end
        if(s_axis_tfirst_reg)
          s_axis_tfirst_reg <= 1'b0;
      end
    end
  endgenerate
endmodule
