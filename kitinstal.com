$! [WATCHER]KITINSTAL.COM
$!
$!  KITINSTAL procedure for installing WATCHER.
$!
$! Copyright (c) 2013, Endless Software Solutions.
$!
$! All rights reserved.
$!
$! Redistribution and use in source and binary forms, with or without
$! modification, are permitted provided that the following conditions
$! are met:
$!
$!     * Redistributions of source code must retain the above
$!       copyright notice, this list of conditions and the following
$!       disclaimer.
$!     * Redistributions in binary form must reproduce the above
$!       copyright notice, this list of conditions and the following
$!       disclaimer in the documentation and/or other materials provided
$!       with the distribution.
$!     * Neither the name of the copyright owner nor the names of any
$!       other contributors may be used to endorse or promote products
$!       derived from this software without specific prior written
$!       permission.
$!
$! THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
$! "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
$! LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
$! A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
$! OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
$! SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
$! LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
$! DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
$! THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
$! (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
$! OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
$!
$ on control_y then goto watcher_control_y
$ on warning then goto watcher_fail
$
$ if (p1 .eqs. "VMI$_INSTALL") then goto watcher_install
$ if (f$element(0,"_",p1) .eqs. "HELP") then goto 'p1'
$ exit VMI$_UNSUPPORTED
$
$watcher_control_y:
$ VMI$CALLBACK CONTROL_Y
$
$watcher_fail:
$ watcher_status == $status
$ exit 'watcher_status
$
$watcher_install:
$ watcher_say := write sys$output
$ define bin_dir vmi$kwd:
$
$ tmp = f$getsyi ("HW_MODEL")
$ if tmp .gt. 0 .and. tmp .lt. 1024
$ then
$   watcher_arch = "VAX"
$   watcher_system_type = 1
$   watcher_system_name = watcher_arch
$ else
$   watcher_system_type = f$getsyi ("ARCH_TYPE")
$   watcher_system_name = f$element(watcher_system_type, ",", "OTHER,VAX,AXP,I64") - ","
$   watcher_arch = f$edit (f$getsyi ("ARCH_NAME"), "TRIM,UPCASE")
$ endif
$ if watcher_arch .eqs. "VAX"
$ then
$   watcher_reqd_vmsver = "V5.4-3"
$   watcher_reqd_vmsver_old = "054"
$   base_saveset   = "B"
$ endif
$ if watcher_arch .eqs. "ALPHA"
$ then
$   watcher_reqd_vmsver = "V6.0"
$   watcher_reqd_vmsver_old = "060"
$   base_saveset   = "C"
$ endif
$ if watcher_arch .eqs. "IA64"
$ then
$   watcher_reqd_vmsver = "V8.2"
$   watcher_reqd_vmsver_old = "082"
$   base_saveset   = "D"
$ endif
$ VMI$CALLBACK CHECK_VMS_VERSION watcher_vmsverok 'watcher_reqd_vmsver_old'
$ if .not. watcher_vmsverok
$ then
$   VMI$CALLBACK MESSAGE E VMSVER -
        "This product requires OpenVMS ''watcher_system_name' ''watcher_reqd_vmsver' to run."
$   exit VMI$_FAILURE
$ endif
$ open/read watcher_t VMI$KWD:WATCHER_INSTALLING_VERSION.DAT
$ read watcher_t watcher_installing_version
$ read watcher_t watcher_kit_version
$ close watcher_t
$
$ watcher_say ""
$ watcher_say f$fao("               WATCHER !AS Installation Procedure",-
                watcher_installing_version)
$ type SYS$INPUT:

        Copyright (c) 2010, Matthew Madison.
        Copyright (c) 2013, Endless Software Solutions.

        All rights reserved.

        Redistribution and use in source and binary forms, with or without
        modification, are permitted provided that the following conditions
        are met:

            * Redistributions of source code must retain the above
              copyright notice, this list of conditions and the following
              disclaimer.
            * Redistributions in binary form must reproduce the above
              copyright notice, this list of conditions and the following
              disclaimer in the documentation and/or other materials provided
              with the distribution.
            * Neither the name of the copyright owner nor the names of any
              other contributors may be used to endorse or promote products
              derived from this software without specific prior written
              permission.

        THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
        "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
        LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
        A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
        OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
        SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
        LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
        DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
        THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
        (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
        OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    WATCHER is an idle terminal monitor.  That is, it logs out
    interactive users after a certain period of inactivity.  WATCHER
    is fully configurable, allowing the system manager to define which
    terminals to watch, what measurements to use, and how long a
    terminal should be idle before getting zapped.  It also includes
    provisions for preventing logouts or overriding inactivity settings
    based on any combination of username, UIC, terminal, privileges,
    image being run, held identifier, and time of day.

    WATCHER runs on VAX/VMS V5.4 and later, OpenVMS Alpha V6.1 and later,
    and OpenVMS Industry Standard 64 V8.2 and later.

$
$ watcher_upgrading = 0
$
$ watcher_do_command = "YES"
$ watcher_do_help = "YES"
$ watcher_do_doc = "YES"
$ watcher_do_source = "NO"
$ watcher_do_startup = "YES"
$
$ watcher_pcsi_db = "SYS$SYSTEM:ESS-''watcher_system_name'VMS-WATCHER-*.PCSI$DATABASE"
$ if (f$search(watcher_pcsi_db) .nes. "")
$ then
$   VMI$CALLBACK MESSAGE E PCSI -
        "This product has already been installed via PRODUCT INSTALL"
$   type SYS$INPUT:

    **** WARNING! ****

    The installation has detected a previous installation via the
    POLYCENTER Software Installation utility (PCSI).  Either remove
    the product via the PRODUCT REMOVE command and restart the
    VMSINSTAL process, or continue to update the software using PCSI
    software kits.

$   exit VMI$_FAILURE
$ endif
$
$ if (f$search("SYS$STARTUP:WATCHER_STARTUP.COM") .nes. "") then -
$   @SYS$STARTUP:WATCHER_STARTUP LOGICALS
$ if (f$trnlnm("WATCHER_ROOT") .eqs. "")
$ then
$   if (f$trnlnm("WATCHER_DIR") .nes. "")
$   then
$     ! need to indicate we found older, pre-V4.2 installation?
$     ! what do we do?
$   else
$     watcher_def_root = "SYS$COMMON:[WATCHER.]"
$   endif
$ else
$   watcher_def_root = f$parse("WATCHER_ROOT:[000000]",,,"DEVICE","NO_CONCEAL") -
                 + f$parse("WATCHER_ROOT:[000000]",,,"DIRECTORY","NO_CONCEAL") -
                 - "[000000]"
$   if (f$search("WATCHER") .nes. "")
$   then
$     VMI$CALLBACK MESSAGE I INSTALDET -
        "An existing installation has been detected at ''watcher_def_root'"
$     watcher_upgrading = 1
$   endif
$ endif
$ watcher_def_root = watcher_def_root - ".]" + "]"
$
$ask_watcher_top:
$ VMI$CALLBACK ASK watcher_root -
        "Where should the watcher root directory be located" -
        'watcher_def_root'
$ if ((f$parse(watcher_root,"$$NOSUCHDEV$$:[$$NOSUCHDIR$$]",,"DEVICE","SYNTAX_ONLY") .eqs. "$$NOSUCHDEV$$:") .or. -
     (f$parse(watcher_root,"$$NOSUCHDEV$$:[$$NOSUCHDIR$$]",,"DIRECTORY","SYNTAX_ONLY") .eqs. "[$$NOSUCHDIR$$]") .or. -
     (f$parse(watcher_root,,,,"SYNTAX_ONLY") .eqs. "") .or. -
     (f$locate(">[",watcher_root) .lt. f$length(watcher_root) .or. f$locate("]<",watcher_root) .lt. f$length(watcher_root)))
$ then
$   type SYS$INPUT:

    Please enter a device and directory specification.

$   goto ask_watcher_top
$ endif
$
$ if (watcher_upgrading .and. (watcher_def_root .eqs. watcher_root))
$ then
$   vmi$callback ask watcher_ok -
        "Do you want to upgrade the current installation" -
        "YES" BH "@VMI$KWD:KITINSTAL HELP_UPGRADE"
$   if (.not. watcher_ok) then goto ask_watcher_top
$ endif
$
$ VMI$CALLBACK ASK watcher_do_command -
        "Do you want to install the WATCHER command into DCLTABLES" -
        'watcher_do_command' B "@VMI$KWD:KITINSTAL HELP_COMMAND"
$
$ VMI$CALLBACK ASK watcher_do_help -
        "Do you want to add WATCHER to the system help library" -
        'watcher_do_help' B "@VMI$KWD:KITINSTAL HELP_HELP"
$
$ VMI$CALLBACK ASK watcher_do_doc -
        "Do you want to install the software documentation" -
        'watcher_do_doc' B "@VMI$KWD:KITINSTAL HELP_DOC"
$
$ VMI$CALLBACK ASK watcher_do_source -
        "Do you want to install the source code" -
        'watcher_do_source' B "@VMI$KWD:KITINSTAL HELP_SOURCE"
$
$ VMI$CALLBACK ASK watcher_do_startup -
        "Copy system startup procedure to SYS$STARTUP" -
        'watcher_do_startup' B "@VMI$KWD:KITINSTAL HELP_STARTUP"
$
$ VMI$CALLBACK MESSAGE I INSTALL "Installing WATCHER software..."
$
$ watcher_root = f$parse(watcher_root,,,"DEVICE","SYNTAX_ONLY") -
	+ "[" + (f$extract(1,-1,f$parse(watcher_root,,,"DIRECTORY","SYNTAX_ONLY")) -
	- "][" - "><" - ">[" - "]<" - "]" - ">")
$ watcher_iroot = f$parse(watcher_root+"]",,,"DEVICE","SYNTAX_ONLY,NO_CONCEAL") -
	+ "[" + (f$extract(1,-1,f$parse(watcher_root+"]",,,"DIRECTORY","NO_CONCEAL,SYNTAX_ONLY")) -
	- "][" - "><" - ">[" - "]<" - "]" - ">") + "]"
$ watcher_install_device = f$parse(watcher_iroot,,,"DEVICE")
$ watcher_install_root = "WATCHER_DEVICE:"+ f$parse(watcher_iroot,,,"DIRECTORY") - "]" + ".]"
$ define WATCHER_DEVICE 'watcher_install_device'/TRANSLATION=(CONCEALED,TERMINAL)
$ define WATCHER_INSTALL_ROOT 'watcher_install_root'/TRANSLATION=CONCEALED
$ define WATCHER_ROOT 'watcher_install_root'/TRANSLATION=CONCEALED
$
$ if (f$parse("''watcher_root']") .eqs. "") then -
    VMI$CALLBACK CREATE_DIRECTORY USER 'watcher_root'] -
                "/OWNER=[1,4]/PROT=(S:RWE,O:RWE,G:RE,W:E)"
$
$ if (f$parse("''watcher_root'.''watcher_arch'_EXE]") .eqs. "") then -
    VMI$CALLBACK CREATE_DIRECTORY USER 'watcher_root'.'watcher_arch'_exe] -
                "/OWNER=[1,4]/PROT=(S:RWE,O:RWE,G:RE,W:E)"
