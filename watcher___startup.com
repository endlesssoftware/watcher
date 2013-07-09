$ ! Procedure:  WATCHER___STARTUP.COM
$ __vfy = "VFY_''f$parse(f$environment("procedure"),,,"name")'"
$ if (f$type('__vfy') .eqs. "") then __vfy = 0
$ __vfy_saved = f$verify(&__vfy)
$
$err: subroutine
$ set noon
$ severity = f$edit(P1,"COLLAPSE,UPCASE")
$ identification = f$edit(P2,"COLLAPSE,UPCASE")
$ text = f$edit(P3,"TRIM")
$ continuation = (f$edit(P4,"COLLAPSE,UPCASE") .nes. "")
$ say = "write sys$output"
$ percent = "%"
$ if (continuation) then percent = "-"
$ if ((severity .eqs. "") .or. (identification .eqs. "") .or. (text .eqs. ""))
$ then say "%''facility'-F-SPOTTHEERR, <''severity'><''identification'><''text'>"
$ else say "''percent'''facility'-''severity'-''identification', ''text'"
$ endif
$ exitt 1
$ endsubroutine
$
$ procedure = f$element(0,";",f$environment("PROCEDURE"))
$ procedure_name = f$parse(procedure,,,"NAME")
$ facility = procedure_name
$ location = f$parse(procedure,,,"DEVICE","NO_CONCEAL") -
                + f$parse(procedure,,,"DIRECTORY","NO_CONCEAL") -
                - "][" - ".]" - "]"
$
$ set noon
$ set symbol/scope=(nolocal)
$ on warning then goto bail_out
$ on control_y then goto bail_out
$
$ if ((f$getsyi("HW_MODEL") .gt. 0) .and. (f$getsyi("HW_MODEL") .lt. 1024))
$ then _arch_type = 1
$ else _arch_type = f$getsyi("ARCH_TYPE")
$ endif
$ _arch_name = f$element(_arch_type,",","OTHER,VAX,AXP,I64") - ","
$ _vax = (_arch_type .eq. 1)
$ _axp = (_arch_type .eq. 2)
$ _i64 = (_arch_type .eq. 3)
$ _other = (.not. (_vax .or. _axp .or. _i64))
$
$check_quota: subroutine
$ symbol = f$edit(p1,"UPCASE,COLLAPSE,TRIM,UNCOMMENT")
$ default = f$edit(p2,"UPCASE,COLLAPSE,TRIM,UNCOMMENT")
$ if (f$type('symbol') .eqs. "")
$ then
$   'symbol' == 'default'
$ else
$   if ('symbol' .lt. 'default') then
$     'symbol' == 'default'
$ endif
$ exit 1
$ endsubroutine
$
$ dns = "define/executive/nolog/system"
$ say = "write sys$output"
$ err = "call___ err"
$ saysym = "write/symbol sys$output"
$ check_quota = "call___ check_quota"
$
$start:
$ dns/trans=concealed	WATCHER_ROOT	'location'.]
$ dns			WATCHER_AXP_EXE	WATCHER_ROOT:[AXP_EXE]
$ dns			WATCHER_I64_EXE	WATCHER_ROOT:[I64_EXE]
$ dns			WATCHER_VAX_EXE	WATCHER_ROOT:[VAX_EXE]
$ dns			WATCHER_EXE	WATCHER_'_arch_name'_EXE
$ dns			WATCHER_DIR	WATCHER_ROOT:[000000],WATCHER_EXE
$
$ dns 			WATCHER_CONFIG	WATCHER_DIR:WATCHER_CONFIG.WCFG
$ dns 			WATCHER_LOG	WATCHER_DIR:WATCHER.LOG
$
$ if (f$search("SYS$STARTUP:WATCHER_SYSTARTUP.COM") .nes. "")
$ then
$   @SYS$STARTUP:WATCHER_SYSTARTUP.COM
$ else
$   if (f$search("WATCHER_DIR:WATCHER_SYSTARTUP.COM") .nes. "") then -
$     @WATCHER_DIR:WATCHER_SYSTARTUP.COM
$ endif
$
$ if (f$edit(p1,"UPCASE,TRIM,UNCOMMENT,COLLAPSE") .eqs. "LOGICALS") then -
$   goto bail_out
$
$ if (f$search("WATCHER_DIR:WATCHER.LOG;-1") .nes. "") then -
$   purge/keep=5 WATCHER_DIR:WATCHER.LOG
$
$! Need to test for these symbols and define to the default values below,
$! if they are not...don't allow them to be set below these values...
$
$ check_quota watcher_ast_limit 	50
$ check_quota watcher_buffer_limit 	2048
$ check_quota watcher_enque_limit	10
$ check_quota watcher_extent 		2048
$ check_quota watcher_io_buffered 	32
$ check_quota watcher_io_direct		32
$ check_quota watcher_file_limit	10
$ check_quota watcher_page_file		16384
$ check_quota watcher_queue_limit	50
$
$ run/detached/output=NL:/process="Watcher"-
     /ast='watcher_ast_limit'/buffer='watcher_buffer_limit'-
     /file_limit='watcher_file_limit'/io_buffered='watcher_io_buffered'-
     /io_direct='watcher_io_direct'/job_table=0-
     /maximum_working_set=512/time_limit=0/page_file='watcher_page_file'-
     /queue_limit='watcher_queue_limit'/enque='watcher_enque_limit'-
     /extent='watcher_extent'-
     /priv=(nosame,tmpmbx,netmbx,oper,world,share,sysnam,-
    	    prmmbx,sysprv,cmkrnl,pswapm)-
     /input=WATCHER_DIR:WATCHER.COM -
     /output=WATCHER_LOG: -
     SYS$SYSTEM:LOGINOUT.EXE
$
$bail_out:
$ exitt 1.or.(0*f$verify(__vfy_saved))
$ !+==========================================================================
$ !
$ !  FACILITY:   WATCHER
$ !
$ !  ABSTRACT:   WATCHER system startup procedure.
$ !
$ !  AUTHOR:         Tim Sneddon
$ !
$ !  Copyright (c) 2013, Endless Software Solutions.
$ !
$ !  All rights reserved.
$ !
$ !  Redistribution and use in source and binary forms, with or without
$ !  modification, are permitted provided that the following conditions
$ !  are met:
$ !
$ !      * Redistributions of source code must retain the above
$ !        copyright notice, this list of conditions and the following
$ !        disclaimer.
$ !      * Redistributions in binary form must reproduce the above
$ !        copyright notice, this list of conditions and the following
$ !        disclaimer in the documentation and/or other materials provided
$ !        with the distribution.
$ !      * Neither the name of the copyright owner nor the names of any
$ !        other contributors may be used to endorse or promote products
$ !        derived from this software without specific prior written
$ !        permission.
$ !
$ !  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
$ !  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
$ !  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
$ !  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
$ !  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
$ !  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
$ !  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
$ !  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
$ !  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
$ !  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
$ !  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
$ !
$ !  CREATION DATE:  10-MAY-2013
$ !
$ !  MODIFICATION HISTORY:
$ !
$ !      10-MAY-2013 V1.0    Sneddon     Initial coding.
$ !-==========================================================================
