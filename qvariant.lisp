(in-package :qt)
(named-readtables:in-readtable :qt)

(define-marshalling-test (value :|QVariant|)
  (typecase value
    ((or string integer single-float double-float
         boolean) t)
    (qobject
     (or (qtypep value "QVariant")
         (iter (for (nil . type) in (variant-map))
           (thereis (qtypep value type)))))
    (t nil)))

(defmarshal (value :|QVariant| :around cont)
  (funcall cont
           (if (qtypep value "QVariant")
               value
               (qvariant value))))

(defmarshal (value :|const QVariant&| :around cont)
  (if (qtypep value "QVariant")
      (funcall cont value)
      (let ((variant (qvariant value)))
        (unwind-protect
             (funcall cont variant)
          (#_delete variant)))))

(defmarshal-override (value (:|QVariant| :|const QVariant&|))
  (if (qtypep value "QVariant")
      value
      (qvariant value)))

;;; QVariant has conversion methods for classes in QtCore
;;; *UNVARIANT-TYPES* lists such classes and types, they can be
;;; unvarianted by calling toClass on them.  UNVARIANT-MAP builds an
;;; array from *UNVARIANT-TYPES*, indexed by QVariant type-codes and
;;; containing functions which will call appropriate toClass methods.
;;;
;;; Classes which are from QtGui don't have such methods, so they are
;;; unvarianted by calling constData, constData returns a raw pointer,
;;; so we need to know which class it belongs to.
;;; UNVARIANT-NON-CORE-MAP makes an array from
;;; *UNVARIANT-NON-CORE-TYPES*, it's indexed by the type-code of the
;;; variant and has classes as elements.
;;;
;;; Making a QVariant from an object is easier, just need to call
;;; (#_new QVariant type-code object). VARIANT-MAP builds a map from
;;; classes to type-codes.

(defparameter *unvariant-non-core-types*
  '("QBitmap" "QBrush" "QColor" "QCursor" "QFont" "QIcon" "QImage" "QKeySequence"
    "QMatrix4x4" "QPalette" "QPen" "QPixmap" "QPolygon" "QQuaternion" "QRegion"
    "QSizePolicy" "QTextFormat" "QTextLength" "QTransform" "QVector2D" "QVector3D"
    "QVector4D"))

(defparameter *unvariant-types*
  '(("Bool" "toBool") ("Int" "toInt") ("UInt" "toUInt") ("LongLong" "toLongLong")
    ("ULongLong" "toULongLong") ("Double" "toDouble") ("Char" "toChar")
    ("QVariantMap" "toMap") ("QVariantList" "toList") ("QString" "toString")
    ("QStringList" "toStringList") ("QByteArray" "toByteArray") ("QBitArray" "toBitArray")
    ("QDate" "toDate") ("QTime" "toTime") ("QDateTime" "toDateTime") ("QUrl" "toUrl")
    ("QLocale" "toLocale") ("QRect" "toRect") ("QRectF" "toRectF") ("QSize" "toSize")
    ("QSizeF" "toSizeF") ("QLine" "toLine") ("QLineF" "toLineF") ("QPoint" "toPoint")
    ("QPointF" "toPointF") ("QRegularExpression" "toRegularExpression") ("QVariantHash" "toHash")
    ("QEasingCurve" "toEasingCurve")))

(defparameter *qmetatypes*
  (append '("QByteArray" "QBitArray" "QDate" "QTime" "QDateTime" "QUrl" "QChar"
            "QLocale" "QRect" "QRectF" "QSize" "QSizeF" "QLine" "QLineF" "QPoint" "QPointF"
            "QRegularExpression" "QEasingCurve")
          *unvariant-non-core-types*))

(defun variant-map ()
  (with-cache ()
    (loop for type in *qmetatypes*
          for class = (find-qclass type nil)
          when class
            collect (cons (enum-value
			   (interpret-call "QMetaType" type))
                          class))))

(defun unvariant-map ()
  (with-cache ()
    (let ((new-map (make-hash-table)))
      ;; Leave invalid QVariant as it is
      (setf (gethash 0 new-map) #'identity)
      (loop for (type method) in *unvariant-types*
            for enum = (enum-value
			(interpret-call "QMetaType" type))
            do (setf (gethash enum new-map)
                     method))
      new-map)))

(defun unvariant-non-core-map ()
  (with-cache ()
    (let ((new-map (make-hash-table)))
      (loop for type in *unvariant-non-core-types*
            for enum = (enum-value
                        (interpret-call "QMetaType" type))
            do (setf (gethash enum new-map)
                     (find-qclass type)))
      new-map)))

(defun qvariant (value)
  ;; Memory managment of QVariants is unclear,
  ;; in some cases it can be deleted automatically, while not in others.
  ;; Disable caching, otherwise they will be stuck in the cache forever.
  (let ((*inhibit-caching* t))
    (etypecase value
      (string (#_new QVariant :|const QString&| value))
      (integer (#_new QVariant :|int| value))
      ((or single-float double-float) (#_new QVariant :|double| value))
      (boolean (#_new QVariant :|bool| value))
      (qobject
       (iter (for (code . type) in (variant-map))
         (when (qtypep value type)
           (return (with-objects ((type (#_new QMetaType code)))
		     (#_new QVariant type (qobject-pointer value)))))
         (finally (return value)))))))

(defun %unvariant (unvariant-map variant type)
  (let ((function (gethash type unvariant-map)))
    (when (stringp function)
      (setf function
            (compile nil `(lambda (x)
                            (optimized-call nil x ,function)))
            (gethash type unvariant-map) function))
    (funcall function variant)))

(defun unvariant (variant &optional (type (find-qtype "QVariant")))
  (let* ((qobject (%qobject (qtype-class type) variant))
         (code (#_typeId qobject))
         (unvariant-map (unvariant-map)))
    (let ((method (and unvariant-map (gethash code unvariant-map))))
      (if method
          (%unvariant unvariant-map qobject code)
          (let* ((non-core-map (unvariant-non-core-map))
                 (class (and non-core-map (gethash code non-core-map))))
            (if class
                (%qobject class (#_constData qobject))
                qobject))))))