$
$ if (watcher_do_command) then -
$    VMI$CALLBACK PROVIDE_DCL_COMMAND WCP_CMD_CLD.CLD
$
$ if (watcher_do_help)
$ then
$    VMI$CALLBACK PROVIDE_DCL_HELP WATCHER_HELP.HLP
$    VMI$CALLBACK PROVIDE_DCL_HELP WCP_HELP.HLP
$ endif
$ VMI$CALLBACK PROVIDE_FILE W_TMP WCP_HELPLIB.HLB 'watcher_root'] K
$
$ VMI$CALLBACK PROVIDE_FILE W_TMP SAMPLE_CONFIG.WCP 'watcher_root'] K
$
$ VMI$CALLBACK PROVIDE_FILE W_TMP WATCHER_LOGOUT.TEMPLATE 'watcher_root'] K
$ VMI$CALLBACK PROVIDE_FILE W_TMP WATCHER_SYSTARTUP.TEMPLATE 'watcher_root'] K
$
$ VMI$CALLBACK PROVIDE_FILE W_TMP DECW_STARTLOGIN.COM 'watcher_root'] K
$ VMI$CALLBACK PROVIDE_FILE W_TMP WATCHER.COM 'watcher_root'] K
$ VMI$CALLBACK PROVIDE_FILE W_TMP WATCHER_MAIL.COM 'watcher_root'] K
$ VMI$CALLBACK PROVIDE_FILE W_TMP WATCHER_SHUTDOWN.COM 'watcher_root'] K
$ VMI$CALLBACK PROVIDE_FILE W_TMP WATCHER___STARTUP.COM 'watcher_root'] K
$
$ VMI$CALLBACK RESTORE_SAVESET 'base_saveset'
$
$ VMI$CALLBACK MESSAGE I LINK "Linking WATCHER software..."
$ watcher_default = F$ENVIRONMENT("DEFAULT")
$ SET DEFAULT VMI$KWD:
$ @VMI$KWD:LINK
$ SET DEFAULT 'watcher_default'
$
$ VMI$CALLBACK PROVIDE_IMAGE W_TMP WATCHER.EXE -
	'watcher_root'.'watcher_arch'_EXE] K
