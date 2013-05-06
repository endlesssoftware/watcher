$ ! Procedure:	GENERATE_SYMBOLS.COM
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
		+ f$parse(procedure,,,"DIRECTORY","NO_CONCEAL") - "]["
$
$ set noon
$ set symbol/scope=(nolocal)
$ on warning then goto bail_out
$ on control_y then goto bail_out
$
$ _arch_type = f$getsyi("ARCH_TYPE")
$ _arch_name = f$element(_arch_type,",","OTHER,VAX,ALPHA,I64") - ","
$ _vax = (_arch_type .eq. 1)
$ _axp = (_arch_type .eq. 2)
$ _i64 = (_arch_type .eq. 3)
$ _other = (.not. (_vax .or. _axp .or. _i64))
$
$ say = "write sys$output"
$ err = "call___ err"
$ saysym = "write/symbol sys$output"
$ months = "January/February/March/April/May/June/July/August/September/" -
         + "October/November/December"
$
$init:
$ source = f$edit(p1, "TRIM,UNCOMMENT,COLLAPSE")
$ target = f$edit(p2, "TRIM,UNCOMMENT,COLLAPSE")
$ if ((source .eqs. "") .or. (target .eqs. "")) then -
$    goto err_param
$
$start:
$ close/nolog source_chan
$ open/read source_chan 'source'
$loop:
$ read/end_of_file=endloop source_chan line
$ line = f$edit(line,"UPCASE,UNCOMMENT,TRIM,COLLAPSE")
$ if (line .eqs. "") then goto loop
$ 'f$element(0,"=",line)' = "''f$element(1,"=",line)'"
$ goto loop
$endloop:
$ close/nolog source_chan
$
$ date = f$cvtime("TODAY","ABSOLUTE","DATE")
$
$ err I GENSYM "generating dynamic DOCUMENT symbols for version ''text_version' on ''date'"
$
$ month = f$element(f$integer(f$cvtime(date,, "MONTH")) - 1, "/", months)
$
$ copyyear = f$cvtime(date,, "YEAR")
$ reldate = f$cvtime(date,, "DAY") + "-" -
          + f$edit(f$extract(0, 3, month), "UPCASE") + "-" + copyyear
$ relmonth = month + ", " + copyyear
$ prtdate = f$cvtime(date,, "DAY") + " " -
          + f$extract(0, 3, month) + " " + copyyear
$
$ close/nolog targe_chan
$ open/write target_chan 'target'
$ write target_chan "<DEFINE_SYMBOL>(COPYYEAR\''copyyear')"
$ write target_chan "<DEFINE_SYMBOL>(RELDATE\''reldate')"
$ write target_chan "<DEFINE_SYMBOL>(RELMONTH\''relmonth')"
$ write target_chan "<DEFINE_SYMBOL>(PRTDATE\''prtdate')"
$ write target_chan "<DEFINE_SYMBOL>(VER\''text_version')"
$ close/nolog target_chan
$
$ goto bail_out
$
$err_param:
$ err F INSFPARM "insufficient or incomplete arguments"
$ goto bail_out
$
$bail_out:
$ close/nolog source_chan
$ close/nolog target_chan
$ exitt 1.or.(0*f$verify(__vfy_saved))
$ !+==========================================================================
$ !
$ ! Procedure:	GENERATE_SYMBOLS.COM
$ !
$ ! Purpose:	a template command procedure
$ !
$ ! Parameters:	P1 =
$ !		P2 =
$ !
$ ! History:
$ !		07-SEP-2010, TES; Version V1.0
$ !	001 -	Original version.
$ !-==========================================================================
