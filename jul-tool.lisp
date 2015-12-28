(in-package :cl-user)

(defpackage :jul-tool
  (:use :common-lisp
        :julian
        :prompt)
  (:export :jul-tool))

(in-package :jul-tool)

(defparameter command '())
(defparameter args '())
(defparameter tz-offset nil)
(defvar reg-a 0)
(defvar reg-b 0)
(defparameter *days* '(0 "Monday" 1 "Tuesday" 2 "Wednesday" 3 "Thursday" 4 "Friday" 5 "Saturday" 6 "Sunday"))
(defconstant unix-epoch 210866760000)
(defconstant j2000-epoch 211813488000)
(defparameter *prompts* '())

(defun current-gregorian-date ()
  (multiple-value-bind
        (second minute hour date month year day-of-week dst-p tz)
      (get-decoded-time)
    (declare (ignore day-of-week dst-p))
    (when (null tz-offset)
      (setf tz-offset (* tz (/ 86400 24))))
    (list year month date hour minute second)))

(defun parse-julian-hms (julian) ; seconds since epoch
  (let* ((rem (mod (- julian 43200) 86400))
         (hours (truncate (/ rem 3600)))
         (minutes (truncate (/ (- rem (* hours 3600)) 60)))
         (seconds (truncate (- rem (* hours 3600) (* minutes 60)))))
    (list hours minutes seconds)))
    
(defun julian->date-time (julian) ; in seconds since epoch
  (destructuring-bind (hour minute second)
      (parse-julian-hms julian)
    (destructuring-bind (year month day)
        (julian->gregorian (round (/ julian 86400.l0)))
      (list year month day hour minute second))))
  
(defun current-julian-date ()
  (destructuring-bind (year month day hour minute second)
      (current-gregorian-date)
    (+ (* 86400 (gregorian->julian year month day))
          (* hour 3600) (* minute 60) second -43200)))

(defun display ()
  (destructuring-bind (year month day hour minute second)
      (julian->date-time reg-a)
    (format t "Julian: ~F   Gregorian: ~4,'0D/~2,'0D/~2,'0D ~2,'0D:~2,'0D:~2,'0D~%" (/ reg-a 86400.l0) year month day hour minute second)))

(defun parse-string-to-float (string)
  (let ((*read-eval* nil))
    (with-input-from-string (stream (concatenate 'string string "l0"))
      (car (loop for number = (read stream nil nil)
            while number collect number)))))

(defun gmtset ()
  (flet ((remz (s)
           (let ((r (search "0" s)))
             (if (and (numberp r) (= 0 r))
                 (subseq s 1)
                 s))))
    ;; gmtset hhmmss, yymmdd
    (destructuring-bind (year month day hour minute second)
        (julian->date-time reg-a)
      (let ((str1 (format nil "~2,'0D~2,'0D~2,'0D" hour minute second))
            (str2 (format nil "~2,'0D~2,'0D~2,'0D" (- year 2000) month day)))
        (format t "gmtset ~A, ~A~%" (remz str1) (remz str2))))))

(defun unixtime ()
  (format t "Unix time: ~A~%" (- reg-a unix-epoch))) 

(defun j2000 () ; 2000.0 + (Julian date − 2451545.0)/365.25
  (format t "J2000 time: ~F~%" (+ 2000.0l0 (/ (/ (- reg-a j2000-epoch) 86400l0) 365.25l0))))

(defun read-j2000 (str) ; 2000.0 + (Julian date − 2451545.0)/365.25
  (let* ((base (parse-string-to-float str))
         (partial (- base 2000.0l0))
         (days (* partial 365.25l0))) ; days after 2000 1 1
    (setf reg-a (+ j2000-epoch (round (* days 86400l0))))))

(defun tle ()
  (destructuring-bind (year month day hour minute second)
      (julian->date-time reg-a)
    (declare (ignore hour minute second))
    (let ((short (multiple-value-bind (one two) (truncate (/ year 100l0))
                   (declare (ignore one)) two)))
      (multiple-value-bind (main rest) (truncate (/ (+ reg-a -43200) 86400l0))
        (declare (ignore main))
        (let ((rem (format nil "~8$" rest)))
          (format t "TLE time: ~D~3,'0D~A~%" (round (* 100.0l0 short)) (day-of-year year month day) (subseq rem 1)))))))
    
(defun read-tletime (str)
  (let* ((year (+ 2000 (parse-integer (subseq str 0 2))))
         (jday (round (* 86400l0 (parse-string-to-float (subseq str 2)))))
         (base (* 86400 (gregorian->julian year 1 1))))
    (setf reg-a (+ base jday -86400 -43200))))

(defun read-unixtime (str)
  (setf reg-a (+ unix-epoch (parse-integer str :junk-allowed t))))

(defun setprompt ()
  (setf (get 'prompt *prompts*) (format nil "~D> " (round (/ reg-a 86400l0)))))

(defprompt ("q" "quit" *prompts*)
  (end-prompt))

(defprompt ("swa" "swap registers a and b" *prompts*)
  (let ((tmp reg-a))
    (setf reg-a reg-b)
    (setf reg-b tmp))
  (setprompt)
  (display))
    
(defprompt ("today" "use current date/time" *prompts*)
  (setf reg-a (current-julian-date))
  (setprompt)
  (display))

(defprompt ("sto" "set register B from register A" *prompts*)
  (setf reg-b reg-a))

(defprompt ("diff" "difference between register A and register B" *prompts*)
  (let ((j (/ (abs (- reg-a reg-b)) 86400l0)))
    (format t "~D days (~F julian" (round j) j)
    (if (< j .04166666666666666666l0)
        (format t ", ~D seconds)~%" (abs (- reg-a reg-b)))
        (format t ")~%")))
  (display))

(defprompt ("vxworks" "display as a vxWorks gmtset command" *prompts*)
  (gmtset))

(defprompt ("+" "add a julian day offset to the current date/time" *prompts*)
  (setf reg-a (+ (round (* 86400 (parse-string-to-float (poparg)))) reg-a))
  (setprompt)
  (display))

(defprompt ("=" "set gregorian date" *prompts*)
  (setf reg-a (* 86400 (gregorian->julian (parse-integer (poparg) :junk-allowed t)
                                          (parse-integer (poparg) :junk-allowed t)
                                          (parse-integer (poparg) :junk-allowed t))))
  (setprompt)
  (display))

(defprompt ("=j" "set julian date" *prompts*)
  (setf reg-a (round (* 86400l0 (parse-string-to-float (poparg)))))
  (setprompt)
  (display))

(defprompt ("j2000" "display as J2000 format" *prompts*)
  (j2000))

(defprompt ("=j2000" "set from astronimical J2000 format" *prompts*)
  (setf reg-a (read-j2000 (poparg)))
  (setprompt)
  (display))

(defprompt ("unix" "display as unix time" *prompts*)
  (unixtime))

(defprompt ("=unix" "set from unix format time" *prompts*)
  (read-unixtime (poparg))
  (setprompt)
  (display))

(defprompt ("tle" "display as TLE format time" *prompts*)
  (tle))

(defprompt ("=tle" "set from the TLE format time string" *prompts*)
  (read-tletime (poparg))
  (setprompt)
  (display))

(defprompt ("tz" "set timezone offset" *prompts*)
  (let* ((offset (* -86400/24 (parse-integer (poparg) :junk-allowed t)))
         (delta (- tz-offset offset)))
    (setf reg-a (+ reg-a delta))
    (setf tz-offset (- tz-offset delta)))
  (setprompt)
  (display))

(defprompt ("info" "display information" *prompts*)
  (destructuring-bind (year month day hour minute second)
      (julian->date-time reg-a)
    (destructuring-bind (gmt-year gmt-month gmt-day gmt-hour gmt-minute gmt-second)
        (julian->date-time (+ reg-a tz-offset))
      (setf gmt-second second)
      (format t "Local: ~2,'0D/~2,'0D/~4,'0D (~D) ~2,'0D:~2,'0D:~2,'0D~%" month day year (truncate (/ reg-a 86400l0)) hour minute second)
      (format t "  UTC: ~2,'0D/~2,'0D/~4,'0D (~D) ~2,'0D:~2,'0D:~2,'0D~%" gmt-month gmt-day gmt-year (truncate (/ (+ tz-offset reg-a) 86400l0)) gmt-hour gmt-minute gmt-second)
      (unixtime)
      (j2000)
      (tle)
      (format t "Local timezone is ~D hours from GMT~%" (round (/ tz-offset -3600)))
      (format t "Day of year: ~A/~A~%" (day-of-year year month day) (days-in-year year))
      (format t "The day of the week is ~A~%" (getf *days* (mod (round (/ reg-a 86400l0)) 7)))
      (format t "~@(~r~) days in this month~%" (days-in-month year month))
      (format t "This day is~[~; not~] in a leap year~%" (cond ((leap-year-p year) 0) (t 1))))))
  
(defun jul-tool ()
  (setf reg-a (current-julian-date))
  (display)
  (prompt
   (format nil "~D> " (round (/ reg-a 86400l0)))
   *prompts* :helpname "?"))

