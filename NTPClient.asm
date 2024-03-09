***********************************************************************************++
* NTPClient
*
* Minimum NTP client for C68 and SMSQ/E
*
* Needs installed Ethernet driver
*
************************************************************************************
                INCLUDE 'win1_assembler_qdos1_in'
                INCLUDE 'win1_assembler_qdos2_in'
                INCLUDE 'win1_assembler_macro_lib'

                INCLUDE 'dataspace_in'
                INCLUDE 'debug_mac'
                INCLUDE 'generic_mac'

NDEBUG          SETNUM  0                       ; flag = 1 : "NO DEBUG", and, for consistency ( 8): 
DEBUG           EQU     0                       ; flag = 1 : Write a log file

                SECTION Code
CodeStart:
Start:          JOBSTRT {'NTPClient'},RealStart
                VERSION {'NTP client for Q68 0.01 alpha'},{'tofro'}

RealStart       
                lea.l   0(a6,a4.l),a6                   ; let a6 point to data space

                moveq   #-1,d1
                moveq   #IO.OLD,d3
                lea     hostaddress,a0
                QDOSOC$ IO.OPEN
                
                tst.b   d0
                bne     errout
                rts


errout

hostaddress
                STRING$ {'udp_ntp.org:132'}
                
                END
