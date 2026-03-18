; This file is part of the TinyCore MicroKernel for the Foenix F256.
; Copyright 2022, 2023 Jessie Oberreuter <Gadget@HackwrenchLabs.com>.
; SPDX-License-Identifier: GPL-3.0-only

; As with the Linux Kernel Exception to the GPL3, programs
; built to run on the MicroKernel are expected to include
; this file.  Doing so does not affect their license status.

; Kernel Calls
; Populate the kernel.arg.* variables appropriately, and
; then JSR to one of the velctors below:

kernel      .namespace

            .virtual    $ff00

NextEvent   .fill   4   ; Copy the next event into user-space.
ReadData    .fill   4   ; Copy primary bulk event data into user-space
ReadExt     .fill   4   ; Copy secondary bolk event data into user-space
Yield       .fill   4   ; Give unused time to the kernel.
Putch       .fill   4   ; deprecated
RunBlock    .fill   4   ; Chain to resident program by block ID.
RunNamed    .fill   4   ; Chain to resident program by name.
Chdir       .fill   4   ; Change/get current working directory (buflen>0: chdir, buflen=0: getcwd)

BlockDevice .namespace
List        .fill   4   ; Returns a bit-set of available block-accessible devices.
GetName     .fill   4   ; Gets the hardware level name of the given block device or media.
GetSize     .fill   4   ; Get the number of raw sectors (48 bits) for the given device
Read        .fill   4   ; Read a raw sector (48 bit LBA)
Write       .fill   4   ; Write a raw sector (48 bit LBA)
Format      .fill   4   ; Perform a low-level format if the media support it.
Export      .fill   4   ; Update the FileSystem table with the partition table (if present).
            .endn

FileSystem  .namespace
List        .fill   4   ; Returns a bit-set of available logical devices.
GetSize     .fill   4   ; Get the size of the partition or logical device in sectors.
MkFS        .fill   4   ; Creates a new file-system on the logical device.
CheckFS     .fill   4   ; Checks the file-system for errors and corrects them.
Mount       .fill   4   ; Mark the file-system as available for File and Directory operations.
Unmount     .fill   4   ; Mark the file-system as unavailable for File and Directory operations.
ReadBlock   .fill   4   ; Read a partition-local raw sector on an unmounted device.
WriteBlock  .fill   4   ; Write a partition-local raw sector on an unmounted device.
            .endn

File        .namespace
Open        .fill   4   ; Open the given file for read, create, or append.
Read        .fill   4   ; Request bytes from a file opened for reading.
Write       .fill   4   ; Write bytes to a file opened for create or append.
Close       .fill   4   ; Close an open file.
Rename      .fill   4   ; Rename a closed file.
Delete      .fill   4   ; Delete a closed file.
Seek        .fill   4   ; Seek to a specific position in a file.
            .endn

Directory   .namespace
Open        .fill   4   ; Open a directory for reading.
Read        .fill   4   ; Read a directory entry; may also return VOLUME and FREE events.
Close       .fill   4   ; Close a directory once finished reading.
MkDir       .fill   4   ; Create a directory
RmDir       .fill   4   ; Delete a directory
            .endn
            
            .fill   4   ; call gate

Net         .namespace  ; These are changing!
GetIP       .fill   4   ; Get the local IP address.
SetIP       .fill   4   ; Set the local IP address.
GetDNS      .fill   4   ; Get the configured DNS IP address.
SetDNS      .fill   4   ; Set the configured DNS IP address.
SendICMP    .fill   4
Match       .fill   4

UDP         .namespace
Init        .fill   4
Send        .fill   4
Recv        .fill   4
            .endn

TCP         .namespace
Open        .fill   4
Accept      .fill   4
Reject      .fill   4
Send        .fill   4
Recv        .fill   4
Close       .fill   4
            .endn

            .endn
            
Display     .namespace
Reset       .fill   4   ; Re-init the display
GetSize     .fill   4   ; Returns rows/cols in kernel args.
DrawRow     .fill   4   ; Draw text/color buffers left-to-right
DrawColumn  .fill   4   ; Draw text/color buffers top-to-bottom
            .endn

Clock       .namespace
GetTime     .fill   4
SetTime     .fill   4
            .fill   12  ; 65816 vectors
SetTimer    .fill   4
            .endn

            .endv            

; Kernel Call Arguments
; Populate the structure before JSRing to the associated vector.

            .virtual    $00f0   ; Arg block
args        .dstruct    args_t
            .cerror     * > $00ff, "Out of kernel arg space."
            .endv            

args_t      .struct

events      .dstruct    event_t ; The GetNextEvent dest address is globally reserved.

            .union
run         .dstruct    run_t
recv        .dstruct    recv_t
fs          .dstruct    fs_t
file        .dstruct    file_t
directory   .dstruct    dir_t
display     .dstruct    display_t
net         .dstruct    net_t
config      .dstruct    config_t
timer       .dstruct    timer_t
            .endu

