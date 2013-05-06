.TITLE	    WATCHER_MSG
.FACILITY   WATCHER,1075/PREFIX=WATCHER__
.IDENT	    "V1.3-1"
!+
! DESCRIPTION:
!
!   This module contains message codes used by WATCHER.
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
!   19-MAR-1990	V1.0	Madison	    Initial coding.
!   02-NOV-1990	V1.1	Madison	    Change LOGOUT, DISCONNECT (Ward@Harris)
!   22-MAR-1991	V1.2	Madison	    Add multiple-warnings support. (Kimura@HAC)
!   29-MAR-1991	V1.2-1	Madison	    Fix DISCWARN's FAO_COUNT. (Kimura@HAC)
!   03-FEB-1993	V1.3	Madison	    Add FORCEX-related stuff.
!   06-SEP-2010 V1.3-1  Sneddon     Updated license to BSD at request of M. Madison.
!-
.SEVERITY   	FATAL
NOCFG	    	<no configuration file found>

.SEVERITY   	WARNING
INACTIVE    	<this terminal has been inactive since !8%T (!8%T)>/FAO=2

.SEVERITY   	INFORMATION
DISCWARN    	<disconnection will occur in !8%T at !8%T>/FAO=2
LOGWARN	    	<logout will occur in !8%T at !8%T>/FAO=2
LOGOUT	    	<logging out process due to inactivity at !8%T>/FAO=1
DISCONNECT  	<disconnecting terminal due to inactivity at !8%T>/FAO=1
LOGGEDOUT   	<WATCHER logged out user !AD, pid !XL, term !AD (!AD), last change !%D>/fao=8
DISCONNECTED	<WATCHER disconnected user !AD, pid !XL, term !AD (!AD), last change !%D>/fao=8
FORCEXWARN  	<forced image exit will occur in !8%T at !8%T>/FAO=2
FORCEX	    	<forcing image exit due to inactivity at !8%T>/FAO=1
FORCEDEXIT    	<WATCHER forced image exit of user !AD, pid !XL, term !AD (!AD), last change !%D>/fao=8
