.TITLE	    WCP_MSG
.FACILITY   WCP,1076/PREFIX=WCP__
.IDENT	    "V1.1-1"
!+
! DESCRIPTION:
!
!   This module contains message codes used by the WCP utility.
!
! AUTHOR:
!
!   M. Madison
!
!   Copyright (c) 2010, Matthew Madison.
!
!   All rights reserved.
!
!   Redistribution and use in source and binary forms, with or without
!   modification, are permitted provided that the following conditions
!   are met:
!
!       * Redistributions of source code must retain the above
!         copyright notice, this list of conditions and the following
!         disclaimer.
!       * Redistributions in binary form must reproduce the above
!         copyright notice, this list of conditions and the following
!         disclaimer in the documentation and/or other materials provided
!         with the distribution.
!       * Neither the name of the copyright owner nor the names of any
!         other contributors may be used to endorse or promote products
!         derived from this software without specific prior written
!         permission.
!
!   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
!   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
!   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
!   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
!   OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
!   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
!   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
!   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
!   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
!   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
!   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
!
! UPDATE HISTORY:
!
!   16-NOV-1989	V1.0	Madison	    Initial coding.
!   07-JAN-1991	V1.1	Madison	    Add NOPRIV.
!   06-SEP-2010 V1.1-1  Sneddon     Updated license to BSD at request of M. Madison.
!-
.SEVERITY   	ERROR
NOPRIV	    	<no privilege for attempted operation (!AS required)>/FAO=1

.SEVERITY   	WARNING
RECNOTFOUND 	<no record found to match "!AS">/FAO=1
IDERR	    	<error translating identifer "!AS">/FAO=1
UICERR	    	<error translating UIC "!AS">/FAO=1
CANTIND	    	<failed to redirect input stream>
NORDCFG	    	<could not read configuration file !AS>/FAO=1
NOWRTCFG    	<could not write configuration file !AS>/FAO=1
NOOPNOUT    	<could not open output file !AS>/FAO=1
NOCONTACT   	<unable to contact WATCHER process>

.SEVERITY   	INFORMATION
READCFG	    	<read configuration from file !AS>/FAO=1
WROTECFG    	<wrote configuration to file !AS>/FAO=1
VERSION	    	<WATCHER Control Program, version !AS>/FAO=1

.END