ext         = $f8
extlen      = $fa
buf         = $fb
buflen      = $fd
ptr         = $fe
            .ends

          ; Event calls
event_t     .struct
dest        .word       ?   ; GetNextEvent copies event data here
pending     .byte       ?   ; Negative count of pending events
end         .ends

          ; Generic recv
recv_t      .struct
buf         = args.buf
buflen      = args.buflen
            .ends

          ; Run Calls
run_t       .struct
block_id    .byte   ?
            .ends

          ; FileSystem Calls
fs_t        .struct
            .union
format      .dstruct    fs_mkfs_t
mkfs        .dstruct    fs_mkfs_t
            .endu
            .ends
fs_mkfs_t .struct
drive       .byte       ?
cookie      .byte       ?
label       = args.buf
label_len   = args.buflen
            .ends
    
          ; File Calls
file_t      .struct
            .union
open        .dstruct    fs_open_t
read        .dstruct    fs_read_t
write       .dstruct    fs_write_t
seek        .dstruct    fs_seek_t
close       .dstruct    fs_close_t
rename      .dstruct    fs_rename_t
delete      .dstruct    fs_open_t
            .endu
            .ends            
fs_open_t   .struct
drive       .byte       ?
cookie      .byte       ?
fname       = args.buf
fname_len   = args.buflen
mode        .byte       ?
READ        = 0
WRITE       = 1
END         = 2
            .ends
fs_read_t   .struct
stream      .byte       ?
buflen      .byte       ?
            .ends
fs_write_t  .struct
stream      .byte       ?
buf         = args.buf
buflen      = args.buflen
            .ends
fs_seek_t  .struct
stream      .byte       ?
position    .dword      ?
            .ends
fs_close_t  .struct
stream      .byte       ?
            .ends
fs_rename_t .struct
drive       .byte       ?
cookie      .byte       ?
old         = args.buf
old_len     = args.buflen
new         = args.ext
new_len     = args.extlen
            .ends
fs_delete_t .struct
drive       .byte       ?
cookie      .byte       ?
fnane       = args.buf
fname_len   = args.buflen
            .ends


          ; Directory Calls
dir_t       .struct
            .union
open        .dstruct    dir_open_t
read        .dstruct    dir_read_t
close       .dstruct    dir_close_t
mkdir       .dstruct    dir_open_t
rmdir       .dstruct    dir_open_t
            .endu
            .ends            
dir_open_t  .struct
drive       .byte       ?
cookie      .byte       ?
path        = args.buf
path_len    = args.buflen
            .ends
dir_read_t  .struct
stream      .byte       ?
buflen      .byte       ?
            .ends
dir_close_t .struct
stream      .byte       ?
            .ends

          ; Drawing Calls
display_t   .struct
x           .byte       ?   ; coordinate or size
y           .byte       ?   ; coordinate or size
text        = args.buf      ; text
color       = args.ext      ; color
buf         = args.buf      ; deprecated
buf2        = args.ext      ; deprecated
buflen      = args.buflen
            .ends

          ; Net calls
net_t       .struct

socket      = args.buf

            ; Arguments
            .union

           ; Init
            .struct
src_port    .word       ?
dest_port   .word       ?
dest_ip     .fill       4            
            .ends            
            
           ; Send / Recv
            .struct
accepted    .byte       ?            
buf         = args.ext
buflen      = args.extlen
            .ends

            .endu
            .ends

config_t    .struct
            .union
            .endu
            .ends

timer_t     .struct
units       .byte       ?
FRAMES      = 0
SECONDS     = 1
QUERY       = 128
absolute    .byte       ?
cookie      .byte       ?
            .ends
                                      
time_t      .struct
century     .byte       ?
year        .byte       ?
month       .byte       ?
day         .byte       ?
hours       .byte       ?
minutes     .byte       ?
seconds     .byte       ?
centis      .byte       ?
size        .ends

; Events
; The vast majority of kernel operations communicate with userland
; by sending events; the data contained in the various events are
; described following the event list.

event       .namespace

            .virtual 0
            .word   ?   ; Reserved
            .word   ?   ; Deprecated
JOYSTICK    .word   ?   ; Game Controller changes.
DEVICE      .word   ?   ; Device added/removed.

key         .namespace
PRESSED     .word   ?   ; Key pressed
RELEASED    .word   ?   ; Key released.
            .endn

mouse       .namespace
DELTA       .word   ?   ; Regular mouse move and button state
CLICKS      .word   ?   ; Click counts
            .endn

block       .namespace
NAME        .word   ?
SIZE        .word   ?
DATA        .word   ?   ; The read request has succeeded.
WROTE       .word   ?   ; The write request has completed.
FORMATTED   .word   ?   ; The low-level format has completed.
ERROR       .word   ?
            .endn

fs          .namespace
SIZE        .word   ?
CREATED     .word   ?
CHECKED     .word   ?
DATA        .word   ?   ; The read request has succeeded.
WROTE       .word   ?   ; The write request has completed.
ERROR       .word   ?
            .endn

