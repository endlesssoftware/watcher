$ IF p1 .EQS. ""
$ THEN doc_dir = "MG_KIT:[WATCHER]"
$ ELSE doc_dir = p1
$ ENDIF
$ IF p2 .EQS. ""
$ THEN outfile = "MG_ETC:[]WATCHER_DOC_LIST.DAT"
$ ELSE outfile = p2
$ ENDIF
$ create 'outfile
$ close/nolog watcher_doc_list
$ open/append watcher_doc_list 'outfile
$ write watcher_doc_list "!"
$ write watcher_doc_list "! WATCHER documentation files."
$ write watcher_doc_list "!"
$ call make_list "''DOC_DIR'WATCHER*.PS"
$ call make_list "''DOC_DIR'WATCHER*.PDF"
$ call make_list "''DOC_DIR'WATCHER*.TXT"
$ call make_list "''DOC_DIR'WATCHER*.HTML"
$ close/nolog watcher_doc_list
$ write sys$output "''outfile' created"
$ exit
$ MAKE_LIST: SUBROUTINE
$  _Loop:
$	file = f$search(p1)
$	if file.eqs."" then exit
$	name = f$parse(file,"","","NAME")+f$parse(file,"","","TYPE")
$	write watcher_doc_list -
	    f$fao("WATCHER_TMP !32AS WATCHER_INSTALL_ROOT:[DOC]", name)
$	goto _loop
$ ENDSUBROUTINE
