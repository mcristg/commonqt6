(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:oos 'asdf:load-op :trivial-features))

;;; system

(defsystem :qt
  :description "Interface for the Qt GUI framework"
  :license "BSD"
  :components
  (#|#-windows
   (:module "so"
    :pathname ""
    :serial t
    :components
    ((makefile "commonqt.pro")
     (:static-file "commonqt.h")
     (cpp->so "commonqt" :depends-on ("commonqt.h"))))|#
   (:module "lisp"
    :pathname ""
    :serial t
    :components
    ((:file "package")
     (:file "utils")
     (:file "ffi")
     (:file "reader")
     (:file "meta-classes")
     (:file "classes")
     (:file "info")
     (:file "marshal")
     (:file "unmarshal")
     (:file "primitive-call")
     (:file "call")
     (:file "meta")
     (:file "qvariant")
     (:file "property")
     (:file "qlist")
     (:file "qapp")
     (:file "connect")
     (:file "std-function")
     (:file "image-utils"))))
  :defsystem-depends-on (:trivial-features)
  :depends-on (:cffi :named-readtables :cl-ppcre :alexandria
               :closer-mop
	       :iterate :trivial-garbage
	       #+(or darwin (not (or sbcl ccl))) :bordeaux-threads))
