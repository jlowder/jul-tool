(defsystem jul-tool
    :name "Jul-Tool"
    :version "0.9.0"
    :author "Jason Lowdermilk <jlowdermilk@gmail.com>"
    :licence "MIT"
    :description "Interactive Julian Date Calculator"
    :long-description "Simple command-line tool for converting to and from julian dates, and other date-related functions."
    :depends-on (:julian
                 :prompt)
    :components ((:file "jul-tool")))
