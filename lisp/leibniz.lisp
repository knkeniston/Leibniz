(defun smatch (p s &optional (ht (make-hash-table)))
  (cond
   ;; If p is nil, then we have a match iff s is nil.
   ((null p) (if (null s) ht nil))

   ;; If p not nil and s is nil, then there is no match.
   ((null s) nil)

   ;; If p is an atom, then we have a match iff p and s are the same atom.
   ((atom p) (if (eq p s) ht nil))

   ;; At this point p is a non-empty list and s is not nil
   ;; (s could be an atom or a list).
   ;; If p is a joker, then p matches s.
   ((and (= (length p) 2)
         (eq (car p) '?) )
    (setf (gethash (cadr p) ht) s) ; insert (key=(cadr p),val=s) into hash tbl
    ht)

   ;; At this point p is a non-empty list and p is not a joker.
   ;; Therefore, if s is an atom, there is no match.
   ((atom s) nil)

   ;; At this point both p and s and are non-empty lists.
   ;; We have a complete match iff their car's and cdr's both match.
   (t (and (smatch (car p) (car s) ht)
           (smatch (cdr p) (cdr s) ht) )) ) )

(defun phash (ht)
  (maphash #'(lambda (k v) (format t "~A=~A~%" k v)) ht) )

(defparameter *diff-sum-rule*
  (list
   #'(lambda (f ht)
       (smatch '(d (+ (? e1) (? e2)) (? v)) f ht) )
   #'(lambda (ht)
       (let ((v (gethash 'v ht)))
         (list '+ 
               (list 'd (gethash 'e1 ht) v)
               (list 'd (gethash 'e2 ht) v) ) ) )
   '*diff-sum-rule*) )

(defparameter *diff-x-rule*
  (list         
   #'(lambda (f ht)
       (and
        (smatch '(d (? e) (? v)) f ht)
        (equal (gethash 'e ht) (gethash 'v ht)) ) )
   #'(lambda (ht) 1)
   '*diff-x-rule*) )

(defun has-var (v e)
  (cond
   ((null e) nil)
   ((atom e) (eq v e))
   (t (or (has-var v (car e))
          (has-var v (cdr e)) )) ) )

(defparameter *diff-const-rule*
  (list
   #'(lambda (f ht)
       (and
        (smatch '(d (? e) (? v)) f ht)
        (not (has-var (gethash 'v ht) (gethash 'e ht))) ) )
   #'(lambda (ht) 0)
   '*diff-const-rule*) )

(defparameter *diff-product-rule*
  (list
   #'(lambda (f ht)
       (smatch '(d (* (? e1) (? e2)) (? v)) f ht) )
   #'(lambda (ht)
       (let ((e1 (gethash 'e1 ht))
             (e2 (gethash 'e2 ht))
             (v (gethash 'v ht)) )
         (list '+
               (list '* e1 (list 'd e2 v))
               (list '* e2 (list 'd e1 v)) ) ) )
   '*diff-product-rule*) )

(defparameter *diff-power-rule*
  (list
   #'(lambda (f ht)
       (and
        (smatch '(d (expt (? e) (? n)) (? v)) f ht)
        (numberp (gethash 'n ht)) ) )
   #'(lambda (ht)
       (let ((e (gethash 'e ht))
             (n (gethash 'n ht))
             (v (gethash 'v ht)) )
         (list '* n
               (list '* (list 'expt e (- n 1))
                     (list 'd  e v) ) ) ) )
   '*diff-power-rule*) )

(defparameter *fold-binop-rule*
  (list
   #'(lambda (f ht)
       (and
        (smatch '((? op) (? a) (? b)) f ht)
        (numberp (gethash 'a ht)) (numberp (gethash 'b ht))
        (member (gethash 'op ht) '(- + * / expt)) ) )
   #'(lambda (ht)
       (funcall (gethash 'op ht) (gethash 'a ht) (gethash 'b ht)) )
   '*fold-binop-rule*) )

(defparameter *expt0-rule*
  (list
   #'(lambda (f ht)
       (smatch '(expt (? e) 0) f ht) )
   #'(lambda (ht) 1)
   '*expt0-rule*) )

(defparameter *expt1-rule*
  (list
   #'(lambda (f ht)
       (smatch '(expt (? e) 1) f ht) )
   #'(lambda (ht)
       (gethash 'e ht) )
   '*expt1-rule*) )

(defparameter *unity-rule*
  (list
   #'(lambda (f ht)
       (or (smatch '(* (? e) 1) f ht)
           (smatch '(* 1 (? e)) f ht)
           (smatch '(+ (? e) 0) f ht)
           (smatch '(+ 0 (? e)) f ht) ) )
   #'(lambda (ht)
       (gethash 'e ht) )
   '*unity-rule*) )

(defparameter *times0-rule*
  (list
   #'(lambda (f ht)
       (or (smatch '(* (? e) 0) f ht)
           (smatch '(* 0 (? e)) f ht) ) )
   #'(lambda (ht) 0)
   '*times0-rule*) )

(defun rule-test (rule) (car rule))
(defun rule-xform (rule) (cadr rule))
(defun rule-name (rule) (caddr rule))

(defparameter *rules*
  (list *diff-sum-rule* 
        *diff-x-rule* 
        *diff-const-rule* 
        *diff-product-rule* 
        *diff-power-rule* 
        *fold-binop-rule*
        *expt0-rule* 
        *expt1-rule* 
        *unity-rule* 
        *times0-rule*) )

;;;
;;; Try rule on expr recursively.
;;; Ruturn nil if rule never fires,
;;; else return transformed expression.
;;;
(defun try-rule (rule expr ht)
  (cond
   ((atom expr) nil)
   ((funcall (rule-test rule) expr ht)
    (format t "~%~a fires." (rule-name rule))
    (funcall (rule-xform rule) ht) )    ; fire rule
   (t (let ((efirst (try-rule rule (car expr) ht)))
        (cond
         (efirst (cons efirst (cdr expr)))
         (t (let ((erest (try-rule rule (cdr expr) ht)))
              (cond
               (erest (cons (car expr) erest))
               (t nil) ) )) ) )) ) )

;;;
;;; Try all rules on expr recursively.
;;; The transformed expr from the first rule fired is returned.
;;; If no rules fire, then nil is returned.
;;;
(defun try-rules (rules expr ht)
  (if (null rules) 
    nil
    (let ((e (try-rule (car rules) expr ht)))
      (if e e (try-rules (cdr rules) expr ht)) ) ) )

;;;
;;; We continually try our rules on expr as long as some rule fires.
;;; As soon as no rule fires, we return the most recently
;;; transformed expression.
;;;
(defun reduce-expr (expr &optional (ht (make-hash-table)))
  (let ((e (try-rules *rules* expr ht)))
    (if (null e)
      expr
      (reduce-expr e ht) ) ) )

(setf fff '(d (+ (expt x 2) (* 2 x)) x))
(setf hhh (make-hash-table))

        
