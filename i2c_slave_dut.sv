module i2c_slave_dut #(
    parameter SLAVE_ADDRESS        = 7'h42,    // 7-bit default slave address
    parameter MEM_DEPTH            = 16,       // Size of internal data buffer
    parameter SUPPORT_GENERAL_CALL = 1,        // Enable support for general call (0x00)
    parameter SUPPORT_10BIT        = 1         // Enable support for 10-bit addressing
)(
    input  logic clk,             // System clock
    input  logic rst_n,           // Asynchronous active-low reset
    inout  tri   scl,             // I2C serial clock line (bidirectional)
    inout  tri   sda              // I2C serial data line (bidirectional)
);

        // FSM state definitions
    typedef enum logic [3:0] {
        IDLE,                // Wait for START
        START_DETECTED,      // START has been observed
        CHECK_ADDRESS,       // Check 7-bit address match
        EXT_ADDR_PHASE,      // Receive second byte for 10-bit address
        CHECK_10BIT,         // Validate full 10-bit address
        ACK_ADDRESS,         // Send ACK/NACK after address
        DATA_PHASE,          // Transfer data (read or write)
        ACK_DATA,            // Send ACK/NACK after data byte
        STOP_DETECTED        // STOP condition has occurred
    } i2c_state_t;

    // State machine registers
    i2c_state_t current_state, next_state;

    // SDA and SCL control signals
    logic sda_out;          // Value to drive onto SDA (0 or 1)
    logic sda_oe;           // Output enable for SDA (1 = drive, 0 = high-Z)
    logic scl_stretch;      // Clock stretching enable (1 = pull SCL low)

    // Drive SDA/SCL based on control signals
    assign sda = (sda_oe) ? sda_out : 1'bz; // Tri-state control for SDA
    assign scl = (scl_stretch) ? 1'b0 : 1'bz; // Tri-state control for SCL

    // Read values of SDA and SCL from the bus
    logic sda_in = sda;
    logic scl_in = scl;

    // Internal Registers
        // Shift register for collecting incoming bits
    logic [7:0] shift_reg;

    // Bit counter (0 to 8) for counting bits within a byte
    logic [3:0] bit_count;

    // Addressing flags
    logic rw_bit;                  // Read/Write flag (1 = read)
    logic is_10bit_mode;           // Indicates if current transaction uses 10-bit address
    logic general_call_detected;   // True when general call (0x00 address) is received
    logic [9:0] received_addr_10bit; // Stores full 10-bit address

    // Address match result and ACK control
    logic addr_matched;            // True if slave address matches DUT
    logic nack_next;               // Indicates a NACK should be sent on next ACK phase

    // Internal data buffer (multi-byte storage)
    logic [7:0] mem_buffer [0:MEM_DEPTH-1];
    logic [3:0] mem_ptr;           // Buffer read/write pointer

    // START/STOP Edge Detection
        // Track the previous SDA and SCL values to detect edges
    logic prev_sda, prev_scl;
    always_ff @(posedge clk) begin
        prev_sda <= sda_in;
        prev_scl <= scl_in;
    end

    // Detect I²C START condition: SDA falls while SCL is high
    wire start_condition_detected = (prev_sda == 1 && sda_in == 0 && scl_in == 1);

    // Detect I²C STOP condition: SDA rises while SCL is high
    wire stop_condition_detected  = (prev_sda == 0 && sda_in == 1 && scl_in == 1);
    
	// FSM Sequential
        // Sequential FSM: update the current state on each clock
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE; // Reset to idle
        else if (start_condition_detected && current_state != IDLE)
            current_state <= START_DETECTED; // Repeated START re-enters protocol flow
        else
            current_state <= next_state; // Normal FSM advance
    end

    // FSM Combinational
        // Combinational FSM: compute next_state based on current_state and inputs
    always_comb begin
        next_state = current_state; // Default hold state
        case (current_state)
            IDLE: if (start_condition_detected)
                next_state = START_DETECTED;

            START_DETECTED: if (bit_count == 8)
                next_state = (SUPPORT_10BIT && shift_reg[7:3] == 5'b11110)
                             ? EXT_ADDR_PHASE : CHECK_ADDRESS;

            CHECK_ADDRESS: if (addr_matched || general_call_detected)
                next_state = ACK_ADDRESS;
            else
                next_state = IDLE; // NACK and ignore transaction

            EXT_ADDR_PHASE: if (bit_count == 8)
                next_state = CHECK_10BIT;

            CHECK_10BIT: if (received_addr_10bit == SLAVE_ADDRESS)
                next_state = ACK_ADDRESS;
            else
                next_state = IDLE;

            ACK_ADDRESS: next_state = DATA_PHASE;

            DATA_PHASE: if (bit_count == 8)
                next_state = ACK_DATA;

            ACK_DATA: next_state = stop_condition_detected ? STOP_DETECTED : DATA_PHASE;

            STOP_DETECTED: next_state = IDLE;

            default: next_state = IDLE;
        endcase
    end

    // Bit Counter + Shifting
        // Bit counter for receiving/transmitting 8-bit sequences
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || current_state inside {ACK_DATA, ACK_ADDRESS})
            bit_count <= 0; // Reset counter during ACK phases
        else if (scl_in && current_state inside {START_DETECTED, EXT_ADDR_PHASE, DATA_PHASE})
            bit_count <= bit_count + 1; // Count bits on SCL high
    end

        // Shift register collects input bits serially via SDA
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= 0;
        else if (scl_in && current_state inside {START_DETECTED, EXT_ADDR_PHASE, DATA_PHASE})
            shift_reg <= {shift_reg[6:0], sda_in}; // Shift in new SDA bit
    end

    // Address Logic
        // Track address, R/W bit, and mode flags
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rw_bit <= 0;
            is_10bit_mode <= 0;
            general_call_detected <= 0;
        end
        else if (current_state == START_DETECTED && bit_count == 7) begin
            rw_bit <= shift_reg[0]; // Extract R/W bit
            // Check for 10-bit addressing prefix (11110xx)
            if (SUPPORT_10BIT && shift_reg[7:3] == 5'b11110) begin
                is_10bit_mode <= 1;
                received_addr_10bit[9:8] <= shift_reg[2:1]; // Save top 2 bits
            end
            else begin
                is_10bit_mode <= 0;
            end

            // General call is 0x00 with write
            if (SUPPORT_GENERAL_CALL && shift_reg[7:1] == 7'd0 && shift_reg[0] == 0)
                general_call_detected <= 1;
        end
        else if (current_state == EXT_ADDR_PHASE && bit_count == 8) begin
            received_addr_10bit[7:0] <= shift_reg; // Save second byte of 10-bit address
        end
        else if (current_state == STOP_DETECTED) begin
            general_call_detected <= 0; // Clear general call after transaction
        end
    end

    // Address match logic for 7-bit mode
    assign addr_matched = (!is_10bit_mode && shift_reg[7:1] == SLAVE_ADDRESS);
    
    // Compute whether to send NACK on next ACK
    assign nack_next = (!addr_matched && !general_call_detected);
    
	// Memory Buffer Logic
        // Memory pointer management (write/read offset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ptr <= 0;
        end
        else if (start_condition_detected) begin
            mem_ptr <= 0; // Reset on new transaction
        end
        else if (current_state == ACK_DATA) begin
            if (!rw_bit && mem_ptr < MEM_DEPTH) begin
                mem_buffer[mem_ptr] <= shift_reg; // On write, latch received byte
            end
            mem_ptr <= mem_ptr + 1; // Increment pointer for both read and write
        end
    end

    // SDA Output & ACK/NACK Handling — Unified Driver
        // Unified SDA driving block for data output and acknowledgments
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out <= 1'b1;
            sda_oe  <= 0;
        end else begin
            unique case (current_state)

                // Address/Data ACK phase
                ACK_ADDRESS, ACK_DATA: begin
                    if (nack_next) begin
                        sda_out <= 1'b1; // Release SDA (NACK)
                        sda_oe  <= 0;
                    end else begin
                        sda_out <= 1'b0; // Drive SDA low for ACK
                        sda_oe  <= 1;
                    end
                end

                // Read transfer phase: send byte to master MSB first
                DATA_PHASE: begin
                    if (rw_bit && bit_count < 8) begin
                        sda_out <= mem_buffer[mem_ptr][7 - bit_count]; // Output MSB→LSB
                        sda_oe  <= 1;
                    end else begin
                        sda_out <= 1'b1;
                        sda_oe  <= 0; // Tri-state after byte
                    end
                end

                // Default idle or transition states
                default: begin
                    sda_out <= 1'b1; // Default to high when not used
                    sda_oe  <= 0;
                end
            endcase
        end
    end

    // Optional: Clock Stretching
        // Simple clock stretching logic: if memory is full during a write,
    // or the slave needs time before it can ACK, hold SCL low.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            scl_stretch <= 0; // No stretching after reset
        else if ((current_state == DATA_PHASE || current_state == ACK_ADDRESS) &&
                 mem_ptr >= MEM_DEPTH)
            scl_stretch <= 1; // Activate stretching if buffer is full
        else if (current_state == ACK_DATA || stop_condition_detected)
            scl_stretch <= 0; // Release SCL after data ACK or transaction end
    end

endmodule

/* state diagram for i2c slave FSM
IDLE
│
├───▶ START_DETECTED
│         │
│         ├── 7-bit Address Phase
│         ├──▶ CHECK_ADDRESS
│         │         │
│         │         ├──▶ ACK_ADDRESS    (if matched or general call)
│         │         └──▶ IDLE           (if unmatched and NACK)
│         │
│         └──▶ EXT_ADDR_PHASE           (if 10-bit prefix detected)
│                   └──▶ CHECK_10BIT
│                          └──▶ ACK_ADDRESS / IDLE
│
├──▶ DATA_PHASE_WRITE / DATA_PHASE_READ
│         └──▶ ACK_DATA
│
├──▶ REPEATED_START_DETECTED
│         └──▶ START_DETECTED (re-entry)
│
└──▶ STOP_DETECTED
        └──▶ IDLE
		*/