$ VMI$CALLBACK PROVIDE_IMAGE W_TMP FORCE_EXIT.EXE -
	'watcher_root'.'watcher_arch'_EXE] K
$ VMI$CALLBACK PROVIDE_IMAGE W_TMP WCP.EXE -
	'watcher_root'.'watcher_arch'_EXE] K
$
$ if (watcher_do_doc)
$ then
$   VMI$CALLBACK MESSAGE I INSTALL_DOC "Installing documentation files..."
$   if (f$parse("''watcher_root'.DOC]").eqs."") then -
        VMI$CALLBACK CREATE_DIRECTORY USER 'watcher_root'.DOC] -
                "/OWNER=[1,4]/PROT=(S:RWE,O:RWE,G:R,W:R)"
$   VMI$CALLBACK PROVIDE_FILE "" WATCHER_DOC_LIST.DAT "" T
$ endif
$
$ if (watcher_do_source)
$ then
$   VMI$CALLBACK MESSAGE I INSTALL_SOURCE "Installing source kit..."
$   if (f$parse("''watcher_root'.SRC]") .eqs. "")
$   then
        VMI$CALLBACK CREATE_DIRECTORY USER 'watcher_root'.SRC] -
                "/owner=[1,4]/prot=(s:rwe,o:rwe,g:r,w:r)"
