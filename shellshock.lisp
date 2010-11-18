;;;; shellshock.lisp

;;;; This file contains the package and other top-level definitions
;;;; for the SHELLSHOCK package.

;;; Copyright (C) 2010 Joseph F. Miklojcik III.
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use,
;;; copy, modify, merge, publish, distribute, sublicense, and/or sell
;;; copies of the Software, and to permit persons to whom the
;;; Software is furnished to do so, subject to the following
;;; conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;; 
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (progn
    (asdf:operate 'asdf:load-op 'boxen)
    (boxen:arm) ))

(defpackage #:shellshock
  (:documentation
   ┌──────────────────────────────────────────────────────────────────
   │Use this package to execute shell commands from within the
   │programs you have so defiantly not written in Python or Ruby.
   │Calling SHELLSHOCK:ARM will set #! as a macro character, so you
   │can write shell commands in your program without any
   │hyper-quoting.  From #! to the end of the line will be replaced
   │with a closure that runs that shell command exactly, collecting
   │stdout and stderr into a string.
   │
   │Heaven help you if the child process wants input, hangs, or if
   │anything at all goes wrong.
   └────────────────────────────────────────────────────────────────── )
  (:use #:common-lisp #:sb-ext #:boxen)
  (:export #:*shell* #:*shell-command-arg* #:reader #:arm) )

(in-package :shellshock)

(defvar *shell* "/bin/bash")
(defvar *shell-command-arg* "-c")

(defun reader (input C N)
  ┌──────────────────────────────────────────────────────────────────────
  │This is meant to be set as the function for a macro character.  See
  │SET-MACRO-CHARACTER for details on how the arguments are used.
  │This reads until the end of the line, then creates a closure that
  │runs that in a shell named by *SHELL* using the
  │*SHELL-COMMAND-ARGS* argument.  The resulting closure returns all
  │of stdout and stderr as a string.  Example:
  │
  │CL-USER> (defun foo ()
  │           #! date
  │         )
  │FOO
  │CL-USER> (foo)
  │"Sun Apr 25 14:41:43 EDT 2010
  │"
  │CL-USER> (foo)
  │"Sun Apr 25 14:41:45 EDT 2010
  │"
  │
  │Note that you needn't hyperquote.  Compare:
  │
  │foo = `python2.4 \`which foo\` update "$BAR"`
  │
  │Are you sure you quoted $BAR correctly?
  │
  │(setf foo #! python2.4 `which foo` update "$BAR"
  │  )
  │
  │This only works on SBCL.  It fails cryptically and miserably if
  │anything at all goes wrong.  Note also that there is no way to
  │enter multi-line shell commands with this syntax.
  └──────────────────────────────────────────────────────────────────────
  (unless (equal C #\!)
    (warn "SHELLSHOCK:READER called on a sub-character that is not #\!.") )
  (unless (null N)
    (warn "SHELLSHOCK:READER called with a number before the sub-character?") )
  `(funcall #'(lambda ()
		(with-output-to-string (out)
		  (sb-ext:run-program *shell*
				      '(,*shell-command-arg* ,(read-line input))
				      :output out
				      :error :output )))))

(defun arm ()
  (set-macro-character #\$ #'reader) )