file        .namespace
NOT_FOUND   .word   ?   ; The file file was not found.
OPENED      .word   ?   ; The file was successfully opened.
DATA        .word   ?   ; The read request has succeeded.
WROTE       .word   ?   ; The write request has completed.
EOF         .word   ?   ; All file data has been read.
CLOSED      .word   ?   ; The close request has completed.
RENAMED     .word   ?   ; The rename request has completed.
DELETED     .word   ?   ; The delete request has completed.
ERROR       .word   ?   ; An error occured; close the file if opened.
SEEK        .word   ?   ; The seek request has completed.
            .endn

directory   .namespace
OPENED      .word   ?   ; The directory open request succeeded.
VOLUME      .word   ?   ; A volume record was found.
FILE        .word   ?   ; A file record was found.
FREE        .word   ?   ; A file-system free-space record was found.
EOF         .word   ?   ; All data has been read.
CLOSED      .word   ?   ; The directory file has been closed.
ERROR       .word   ?   ; An error occured; user should close.
CREATED     .word   ?   ; The directory has been created.
DELETED     .word   ?   ; The directory has been deleted.
            .endn

net         .namespace            
TCP         .word   ?
UDP         .word   ?
            .endn

timer       .namespace
EXPIRED     .word   ?
            .endn

clock       .namespace
TICK        .word   ?
            .endn

irq         .namespace
IRQ         .word   ?
            .endn

            .endv

event_t     .struct
type        .byte   ?   ; Enum above
buf         .byte   ?   ; page id or zero
ext         .byte   ?   ; page id or zero
            .union
key         .dstruct    kernel.event.key_t
mouse       .dstruct    kernel.event.mouse_t
joystick    .dstruct    kernel.event.joystick_t
udp         .dstruct    kernel.event.udp_t
tcp         .dstruct    kernel.event.tcp_t
file        .dstruct    kernel.event.file_t
directory   .dstruct    kernel.event.dir_t
timer       .dstruct    kernel.event.timer_t
irq         .dstruct    kernel.event.irq_t
            .endu
            .ends
                 
          ; Data in keyboard events
key_t       .struct
keyboard    .byte   ?   ; Keyboard ID
raw         .byte   ?   ; Raw key ID
ascii       .byte   ?   ; ASCII value
flags       .byte   ?   ; Flags (META)
META        = $80       ; Meta key; no associated ASCII value.
            .ends    
            
          ; Data in mouse events
mouse_t     .struct
            .union
delta       .dstruct    kernel.event.m_delta_t
clicks      .dstruct    kernel.event.m_clicks_t
            .endu
            .ends
m_delta_t   .struct
x           .byte   ?
y           .byte   ?
z           .byte   ?
buttons     .byte   ?
            .ends
m_clicks_t  .struct
inner       .byte   ?
middle      .byte   ?
outer       .byte   ?
            .ends            

joystick_t  .struct
joy0        .byte   ?
joy1        .byte   ?
            .ends

          ; Data in file events:
file_t      .struct
stream      .byte   ?
cookie      .byte   ?
            .union
data        .dstruct    kernel.event.fs_data_t
wrote       .dstruct    kernel.event.fs_wrote_t
            .endu
            .ends
fs_data_t   .struct     ; ext contains disk id
requested   .byte   ?   ; Requested number of bytes to read
read        .byte   ?   ; Number of bytes actually read
            .ends
fs_wrote_t  .struct     ; ext contains disk id
requested   .byte   ?   ; Requested number of bytes to read
wrote       .byte   ?   ; Number of bytes actually read
            .ends

          ; Data in directory events:
dir_t       .struct
stream      .byte   ?
cookie      .byte   ?
            .union
volume      .dstruct    kernel.event.dir_vol_t
file        .dstruct    kernel.event.dir_file_t
free        .dstruct    kernel.event.dir_free_t
            .endu
            .ends
dir_vol_t   .struct     ; ext contains disk id
len         .byte   ?   ; Length of volname (in buf)
flags       .byte   ?   ; block size, text encoding
            .ends
dir_file_t  .struct     ; ext contains byte count and modified date
len         .byte   ?
flags       .byte   ?   ; block scale, text encoding, approx size
            .ends
dir_free_t  .struct     ; ext contains byte count and modified date
flags       .byte   ?   ; block scale, text encoding, approx size
            .ends
dir_ext_t   .struct     ; Extended information; more to follow.
free        .fill   6   ; blocks used/free
            .ends

          ; Data in net events (major changes coming)
udp_t       .struct
token       .byte   ?   ; TODO: break out into fields
            .ends

tcp_t       .struct
len         .byte   ?   ; Raw packet length.
            .ends

timer_t     .struct
value       .byte   ?
cookie      .byte   ?
            .ends

irq_t       .struct
group       .byte   ?
bitval      .byte   ?
            .ends

            .endn


            .endn