$   endif
$   VMI$CALLBACK RESTORE_SAVESET E
$   VMI$CALLBACK PROVIDE_FILE W_TMP -
	WATCHER'watcher_kit_version'_SOURCE.ZIP 'watcher_root'.SRC]
$ endif
$
$ close/nolog sp
$ open/write sp VMI$KWD:WATCHER_STARTUP.COM
$ write sp "$! WATCHER Startup Procedure -- generated by VMSINSTAL at ''f$time()'"
$ write sp "$ set noon"
$ write sp "$ @''watcher_root']WATCHER___STARTUP.COM 'p1' 'p2' 'p3' 'p4' "-
	+ "'p5' 'p6' 'p7' 'p8'"
$ write sp "$ exitt 1"
$ close/nolog sp
$
$ if (watcher_do_startup)
$ then
$    VMI$CALLBACK PROVIDE_FILE W_TMP WATCHER_STARTUP.COM -
        VMI$ROOT:[SYS$STARTUP] C
$    VMI$CALLBACK SET STARTUP WATCHER_STARTUP.COM LOGICALS
$ endif
$
$ exit VMI$_SUCCESS
$help_upgrade:
$ type SYS$INPUT:

    The following version of WATCHER has been detected by the
    installation procedure:

$ wcp show version
$ type SYS$INPUT:

    To replace this installation with the software in this
    software installation kit, answer YES.  To chose another
    directory to install to, answer NO and enter a different
    path.  To exit this installation completely type CTRL/Y.

$ exit VMI$_SUCCESS
$help_command:
$ type sys$input:

    The WATCHER WCP utility can be installed into DCLTABLES
    making it a known command.  This is not a critical feature
    of the product and it is easy enough to run WCP by simply
    defining a symbol (foreign command) to point to the
    executable.  To install WCP in the system command tables,
    answer YES to this question.

$ exit VMI$_SUCCESS
$help_help:
$ type sys$input:

    The WATCHER installation kit includes an online help file
    that can be installed into the system help file.  It can
    then be accessed with the HELP command.  This is not a
    critical feature of the product.  To install the WATCHER
    online help file in the system HELP library, answer YES
    to this question.

$ exit VMI$_SUCCESS
$help_doc:
$ type sys$input:

    The full WATCHER documentation is included in this software kit.
    It is available in HTML, PDF, PostScript and Text formts.  To
    install the documentation, answer YES to this option.

$ exit VMI$_SUCCESS
$help_source:
$ type sys$input:

    WATCHER is open source software and includes the full source of
    the software.  To install a ZIP file containing the source
    code, answer YES to this option.

$ exit VMI$_SUCCESS
$help_startup:
$ type sys$input:

    As part of the installation process WATCHER generates a small
    system startup procedure that needs to be executed before
    using WATCHER.  To make things more convenient, the install
    process can copy this procedure to SYS$STARTUP.  This is
    not a critical feature of the product.

$ exit VMI$_SUCCESS
