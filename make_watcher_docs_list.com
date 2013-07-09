$ IF p1 .EQS. ""
$ THEN doc_dir = "MG_KIT:[WATCHER]"
$ ELSE doc_dir = p1
$ ENDIF
$ IF p2 .EQS. ""
$ THEN outfile = "MG_KIT:[]WATCHER_DOCS_LIST.DAT"
$ ELSE outfile = p2
$ ENDIF
$ create 'outfile
$ close/nolog watcher_docs_list
$ open/append watcher_docs_list 'outfile
$ write watcher_docs_list "!"
$ write watcher_docs_list "! WATCHER documentation files."
$ write watcher_docs_list "!"
$ call make_list "''DOC_DIR'WATCHER*.PS"
$ call make_list "''DOC_DIR'WATCHER*.PDF"
$ call make_list "''DOC_DIR'WATCHER*.TXT"
$ call make_list "''DOC_DIR'WATCHER*.HTML"
$ close/nolog watcher_docs_list
$ write sys$output "''outfile' created"
$ exit
$ MAKE_LIST: SUBROUTINE
$  _Loop:
$	file = f$search(p1)
$	if file.eqs."" then exit
$	name = f$parse(file,"","","NAME")+f$parse(file,"","","TYPE")
$	write watcher_docs_list -
	    f$fao("WATCHER_TMP !32AS WATCHER_INSTALL_ROOT:[DOC]", name)
$	goto _loop
$ ENDSUBROUTINE
