(defparameter *mmm*
  '(((a) (a))
    (((? x)) (b))
    ((a b c) (a b c))
    ((a (? x) c) (a b c))
    (((? x) (? y) (? z)) (a b c))
    ((a (b c) d) (a (b c) d))
    ((a ((? x) c) d) (a (b c) d))
    ((a ((? x) (? y)) (? z)) (a (b c) d))
    ((a (b (c d) (e f) g) h) (a (b (c d) (e f) g) h))
    ((a ((? x) (c d) (e (? y)) g) (? z)) (a (b (c d) (e f) g) h)) ) )

(defun dump-hash (ht)
  (maphash #'(lambda (k v) (format t "~A=~A~%" k v)) ht) )

(defun stest (&optional (pairs *mmm*) (ht (make-hash-table)))
  (cond
   ((null pairs) nil)
   (t (let ((p (caar pairs)) (s (cadar pairs)))
	(format t "~%p = ~A: " p)
	(format t "~%s = ~A: " s)
	(cond
	 ((smatch p s ht)
	  (format t "~%SUCCESS: ht-dump:~%")
	  (dump-hash ht) )
	 (t (format t "~%FAIL FAIL FAIL FAIL FAIL~%")) ) )
      (format t "~%type n<return>")
      (read)
      (clrhash ht)
      (stest (cdr pairs) ht) ) ) )

(defparameter *sss*   ; simple test expressions
  '((* z 0)
    (* 0 z)
    (* z 1)
    (expt z 1)
    (expt z 0)
    (d (expt z 2) z)
    (d (* z z) z)
    (d k z)
    (d z z)
    (d (+ z z) z) ) )

(defparameter *fff*  ; non-trivial test expressions
  '((d (+ (expt x 2) (* 2 x)) x)
    (+ (d (expt x 3) x) (d (expt y 5) y))
    (d (+ (+ (+ (* 5 (expt x 3)) (* -3 (expt x 2))) (* 6 x)) 10) x)
    (d (expt (+ z 2) 3) z)
    (d (+ (+ (+ (+ x x) x) x) x) x)
    (d (* (+ (* 3 x) 4) 5) x)
    (d (* (* (* 3 4) 5) x) x)
    (d (expt (expt x 2) 3) x)
    (* 0 (d (expt (expt x 2) 3) x))
    (d (expt (* (+ z 4) (* 10 z)) 3) z) ) )

;;;
;;; convert prefix expression into infix
;;;
(defun pre2infix (expr)
  (cond
   ((atom expr) expr)
   ((= (length expr) 3)
    (let ((op (car expr)))
      (cond
       ((or (eq op '+) (eq op '-) (eq op '*) (eq op '/))
	(list (pre2infix (cadr expr)) op (pre2infix (caddr expr))) )
       ((eq op 'expt)
	(list (pre2infix (cadr expr)) '^ (pre2infix (caddr expr))) )
       (t
	(cons (pre2infix (car expr))
	      (pre2infix (cdr expr)) ) ) ) ) )
   (t
    (cons (pre2infix (car expr))
	  (pre2infix (cdr expr)) ) ) ) )

;;;
;;; test #'reduce-expr on a list of expressions
;;;
(defun ltest (expressions &optional (ht (make-hash-table)))
  (cond
   ((null expressions) (format t "done~%"))
   (t (let* ((f (car expressions))
	     (ff (pre2infix f))
	     (r (reduce-expr f ht))
	     (rr (pre2infix r)) )
	(format t "~%formula: ~A~%infix: ~A" f ff)
	(format t "~%result: ~A~%infix: ~A ~%------~%" r rr)
	(format t "~%type n<return>")
	(read) )
      (ltest (cdr expressions) ht) ) ) )


  
