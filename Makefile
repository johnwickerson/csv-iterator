EXECUTABLE=csv_iterator

all: parser.mly lexer.mll csv_iterator.ml
	ocamlyacc parser.mly
	ocamllex lexer.mll
	ocamlc unix.cma str.cma parser.mli parser.ml lexer.ml csv_iterator.ml -o ${EXECUTABLE}

clean:
	rm -f *.cmo
	rm -f *.cmi
	rm -f lexer.ml parser.ml parser.mli
	rm -f ${EXECUTABLE}

deepclean:
	rm -rf out-*
