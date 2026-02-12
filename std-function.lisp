;;; -*- show-trailing-whitespace: t; indent-tabs-mode: nil -*-

(in-package :qt)
(named-readtables:in-readtable :qt)

(cffi:defcfun ("sw_create_std_function" create-std-function)
  :pointer
  (c-callback :pointer)
  (id :int))

(cffi:defcfun ("sw_destroy_std_function" destroy-std-function)
  :void
  (function-ptr :pointer))

(defparameter *std-functions* (make-hash-table))
(defparameter *std-function-counter* 0)
(defvar *std-function-lock* (bt:make-recursive-lock "std-functions"))

(defun find-and-unregister-lisp-callback (id)
  (bt:with-recursive-lock-held (*std-function-lock*)
    (let ((lisp-callback (or (gethash id *std-functions*)
                             (error "Standard function callback ID not found: ~a" id))))
      (remhash id *std-functions*)
      lisp-callback)))

(cffi:defcallback std-function-c-callback :void ((qvariant-ptr :pointer)
                                                 (id :int))
  (funcall (find-and-unregister-lisp-callback id) (unvariant qvariant-ptr)))

(defconstant +max-int+ (1- (expt 2 (1- (* 8 (cffi:foreign-type-size :int))))))

(defun create-std-function-for-lisp-callback (lisp-callback)
  (bt:with-recursive-lock-held (*std-function-lock*)
    (let ((function-id (setq *std-function-counter*
                             (mod (1+ *std-function-counter*) +max-int+))))
      (setf (gethash function-id *std-functions*) lisp-callback)
      (create-std-function (cffi:callback std-function-c-callback) function-id))))

(define-marshalling-test (value :|const std::function<void (const QVariant &)>&|)
  (functionp value))

(defmarshal (value :|const std::function<void (const QVariant &)>&| :around cont)
  (let ((std-function (create-std-function-for-lisp-callback value)))
    (unwind-protect
         (funcall cont std-function)
      ;; Qt will copy the std::function so we can destroy it now.
      (destroy-std-function std-function))))
