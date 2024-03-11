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
                clr.w   retries(a6)
retry
                DEBUG   {'Attempt to connect socket'}
                add.w   #1,retries(a6)
                move.w  maxRetries,d7
                cmp.w   retries(a6),d7                  ; number of retries exceeded?
                beq     errOut
                moveq   #-1,d1
                moveq   #IO.OLD,d3
                lea     hostaddress,a0
                QDOSOC$ IO.OPEN
          
                tst.b   d0
                bne     retry

                move.l  a0,netChannel(a6)

                DEBUG   {'Successful connect'}
                clr.w   retries(a6)

retrySend
                add.w   #1,retries(a6)
                move.w  maxRetries,d7
                cmp.w   retries(a6),d7                  ; number of retries exceeded?
                beq.s   errOut

                jsr     sendRequest                     ; send the request packet
                tst.b   d0
                bne.s   retrySend
                tst.b   d0
                bne     errout

                DEBUG   {'Request sent'}

                move.w  #48,d2
                lea     connectTO,a0                    ; how long to wait for receiving
                move.w  (a0),d3
                move.l  netChannel(a6),a0
                lea     packetBuffer(a6),a1
                move.l  #48,d2 

                QDOSIO$ IO.FSTRG

                cmp.l   #48,d1                          ; if we have 48 bytes or more, we're happy
                bge.s   recOK
                bra.s   retrySend                       ; otherwise, send request again
recOK   
                DEBUG   {'Received answer'}
                lea     packetBuffer(a6),a1             ; back to start of buffer
                move.l  32(a1),d1                       ; get time in seconds since 1.1.1900
        
DIFFTIME        EQU     $726CF4E0                       ; difference in seconds to 1.1.1961
                ; EQU     61*364.25*24*60*60            ; difference in seconds to 1.1.1961
                add.l   #DIFFTIME,d1
                DEBUG   {'Setting time'}
                QDOSMT$ MT.SCLCK                        ; set the clock

                bra     OKExit


errout
                DEBUG   {'Error exit'}
                move.l  channelId(a6),a0
                move.w  UT.ERR,a1
                jsr     (a1)
                bra     exitProg

OKExit
                DEBUG   {'OK exit'}
                lea     signoff,a1
                move.w  (a1)+,d2
                moveq   #-1,d3
                QDOSIO$ IO.SSTRG
exitProg
                moveq   #-1,d1
                move.l  #100,d3                 ; wait 2s for signoff mesg
                sub.l   a1,a1
                QDOSMT$ MT.SUSJB

                moveq   #-1,d1
                moveq   #0,d3
                QDOSMT$ MT.FRJOB

forever
                DEBUG   {'After MT.FRJOB'}
                bra.s   forever                ; should never be reached


sendRequest
                DEBUG   {'Preparing request packet'}
                lea     requestPacket,a1
                move.w  #requestPacketEnd-requestPacket,d2
                lea     connectTO,a0                    ; how long to wait for sending
                move.w  (a0),d3
                
                move.l  netChannel(a6),a0
                QDOSIO$ IO.SSTRG
                DEBUG   {'request packet sent'}
                rts

windowName
                STRING$ {'con_140x15a1x10'}

signoff
                STRING$ {'NTP client exiting'}      


; The following need to go into a config block later
maxRetries
                dc.w    5
connectTO       
                dc.w    10*50                   ; how long (s) to wait for a connection
hostaddress
                STRING$ {'udp_192.168.178.3:123'}
;                STRING$ {'udp_pool.ntp.org:123'}
  
requestPacket
                dc.l    %00011011000011111111111100000000
                dc.l    0,0,0
                dc.l    0,0,0,0,0,0,0,0
requestPacketEnd
                END
