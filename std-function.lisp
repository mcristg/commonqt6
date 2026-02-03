;;; -*- show-trailing-whitespace: t; indent-tabs-mode: nil -*-

;;; std::function callback support for Qt6 QWebEnginePage::runJavaScript
;;; This file provides CFFI bindings and marshallers to bridge Lisp callbacks
;;; to C++ std::function parameters in Qt6.

(in-package :qt)
(named-readtables:in-readtable :qt)

;;; ============================================================================
;;; CFFI Bindings to the C++ wrapper library (compiled into commonqt6.dll)
;;; ============================================================================

;;; The std::function bridge helpers are compiled into the main commonqt/commonqt6 library,
;;; so we use qt:*FOREIGN-LIBRARY* to access them (the same library that provides the rest
;;; of the Qt bindings).

;;; Import the foreign library that's already defined by the qt package.
;;; The std::function bridge code is compiled into commonqt6.dll, so no separate library is needed.

;;; Create a std::function wrapper from a C callback and user_data.
;;;
;;; These are defined in qwebengine-std-function.cpp and compiled into the main
;;; commonqt6.dll library.
;;;
;;; Args:
;;;   c_callback: a CFFI callback (void (*)(const QVariant*, void*))
;;;   user_data: opaque pointer to pass to the callback
;;;
;;; Returns: opaque pointer to a wrapper (must be freed with destroy-std-function-wrapper)
(cffi:defcfun ("create_std_function_wrapper" create-std-function-wrapper)
    :pointer
  (c-callback :pointer)
  (user-data :pointer))

;;; Destroy a std::function wrapper created by create-std-function-wrapper.
(cffi:defcfun ("destroy_std_function_wrapper" destroy-std-function-wrapper)
    :void
  (wrapper-ptr :pointer))

;;; Get the actual std::function<void(const QVariant&)>* pointer from a wrapper.
;;; This is used internally to pass to Qt's runJavaScript.
(cffi:defcfun ("get_std_function_ptr" get-std-function-ptr)
    :pointer
  (wrapper-ptr :pointer))

;;; ============================================================================
;;; Storage for callback wrappers and their associated Lisp callbacks
;;; ============================================================================

;;; Keep track of active std::function wrappers and their Lisp callbacks
;;; so we can ensure the Lisp callbacks stay alive for the duration.
(defparameter *std-function-wrappers* (make-hash-table :test #'eql))
(defparameter *std-function-wrapper-counter* 0)
(defvar *std-function-wrapper-lock* (sb-thread:make-mutex :name "std-function-wrappers"))

;;; ============================================================================
;;; Marshal helper: convert a Lisp callback to a std::function parameter
;;; ============================================================================

(defun create-std-function-for-lisp-callback (lisp-callback)
  "Create a std::function wrapper that will invoke a Lisp callback.

    Args:
      lisp-callback: a Lisp function to call when the C++ code invokes the callback

    Returns: a pointer suitable for passing as a std::function parameter to Qt,
             and an opaque wrapper ID to pass to destroy-std-function-callback later."
  (let* ((wrapper-id (sb-thread:with-mutex (*std-function-wrapper-lock*)
                       (incf *std-function-wrapper-counter*))))

    ;; Define the C callback that will invoke the Lisp function. We don't
    ;; bind its return value to a local variable because the symbol
    ;; `std-function-c-callback` is the name used to obtain a pointer below.
    (cffi:defcallback std-function-c-callback :void
        ((qvariant-ptr :pointer)
         (user-data :pointer))
      (declare (ignore user-data))
      (let ((result (qt::%qobject (qt::find-qclass "QVariant") qvariant-ptr)))
        (funcall lisp-callback result)))

    ;; Convert the C callback to a pointer and create the wrapper
    (let* ((c-callback-ptr (cffi:callback std-function-c-callback))
           (wrapper-ptr (create-std-function-wrapper c-callback-ptr
                                                     (cffi:make-pointer wrapper-id))))

      ;; Store the Lisp callback and C callback pointer for later cleanup
      (sb-thread:with-mutex (*std-function-wrapper-lock*)
        (setf (gethash wrapper-id *std-function-wrappers*)
              (list lisp-callback c-callback-ptr wrapper-ptr)))

      (values wrapper-ptr wrapper-id))))

(defun destroy-std-function-callback (wrapper-ptr wrapper-id)
  "Clean up a std::function wrapper and its associated Lisp callback.

   Args:
     wrapper-ptr: pointer returned from create-std-function-for-lisp-callback
     wrapper-id: the wrapper ID returned from create-std-function-for-lisp-callback"
  (sb-thread:with-mutex (*std-function-wrapper-lock*)
    (remhash wrapper-id *std-function-wrappers*))
  (destroy-std-function-wrapper wrapper-ptr))

;;; ============================================================================
;;; Marshalling definition for std::function<void(const QVariant&)>
;;; ============================================================================

;;; When marshalling a Lisp callback to a std::function parameter,
;;; create a wrapper and return the std::function pointer. Ensure the
;;; wrapper is cleaned up after the call via unwind-protect.
(define-marshalling-test (value :|std::function<void (const QVariant&)>|)
  (functionp value))
(define-marshalling-test (value :|std::function<void(const QVariant&)>|)
  (functionp value))
(define-marshalling-test (value :|const std::function<void (const QVariant&)>&|)
  (functionp value))
(define-marshalling-test (value :|const std::function<void(const QVariant&)>&|)
  (functionp value))
(define-marshalling-test (value :|std::function<void (const QVariant&)>&|)
  (functionp value))
(define-marshalling-test (value :|std::function<void(const QVariant&)>&|)
  (functionp value))
(define-marshalling-test (value :|const std::function<void (const QVariant &)>&|)
  (functionp value))
(define-marshalling-test (value :|std::function<void (QVariant)>|)
  (functionp value))
(define-marshalling-test (value :|std::function<void(QVariant)>|)
  (functionp value))
(define-marshalling-test (value :|const std::function<void (QVariant)>&|)
  (functionp value))
(define-marshalling-test (value :|std::function<void (QVariant)>&|)
  (functionp value))
(defmarshal (value :|std::function<void (const QVariant&)>| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|std::function<void(const QVariant&)>| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|const std::function<void (const QVariant&)>&| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|const std::function<void(const QVariant&)>&| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|std::function<void (const QVariant&)>&| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|std::function<void(const QVariant&)>&| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|const std::function<void (const QVariant &)>&| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|std::function<void (QVariant)>| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|std::function<void(QVariant)>| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|const std::function<void (QVariant)>&| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))

(defmarshal (value :|std::function<void (QVariant)>&| :around cont)
  (multiple-value-bind (wrapper-ptr wrapper-id)
      (create-std-function-for-lisp-callback value)
    (unwind-protect
         (funcall cont (get-std-function-ptr wrapper-ptr))
      (destroy-std-function-callback wrapper-ptr wrapper-id))))
