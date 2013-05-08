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
$ exit VMI$_SUCCESS
