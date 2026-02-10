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

(defun get-lisp-callback-and-destroy-std-fn (id)
  (bt:with-recursive-lock-held (*std-function-lock*)
    (destructuring-bind (lisp-callback function-ptr)
        (or (gethash id *std-functions*) (error "Standard function callback ID not found: ~a" id))
      (destroy-std-function function-ptr)
      (remhash id *std-functions*)
      lisp-callback)))

(cffi:defcallback std-function-c-callback :void ((qvariant-ptr :pointer)
                                                 (id :int))
  (funcall (get-lisp-callback-and-destroy-std-fn id) (unvariant qvariant-ptr)))

(defun create-std-function-for-lisp-callback (lisp-callback)
  (bt:with-recursive-lock-held (*std-function-lock*)
    (let* ((function-id (incf *std-function-counter*))
           (function-ptr (create-std-function (cffi:callback std-function-c-callback) function-id)))
      (setf (gethash function-id *std-functions*)
            (list lisp-callback function-ptr))
      function-ptr)))

(define-marshalling-test (value :|const std::function<void (const QVariant &)>&|)
  (functionp value))

(defmarshal (value :|const std::function<void (const QVariant &)>&| :around cont)
  (funcall cont (create-std-function-for-lisp-callback value)))
