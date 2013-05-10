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
$ dns = "define/executive/nolog/system"
$ say = "write sys$output"
$ err = "call___ err"
$ saysym = "write/symbol sys$output"
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
$ if (f$trnlnm("WATCHER_TRACE","LNM$SYSTEM_DIRECTORY","EXECUTIVE") .eqs. "") then -
$   dns 			WATCHER_TRACE	WATCHER_DIR:WATCHER_TRACE.LOG
$
$ if (f$search("WATCHER_DIR:WATCHER.LOG;-1") .nes. "") then -
$   purge/keep=5 WATCHER_DIR:WATCHER.LOG
$
$ WATCHER_AST_LIMIT == 50
$ WATCHER_BUFFER_LIMIT == 2048
$ WATCHER_ENQUE_LIMIT == 10
$ WATCHER_EXTENT == 2048
$ WATCHER_IO_BUFFERED = 32
$ WATCHER_IO_DIRECT == 32
$ WATCHER_FILE_LIMIT == 10
$ WATCHER_PAGE_FILE == 16384
$ WATCHER_QUEUE_LIMIT == 50
$
$ RUN/DETACHED/OUTPUT=NL:/PROCESS="Watcher"-
    /AST_LIMIT=50/BUFFER=2048/ENQUE=10/EXTENT=2048-
    /FILE_LIMIT=10/IO_BUF=32/IO_DIR=32/JOB_TABLE=0-
    /MAXIMUM=512/TIME_LIMIT=0/PAGE_FILE=16384/QUEUE_LIMIT=50-
    /PRIV=(NOSAME,TMPMBX,NETMBX,OPER,WORLD,SHARE,SYSNAM,-
    	    PRMMBX,SYSPRV,CMKRNL,PSWAPM)-
    /INPUT=WATCHER_DIR:WATCHER.COM -
    /OUTPUT=WATCHER_LOG: -
    SYS$SYSTEM:LOGINOUT.EXE
$ EXIT 1
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
