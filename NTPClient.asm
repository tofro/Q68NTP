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

                lea     windowDef,a1
                move.w  UT.CON,a2
                jsr     (a2)

                move.l  a0,channelId(a6)
                move.w  UT.MTEXT,a2
                lea     signon,a1
                jsr     (a2)

                clr.w   retries(a6)
retry
                add.w   #1,retries(a6)
                move.w  maxRetries,d7
                cmp.w   retries(a6),d7                  ; number of retries exceeded?
                beq     errOut
                moveq   #-1,d1
                moveq   #IO.SHARE,d3                    ; we're a UDP client
                lea     hostaddress,a0
                QDOSOC$ IO.OPEN
          
                tst.b   d0
                bne     retry

                move.l  a0,netChannel(a6)

                clr.w   retries(a6)

retrySend
                add.w   #1,retries(a6)
                move.w  maxRetries,d7
                cmp.w   retries(a6),d7                  ; number of retries exceeded?
                beq     errOut

                jsr     sendRequest                     ; send the request packet
                tst.b   d0
                bne.s   retrySend

                lea     connectTO,a0                    ; how long to wait for receiving
                move.w  (a0),d3
                move.l  netChannel(a6),a0
                lea     packetBuffer(a6),a1
                move.l  #48,d2 

                QDOSIO$ IO.FSTRG
                DEBUG   {'Received answer'}

                cmp.l   #48,d1                          ; if we have 48 bytes or more, we're happy
                bge.s   recOK
                bra.s   retrySend                       ; otherwise, send request again
recOK   
                lea     packetBuffer(a6),a1             ; back to start of buffer
                move.l  32(a1),d7                       ; get time in seconds since 1.1.1900
        
                move.l  channelId(a6),a0
                move.w  UT.MTEXT,a2
                lea     setTime,a1
                jsr     (a2)

; NTP times come in seconds since 1.1.1900. QL time is seconds since 1.1.1961 (for  whatever reason)
; we need to subtract (61*365 + 15 (leap years))*86400 = 1924992000
DIFFTIME        EQU     1924992000                      ; difference in seconds to 1.1.1961
                sub.l   #DIFFTIME,d7
                add.l   utcOfs,d7                       ; add time zone offset (NTP delivers UTC)
                move.l  d7,d1
                DEBUG   {'Setting time'}
                QDOSMT$ MT.SCLCK                        ; set the clock

                bra     OKExit


errout
                DEBUG   {'Error exit'}
                move.l  channelId(a6),a0
                move.w  UT.ERR,a2
                jsr     (a2)
                bra     exitProg

OKExit
                DEBUG   {'OK exit'}
                move.l  channelId(a6),a0
                lea     signoff,a1
                move.w  UT.MTEXT,a2
                jsr     (a2)

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
                lea     requestPacket,a1
                move.w  #requestPacketEnd-requestPacket,d2
                lea     connectTO,a0                    ; how long to wait for sending
                move.w  (a0),d3
                
                move.l  netChannel(a6),a0
                QDOSIO$ IO.SSTRG
                rts

windowDef
                dc.b    4               ; Border
                dc.b    1               ; border width
                dc.b    0               ; paper
                dc.b    7               ; ink
                dc.w    140
                dc.w    20
                dc.w    10
                dc.w    10
signon
                STRING$ {'Q68 NTP Client',10}
                dc.w    0
setTime 
                STRING$ {'Setting time',10}
                dc.w    0
signoff
                STRING$ {'Time set',10}      
                dc.w    0

; The following need to go into a config block later
maxRetries
                dc.w    5
connectTO       
                dc.w    10*50                   ; how long (s) to wait for a connection
hostaddress
;                STRING$ {'udp_192.168.178.3:123'}
;                STRING$ {'udp_91.229.245.70:123'}
                STRING$ {'udp_pool.ntp.org:123'}
                dc.w    0

utcOfs          dc.l    60*60                   ; 1 hour offset
                dc.w    0

requestPacket
                dc.l    $e3000800
                dc.l    0,0,0
                dc.l    0,0,0,0,0,0,0,0
requestPacketEnd
                END
