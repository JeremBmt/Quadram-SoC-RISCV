/*
  Description: Single-cycle RISC-V processor (RV32IM) interfaced with QuadRAM
  Modification: Ajout d'un cycle d'attente pour la synchronisation de lecture mémoire
*/

module system #(
    parameter DataWidth = 32,            // Largeur des registres internes
    parameter AddrWidth = 12,            // Largeur du bus d'adresse QuadRAM (12 bits = 4096 octets)
    parameter MemSize   = 1 << AddrWidth // Taille de la mémoire d'instructions
)(
    input  wire                  clk,
    input  wire                  reset,

    // Bus vers le composant QuadRAM externe
    output reg  [AddrWidth-1:0]  data_addr, // Adresse externe (12 bits)
    output reg  [7:0]            data_out,  // Donnée à écrire (8 bits)
    input  wire [7:0]            data_in,   // Donnée lue depuis la QuadRAM (8 bits)
    output reg                   we         // Write Enable externe
);

  localparam InstrSize = 32;
  localparam NRegs     = 32;

  // États pour la machine à états de lecture
  localparam FETCH_EXEC = 1'b0;
  localparam WAIT_DATA  = 1'b1;
  reg state;

  // Mémoire d'instructions interne
  reg  [DataWidth-1:0] memory[0:MemSize-1];
  wire [InstrSize-1:0] instr;              // Déclaré en wire pour lecture immédiate
  reg  [AddrWidth-1:0] pc;
  reg  [DataWidth-1:0] regs[0:NRegs-1];

  // Assignation combinatoire : l'instruction dépend du PC actuel
  assign instr = memory[pc];

  /* Décodage RISC-V */
  `define OPCODE  instr[6:0]
  `define F3      instr[14:12]
  `define F7      instr[31:25]

  `define RS1     instr[19:15]
  `define RS2     instr[24:20]
  `define RD      instr[11:7]

  `define I_IMM   $signed(instr[31:20])
  `define S_IMM   $signed(instr[31:25] << 5 | instr[11:7])

  `define LOAD_OFFSET  instr[31:20]
  `define STORE_OFFSET (instr[31:25] << 5 | instr[11:7])

  /* Opcodes */
  `define ARITHMETIC     7'b0110011
  `define IMM_ARITHMETIC 7'b0010011
  `define LOAD           7'b0000011
  `define STORE          7'b0100011
  `define EBREAK         7'b1110011

  /* Instructions */
  `define ADD   {3'b000, 7'b0000000}
  `define SUB   {3'b000, 7'b0100000}
  `define SLL   {3'b001, 7'b0000000}
  `define SRL   {3'b101, 7'b0000000}
  `define MUL   {3'b000, 7'b0000001}
  `define DIV   {3'b100, 7'b0000001}

  `define LW    3'b010
  `define SW    3'b010

  `define ADDI  3'b000
  `define ANDI  3'b111
  `define ORI   3'b110

  integer index;

  // Chargement du fichier programme
  initial begin
    $readmemh("instr2.txt", memory);
  end

  // Exécution matérielle synchrone sur front d'horloge
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      pc        <= 0;
      data_addr <= 0;
      data_out  <= 0;
      we        <= 1'b0;
      state     <= FETCH_EXEC;
      for (index = 0; index < NRegs; index = index + 1) begin
        regs[index] <= 0;
      end
    end else begin
      we <= 1'b0; // Par défaut pas d'écriture en mémoire

      if (state == WAIT_DATA) begin
        // --- CYCLE 2 DU LOAD : La mémoire a fourni la donnée ---
        regs[`RD] <= {24'b0, data_in}; // On stocke la donnée dans le registre cible
        pc        <= pc + 1'b1;        // On incrémente enfin le PC
        state     <= FETCH_EXEC;       // On retourne au cycle normal d'exécution
      end else begin
        // --- CYCLE NORMAL : Fetch et Exécution ---
        case (`OPCODE)
          `LOAD: begin
            case (`F3)
              `LW: begin
                // On présente l'adresse sur le bus externe
                data_addr <= `LOAD_OFFSET + regs[`RS1][AddrWidth-1:0];
                state     <= WAIT_DATA; // On gèle le PC et on attend le cycle suivant
              end
              default: $display("erreur: mauvaise instruction load");
            endcase
          end

          `ARITHMETIC: begin
            pc <= pc + 1'b1; // Incrémentation pour les instructions qui ne bloquent pas
            case ({`F3, `F7})
              `ADD: regs[`RD] <= regs[`RS1] + regs[`RS2];
              `SUB: regs[`RD] <= regs[`RS1] - regs[`RS2];
              `SRL: regs[`RD] <= regs[`RS1] >> regs[`RS2][4:0];
              `SLL: regs[`RD] <= regs[`RS1] << regs[`RS2][4:0];
              `MUL: regs[`RD] <= regs[`RS1] * regs[`RS2];
              `DIV: regs[`RD] <= (regs[`RS2] == 0) ? -1 : ($signed(regs[`RS1]) / $signed(regs[`RS2]));
              default: $display("erreur: mauvaise instruction arithmetique");
            endcase
          end

          `IMM_ARITHMETIC: begin
            pc <= pc + 1'b1;
            case (`F3)
              `ADDI: regs[`RD] <= regs[`RS1] + `I_IMM;
              `ANDI: regs[`RD] <= regs[`RS1] & `I_IMM;
              `ORI:  regs[`RD] <= regs[`RS1] | `I_IMM;
              default: $display("erreur: mauvaise instruction arithmetique immediate");
            endcase
          end

          `STORE: begin
            pc <= pc + 1'b1;
            case (`F3)
              `SW: begin
                data_addr <= `STORE_OFFSET + regs[`RS1][AddrWidth-1:0];
                data_out  <= regs[`RS2][7:0];
                we        <= 1'b1;
              end
              default: $display("erreur: mauvaise instruction store");
            endcase
          end

          `EBREAK: begin
            $display("Fin d'execution detectee via EBREAK");
            $stop;
          end

          default: begin
            pc <= pc + 1'b1;
            $display("erreur: mauvaise valeur dans op-code");
          end
        endcase
      end
    end
  end

endmodule
