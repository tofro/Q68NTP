#
# Flappy Bird for the Q68
#
# Assumptions:
#   DATA_USE points to Device/Directory holding the Sources
#   LINK_TARGET environment variable holds the name of the binary to create
#
# Program filenames
#
ASM  = win1_assembler_qmac
LK   = win1_assembler_qlink
MK   = win1_c68_make
SH   = win1_c68_sh
TC   = win1_c68_touch
RM   = win1_c68_rm

#
# Assembler command line options
#
ASMCMD   = -list -link 
LINK_TARGET = ram1_flappy_exe
MAPFILE = ram1_flappy_map
LINK_OPTIONS= -prog ${LINK_TARGET} -list ${MAPFILE} -crf -filetype 1

D = dos2_flappy_
L = win1_assembler_

#
# Input files
#

# All other files
OBJS = rect_rel vline_rel \
      FlappyRedFlapQPC_rel FlappyRedQPC_rel \
      GameOverQPC_rel GetReadyQPC_rel

# The rel file that is the "main program" (and thus goes first...)
MAIN_OBJ = flappy_rel

VER = ver_in

default: ${MAIN_OBJ} ${OBJS}
  ${LK} ${MAIN_OBJ} link ${LINK_TARGET} ${LINK_OPTIONS}
clean:
  ${RM} ${MAIN_OBJ} ${OBJS} ${LINK_TARGET} ${MAPFILE} *_bin *_list ram1_err *.list *.rel

#
# Header file dependencies
#
flappy_rel:     dataspace_in flappy_asm debug_mac generic_mac
rect_rel:       rect_asm generic_mac dataspace_in debug_mac
vline_rel:      vline_asm generic_mac dataspace_in debug_mac
flappy_rel:     flappy_asm generic_mac dataspace_in debug_mac

#
# Rule for turning _asm into _rel files
#
_asm_rel:
    ${ASM} $C$*_asm ${ASMCMD}
.asm.rel:
    ${ASM} $C$*.asm ${ASMCMD}
